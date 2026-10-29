# 消息协议与传输策略

## 目标

- 应用自己的消息内容、解析和 UI 不绑定 Agora SDK。
- 文本统一走自定义 envelope；附件在 OSS 可用时也走 envelope。
- 没有 OSS 时不丢文件：`hybrid` 模式回退到 SDK 原生消息类型。
- 新增消息类型只扩展 `ChatMessageContent` 和 envelope payload，不改 `ChatMessage` 的字段列表。

## Envelope

Agora 传输时使用：

```dart
ChatMessage.createCustomSendMessage(
  targetId: conversationId,
  event: 'app.im.message',
  params: {
    'payload': jsonEncode({
      'v': 1,
      'clientId': 'local-...',
      'kind': 'text',
      'payload': {'text': 'hello'},
    }),
  },
);
```

完整结构：

```json
{
  "v": 1,
  "clientId": "local-179...",
  "kind": "text | image | voice | file | video | location | contact | custom | system",
  "payload": {}
}
```

约束：

- `v` 目前必须为 `1`，未来不兼容变更升版本。
- `clientId` 用于乐观消息/SDK 回显去重。
- 不发送 `localPath`、`secret` 等本机信息；附件只发送已上传的 HTTPS URL。
- 未知 `kind` 或旧 `v` 进入 `UnknownMessageContent`，不会让消息丢失。

### 各类型 payload

| kind | payload |
|---|---|
| text | `{"text":"...","quote":{"messageId":"...","senderId":"...","kind":"image","imageUrl":"https://..."}}`，`quote` 可选；`thumbnailPath` 只存在本机，不进入 payload |
| image | `{"url":"https://...","width":800,"height":600}` |
| voice | `{"url":"https://...","durationSeconds":7}` |
| file | `{"url":"https://...","fileName":"brief.pdf","fileSizeBytes":1234,"mimeType":"application/pdf"}` |
| video | `{"url":"https://...","durationSeconds":12,"width":1920,"height":1080}` |
| location | `{"latitude":31.2,"longitude":121.5,"address":"...","title":"..."}` |
| contact | `{"userId":"...","displayName":"...","avatarUrl":"..."}` |
| custom | `{"event":"...","params":{...}}` |
| system | `{"text":"...","systemType":"..."}` |

## 传输模式

通过编译参数控制：

```shell
flutter run --dart-define=MESSAGE_TRANSPORT=hybrid
```

| 模式 | 文本 | 图片/语音/文件 |
|---|---|---|
| `native` | Agora TXT；带引用的文本仍走 envelope | Agora IMAGE/VOICE/FILE |
| `custom` | envelope | envelope；必须配置 `AttachmentUploader`，否则发送失败并留在 outbox |
| `hybrid`（默认） | envelope | 有 uploader 时 envelope；没有时回退原生类型 |

`hybrid` 的目的：当前还没有 OSS 时，文本已经统一协议，附件仍能正常发送；接上 OSS 后无需改 UI/消息模型。

## OSS 上传 seam

`domain/services/message_transport.dart`：

```dart
abstract interface class AttachmentUploader {
  Future<AttachmentUploadResult?> upload(AttachmentUploadRequest request);
}
```

仓库在发送图片/语音/文件前调用 uploader：

```text
local file
  ↓ uploader.upload()
remote https URL
  ↓ ChatMessageEnvelope
ChatCustomMessageBody(event: app.im.message, params: payload)
```

上传失败/未配置：

- `hybrid` → 原生 SDK 消息（仍可发送）
- `custom` → 抛错，outbox 保留，等待重试/配置修正

`AppDependencies.create(attachmentUploader: ...)` 是注入点。默认未配置，因此当前附件走 hybrid 回退。

### 接入 OSS 后的设置步骤

1. 实现 `OssAttachmentUploader implements AttachmentUploader`，返回 HTTPS URL。
2. 在 App 启动处注入：

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    AgoraImApp(
      attachmentUploader: OssAttachmentUploader(...),
    ),
  );
}
```

3. 保持默认：

```shell
--dart-define=MESSAGE_TRANSPORT=hybrid
```

只要 uploader 返回了 URL，图片、语音、文件都会自动走自定义 envelope；文本本来就默认走 envelope。

如果希望强制失败而不是回退原生：

```shell
--dart-define=MESSAGE_TRANSPORT=custom
```

默认粒度是“所有附件”。如果只希望文档文件走 custom、图片/语音仍 native，可用按类型白名单：

```shell
# 只有文档文件走 OSS/custom；图片、语音仍使用原生消息
--dart-define=MESSAGE_TRANSPORT=hybrid
--dart-define=CUSTOM_ATTACHMENT_KINDS=file
```

默认 `CUSTOM_ATTACHMENT_KINDS=image,voice,file,video`，即 uploader 存在时全部附件走 custom。仓库在 `_sendAttachment` 中先检查 `customAttachmentKinds.contains(content.kind)`，不在白名单就回退原生。


## 接收与 UI

`AgoraChatPlatform._decodeBody`：

1. 如果是 `ChatCustomMessageBody` 且 `event == app.im.message`，解析 envelope；
2. 校验版本/kind/payload；
3. 返回 `ChatMessageContent`；
4. 未知/非法 envelope 继续按普通 `CustomMessageContent` 或 `UnknownMessageContent` 保留。

UI 只 switch `ChatMessageContent`，不区分底层是原生还是 envelope：

```dart
switch (message.content) {
  TextMessageContent(:final text) => ...,
  ImageMessageContent(:final remotePath) => ...,
  VoiceMessageContent(:final remotePath) => ...,
  ...
}
```

自定义图片可以直接用 `Image.network(remotePath)` 展示；自定义语音通过 `UrlSource` 播放，不需要先下载。

## 兼容性

- 旧扁平缓存 JSON：`ChatMessage.fromJson` / `OutboxMessage.fromJson` 自动升级为 content。
- 旧原生消息：仍按 `ChatTextMessageBody` / `ChatImageMessageBody` / `ChatVoiceMessageBody` 映射。
- 新客户端发送的文本 envelope：旧客户端可能显示为“自定义消息”；这是统一协议的预期代价。
- 如果必须兼容旧客户端文本，设 `MESSAGE_TRANSPORT=native`，或后续做双发/迁移开关。

## 新增消息类型

1. 在 `ChatMessageKind` 加 enum 值。
2. 在 `ChatMessageContent` 加 sealed 子类。
3. 在 `ChatMessageEnvelope` 加 payload encode/decode。
4. 在 `AgoraChatPlatform._decodeBody` / `sendCustom` 映射。
5. 在 `MessageBubble` 加渲染或使用默认兜底。
6. 补 content/envelope round-trip 测试。

## 当前未完成

- 没有具体 OSS 实现；只提供 `AttachmentUploader` 接口和 hybrid 回退。
- 文件消息 UI/发送入口已完成：无 uploader 时走 Agora 原生 FILE；配置 uploader 后自动走自定义 envelope。
- 自定义附件的下载目前依赖原生消息能力；接入 OSS 后文件卡片按 remote URL 下载。
- 自定义附件没有缩略图字段；图片先直接显示原图 URL。
- 旧客户端文本兼容需要产品决策（统一协议 vs 双发）。
