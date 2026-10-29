import '../../domain/services/local_store.dart';
import 'app_database.dart';
import 'chat_cache.dart';
import 'sqlite_chat_message_store.dart';

ChatCache createChatCache(LocalStore store) => ChatCache(
  store,
  messageStore: SqliteChatMessageStore(AppDatabase.instance, legacy: store),
);
