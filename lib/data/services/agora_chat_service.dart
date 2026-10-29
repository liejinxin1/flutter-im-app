import 'package:flutter/foundation.dart';

import '../../domain/models/chat_conversation.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/friend_request_update.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/services/chat_service.dart';
import '../../domain/services/user_directory.dart';
import 'agora_chat_service_stub.dart'
    if (dart.library.io) 'agora_chat_service_mobile.dart'
    as adapter;

/// Thin, platform-aware facade over the Agora Chat SDK.
///
/// Responsibilities:
/// - choose the native adapter or the Web stub;
/// - expose only app-owned domain models to the rest of the app;
/// - keep SDK callbacks in one place (wired by `ChatConnection`).
class AgoraChatService implements UserDirectory, ChatService {
  final platform = adapter.AgoraChatPlatform();

  @override
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  String? get currentUserId => isSupported ? platform.currentUserId : null;

  @override
  Future<String?> restoreSession({
    required ValueChanged<ChatMessage> onMessage,
    required ValueChanged<ChatMessage> onMessageUpdate,
    required VoidCallback onConversationsChanged,
    required ValueChanged<bool> onConnectionChanged,
    required VoidCallback onSessionInvalidated,
    required ValueChanged<FriendRequestUpdate> onFriendRequestUpdate,
  }) async {
    if (!isSupported) return null;
    return platform.restoreSession(
      onMessage: onMessage,
      onMessageUpdate: onMessageUpdate,
      onConversationsChanged: onConversationsChanged,
      onConnectionChanged: onConnectionChanged,
      onSessionInvalidated: onSessionInvalidated,
      onFriendRequestUpdate: onFriendRequestUpdate,
    );
  }

  @override
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
    if (!isSupported) {
      throw UnsupportedError(
        'Agora Chat Web SDK 尚未接入；当前 Flutter 插件只支持 Android/iOS。',
      );
    }
    await platform.login(
      userId: userId,
      credential: credential,
      usePassword: usePassword,
      onMessage: onMessage,
      onMessageUpdate: onMessageUpdate,
      onConversationsChanged: onConversationsChanged,
      onConnectionChanged: onConnectionChanged,
      onSessionInvalidated: onSessionInvalidated,
      onFriendRequestUpdate: onFriendRequestUpdate,
    );
  }

  @override
  Future<List<ChatConversation>> loadConversations() =>
      !isSupported ? Future.value(const []) : platform.loadConversations();

  @override
  Future<ChatMessagePage> loadMessages(
    String conversationId, {
    ChatConversationKind kind = ChatConversationKind.direct,
    String? cursor,
    int limit = 30,
  }) => !isSupported
      ? Future.value(
          const ChatMessagePage(items: [], cursor: null, hasMore: false),
        )
      : platform.loadMessages(
          conversationId,
          kind: kind,
          cursor: cursor,
          limit: limit,
        );

  @override
  Future<ChatMessage> sendText(
    String conversationId,
    String text, {
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) {
    if (!isSupported) throw UnsupportedError('Agora Chat 仅支持 Android/iOS。');
    return platform.sendText(
      conversationId,
      text,
      kind: kind,
      clientId: clientId,
    );
  }

  @override
  Future<ChatMessage> sendImage(
    String conversationId,
    String path, {
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) {
    if (!isSupported) throw UnsupportedError('Agora Chat 仅支持 Android/iOS。');
    return platform.sendImage(
      conversationId,
      path,
      kind: kind,
      clientId: clientId,
    );
  }

  @override
  Future<ChatMessage> sendVoice(
    String conversationId,
    String path, {
    required int durationSeconds,
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) {
    if (!isSupported) throw UnsupportedError('Agora Chat 仅支持 Android/iOS。');
    return platform.sendVoice(
      conversationId,
      path,
      durationSeconds: durationSeconds,
      kind: kind,
      clientId: clientId,
    );
  }

  @override
  Future<ChatMessage> sendCustom(
    String conversationId,
    String event,
    Map<String, String> params, {
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) {
    if (!isSupported) throw UnsupportedError('Agora Chat 仅支持 Android/iOS。');
    return platform.sendCustom(
      conversationId,
      event,
      params,
      kind: kind,
      clientId: clientId,
    );
  }

  @override
  Future<ChatMessage> sendFile(
    String conversationId,
    String path, {
    String? fileName,
    int? fileSize,
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) {
    if (!isSupported) throw UnsupportedError('Agora Chat 仅支持 Android/iOS。');
    return platform.sendFile(
      conversationId,
      path,
      fileName: fileName,
      fileSize: fileSize,
      kind: kind,
      clientId: clientId,
    );
  }

  @override
  Future<String?> downloadAttachment(String messageId) {
    if (!isSupported) throw UnsupportedError('Agora Chat 仅支持 Android/iOS。');
    return platform.downloadAttachment(messageId);
  }

  @override
  Future<String?> downloadThumbnail(String messageId) {
    if (!isSupported) throw UnsupportedError('Agora Chat 仅支持 Android/iOS。');
    return platform.downloadThumbnail(messageId);
  }

  @override
  Future<void> deleteMessage(
    String conversationId,
    String messageId, {
    ChatConversationKind kind = ChatConversationKind.direct,
  }) async {
    if (isSupported) {
      await platform.deleteMessage(conversationId, messageId, kind: kind);
    }
  }

  @override
  Future<void> recallMessage(String messageId) async {
    if (isSupported) await platform.recallMessage(messageId);
  }

  @override
  Future<void> markConversationRead(
    String conversationId, {
    ChatConversationKind kind = ChatConversationKind.direct,
  }) async {
    if (isSupported) {
      await platform.markConversationRead(conversationId, kind: kind);
    }
  }

  @override
  Future<void> logout() async {
    if (isSupported) await platform.logout();
  }

  @override
  Future<List<UserProfile>> loadContacts() =>
      !isSupported ? Future.value(const []) : platform.loadContacts();

  @override
  Future<Map<String, UserProfile>> loadUserProfiles(List<String> userIds) =>
      !isSupported
      ? Future.value(const {})
      : platform.loadUserProfiles(userIds);

  @override
  Future<void> addContact(String userId) {
    if (!isSupported) throw UnsupportedError('Agora Chat 仅支持 Android/iOS。');
    return platform.addContact(userId);
  }

  @override
  Future<void> acceptContactRequest(String userId) {
    if (!isSupported) throw UnsupportedError('Agora Chat 仅支持 Android/iOS。');
    return platform.acceptContactRequest(userId);
  }

  @override
  Future<void> declineContactRequest(String userId) {
    if (!isSupported) throw UnsupportedError('Agora Chat 仅支持 Android/iOS。');
    return platform.declineContactRequest(userId);
  }

  @override
  Future<void> acceptGroupInvitation(String groupId, String inviter) {
    if (!isSupported) throw UnsupportedError('Agora Chat 仅支持 Android/iOS。');
    return platform.acceptGroupInvitation(groupId, inviter);
  }

  @override
  Future<void> declineGroupInvitation(String groupId, String inviter) {
    if (!isSupported) throw UnsupportedError('Agora Chat 仅支持 Android/iOS。');
    return platform.declineGroupInvitation(groupId, inviter);
  }

  @override
  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  }) {
    if (!isSupported) throw UnsupportedError('Agora Chat 仅支持 Android/iOS。');
    return platform.createGroup(name: name, memberIds: memberIds);
  }

  @override
  Future<void> dispose() async {
    if (isSupported) await platform.dispose();
  }
}
