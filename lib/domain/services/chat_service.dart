import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/friend_request_update.dart';
import '../models/group_member.dart';
import '../models/user_profile.dart';
import 'user_directory.dart';

/// Transport-level contract for a chat backend.
///
/// This is the seam for replacing Agora Chat: the repositories, caches, outbox,
/// ViewModels, and widgets depend on this interface, not on the SDK. A new
/// backend only needs to implement [ChatService] and be wired in
/// `AppDependencies.create`.
abstract interface class ChatService implements UserDirectory {
  bool get isSupported;
  @override
  String? get currentUserId;

  Future<String?> restoreSession({
    required void Function(ChatMessage message) onMessage,
    required void Function(ChatMessage message) onMessageUpdate,
    required void Function() onConversationsChanged,
    required void Function(bool connected) onConnectionChanged,
    required void Function() onSessionInvalidated,
    required void Function(FriendRequestUpdate update) onFriendRequestUpdate,
  });

  Future<void> login({
    required String userId,
    required String credential,
    required bool usePassword,
    required void Function(ChatMessage message) onMessage,
    required void Function(ChatMessage message) onMessageUpdate,
    required void Function() onConversationsChanged,
    required void Function(bool connected) onConnectionChanged,
    required void Function() onSessionInvalidated,
    required void Function(FriendRequestUpdate update) onFriendRequestUpdate,
  });

  Future<List<ChatConversation>> loadConversations();

  Future<ChatMessagePage> loadMessages(
    String conversationId, {
    ChatConversationKind kind = ChatConversationKind.direct,
    String? cursor,
    int limit = 30,
  });

  Future<ChatMessage> sendText(
    String conversationId,
    String text, {
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  });

  Future<ChatMessage> sendImage(
    String conversationId,
    String path, {
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  });

  Future<ChatMessage> sendVoice(
    String conversationId,
    String path, {
    required int durationSeconds,
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  });

  /// Sends an app-defined custom envelope (`event` + JSON `params`).
  Future<ChatMessage> sendCustom(
    String conversationId,
    String event,
    Map<String, String> params, {
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  });

  /// Native SDK file message, used when no external uploader is configured.
  Future<ChatMessage> sendFile(
    String conversationId,
    String path, {
    String? fileName,
    int? fileSize,
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  });

  Future<String?> downloadAttachment(String messageId);
  Future<String?> downloadThumbnail(String messageId);
  Future<void> deleteMessage(
    String conversationId,
    String messageId, {
    ChatConversationKind kind = ChatConversationKind.direct,
  });
  Future<void> recallMessage(String messageId);

  Future<void> markConversationRead(
    String conversationId, {
    ChatConversationKind kind = ChatConversationKind.direct,
  });

  Future<void> logout();

  Future<List<UserProfile>> loadContacts();
  @override
  Future<Map<String, UserProfile>> loadUserProfiles(List<String> userIds);
  @override
  Future<void> updateUserProfile(UserProfile profile);
  Future<void> addContact(String userId);
  Future<void> acceptContactRequest(String userId);
  Future<void> declineContactRequest(String userId);
  Future<void> setContactRemark(String userId, String remark);
  Future<void> acceptGroupInvitation(String groupId, String inviter);
  Future<void> declineGroupInvitation(String groupId, String inviter);
  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  });
  Future<List<GroupMember>> loadGroupMembers(String groupId);
  Future<void> updateGroupName(String groupId, String name);
  Future<void> leaveGroup(String groupId);
  Future<void> removeGroupMember(String groupId, String userId);
  Future<void> setGroupAdmin(
    String groupId,
    String userId, {
    required bool admin,
  });

  Future<void> dispose();
}
