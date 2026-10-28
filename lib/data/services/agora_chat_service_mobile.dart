import 'package:agora_chat_sdk/agora_chat_sdk.dart';
import 'package:flutter/foundation.dart';

import '../../app/app_config.dart';
import '../../domain/models/models.dart' as domain;

/// Native Agora Chat adapter.
///
/// Only this file is allowed to touch `agora_chat_sdk` types. Everything that
/// leaves the adapter is mapped to `domain` models.
class AgoraChatPlatform {
  final String _handlerId = 'agora-im-flutter-${identityHashCode(Object())}';
  bool _initialized = false;
  bool _disposed = false;
  Future<void>? _initializing;
  ValueChanged<domain.ChatMessage>? _onMessage;
  ValueChanged<domain.ChatMessage>? _onMessageUpdate;
  VoidCallback? _onConversationsChanged;
  ValueChanged<bool>? _onConnectionChanged;
  VoidCallback? _onSessionInvalidated;
  ValueChanged<domain.FriendRequestUpdate>? _onFriendRequestUpdate;

  String? get currentUserId => ChatClient.getInstance.currentUserId;

  Future<String?> restoreSession({
    required ValueChanged<domain.ChatMessage> onMessage,
    required ValueChanged<domain.ChatMessage> onMessageUpdate,
    required VoidCallback onConversationsChanged,
    required ValueChanged<bool> onConnectionChanged,
    required VoidCallback onSessionInvalidated,
    required ValueChanged<domain.FriendRequestUpdate> onFriendRequestUpdate,
  }) async {
    _bindCallbacks(
      onMessage: onMessage,
      onMessageUpdate: onMessageUpdate,
      onConversationsChanged: onConversationsChanged,
      onConnectionChanged: onConnectionChanged,
      onSessionInvalidated: onSessionInvalidated,
      onFriendRequestUpdate: onFriendRequestUpdate,
    );
    await _ensureInitialized();
    final client = ChatClient.getInstance;
    if (!await client.isLoginBefore()) return null;
    return client.getCurrentUserId();
  }

  Future<void> login({
    required String userId,
    required String credential,
    required bool usePassword,
    required ValueChanged<domain.ChatMessage> onMessage,
    required ValueChanged<domain.ChatMessage> onMessageUpdate,
    required VoidCallback onConversationsChanged,
    required ValueChanged<bool> onConnectionChanged,
    required VoidCallback onSessionInvalidated,
    required ValueChanged<domain.FriendRequestUpdate> onFriendRequestUpdate,
  }) async {
    _bindCallbacks(
      onMessage: onMessage,
      onMessageUpdate: onMessageUpdate,
      onConversationsChanged: onConversationsChanged,
      onConnectionChanged: onConnectionChanged,
      onSessionInvalidated: onSessionInvalidated,
      onFriendRequestUpdate: onFriendRequestUpdate,
    );

    await _ensureInitialized();
    final client = ChatClient.getInstance;
    if (await client.isLoginBefore()) {
      final currentUserId = await client.getCurrentUserId();
      if (currentUserId == userId && await client.isConnected()) return;
      await client.logout(true);
    }
    if (usePassword) {
      await client.loginWithPassword(userId, credential);
    } else {
      await client.loginWithToken(userId, credential);
    }
  }

  void _bindCallbacks({
    required ValueChanged<domain.ChatMessage> onMessage,
    required ValueChanged<domain.ChatMessage> onMessageUpdate,
    required VoidCallback onConversationsChanged,
    required ValueChanged<bool> onConnectionChanged,
    required VoidCallback onSessionInvalidated,
    required ValueChanged<domain.FriendRequestUpdate> onFriendRequestUpdate,
  }) {
    _onMessage = onMessage;
    _onMessageUpdate = onMessageUpdate;
    _onConversationsChanged = onConversationsChanged;
    _onConnectionChanged = onConnectionChanged;
    _onSessionInvalidated = onSessionInvalidated;
    _onFriendRequestUpdate = onFriendRequestUpdate;
  }

  Future<void> _ensureInitialized() async {
    if (_disposed) throw StateError('Chat platform has been disposed.');
    if (_initialized) return;
    final pending = _initializing ??= _initialize();
    try {
      await pending;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initialize() async {
    final appKey = AppConfig.appKey;
    final appId = AppConfig.appId;
    if (appKey.isEmpty && appId.isEmpty) {
      throw StateError(
        '请使用 --dart-define=AGORA_APP_KEY=... 配置 Agora Chat App Key。',
      );
    }
    final options = appKey.isNotEmpty
        ? ChatOptions.withAppKey(appKey, autoLogin: true)
        : ChatOptions.withAppId(appId, autoLogin: true);
    await ChatClient.getInstance.init(options);
    if (_disposed) return;
    ChatClient.getInstance.addConnectionEventHandler(
      _handlerId,
      ConnectionEventHandler(
        onConnected: () {
          _onConnectionChanged?.call(true);
          _onConversationsChanged?.call();
        },
        onDisconnected: () => _onConnectionChanged?.call(false),
        onTokenDidExpire: () => _onSessionInvalidated?.call(),
        onUserAuthenticationFailed: () => _onSessionInvalidated?.call(),
        onUserKickedByOtherDevice: () => _onSessionInvalidated?.call(),
        onUserDidRemoveFromServer: () => _onSessionInvalidated?.call(),
        onUserDidForbidByServer: () => _onSessionInvalidated?.call(),
        onUserDidChangePassword: () => _onSessionInvalidated?.call(),
      ),
    );
    ChatClient.getInstance.chatManager.addEventHandler(
      _handlerId,
      ChatEventHandler(
        onMessagesReceived: _handleMessages,
        onMessagesRead: _handleMessageUpdates,
        onMessagesDelivered: _handleMessageUpdates,
        onMessagesRecalledInfo: _handleMessageRecalls,
        onConversationsUpdate: () => _onConversationsChanged?.call(),
        onConversationRead: (_, _) => _onConversationsChanged?.call(),
      ),
    );
    ChatClient.getInstance.contactManager.addEventHandler(
      _handlerId,
      ChatContactEventHandler(
        onContactInvited: (userId, reason) => _onFriendRequestUpdate?.call(
          domain.FriendRequestUpdate(
            userId: userId,
            reason: reason,
            type: domain.FriendRequestUpdateType.received,
          ),
        ),
        onFriendRequestAccepted: (userId) => _onFriendRequestUpdate?.call(
          domain.FriendRequestUpdate(
            userId: userId,
            type: domain.FriendRequestUpdateType.accepted,
          ),
        ),
        onFriendRequestDeclined: (userId) => _onFriendRequestUpdate?.call(
          domain.FriendRequestUpdate(
            userId: userId,
            type: domain.FriendRequestUpdateType.declined,
          ),
        ),
        onContactAdded: (userId) => _onFriendRequestUpdate?.call(
          domain.FriendRequestUpdate(
            userId: userId,
            type: domain.FriendRequestUpdateType.contactAdded,
          ),
        ),
      ),
    );
    ChatClient.getInstance.chatManager.addMessageEvent(
      _handlerId,
      ChatMessageEvent(
        onSuccess: (_, message) => _emitMessageStatus(message),
        onError: (_, message, _) => _emitMessageStatus(message),
      ),
    );
    await ChatClient.getInstance.startCallback();
    if (!_disposed) _initialized = true;
  }

  void _handleMessages(List<ChatMessage> messages) {
    for (final message in messages) {
      final record = _mapMessage(message);
      if (record != null) _onMessage?.call(record);
    }
    _onConversationsChanged?.call();
  }

  void _handleMessageUpdates(List<ChatMessage> messages) {
    for (final message in messages) {
      final record = _mapMessage(message);
      if (record != null) _onMessageUpdate?.call(record);
    }
  }

  Future<List<domain.ChatConversation>> loadConversations() async {
    final conversations = await ChatClient.getInstance.chatManager
        .loadAllConversations();
    final records = <domain.ChatConversation>[];
    for (final conversation in conversations) {
      final latest = await conversation.latestMessage();
      final unreadCount = await conversation.unreadCount();
      final latestContent = latest == null
          ? null
          : _decodeBody(latest.body).content;
      records.add(
        domain.ChatConversation(
          id: conversation.id,
          kind: _conversationKind(conversation.type),
          name: null,
          lastMessage: latestContent is domain.TextMessageContent
              ? latestContent.text
              : '',
          lastMessageKind: latestContent?.kind,
          lastMessageSystemType: latestContent is domain.SystemMessageContent
              ? latestContent.systemType
              : null,
          lastActivity: latest == null ? null : _messageTime(latest),
          unreadCount: unreadCount,
          isPinned: false,
        ),
      );
    }
    records.sort(
      (a, b) => (b.lastActivity ?? DateTime(0)).compareTo(
        a.lastActivity ?? DateTime(0),
      ),
    );
    return records;
  }

  Future<domain.ChatMessagePage> loadMessages(
    String conversationId, {
    domain.ChatConversationKind kind = domain.ChatConversationKind.direct,
    String? cursor,
    int limit = 30,
  }) async {
    final page = await ChatClient.getInstance.chatManager
        .fetchHistoryMessagesByOption(
          conversationId,
          kind == domain.ChatConversationKind.group
              ? ChatConversationType.GroupChat
              : ChatConversationType.Chat,
          options: FetchMessageOptions(
            msgTypes: const [
              MessageType.TXT,
              MessageType.IMAGE,
              MessageType.VOICE,
              MessageType.FILE,
              MessageType.VIDEO,
              MessageType.LOCATION,
              MessageType.CUSTOM,
              MessageType.CMD,
            ],
            needSave: true,
            direction: ChatSearchDirection.Up,
          ),
          cursor: cursor,
          pageSize: limit.clamp(1, 50),
        );
    final records = page.data
        .map(_mapMessage)
        .whereType<domain.ChatMessage>()
        .toList();
    final merged = await _mergeLocalAttachmentPaths(records, conversationId);
    merged.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return domain.ChatMessagePage(
      items: merged,
      cursor: page.cursor,
      hasMore: page.cursor != null && page.cursor!.isNotEmpty,
    );
  }

  /// Server history never includes downloaded file paths. Overlay the locally
  /// stored copies so attachments downloaded earlier stay visible.
  Future<List<domain.ChatMessage>> _mergeLocalAttachmentPaths(
    List<domain.ChatMessage> records,
    String conversationId,
  ) async {
    final ids = records
        .where(
          (record) =>
              (record.localPath?.isEmpty ?? true) &&
              (record.thumbnailLocalPath?.isEmpty ?? true) &&
              record.kind != domain.ChatMessageKind.text,
        )
        .map((record) => record.id)
        .toList(growable: false);
    if (ids.isEmpty) return records;
    final Map<String, ChatMessage> localMessages;
    try {
      final messages = await ChatClient.getInstance.chatManager
          .loadMessagesWithIds(ids, conversationId);
      localMessages = {for (final message in messages) message.msgId: message};
    } catch (_) {
      return records;
    }
    if (localMessages.isEmpty) return records;
    return records
        .map((record) {
          final local = localMessages[record.id];
          if (local == null) return record;
          final mapped = _mapMessage(local);
          if (mapped == null) return record;
          return record.copyWith(
            content: record.content.withAttachmentPaths(
              localPath: mapped.localPath,
              thumbnailLocalPath: mapped.thumbnailLocalPath,
            ),
          );
        })
        .toList(growable: false);
  }

  Future<domain.ChatMessage> sendText(
    String conversationId,
    String text, {
    domain.ChatConversationKind kind = domain.ChatConversationKind.direct,
    required String clientId,
  }) async {
    final message = ChatMessage.createTxtSendMessage(
      targetId: conversationId,
      content: text,
      chatType: _chatType(kind),
    );
    message.attributes = {'_app_client_id': clientId};
    await ChatClient.getInstance.chatManager.sendMessage(message);
    return _mapMessage(message)!;
  }

  Future<domain.ChatMessage> sendImage(
    String conversationId,
    String path, {
    domain.ChatConversationKind kind = domain.ChatConversationKind.direct,
    required String clientId,
  }) async {
    final message = ChatMessage.createImageSendMessage(
      targetId: conversationId,
      filePath: path,
      chatType: _chatType(kind),
    );
    message.attributes = {'_app_client_id': clientId};
    await ChatClient.getInstance.chatManager.sendMessage(message);
    return _mapMessage(message)!;
  }

  Future<domain.ChatMessage> sendVoice(
    String conversationId,
    String path, {
    required int durationSeconds,
    domain.ChatConversationKind kind = domain.ChatConversationKind.direct,
    required String clientId,
  }) async {
    final message = ChatMessage.createVoiceSendMessage(
      targetId: conversationId,
      filePath: path,
      duration: durationSeconds,
      displayName: 'voice.m4a',
      chatType: _chatType(kind),
    );
    message.attributes = {'_app_client_id': clientId};
    await ChatClient.getInstance.chatManager.sendMessage(message);
    return _mapMessage(message)!;
  }

  Future<domain.ChatMessage> sendCustom(
    String conversationId,
    String event,
    Map<String, String> params, {
    domain.ChatConversationKind kind = domain.ChatConversationKind.direct,
    required String clientId,
  }) async {
    final message = ChatMessage.createCustomSendMessage(
      targetId: conversationId,
      event: event,
      params: params,
      chatType: _chatType(kind),
    );
    message.attributes = {'_app_client_id': clientId};
    await ChatClient.getInstance.chatManager.sendMessage(message);
    return _mapMessage(message)!;
  }

  Future<domain.ChatMessage> sendFile(
    String conversationId,
    String path, {
    String? fileName,
    int? fileSize,
    domain.ChatConversationKind kind = domain.ChatConversationKind.direct,
    required String clientId,
  }) async {
    final message = ChatMessage.createFileSendMessage(
      targetId: conversationId,
      filePath: path,
      displayName: fileName,
      fileSize: fileSize,
      chatType: _chatType(kind),
    );
    message.attributes = {'_app_client_id': clientId};
    await ChatClient.getInstance.chatManager.sendMessage(message);
    return _mapMessage(message)!;
  }

  Future<String?> downloadAttachment(String messageId) async {
    final client = ChatClient.getInstance;
    final message = await client.chatManager.loadMessage(messageId);
    if (message == null || message.body is! ChatFileMessageBody) return null;
    await client.chatManager.downloadAttachment(message);

    // The SDK mutates the in-memory body on success; prefer it over a DB
    // reload, which may race the persistence of localPath.
    final downloadedBody = message.body;
    if (downloadedBody is ChatFileMessageBody &&
        downloadedBody.localPath.isNotEmpty) {
      return downloadedBody.localPath;
    }

    final updated = await client.chatManager.loadMessage(messageId);
    final body = updated?.body;
    return body is ChatFileMessageBody && body.localPath.isNotEmpty
        ? body.localPath
        : null;
  }

  Future<String?> downloadThumbnail(String messageId) async {
    final client = ChatClient.getInstance;
    final message = await client.chatManager.loadMessage(messageId);
    if (message == null) {
      debugPrint('downloadThumbnail: message $messageId not found locally');
      return null;
    }
    if (message.body is! ChatImageMessageBody) {
      debugPrint('downloadThumbnail: message $messageId is not an image');
      return null;
    }
    try {
      await client.chatManager.downloadThumbnail(message);
    } catch (error) {
      // The SDK may reject a thumbnail that is already cached; fall through to
      // the local copy so a previously downloaded thumbnail is still used.
      debugPrint('downloadThumbnail failed for $messageId: $error');
    }
    return _thumbnailPath(client, messageId, message);
  }

  Future<String?> _thumbnailPath(
    ChatClient client,
    String messageId,
    ChatMessage message,
  ) async {
    final downloadedBody = message.body;
    if (downloadedBody is ChatImageMessageBody &&
        (downloadedBody.thumbnailLocalPath?.isNotEmpty ?? false)) {
      return downloadedBody.thumbnailLocalPath;
    }

    final updated = await client.chatManager.loadMessage(messageId);
    final body = updated?.body;
    return body is ChatImageMessageBody &&
            (body.thumbnailLocalPath?.isNotEmpty ?? false)
        ? body.thumbnailLocalPath
        : null;
  }

  domain.ChatConversationKind _conversationKind(ChatConversationType type) {
    if (type == ChatConversationType.GroupChat) {
      return domain.ChatConversationKind.group;
    }
    if (type == ChatConversationType.ChatRoom) {
      return domain.ChatConversationKind.chatRoom;
    }
    return domain.ChatConversationKind.direct;
  }

  Future<void> deleteMessage(
    String conversationId,
    String messageId, {
    domain.ChatConversationKind kind = domain.ChatConversationKind.direct,
  }) async {
    final conversation = await ChatClient.getInstance.chatManager
        .getConversation(
          conversationId,
          type: _conversationType(kind),
          createIfNeed: false,
        );
    await conversation?.deleteMessage(messageId);
  }

  Future<void> recallMessage(String messageId) =>
      ChatClient.getInstance.chatManager.recallMessage(messageId);

  void _handleMessageRecalls(List<RecallMessageInfo> infos) {
    final currentUserId = ChatClient.getInstance.currentUserId;
    for (final info in infos) {
      final conversationId =
          info.conversationId ?? info.recallMessage?.conversationId;
      if (conversationId == null || conversationId.isEmpty) continue;
      _onMessageUpdate?.call(
        domain.ChatMessage(
          id: info.recallMessageId,
          conversationId: conversationId,
          senderId: info.recallBy,
          content: const domain.SystemMessageContent(
            text: '',
            systemType: 'recall',
          ),
          sentAt: DateTime.now(),
          deliveryState: domain.ChatMessageDeliveryState.sent,
          isOutgoing: info.recallBy == currentUserId,
        ),
      );
    }
    _onConversationsChanged?.call();
  }

  ChatConversationType _conversationType(domain.ChatConversationKind kind) =>
      kind == domain.ChatConversationKind.group
      ? ChatConversationType.GroupChat
      : ChatConversationType.Chat;

  ChatType _chatType(domain.ChatConversationKind kind) =>
      kind == domain.ChatConversationKind.group
      ? ChatType.GroupChat
      : ChatType.Chat;

  void _emitMessageStatus(ChatMessage message) {
    final record = _mapMessage(message);
    if (record == null) return;
    _onMessageUpdate?.call(record);
    _onConversationsChanged?.call();
  }

  Future<void> markConversationRead(
    String conversationId, {
    domain.ChatConversationKind kind = domain.ChatConversationKind.direct,
  }) async {
    final conversation = await ChatClient.getInstance.chatManager
        .getConversation(
          conversationId,
          type: kind == domain.ChatConversationKind.group
              ? ChatConversationType.GroupChat
              : ChatConversationType.Chat,
          createIfNeed: false,
        );
    await conversation?.markAllMessagesAsRead();
    if (kind == domain.ChatConversationKind.direct) {
      await ChatClient.getInstance.chatManager.sendConversationReadAck(
        conversationId,
      );
    }
  }

  Future<List<domain.UserProfile>> loadContacts() async =>
      (await ChatClient.getInstance.contactManager.fetchAllContacts())
          .map(
            (contact) => domain.UserProfile(
              userId: contact.userId,
              remark: contact.remark,
            ),
          )
          .toList(growable: false);

  Future<Map<String, domain.UserProfile>> loadUserProfiles(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return const {};
    final infos = await ChatClient.getInstance.userInfoManager
        .fetchUserInfoById(userIds);
    return {
      for (final entry in infos.entries)
        entry.key: domain.UserProfile(
          userId: entry.value.userId,
          nickname: entry.value.nickName,
          avatarUrl: entry.value.avatarUrl,
        ),
    };
  }

  Future<void> addContact(String userId) =>
      ChatClient.getInstance.contactManager.addContact(userId);

  Future<void> acceptContactRequest(String userId) =>
      ChatClient.getInstance.contactManager.acceptInvitation(userId);

  Future<void> declineContactRequest(String userId) =>
      ChatClient.getInstance.contactManager.declineInvitation(userId);

  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    final group = await ChatClient.getInstance.groupManager.createGroup(
      groupName: name,
      inviteMembers: memberIds,
      options: ChatGroupOptions(
        style: ChatGroupStyle.PrivateMemberCanInvite,
        inviteNeedConfirm: true,
      ),
    );
    await ChatClient.getInstance.chatManager.getConversation(
      group.groupId,
      type: ChatConversationType.GroupChat,
      createIfNeed: true,
    );
    return group.groupId;
  }

  domain.ChatMessage? _mapMessage(ChatMessage message) {
    final body = message.body;
    final currentUserId = ChatClient.getInstance.currentUserId;
    final isOutgoing = message.from == currentUserId;
    final decoded = _decodeBody(body);
    return domain.ChatMessage(
      id: message.msgId,
      conversationId: message.conversationId ?? message.to ?? '',
      senderId: message.from ?? '',
      content: decoded.content,
      sentAt: _messageTime(message),
      deliveryState: _deliveryState(message, isOutgoing),
      isOutgoing: isOutgoing,
      clientId:
          decoded.clientId ?? message.attributes?['_app_client_id'] as String?,
    );
  }

  ({domain.ChatMessageContent content, String? clientId}) _decodeBody(
    ChatMessageBody body,
  ) {
    if (body is ChatCustomMessageBody && body.event == domain.appMessageEvent) {
      final envelope = domain.ChatMessageEnvelope.tryDecode(
        body.params?['payload'],
      );
      if (envelope != null) {
        return (content: envelope.content, clientId: envelope.clientId);
      }
    }
    final content = switch (body) {
      ChatTextMessageBody text => domain.TextMessageContent(text.content),
      ChatImageMessageBody image => domain.ImageMessageContent(
        localPath: image.localPath,
        remotePath: image.remotePath,
        secret: image.secret,
        thumbnailLocalPath: image.thumbnailLocalPath,
        width: image.width?.toDouble(),
        height: image.height?.toDouble(),
      ),
      ChatVoiceMessageBody voice => domain.VoiceMessageContent(
        localPath: voice.localPath,
        remotePath: voice.remotePath,
        secret: voice.secret,
        durationSeconds: voice.duration,
      ),
      ChatVideoMessageBody video => domain.VideoMessageContent(
        localPath: video.localPath,
        remotePath: video.remotePath,
        secret: video.secret,
        thumbnailLocalPath: video.thumbnailLocalPath,
        durationSeconds: video.duration ?? 0,
        width: video.width?.toDouble(),
        height: video.height?.toDouble(),
      ),
      ChatFileMessageBody file => domain.FileMessageContent(
        fileName: file.displayName,
        fileSizeBytes: file.fileSize ?? 0,
        localPath: file.localPath,
        remotePath: file.remotePath,
        secret: file.secret,
      ),
      ChatLocationMessageBody location => domain.LocationMessageContent(
        latitude: location.latitude,
        longitude: location.longitude,
        address: location.address,
        title: location.buildingName,
      ),
      ChatCustomMessageBody custom => domain.CustomMessageContent(
        event: custom.event,
        params: {...?custom.params},
      ),
      ChatCmdMessageBody command => domain.SystemMessageContent(
        text: command.action,
        systemType: 'command',
      ),
      _ => domain.UnknownMessageContent(rawType: body.type.name),
    };
    return (content: content, clientId: null);
  }

  DateTime _messageTime(ChatMessage message) {
    final timestamp = message.serverTime > 0
        ? message.serverTime
        : message.localTime;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  domain.ChatMessageDeliveryState _deliveryState(
    ChatMessage message,
    bool isOutgoing,
  ) {
    if (!isOutgoing) return domain.ChatMessageDeliveryState.sent;
    if (message.hasReadAck) return domain.ChatMessageDeliveryState.read;
    if (message.hasDeliverAck) return domain.ChatMessageDeliveryState.delivered;
    return switch (message.status) {
      MessageStatus.CREATE ||
      MessageStatus.PROGRESS => domain.ChatMessageDeliveryState.sending,
      MessageStatus.SUCCESS => domain.ChatMessageDeliveryState.sent,
      MessageStatus.FAIL => domain.ChatMessageDeliveryState.failed,
    };
  }

  Future<void> logout() async {
    if (!_initialized) return;
    final client = ChatClient.getInstance;
    if (await client.isLoginBefore()) await client.logout(true);
    if (await client.isLoginBefore() ||
        await client.getCurrentUserId() != null) {
      throw StateError(
        'Agora Chat logout completed but the SDK session is still active.',
      );
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    clearCallbacks();
    final client = ChatClient.getInstance;
    client.removeConnectionEventHandler(_handlerId);
    client.chatManager.removeEventHandler(_handlerId);
    client.chatManager.removeMessageEvent(_handlerId);
    client.contactManager.removeEventHandler(_handlerId);
    _initialized = false;
  }

  void clearCallbacks() {
    _onMessage = null;
    _onMessageUpdate = null;
    _onConversationsChanged = null;
    _onConnectionChanged = null;
    _onSessionInvalidated = null;
    _onFriendRequestUpdate = null;
  }
}
