# SDK 边界与替换指南

本文说明当前项目如何隔离 Agora Chat SDK，以及后续换成其他 IM SDK 时需要改哪里。

## 结论

- **UI / ViewModel / 缓存 / outbox / 路由不需要改。**
- 需要改的是 `data/services` 下的 SDK 适配层，以及 `AppDependencies.create` 的一行装配。
- 当前估算：换 SDK 的主要工作量集中在 `ChatService` 适配、消息体类型映射、附件下载、连接/会话失效回调；页面层改动接近 0。

## 依赖方向

```text
ui/features/**        (页面、ViewModel)
        │  只依赖 domain/repositories + domain/models
        ▼
domain/               (ChatRepository、SessionRepository、ContactRepository、
                       GroupRepository、ProfileRepository、ChatService ...)
        ▲
        │  实现
data/repositories/**  (缓存、outbox、分页合并、错误兜底)
        │
        ▼
data/services/**      (唯一允许 import 具体 SDK 的目录)
```

具体约束：

- `ui/` 不 import `package:agora_chat_sdk`、`data/services`、`dart:io`。
- `domain/` 不 import SDK、插件、Flutter widget、`dart:io`。
- `data/services/agora_chat_service_mobile.dart` 是唯一直接接触 Agora Chat 类型的地方。
- `data/services/chat_connection.dart` 只负责把 SDK 回调变成强类型广播流。
- `AppDependencies.create` 是唯一知道“当前用哪个 SDK 实现”的组合根。

## 关键接口

| 接口 | 作用 | 换 SDK 时 |
|---|---|---|
| `ChatRepository` | 会话/历史/发送/附件/已读/outbox | 不需要改 |
| `SessionRepository` | 登录、恢复、登出、连接状态 | 不需要改 |
| `ContactRepository` | 联系人、好友申请 | 不需要改 |
| `GroupRepository` | 建群 | 不需要改 |
| `ProfileRepository` | 昵称/头像/备注 | 不需要改 |
| `ChatService` | 传输层 seam：Agora 适配器实现它 | **需要新实现** |
| `ChatMessageContent` | 文本/图片/语音/文件/视频/位置/联系人/自定义/系统/未知 | **需要映射到新 SDK 的消息体** |
| `ChatConnection` | 订阅/广播 SDK 回调 | 可复用，构造时传新的 `ChatService` |
| `MediaGateway` | 录音/播放/选图 | 与 IM SDK 无关，不需要改 |

`ChatService` 位于 [lib/domain/services/chat_service.dart](../lib/domain/services/chat_service.dart)，只包含领域模型，不包含 SDK 类型。

## 替换步骤

1. 新建 `data/services/xxx_chat_service.dart`，实现 `ChatService`：
   - `login` / `restoreSession` / `logout`
   - 会话列表、历史消息、发送文本/图片/语音
   - 附件/缩略图下载
   - 已读、联系人、群组、用户资料
   - 把新 SDK 的 message/conversation/contact 类型映射为 `domain/models`；消息体映射到 `ChatMessageContent` 子类。
2. 如有新的回调模型，扩展/替换 `ChatConnection` 的接线；`ChatConnection` 的对外 stream 契约保持不变。
3. 在 `AppDependencies.create` 中把默认的 `AgoraChatService()` 换成新实现。
4. 跑现有测试；页面和 ViewModel 测试不需要改。

## 当前遗留耦合

- `ChatConnection` 仍是 Agora 回调形态的适配器；新 SDK 需要提供等价的登录/回调入口。
- `AgoraChatService` 的 `isSupported` 目前按 Android/iOS 判断；Web 若要真正聊天，需要接 Chat Web SDK 适配器。
- 附件下载目前走 `downloadAttachment(messageId)` 的“按 ID 重新加载”语义；新 SDK 若只支持传 message 对象，需要在适配器内部保存 ID→对象或调整 `ChatService` 签名。
- 错误仍然是 `AppFailure` + 原始 SDK 文本；新 SDK 的错误码建议映射成 `AppFailure` 子类，避免把 SDK 异常直接冒到 UI。

## 验收清单

- `grep -R "agora_chat_sdk" lib/ui lib/domain` 无结果。
- `flutter analyze` 无问题。
- `flutter test` 全绿。
- `flutter build web` 通过（UI 预览仍可编译）。
- 断网/重连/附件下载/语音播放各跑一次真机回归。
