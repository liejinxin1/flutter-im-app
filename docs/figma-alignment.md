# Figma 设计对齐记录

> 设计稿：https://www.figma.com/design/BDUYBOME8YJ04SsAMyYguI/免费的聊天UI?node-id=21-122  
> 目标 Frame：`Chats`（node `21:122`）  
> 更新日期：2026-10-26

## 1. 当前可读取状态

- Figma Desktop 已在运行，并且打开了该文件；
- 但本地 MCP server 未启动：`127.0.0.1:3845` 没有监听，DSH 的 `figma` MCP 状态是 `disconnected`；
- 本轮通过 **Figma 桌面截图 + 像素采样** 读取了 `Chats` 页面的颜色和排版，用于先修系统栏和聊天列表；
- 精确的 Figma variables、Auto Layout 数值、字体文件和切图，仍建议开启本地 MCP 后读取。

开启方式（Figma 官方 Desktop MCP）：

```text
Figma Desktop 左上角 Figma 菜单 → Preferences → Enable local MCP Server
```

成功后应能看到 `http://127.0.0.1:3845/mcp`。如果菜单里没有这一项，通常是当前账号/席位不满足 Figma 的 Desktop MCP 要求，可改用截图/导出资源方式。

## 2. 从 `Chats` Frame 采样到的值

| Token | 值 | 用途 |
|------|----|------|
| Header | `#135CAF` | 顶部渐变主色 |
| Header right | `#2E6FB8` | 顶部右侧浅色过渡 |
| Accent | `#13B0F7` | 底部选中 pill、发送/主按钮 |
| Badge | `#40C4FF` | 未读角标 |
| Text primary | `#2C2D3A` | 姓名、标题 |
| Text secondary | `#9A9BB1` | 预览、时间、未选中导航 |
| Body | `#FFFFFF` | 会话列表背景 |

排版（按 81% 截图换算，误差约 ±1px）：

| 元素 | 设计值 | 代码值 |
|------|--------|--------|
| 顶部标题 E-Chat | 18 SemiBold | `GradientHeader` 18 / w600 |
| 会话姓名 | 16 SemiBold | `ConversationTile` 16 / w600 |
| 消息预览 | 13 Regular | `ConversationTile` 13 |
| 时间 | 11 Regular | `ConversationTile` 11 |
| 未读角标 | 10 Semibold | `ConversationTile` 10 / w600 |
| 底部导航标签 | 12 | `AppBottomNav` 12 |

设计稿字体在 Figma 中显示为 **`Ag 18px / Semi Bold`**（Agrandir 系列的可能性较大）。项目当前没有该字体文件，暂用 Roboto；如果要 1:1，需要提供可授权的字体文件并加入 `pubspec.yaml`。

## 3. 本轮已实现的系统 UI 调整

### 3.1 沉浸式状态栏

- `main.dart` 改为 `AppSystemUi.configure()`，统一 `SystemUiMode.edgeToEdge`；
- `GradientHeader` 自己承担顶部 `MediaQuery.padding.top`，渐变会铺到状态栏下面；
- 所有带渐变头的页面移除顶部 `SafeArea`，只保留内容安全区；
- 页面通过 `AnnotatedRegion<SystemUiOverlayStyle>` 切换图标亮度：
  - 渐变头页面（Chats/Groups/Contacts/Profile/More/Add Friend/Create Group/Friend Requests）：白色状态栏图标；
  - 登录、聊天页：深色状态栏图标。

### 3.2 Android 底部系统栏变白

Android 15 的 edge-to-edge 会忽略 `systemNavigationBarColor`，因此不只依赖这个字段：

- 有 App 底部导航的页面：`AppBottomNav` 外包白色 `SafeArea`，系统栏区域始终是白色；
- 没有 App 底部导航的页面：`Scaffold.bottomNavigationBar = SystemNavBarInset()`，只占 `viewPadding.bottom` 高度并填白；
- 聊天页本身是白色 Scaffold + 底部 SafeArea，系统栏区域自然为白色；
- `systemNavigationBarIconBrightness` 统一为 `dark`。

### 3.3 颜色/字号/列表细节

- 主色：`#1565C0` → `#135CAF`；
- 亮蓝：`#24B6E8` → `#13B0F7`；
- 未读角标：`#22B5DE` → `#40C4FF`，圆形 → 8px 圆角；
- 正文主色：`#292929` → `#2C2D3A`；
- 次要文字：`#9A9BAB` → `#9A9BB1`；
- 顶部渐变改为设计稿的深蓝，右侧 14% 渐变到 `#2E6FB8`；去掉底部圆角和阴影；
- 会话列表去掉分隔线，行高/头像/字号按设计稿调整；
- 时间格式改为设计稿规则：当天只显示 `HH:mm`，更早显示 `HH:mm MM/dd`；
- 底部导航选中态改为纯色 `#13B0F7`，高度 64，标签 12。

## 4. 仍需设计确认

1. **字体文件**：设计使用 `Ag` 字体，项目没有该资源；需要字体授权文件，或确认用替代字体（如 Manrope/Outfit）。
2. **Login 页**：设计稿是手机号 + OTP 的蓝色渐变卡片；当前项目是 Agora Chat 用户 ID + 密码/Token 的登录表单。两者信息架构不同，是否需要按设计稿重构登录页，需要产品确认。
3. **Chats Conversation 页**：本轮只采样了会话列表，聊天页的气泡、输入栏、时间线分隔需要读取对应 Frame 后再对齐。
4. **其他页面**：Contacts/Groups/Profile/More 的独立 Frame 还没有逐个采样，目前先复用同一套 token 和渐变头。
5. **MCP**：开启后可以直接读 `get_variable_defs` / `get_design_context`，把上面的近似值替换成精确值，并导出真实头像/图标资源。

## 5. 复现验证

```shell
dart format lib test
flutter analyze
flutter test
flutter build web --no-tree-shake-icons
flutter build apk --debug
```

本轮结果：format 无改动、analyze 零问题、83 个测试通过、Android debug 构建成功（Web 构建仅在 Web 相关改动时执行）。
