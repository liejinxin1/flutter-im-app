import 'friend_cache.dart';
import 'friend_cache_factory_stub.dart'
    if (dart.library.io) 'friend_cache_factory_io.dart'
    as platform;

FriendCache? createFriendCache() => platform.createFriendCache();
