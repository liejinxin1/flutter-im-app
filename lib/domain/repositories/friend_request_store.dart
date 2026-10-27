import '../models/friend_request_update.dart';

/// Persists received-but-unhandled friend requests because the Agora Chat SDK
/// (1.4.0+1) exposes only live invitation events, not a pending list.
abstract interface class FriendRequestStore {
  Future<List<FriendRequestUpdate>> load(String userId);

  Future<void> save(String userId, List<FriendRequestUpdate> requests);
}
