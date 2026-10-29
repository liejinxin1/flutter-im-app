import 'app_database.dart';
import 'friend_cache.dart';

FriendCache? createFriendCache() => FriendCache(AppDatabase.instance);
