# 本地数据层

> 目标：把聊天缓存、用户资料、好友关系和设置从“临时 JSON”迁移到可演进的本地数据库，同时保持未来替换 IM SDK 或接入业务服务器的边界。

## 当前实现

- SQLite 数据库：`agora_im.sqlite`
- 入口：`lib/data/local/app_database.dart`
- Store：`lib/data/local/sqlite_local_store.dart`
- 平台选择：
  - Android/iOS/桌面：SQLite
  - Web：`SharedPreferences` fallback
- 旧版本 SharedPreferences 数据在首次读取时按 key 自动提升到 SQLite，避免升级后丢缓存。

## Schema 概览

```text
kv               key-value，承接现有分页/outbox/设置等缓存
profiles         account_id + user_id + nickname/avatar/remark
friendships      account_id + user_id + remark + status
friend_requests  account_id + target_key + payload + occurred_at
conversations    account_id + conversation_id + payload + last_activity
messages         account_id + conversation_id + message_id + payload + sent_at
```

`profiles` 已由 `SqliteProfileRepository` 作为资料缓存主路径；`friendships` 由 `FriendCache` 作为联系人/备注缓存，Agora SDK 仍是关系动作的事实来源。

## 分层边界

```text
UI / ViewModel
  ↓
ChatRepository / ContactRepository / ProfileRepository / AppSettings
  ↓
AgoraChatRepository / AgoraContactRepository / PrefsProfileRepository ...
  ↓
ChatConnection → ChatService
  ↓
AgoraChatService → agora_chat_sdk
```

- UI 不 import SQLite、Agora SDK 或 SharedPreferences。
- `ChatService` 是 IM 传输 seam；未来业务服务器版本实现同样的接口。
- `ProfileRepository` 是用户资料 seam；未来可由业务服务器覆盖。
- `ContactRepository` 是好友关系/备注/申请 seam；当前 SDK 实现负责动作，本地缓存负责离线可见。
- 消息内容仍用 `ChatMessageContent` + envelope，不把 SDK body 写进数据库。

## 仍待完成

- 业务服务器模式下，由服务器返回资料/好友关系，SQLite 只作为只读缓存。
- 将消息 payload 从 JSON 列逐步拆成可索引的摘要列（当前按 conversation + sent_at 建索引）。
- 迁移旧 SharedPreferences 后清理旧 key（当前是惰性迁移并删除旧 key）。
- 资料/好友/备注编辑页面。

## 为什么现在只做到这一步

先把“数据库后端 + 平台选择 + 旧数据迁移 + 仓库边界”落稳，比直接重写所有仓库风险低。下一步可以逐仓库替换，不需要一次性改 UI 或消息协议。
