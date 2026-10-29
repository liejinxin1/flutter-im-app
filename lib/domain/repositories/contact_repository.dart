import '../models/friend_request_update.dart';
import '../models/user_profile.dart';

abstract interface class ContactRepository {
  Stream<FriendRequestUpdate> get friendRequestUpdates;

  Future<List<UserProfile>> loadContacts();
  Future<void> addContact(String userId);
  Future<void> acceptContactRequest(String userId);
  Future<void> declineContactRequest(String userId);
  Future<void> acceptGroupInvitation(String groupId, String inviter);
  Future<void> declineGroupInvitation(String groupId, String inviter);
}
