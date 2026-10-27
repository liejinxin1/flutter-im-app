import '../../domain/models/friend_request_update.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/contact_repository.dart';
import '../services/chat_connection.dart';

class AgoraContactRepository implements ContactRepository {
  AgoraContactRepository(this._connection);

  final ChatConnection _connection;

  @override
  Stream<FriendRequestUpdate> get friendRequestUpdates =>
      _connection.friendRequestUpdates;
  @override
  Future<List<UserProfile>> loadContacts() =>
      _connection.service.loadContacts();
  @override
  Future<void> addContact(String userId) =>
      _connection.service.addContact(userId);
  @override
  Future<void> acceptContactRequest(String userId) =>
      _connection.service.acceptContactRequest(userId);
  @override
  Future<void> declineContactRequest(String userId) =>
      _connection.service.declineContactRequest(userId);
}
