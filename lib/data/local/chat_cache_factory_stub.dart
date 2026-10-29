import '../../domain/services/local_store.dart';
import 'chat_cache.dart';

ChatCache createChatCache(LocalStore store) => ChatCache(store);
