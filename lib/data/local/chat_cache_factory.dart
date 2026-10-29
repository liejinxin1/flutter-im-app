import '../../domain/services/local_store.dart';
import 'chat_cache.dart';
import 'chat_cache_factory_stub.dart'
    if (dart.library.io) 'chat_cache_factory_io.dart'
    as platform;

ChatCache createChatCache(LocalStore store) => platform.createChatCache(store);
