import 'package:flutter/foundation.dart';

import '../../domain/models/chat_conversation.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/friend_request_update.dart';
import '../../domain/models/user_profile.dart';

/// Web/unsupported-platform adapter. Shapes match the native adapter so the
/// facade can be selected with a conditional import.
class AgoraChatPlatform {
  String? get currentUserId => null;

  Future<void> login({
    required String userId,
    required String credential,
    required bool usePassword,
    required ValueChanged<ChatMessage> onMessage,
    required ValueChanged<ChatMessage> onMessageUpdate,
    required VoidCallback onConversationsChanged,
    required ValueChanged<bool> onConnectionChanged,
    required VoidCallback onSessionInvalidated,
    required ValueChanged<FriendRequestUpdate> onFriendRequestUpdate,
  }) async {
    throw UnsupportedError(
      'Agora Chat Flutter SDK is only available on Android and iOS.',
    );
  }

  Future<List<ChatConversation>> loadConversations() async => const [];

  Future<ChatMessagePage> loadMessages(
    String conversationId, {
    ChatConversationKind kind = ChatConversationKind.direct,
    String? cursor,
    int limit = 30,
  }) async => const ChatMessagePage(items: [], cursor: null, hasMore: false);

  Future<ChatMessage> sendText(
    String conversationId,
    String text, {
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) =>
      Future.error(UnsupportedError('Agora Chat Flutter SDK is unavailable.'));

  Future<ChatMessage> sendImage(
    String conversationId,
    String path, {
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) =>
      Future.error(UnsupportedError('Agora Chat Flutter SDK is unavailable.'));

  Future<ChatMessage> sendVoice(
    String conversationId,
    String path, {
    required int durationSeconds,
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) =>
      Future.error(UnsupportedError('Agora Chat Flutter SDK is unavailable.'));

  Future<ChatMessage> sendCustom(
    String conversationId,
    String event,
    Map<String, String> params, {
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) =>
      Future.error(UnsupportedError('Agora Chat Flutter SDK is unavailable.'));

  Future<ChatMessage> sendFile(
    String conversationId,
    String path, {
    String? fileName,
    int? fileSize,
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) =>
      Future.error(UnsupportedError('Agora Chat Flutter SDK is unavailable.'));

  Future<String?> downloadAttachment(String messageId) =>
      Future.error(UnsupportedError('Agora Chat Flutter SDK is unavailable.'));

  Future<String?> downloadThumbnail(String messageId) =>
      Future.error(UnsupportedError('Agora Chat Flutter SDK is unavailable.'));

  Future<void> deleteMessage(
    String conversationId,
    String messageId, {
    ChatConversationKind kind = ChatConversationKind.direct,
  }) =>
      Future.error(UnsupportedError('Agora Chat Flutter SDK is unavailable.'));

  Future<void> recallMessage(String messageId) =>
      Future.error(UnsupportedError('Agora Chat Flutter SDK is unavailable.'));

  Future<void> markConversationRead(
    String conversationId, {
    ChatConversationKind kind = ChatConversationKind.direct,
  }) async {}

  Future<List<UserProfile>> loadContacts() async => const [];

  Future<Map<String, UserProfile>> loadUserProfiles(
    List<String> userIds,
  ) async => const {};

  Future<void> addContact(String userId) =>
      Future.error(UnsupportedError('Agora Chat Flutter SDK is unavailable.'));

  Future<void> acceptContactRequest(String userId) =>
      Future.error(UnsupportedError('Agora Chat Flutter SDK is unavailable.'));

  Future<void> declineContactRequest(String userId) =>
      Future.error(UnsupportedError('Agora Chat Flutter SDK is unavailable.'));

  Future<void> acceptGroupInvitation(String groupId, String inviter) =>
      Future.error(UnsupportedError('Agora Chat Flutter SDK is unavailable.'));

  Future<void> declineGroupInvitation(String groupId, String inviter) =>
      Future.error(UnsupportedError('Agora Chat Flutter SDK is unavailable.'));

  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  }) =>
      Future.error(UnsupportedError('Agora Chat Flutter SDK is unavailable.'));

  Future<void> logout() async {}

  Future<void> dispose() async {}

  Future<String?> restoreSession({
    required ValueChanged<ChatMessage> onMessage,
    required ValueChanged<ChatMessage> onMessageUpdate,
    required VoidCallback onConversationsChanged,
    required ValueChanged<bool> onConnectionChanged,
    required VoidCallback onSessionInvalidated,
    required ValueChanged<FriendRequestUpdate> onFriendRequestUpdate,
  }) async => null;
}
