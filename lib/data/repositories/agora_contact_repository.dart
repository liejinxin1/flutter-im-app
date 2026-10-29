import '../../domain/models/friend_request_update.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/contact_repository.dart';
import '../local/friend_cache.dart';
import '../services/chat_connection.dart';

class AgoraContactRepository implements ContactRepository {
  AgoraContactRepository(this._connection, {this.cache});

  final ChatConnection _connection;
  final FriendCache? cache;

  String get _accountId => _connection.service.currentUserId ?? '';

  @override
  Stream<FriendRequestUpdate> get friendRequestUpdates =>
      _connection.friendRequestUpdates;
  @override
  Future<List<UserProfile>> loadContacts() async {
    try {
      final contacts = await _connection.service.loadContacts();
      await cache?.saveAll(_accountId, contacts);
      return contacts;
    } catch (_) {
      final cached = await cache?.load(_accountId) ?? const <UserProfile>[];
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  @override
  Future<void> addContact(String userId) =>
      _connection.service.addContact(userId);
  @override
  Future<void> acceptContactRequest(String userId) =>
      _connection.service.acceptContactRequest(userId);
  @override
  Future<void> declineContactRequest(String userId) =>
      _connection.service.declineContactRequest(userId);
  @override
  Future<void> updateRemark(String userId, String remark) async {
    await _connection.service.setContactRemark(userId, remark);
    await cache?.updateRemark(_accountId, userId, remark);
  }

  @override
  Future<void> acceptGroupInvitation(String groupId, String inviter) =>
      _connection.service.acceptGroupInvitation(groupId, inviter);
  @override
  Future<void> declineGroupInvitation(String groupId, String inviter) =>
      _connection.service.declineGroupInvitation(groupId, inviter);
}
