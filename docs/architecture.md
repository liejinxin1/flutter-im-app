# Agora IM Flutter 架构说明

> 适用版本：Flutter 3.47.7 / Dart 3.13.5 / agora_chat_sdk 1.4.0+1  
> 目标：当前以 Agora Chat 为主，但页面、状态、缓存和路由不绑定具体 IM SDK，后续可替换。

## 1. 结论

当前结构已经具备可维护的生产骨架：

- UI 不直接接触 SDK、插件、`dart:io`。
- ViewModel 只依赖 domain 接口，可脱离 SDK 单测。
- `data` 层负责 SDK 适配、缓存、outbox、错误兜底。
- go_router 负责页面级导航，`AppDependencies` 是唯一组合根。
- 中英文通过 ARB 管理，`AppError` 用错误码而不是中文字符串跨层传递。
- 手机使用底部导航，平板/桌面使用 `NavigationRail`，内容有最大宽度约束。
- 已预留 REST `ApiClient` 和 `ChatService` 传输契约，方便后续接服务端接口或更换 IM SDK。

验证状态：`flutter analyze` 零问题，`flutter test` 全绿，Web 与 Android debug 可构建。

## 2. 分层

```text
lib/
  app/
    app.dart                 # MaterialApp.router + 本地化 + 系统 UI
    app_config.dart          # AppKey、API Base URL、超时
    app_dependencies.dart    # 组合根 / 生命周期
    router/                  # go_router
    navigation/              # 全局 root navigator key
    coordinators/            # 跨页面协作（outbox replay）
  domain/
    models/                  # ChatMessage / ChatConversation / UserProfile ...
    repositories/            # Chat/Session/Contact/Group/Profile/Outbox 契约
    services/                # ChatService、MediaGateway、ApiClient、LocalStore
    errors/                  # AppFailure / NetworkFailure / ApiFailure
  data/
    local/                   # 账号隔离缓存、outbox、资料、好友申请
    services/                # Agora 适配、ChatConnection、媒体、HTTP
    repositories/            # 缓存/分页/outbox 聚合
  ui/
    core/
      layout/                # 断点 + 最大宽度内容框
      localization/          # l10n 扩展 + AppError 本地化
      system_ui/             # 状态栏/导航栏样式
      theme/                 # 颜色、字体、ThemeData
      widgets/               # 通用导航、头像、渐变头
      view_model.dart        # dispose 安全的 ChangeNotifier
    features/
      auth/ inbox/ conversation/ contacts/ groups/ profile/ more/ shell/
  previews/                  # @Preview 页面 + 纯内存 fake
  l10n/                      # ARB 与生成的 AppLocalizations
```

### 依赖规则

- `ui` → `domain`，不 import `data`、SDK、插件、`dart:io`。
- `domain` 只依赖 Dart 核心库和 Flutter 的纯 UI 类型之外的东西；不依赖 SDK。
- `data` → `domain`，可以依赖 SDK/插件/`dart:io`。
- `app` 是唯一知道具体实现的地方。
- 新页面必须通过 repository/service 接口访问数据，不能直接 `ChatClient.getInstance()`。

## 3. 关键边界

### 3.1 ChatService（换 SDK 的 seam）

`domain/services/chat_service.dart` 定义传输层契约；`AgoraChatService` 是当前实现。

`ChatRepository`、`SessionRepository`、`ContactRepository`、`GroupRepository`、`ProfileRepository`、`ChatConnection` 都只依赖 `ChatService`/领域模型，不依赖 Agora 类型。更换 SDK 时：

1. 新建 `XxxChatService implements ChatService`；
2. 在 `AppDependencies.create` 注入；
3. 页面、ViewModel、缓存、outbox 不变。

详细步骤见 [sdk-boundary.md](sdk-boundary.md)。

### 3.2 消息内容模型

消息不再用 `text/localPath/duration` 等一堆可空字段，而是 `ChatMessage.content`：

```dart
sealed class ChatMessageContent
├── TextMessageContent
├── AttachmentMessageContent
│   ├── ImageMessageContent
│   ├── VoiceMessageContent
│   ├── FileMessageContent
│   └── VideoMessageContent
├── LocationMessageContent
├── ContactMessageContent
├── CustomMessageContent
├── SystemMessageContent
└── UnknownMessageContent
```

- `ChatMessage.kind` 从 content 派生；UI 用 `switch (message.content)` 渲染。
- 已接收并映射：文本、图片、语音、文件、视频、位置、自定义、命令/系统；未知类型进入 `UnknownMessageContent`，不会丢消息。
- 已发送：文本、图片、语音；文件/位置/联系人等发送接口预留 content 类型和 UI 兜底，后续在 `ChatService`/`ChatRepository` 增加对应 send 方法即可。
- `ChatCache`、`OutboxRepository`、`ChatMessage.toJson` 使用 content 类型序列化；旧版扁平 JSON 会自动升级。
- 新增类型步骤：加 content 类 → 加 SDK 映射 → 在 `MessageBubble` 加分支（或使用默认兜底）→ 补 content round-trip 测试。

传输层 envelope、`MESSAGE_TRANSPORT` 模式、OSS 上传 seam 和 hybrid 回退见 [message-protocol.md](message-protocol.md)。

### 3.3 MediaGateway

选图、录音、播放通过 `domain/services/media_gateway.dart`；实现位于 `data/services/device_media_gateway.dart`，Web 使用 stub。页面不 import `image_picker`、`record`、`audioplayers`。

### 3.4 ApiClient（REST 网络层）

Agora Chat 的网络由 SDK 自己管理，不在 `ApiClient` 中。应用自己的 REST 接口使用：

- `domain/services/api_client.dart`：`ApiRequest` / `ApiResponse` / `ApiClient`；
- `data/services/http_api_client.dart`：基于 `package:http`，处理 JSON、Bearer Token、超时、状态码和网络错误；
- `AppConfig.apiBaseUrl` 由 `--dart-define=API_BASE_URL=...` 配置；未配置时 `AppDependencies.api == null`。

```dart
final response = await api.send(
  const ApiRequest(
    method: ApiMethod.post,
    path: 'v1/session',
    body: {'userId': userId},
  ),
);
```

超过 2xx 抛 `ApiFailure`，超时/连接失败抛 `NetworkFailure`。ViewModel 只处理 `AppError`/`AppFailure`，不接触 `package:http`。

## 4. 状态与生命周期

- ViewModel 继承 `ViewModel`（`ChangeNotifier`），统一 `isDisposed`。
- 每个 stream subscription、`Timer`、`TextEditingController`、`ScrollController`、`ValueNotifier` 都有显式 dispose。
- await 后写状态前检查 `isDisposed`；View 中检查 `mounted`。
- `AppDependencies.dispose()` 关闭 `ApiClient`、`MediaGateway`、`ChatConnection`。
- 发送采用乐观更新 + outbox：先插入 `sending` 气泡，失败标 `failed`，重连由 `OutboxCoordinator.flushOutbox` 重放；SDK 回显按 `clientId` 去重。
- 会话/消息缓存按账号隔离；缓存失败只降级，不阻塞首屏。

## 5. 国际化

- ARB：`lib/l10n/app_en.arb`、`lib/l10n/app_zh.arb`。
- 生成：`lib/l10n/app_localizations.dart`（`flutter gen-l10n`，`generate: true`）。
- `MaterialApp.router` 注入 `AppLocalizations.localizationsDelegates` 和 `supportedLocales`。
- 页面通过 `context.l10n` 取文案；ViewModel 不返回中文字符串，而返回 `AppError(code, detail)`。
- `AppError` 在 UI 层用 `localizedError` 统一翻译；服务端/SDK 原始错误放 `detail`，保留可排查信息。
- 新增文案必须同时更新 en/zh ARB，不能只改页面。

## 6. 响应式

- `AppBreakpoints`：`compact < 600`、`medium 600–899`、`expanded >= 900`。
- `AppShell`：宽屏显示 `NavigationRail` + 内容区；手机显示 `AppBottomNav`。
- `AppContentFrame` 将登录、会话、联系人、资料、更多等页面限制在 760–920 逻辑像素内，避免平板/桌面被拉伸。
- `MessageBubble` 最大 520，避免大屏气泡过长。
- 页面仍以手机为第一优先级；后续可把会话页升级为 master-detail 双栏。

## 7. 错误与可观测性

- `AppFailure` 子类：`AuthFailure`、`NetworkFailure`、`ApiFailure`、`UnsupportedPlatformFailure`。
- `friendlyError` 只负责提取可读 detail，不再返回中文字符串。
- `AppErrorCode` 覆盖校验、录音、附件、播放等已知场景；未知错误显示本地化兜底 + 原始 detail。
- 仍未接入崩溃上报、结构化日志和指标；RTC 前补。

## 8. 测试与预览

- 单元测试：ViewModel、Repository、缓存、outbox、HTTP、布局断点。
- Widget 测试：登录、会话、错误重试、响应式导航。
- 预览：`lib/previews/app_previews.dart`，`flutter widget-preview start`，不需要 SDK/AppKey。
- 预览 smoke test 会实际 pump 所有页面，防止加预览后页面初始化异常。

## 9. 当前限制

- Web 只能预览 UI，不能真正登录/收发；需要 Chat Web SDK 适配器。
- 联系人/建群仍使用局部 `Navigator.push`，后续应迁移到 `/contacts`、`/groups/new` 等路由。
- 会话页仍是单栏；宽屏 master-detail 未做。
- RTC 未开始：`/call/:id`、`CallCoordinator`、`RtcEngine` 适配位置已预留，但尚未接 Agora RTC。
- 附件 OCR/文件/位置/联系人分享仍是占位提示。
- 版本号仍硬编码，后续接 `package_info_plus`。

## 10. 后续顺序

1. 路由收口：联系人、好友申请、建群、资料页全部走 go_router。
2. IM 交互补齐：日期分隔、草稿、会话搜索、连接横幅、群资料。
3. 可观测性：日志、崩溃上报、发送成功率。
4. RTC R0→R1：纯 Dart 状态机 + 信令，再接 Agora RTC。
5. CI：format/analyze/test/build + 真机 smoke。

## 11. 验证命令

```shell
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
# 仅在改动 Web stub/条件导入时执行：
flutter build web --no-tree-shake-icons
```
