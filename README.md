# Flutter IM App

一个基于 Flutter + Agora Chat 的开源即时通讯客户端，优先支持 Android / iOS。项目不是只做 UI 的 Demo：包含真实 SDK 登录、会话、消息、联系人、群组、离线缓存和失败重发，同时把 SDK 适配、业务模型、页面状态和网络层做了分层隔离，方便后续替换 IM SDK 或接入自有 OSS。

> 开源地址：https://github.com/liejinxin1/flutter-im-app  
> **本项目不包含可用的 Agora AppKey，运行前请先看下方“替换成你自己的 AppKey”。**

## 项目简介

这个项目适合作为 Flutter IM 的工程化起点，而不是单文件示例。它重点解决：

- 页面和 ViewModel 不直接依赖 Agora SDK，后续可以替换 `ChatService` 实现；
- 文本、图片、语音、文件等消息统一为 `ChatMessageContent`，避免消息模型字段无限膨胀；
- 文本默认使用 `app.im.message` 自定义协议，附件支持“自定义协议 + OSS”与原生 SDK 类型之间的 hybrid 切换；
- 会话/消息按账号缓存，失败消息进入 outbox，重连后自动重放；
- 中英文、响应式布局、Widget Preview、单元测试和分层边界全部落地。

## 功能特性

- 密码 / Token 登录，会话失效自动回登录页
- 单聊、群聊、分页历史消息、未读/已读状态
- 文本、图片、语音消息发送与接收
- 消息长按菜单：复制、删除、撤回、引用、转发、多选
- 图片预览、语音录制/播放、附件下载
- 消息发送状态、失败重试、持久化 outbox、重连重放
- 联系人、好友申请、好友申请本地持久化
- 创建群组、用户昵称/头像/备注缓存
- 账号隔离的会话/消息缓存
- 中英文界面、手机/宽屏响应式布局
- 自定义消息 envelope、OSS 上传 seam、`native/custom/hybrid` 传输开关
- Widget Preview：不用启动 App 即可查看页面

## 目前进度

> 最后更新：2026-10-28  
> 这是一个持续迭代中的个人项目，进度**不定时更新**；具体实现以代码和 `docs/` 为准，下面只记录当前阶段状态。

### ✅ 已完成

- [x] 密码 / Token 登录、启动恢复会话、会话失效重定向
- [x] go_router 路由：`/login`、`/`、`/chats/:id`
- [x] 会话列表、单聊、群聊、未读/已读状态
- [x] 分页历史、文字/图片/语音消息、消息回显去重
- [x] 消息长按菜单：复制、删除、撤回、引用、转发、多选
- [x] 撤回状态通过 SDK 回调同步到接收端
- [x] 发送状态、失败重试、账号隔离缓存、持久化 outbox、重连重放
- [x] 图片预览/下载、语音录制/播放、附件路径本地恢复
- [x] 联系人、好友申请、好友申请本地持久化、创建群组
- [x] 用户昵称/头像/备注缓存
- [x] 中英文 ARB、`AppError` 错误码、页面本地化
- [x] 手机底部导航 + 宽屏 `NavigationRail` + 内容最大宽度
- [x] `ChatService` 传输 seam、`ApiClient` REST 封装
- [x] `ChatMessageContent` sealed 消息模型
- [x] 文本 `app.im.message` 自定义 envelope
- [x] 附件 `native/custom/hybrid` 传输策略、`AttachmentUploader` 接口、按类型白名单
- [x] Widget Preview、页面 smoke test、90 个测试
- [x] 开源前 AppKey 清理：不提交任何可用 Key

### 🚧 进行中 / 待完善

- [ ] 具体 OSS `AttachmentUploader` 实现（目前只有接口，未配置时附件走 native 回退）
- [ ] 文件消息 UI：文件选择器、上传进度、下载/打开
- [ ] 自定义附件缩略图、失败重试和上传缓存
- [ ] 旧客户端兼容策略：默认文本已走 custom，旧版本不能解析；需要时用 `MESSAGE_TRANSPORT=native` 或后续做双发/版本协商
- [ ] 联系人/好友申请/建群从局部 `Navigator.push` 迁移到 go_router
- [ ] 宽屏 master-detail 双栏
- [ ] RTC 语音/视频、推送、CallKit
- [ ] 群资料/成员管理、草稿、日期分隔、搜索
- [ ] CI、崩溃上报、结构化日志和 RTC 指标

### 📌 下一步

1. 接入 OSS uploader 和文件消息 UI。
2. 补齐消息交互和会话搜索。
3. 迁移剩余页面到路由。
4. RTC R0→R1：状态机 + 信令，再接 Agora RTC。
5. 补 CI 和真机回归。

## 技术栈

- Flutter 3.47+ / Dart 3.13+
- Agora Chat Flutter SDK
- go_router、shared_preferences
- `record`、`audioplayers`、`image_picker`、`flutter_svg`
- `flutter_localizations` + ARB
- 原生 Android / iOS（Web 目前仅保留 UI/接口）

## 替换成你自己的 AppKey

AppKey 是 Agora Chat 应用标识，不是 App Certificate。**不要把 App Certificate 或服务端密钥放进客户端，也不要提交到 Git。**

### 1. 获取 AppKey

1. 打开 [Agora Console](https://console.agora.io/)；
2. 创建一个启用了 Chat 的项目；
3. 在项目配置中复制 **AppKey**，格式类似 `组织名#应用名`；
4. 在 Chat 用户管理中创建测试用户。

### 2. 在运行/构建时传入

项目源码中**没有硬编码 AppKey**。[lib/app/app_config.dart](lib/app/app_config.dart) 只读取编译参数：

```dart
static const String _configuredAppKey = String.fromEnvironment(
  'AGORA_APP_KEY',
);
```

因此运行时必须传入自己的 Key：

```shell
flutter run \
  --dart-define=AGORA_APP_KEY=你的AppKey \
  --dart-define=AGORA_USER_ID=你的测试用户ID
```

Android Studio 中：

1. `Run` → `Edit Configurations`；
2. 在 `Additional run args` 中填入：
   `--dart-define=AGORA_APP_KEY=你的AppKey`
3. 不要把这个配置提交到仓库；`.idea/` 已在 `.gitignore` 中。

构建 APK 时同理：

```shell
flutter build apk --debug \
  --dart-define=AGORA_APP_KEY=你的AppKey
```

### 3. 为什么要这样设计

- 开源仓库不会泄露任何可用 Key；
- 每个开发者使用自己的 Agora 项目，互不影响；
- 可以按环境切换 Key，而不改代码；
- AppKey 本身可以出现在客户端，但 **App Certificate 不能**。

## 详细文档

- [架构说明](docs/architecture.md)
- [SDK 替换边界](docs/sdk-boundary.md)
- [消息协议与传输策略](docs/message-protocol.md)
- [Figma 对齐记录](docs/figma-alignment.md)

## 平台支持

- **Android、iOS**：通过 `agora_chat_sdk` 原生插件连接 Agora Chat；图片/语音依赖 `image_picker`、`record`、`audioplayers`。
- **Web**：Flutter Web 可以构建 UI，但 Agora 的 Flutter Chat 插件只声明 Android/iOS 支持。Web 登录会提示不支持；图片显示为占位符，录音/播放不可用。真正的 Web IM 需要独立的 Chat Web SDK 适配器。

## 架构

项目采用 feature-first MVVM + Repository，依赖方向为 `ui → domain ← data`，由 `app/app_dependencies.dart` 统一组装：

```text
lib/
  app/                 # 启动、go_router 路由、全局导航 key、依赖组合根、outbox 协调器
  domain/              # 模型、仓储契约、ChatService/ApiClient/MediaGateway 边界
  data/
    local/             # SharedPreferences 缓存、outbox、资料缓存、好友申请
    services/          # Agora 适配、回调流、HTTP 客户端、平台媒体
    repositories/      # 面向 ViewModel 的数据入口
  l10n/                # 中英文 ARB 与生成的 AppLocalizations
  previews/            # @Preview 页面和纯内存 fake
  ui/
    core/              # 主题、断点/内容框、本地化、共享组件、ViewModel 基类
    features/          # auth / inbox / conversation / contacts / groups / profile / more
```

- View 只渲染状态、转发用户操作；不 import SDK、插件或 `dart:io`。
- ViewModel 依赖 `domain/repositories` 和 `domain/services` 的接口，不依赖 Agora SDK。
- 设备能力（选图、录音、播放）通过 `MediaGateway` 注入；平台实现位于 `data/services`。
- IM 传输层通过 `ChatService` 隔离；Agora 只是当前实现，换 SDK 时页面/ViewModel/缓存不变。说明见 [docs/sdk-boundary.md](docs/sdk-boundary.md)。
- 应用 REST 接口通过 `ApiClient`/`HttpApiClient` 封装；聊天网络仍由 Chat SDK 管理。
- 消息体使用 `ChatMessageContent` sealed 类型：文本、图片、语音、文件、视频、位置、联系人、自定义、系统、未知；新增类型时页面/缓存/outbox 不需要再加可空字段。
- 文本默认通过 `app.im.message` 自定义 envelope 发送；附件在配置 `AttachmentUploader` 后也走 envelope，未配置时 `hybrid` 自动回退 SDK 原生类型。协议见 [docs/message-protocol.md](docs/message-protocol.md)。
- 中英文使用 `flutter_localizations` + ARB；ViewModel 返回 `AppError` 错误码，页面负责本地化。
- 响应式：手机底部导航，宽屏 `NavigationRail`；页面内容有最大宽度，消息气泡最大 520。
- 路由使用 `go_router`；`/login`、`/`、`/chats/:id` 已接入，登录/会话失效自动重定向。
- 会话与最新消息缓存、发送 outbox、好友申请均按账号隔离，切换账号不会串数据。
- 所有订阅、Timer、Controller 都有明确 dispose 路径；异步回调写状态前检查 `isDisposed` / `mounted`。
- 当前范围约定与后续 RTC 设计见 [AGENTS.md](AGENTS.md) 和 [docs/architecture.md](docs/architecture.md)。

## 页面预览（不用运行 App）

页面预览位于 [lib/previews/app_previews.dart](lib/previews/app_previews.dart)，使用纯内存 fake 数据，不需要 AppKey、不需要登录，也不会初始化 Agora SDK。

Android Studio：

1. 打开 `lib/previews/app_previews.dart`；
2. 打开右侧 **Flutter Widget Preview** 工具窗；
3. 在 `IM Screens` 分组选择 Login / Chats / Groups / Conversation / Contacts / Profile 等页面。

也可以直接用命令行启动预览器：

```shell
flutter widget-preview start
```

改完页面后如果预览没有刷新：

```shell
flutter widget-preview clean
flutter widget-preview start
```

`lib/previews/` 只被 Previewer 使用，不参与 App 运行时；新增页面时建议同时补一个 `@Preview` 和 `test/previews` 下的 smoke test。

## 配置并运行

先完成上面的 **替换成你自己的 AppKey**，再安装依赖并启动：

```shell
flutter pub get
flutter run \
  --dart-define=AGORA_APP_KEY=你的AppKey \
  --dart-define=AGORA_USER_ID=你的测试用户ID
```

不要把 `--dart-define` 里的真实 Key 写进 README、脚本或 Git 提交。密码方式只用于本地测试；正式环境应由自有认证服务签发用户 Token。不要将 App Certificate、服务端密钥或用户密码写入源码。

如果后续接入自有 REST 服务，可配置 API 根地址（不配置时 `ApiClient` 为 null，聊天不受影响）：

```shell
flutter run --dart-define=API_BASE_URL=https://api.example.com/
```

消息传输模式：

```shell
# hybrid（默认）：文本走 envelope；附件有 uploader 时走 envelope，否则原生回退
flutter run --dart-define=MESSAGE_TRANSPORT=hybrid

# 全部原生 Agora 消息类型
flutter run --dart-define=MESSAGE_TRANSPORT=native

# 强制 envelope；附件需要先配置 AttachmentUploader
flutter run --dart-define=MESSAGE_TRANSPORT=custom

# 只让文档文件走 custom，图片/语音仍用原生（配合 uploader）
flutter run --dart-define=MESSAGE_TRANSPORT=hybrid --dart-define=CUSTOM_ATTACHMENT_KINDS=file
```

启动后在登录界面输入用户 ID 和密码，或服务端签发的 Token。App Key 与 App ID 任选其一。申请好友后，可在“联系人”里用对方 Agora Chat 用户 ID 开始会话。

## 验证

```shell
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
# 仅在改动 Web stub/条件导入时执行：
flutter build web --no-tree-shake-icons
```

## 后续建议

主路由、缓存/outbox、用户资料、好友申请持久化、中英文、响应式和 ChatService/ApiClient 边界已经完成第一版；接下来按 [docs/architecture.md](docs/architecture.md) 先补交互（消息长按、日期分隔、草稿），再接入 RTC 语音/视频、推送和 CallKit。注册、群管理、完整离线同步仍未纳入当前范围。
