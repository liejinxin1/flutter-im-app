# 当前功能与项目状态

> 最后更新：2026-10-28  
> 本文是项目级状态快照，记录“现在做到什么程度、关键交互是什么、还差什么”。具体协议细节见 [message-protocol.md](message-protocol.md)，分层约定见 [architecture.md](architecture.md)。

## 一句话概括

这是一个可运行的 Flutter + Agora Chat IM 客户端，已经覆盖登录、会话、单聊/群聊、消息收发、离线缓存、失败重发、联系人、好友申请、建群、中英文、响应式布局和消息长按操作；消息层正在从“SDK 原生类型”迁移到应用自有的 `app.im.message` 协议。

## 功能地图

### 账号与会话

- 密码 / Token 登录
- 启动恢复已有会话
- 会话失效自动回登录页
- 账号切换后缓存、outbox、好友申请按账号隔离

### 会话与消息

- 会话列表、未读数、已读状态
- 会话预览按最后一条消息类型显示文本或 `[图片]/[视频]/[语音]/[文件]` 等
- 单聊、群聊
- SQLite 本地数据库，旧 SharedPreferences 缓存惰性迁移
- 进入聊天优先读本地消息缓存，再合并网络历史
- 群会话名称/头像从 Agora 群资料读取
- 群聊消息显示发送者 ID
- More 设置可关闭“显示网络聊天记录”，仅看本地历史
- 分页历史消息
- 文本、图片、语音发送与接收
- 消息发送状态：发送中 / 成功 / 失败
- 失败消息重试
- 持久化 outbox，重新登录或恢复连接后重放
- 收到新消息时去重，避免本地乐观消息和 SDK 回显重复
- 图片预览、附件下载、语音录制/播放、本地附件路径恢复

### 消息长按操作

长按消息后在消息附近显示微信式悬浮菜单，不再从底部弹出。

| 操作 | 行为 |
|---|---|
| 复制 | 复制文本消息 |
| 引用 | 输入框上方出现引用条，发送后气泡内显示引用卡片 |
| 转发 | 选择目标会话后转发；附件未下载时先下载 |
| 撤回 | 仅自己发送且 2 分钟内的消息；二次确认后调用 SDK |
| 多选 | 进入选择模式，批量复制、转发、删除 |
| 删除 | 二次确认，删除当前设备上的消息 |

引用卡片支持：

- 文本摘要
- 图片 / 视频缩略图
- 语音时长
- 文件名
- 引用发送者 ID
- 点击引用卡片可定位到原消息；原消息未加载时自动翻页查找

### 联系人、群组与资料

- 联系人列表
- 好友申请接收、接受、拒绝
- 好友申请与群聊邀请历史、已同意/已拒绝状态
- 同一好友/群聊只保留最新一条请求状态
- 接受群邀请后自动创建群会话，群聊页可见
- 好友申请与群邀请本地持久化
- 联系人备注编辑（写入 Agora + SQLite，后续可切业务服务器）
- 好友资料页、备注展示
- 群资料页、群成员列表
- 创建群组
- 用户昵称、头像、备注缓存

### 体验与工程化

- 中英文 ARB 文案，ViewModel 返回 `AppError` 错误码
- 手机底部导航 + 宽屏 `NavigationRail`
- 页面内容最大宽度、消息气泡最大宽度
- Widget Preview，不启动 App、不初始化 SDK 即可预览页面
- 录音最长 60 秒、点击录音条外弹出发送/撤回、撤回删除临时文件
- 输入框外点击/按钮操作收起软键盘
- 发送后自动滚到底部，浏览历史时显示新消息条数，加载到底提示没有更多
- 删除/撤回状态本地持久化，重新进入会话不会复活旧内容
- 消息缓存限制：单会话 60 条、最多 80 个会话
- 113 个单元/Widget/预览测试
- Android debug APK 构建验证

## 消息协议现状

应用自有协议：

```text
ChatMessageContent
  → ChatMessageEnvelope (event: app.im.message, version: 1)
  → ChatCustomMessageBody
```

传输模式由 `MESSAGE_TRANSPORT` 控制：

| 模式 | 文本 | 附件 |
|---|---|---|
| `native` | 原生 TXT；带引用时仍走 envelope | 原生 IMAGE/VOICE/FILE |
| `custom` | envelope | envelope，必须有 uploader |
| `hybrid`（默认） | envelope | 有 uploader 且类型在白名单时 envelope，否则原生 |

附件上传接口：

```dart
abstract interface class AttachmentUploader {
  Future<AttachmentUploadResult?> upload(AttachmentUploadRequest request);
}
```

当前**没有具体 OSS 实现**，因此默认 hybrid 下图片/语音/文件仍走 Agora 原生消息；接入 OSS 后通过 `AppDependencies.create(attachmentUploader: ...)` 注入即可。

## 关键目录

```text
lib/app/                依赖组合根、配置、路由、协调器
lib/domain/models/      消息、会话、引用、outbox 等应用模型
lib/domain/repositories 仓储契约
lib/domain/services     ChatService、MediaGateway、ApiClient 等边界
lib/data/services/      Agora 适配、平台媒体、HTTP
lib/data/repositories/  缓存、outbox、发送策略
lib/ui/features/        登录、会话列表、聊天、联系人、群组、资料
lib/previews/           Widget Preview 与内存 fake
docs/                   架构、协议、SDK 边界、状态文档
```

## 当前验证结果

```text
flutter analyze       No issues found
flutter test          113 tests, all passed
flutter build apk     Built build/app/outputs/flutter-apk/app-debug.apk
```

## 已知限制

- **撤回**受 Agora 2 分钟限制；超过后菜单不显示撤回入口。
- **删除**是本地删除，不会删除对方设备上的消息。
- **旧引用消息**没有图片 URL，只能显示占位图；新引用正常。
- **旧客户端兼容**：默认文本走 `app.im.message`，旧版本可能无法解析；需要混合版本时用 `MESSAGE_TRANSPORT=native`。
- **附件自定义协议**依赖 `AttachmentUploader`，目前只有接口，没有 OSS 实现。
- **文件消息 UI**未完成：仓库有 `sendFile`，但没有文件选择器和上传进度。
- **图片保存、语音播放进度**未实现。
- **Web** 只保留 UI/stub，没有 Chat Web SDK 适配。
- 联系人、好友申请、建群仍有局部 `Navigator.push`，尚未全部迁移到 go_router。
- 宽屏 master-detail 双栏、消息搜索、草稿、日期分隔、RTC、推送、群成员管理仍在后续计划。

## 后续顺序

1. 接入 OSS `AttachmentUploader`，补文件选择和上传进度。
2. 补消息搜索、草稿、日期分隔和宽屏双栏。
3. 剩余页面迁移到 go_router。
4. RTC R0→R1：状态机 + 信令，再接 Agora RTC。
5. CI、崩溃上报、结构化日志和真机回归。

## 最近改动

- `c7e1d8e`：悬浮长按菜单、引用缩略图、撤回回归测试
- `6efe85d`：进入多选时收起键盘
- `9410d22`：消息长按、复制/删除/撤回/引用/转发/多选
- `d84ebb0`：README 当前进度与路线图
