import 'dart:async';

import '../../domain/models/chat_conversation.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_message_envelope.dart';
import '../../domain/models/outbox_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/outbox_repository.dart';
import '../../domain/services/chat_service.dart';
import '../../domain/services/message_transport.dart';
import '../local/chat_cache.dart';
import '../services/chat_connection.dart';

/// Chat data entry point for ViewModels.
///
/// Responsibilities:
/// - map SDK calls to domain models (the service already does the mapping);
/// - cache the conversation list and newest message page for offline reads;
/// - persist sends in an outbox until the SDK acknowledges them;
/// - replay the outbox on reconnect.
class AgoraChatRepository implements ChatRepository {
  AgoraChatRepository(
    this._connection,
    this._cache,
    this._outbox, {
    this.transportMode = MessageTransportMode.native,
    this.uploader,
    this.customAttachmentKinds = const {
      ChatMessageKind.image,
      ChatMessageKind.voice,
      ChatMessageKind.file,
      ChatMessageKind.video,
    },
  });

  final ChatConnection _connection;
  final ChatCache _cache;
  final OutboxRepository _outbox;
  final MessageTransportMode transportMode;
  final AttachmentUploader? uploader;
  final Set<ChatMessageKind> customAttachmentKinds;
  final Set<String> _inFlight = {};

  ChatService get _service => _connection.service;

  @override
  Stream<ChatMessage> get incomingMessages => _connection.incomingMessages;
  @override
  Stream<ChatMessage> get messageUpdates => _connection.messageUpdates;
  @override
  Stream<void> get conversationsChanged => _connection.conversationsChanged;

  @override
  Future<List<ChatConversation>> loadConversations() async {
    final userId = _service.currentUserId ?? '';
    try {
      final conversations = await _service.loadConversations();
      if (userId.isNotEmpty) {
        unawaited(_cache.saveConversations(userId, conversations));
      }
      return conversations;
    } catch (error) {
      if (userId.isNotEmpty) {
        final cached = await _cache.loadConversations(userId);
        if (cached.isNotEmpty) return cached;
      }
      rethrow;
    }
  }

  @override
  Future<ChatMessagePage> loadMessages(
    String conversationId, {
    ChatConversationKind kind = ChatConversationKind.direct,
    String? cursor,
    int limit = 30,
  }) async {
    final userId = _service.currentUserId ?? '';
    try {
      final page = await _service.loadMessages(
        conversationId,
        kind: kind,
        cursor: cursor,
        limit: limit,
      );
      // Server history carries no local attachment paths; restore the ones
      // this device already downloaded so images stay visible after re-entry.
      final items = await _cache.mergeAttachmentPaths(userId, page.items);
      if (cursor == null && userId.isNotEmpty) {
        unawaited(_cache.saveMessages(userId, conversationId, items));
      }
      return ChatMessagePage(
        items: items,
        cursor: page.cursor,
        hasMore: page.hasMore,
      );
    } catch (error) {
      if (cursor == null && userId.isNotEmpty) {
        final cached = await _cache.loadMessages(userId, conversationId);
        if (cached.items.isNotEmpty) return cached;
      }
      rethrow;
    }
  }

  @override
  Future<ChatMessage> sendText(
    String conversationId,
    String text, {
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) => _sendWithOutbox(
    conversationId,
    TextMessageContent(text),
    kind: kind,
    clientId: clientId,
  );

  @override
  Future<ChatMessage> sendImage(
    String conversationId,
    String path, {
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) => _sendWithOutbox(
    conversationId,
    ImageMessageContent(localPath: path),
    kind: kind,
    clientId: clientId,
  );

  @override
  Future<ChatMessage> sendVoice(
    String conversationId,
    String path, {
    required int durationSeconds,
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) => _sendWithOutbox(
    conversationId,
    VoiceMessageContent(localPath: path, durationSeconds: durationSeconds),
    kind: kind,
    clientId: clientId,
  );

  @override
  Future<ChatMessage> sendFile(
    String conversationId,
    String path, {
    String? fileName,
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) => _sendWithOutbox(
    conversationId,
    FileMessageContent(localPath: path, fileName: fileName),
    kind: kind,
    clientId: clientId,
  );

  Future<ChatMessage> _sendWithOutbox(
    String conversationId,
    ChatMessageContent content, {
    required ChatConversationKind kind,
    required String clientId,
  }) async {
    final userId = _service.currentUserId ?? '';
    await _saveOutbox(
      userId,
      OutboxMessage(
        clientId: clientId,
        conversationId: conversationId,
        senderId: userId,
        content: content,
        conversationKind: kind,
        createdAt: DateTime.now(),
      ),
    );
    return _withSendLock(clientId, () async {
      final sent = await _sendContent(
        conversationId,
        content,
        kind: kind,
        clientId: clientId,
      );
      await _removeOutbox(userId, clientId);
      return sent;
    });
  }

  Future<ChatMessage> _sendContent(
    String conversationId,
    ChatMessageContent content, {
    required ChatConversationKind kind,
    required String clientId,
  }) async {
    return switch (content) {
      TextMessageContent(:final text) => _sendTextContent(
        conversationId,
        text,
        kind: kind,
        clientId: clientId,
      ),
      ImageMessageContent() ||
      VoiceMessageContent() ||
      FileMessageContent() => _sendAttachment(
        conversationId,
        content as AttachmentMessageContent,
        kind: kind,
        clientId: clientId,
      ),
      _ => throw UnsupportedError(
        'Sending ${content.kind.name} messages is not supported yet.',
      ),
    };
  }

  Future<ChatMessage> _sendTextContent(
    String conversationId,
    String text, {
    required ChatConversationKind kind,
    required String clientId,
  }) {
    if (transportMode == MessageTransportMode.native) {
      return _service.sendText(
        conversationId,
        text,
        kind: kind,
        clientId: clientId,
      );
    }
    return _sendEnvelope(
      conversationId,
      TextMessageContent(text),
      kind: kind,
      clientId: clientId,
    );
  }

  Future<ChatMessage> _sendAttachment(
    String conversationId,
    AttachmentMessageContent content, {
    required ChatConversationKind kind,
    required String clientId,
  }) async {
    if (transportMode == MessageTransportMode.native ||
        !customAttachmentKinds.contains(content.kind)) {
      return _sendNativeAttachment(
        conversationId,
        content,
        kind: kind,
        clientId: clientId,
      );
    }

    final localPath = content.localPath;
    if (localPath == null || localPath.isEmpty) {
      throw StateError('Attachment local path is missing.');
    }

    final currentUploader = uploader;
    if (currentUploader != null) {
      final uploaded = await currentUploader.upload(
        AttachmentUploadRequest(
          localPath: localPath,
          kind: content.kind,
          fileName: content is FileMessageContent ? content.fileName : null,
          mimeType: content is FileMessageContent ? content.mimeType : null,
        ),
      );
      if (uploaded != null) {
        return _sendEnvelope(
          conversationId,
          _withRemoteUrl(content, uploaded),
          kind: kind,
          clientId: clientId,
        );
      }
    }

    if (transportMode == MessageTransportMode.custom) {
      throw StateError(
        'Custom attachment transport requires an AttachmentUploader.',
      );
    }
    // Hybrid: no OSS yet, use the native SDK message type.
    return _sendNativeAttachment(
      conversationId,
      content,
      kind: kind,
      clientId: clientId,
    );
  }

  Future<ChatMessage> _sendEnvelope(
    String conversationId,
    ChatMessageContent content, {
    required ChatConversationKind kind,
    required String clientId,
  }) {
    final envelope = ChatMessageEnvelope(clientId: clientId, content: content);
    return _service.sendCustom(
      conversationId,
      appMessageEvent,
      {'payload': envelope.encode()},
      kind: kind,
      clientId: clientId,
    );
  }

  Future<ChatMessage> _sendNativeAttachment(
    String conversationId,
    AttachmentMessageContent content, {
    required ChatConversationKind kind,
    required String clientId,
  }) {
    if (content is ImageMessageContent) {
      return _service.sendImage(
        conversationId,
        content.localPath ?? '',
        kind: kind,
        clientId: clientId,
      );
    }
    if (content is VoiceMessageContent) {
      return _service.sendVoice(
        conversationId,
        content.localPath ?? '',
        durationSeconds: content.durationSeconds,
        kind: kind,
        clientId: clientId,
      );
    }
    if (content is FileMessageContent) {
      return _service.sendFile(
        conversationId,
        content.localPath ?? '',
        fileName: content.fileName,
        fileSize: content.fileSizeBytes,
        kind: kind,
        clientId: clientId,
      );
    }
    throw UnsupportedError('Unsupported native attachment type.');
  }

  ChatMessageContent _withRemoteUrl(
    AttachmentMessageContent content,
    AttachmentUploadResult uploaded,
  ) {
    if (content is ImageMessageContent) {
      return ImageMessageContent(
        remotePath: uploaded.url,
        width: content.width,
        height: content.height,
      );
    }
    if (content is VoiceMessageContent) {
      return VoiceMessageContent(
        remotePath: uploaded.url,
        durationSeconds: content.durationSeconds,
      );
    }
    if (content is FileMessageContent) {
      return FileMessageContent(
        remotePath: uploaded.url,
        fileName: uploaded.fileName ?? content.fileName,
        fileSizeBytes: uploaded.fileSizeBytes ?? content.fileSizeBytes,
        mimeType: uploaded.mimeType ?? content.mimeType,
      );
    }
    if (content is VideoMessageContent) {
      return VideoMessageContent(
        remotePath: uploaded.url,
        durationSeconds: content.durationSeconds,
        width: content.width,
        height: content.height,
      );
    }
    return content;
  }

  @override
  Future<String?> downloadAttachment(ChatMessage message) async {
    final path = await _service.downloadAttachment(message.id);
    if (path != null && path.isNotEmpty) {
      await _cache.saveAttachmentPath(
        _service.currentUserId ?? '',
        message.id,
        localPath: path,
      );
    }
    return path;
  }

  @override
  Future<String?> downloadThumbnail(ChatMessage message) async {
    final path = await _service.downloadThumbnail(message.id);
    if (path != null && path.isNotEmpty) {
      await _cache.saveAttachmentPath(
        _service.currentUserId ?? '',
        message.id,
        thumbnailLocalPath: path,
      );
    }
    return path;
  }

  @override
  Future<void> markConversationRead(
    String conversationId, {
    ChatConversationKind kind = ChatConversationKind.direct,
  }) async {
    await _service.markConversationRead(conversationId, kind: kind);
    _connection.notifyConversationsChanged();
  }

  @override
  Future<void> flushOutbox(String userId) async {
    if (userId.isEmpty || _service.currentUserId != userId) return;
    final entries = await _outbox.load(userId);
    for (final entry in entries) {
      if (entry.senderId.isNotEmpty && entry.senderId != userId) continue;
      if (_inFlight.contains(entry.clientId)) continue;
      try {
        final sent = await _withSendLock(
          entry.clientId,
          () => _sendOutboxEntry(entry),
        );
        await _removeOutbox(userId, entry.clientId);
        _connection.notifyMessageUpdate(sent);
      } catch (_) {
        // Keep the entry queued for the next connectivity change.
      }
    }
  }

  Future<ChatMessage> _sendOutboxEntry(OutboxMessage entry) => _sendContent(
    entry.conversationId,
    entry.content,
    kind: entry.conversationKind,
    clientId: entry.clientId,
  );

  Future<T> _withSendLock<T>(
    String clientId,
    Future<T> Function() action,
  ) async {
    if (!_inFlight.add(clientId)) {
      throw StateError('该消息正在发送，请稍候');
    }
    try {
      return await action();
    } finally {
      _inFlight.remove(clientId);
    }
  }

  Future<void> _saveOutbox(String userId, OutboxMessage message) async {
    if (userId.isEmpty) return;
    try {
      await _outbox.save(userId, message);
    } catch (_) {
      // A storage failure must not prevent the send attempt.
    }
  }

  Future<void> _removeOutbox(String userId, String clientId) async {
    if (userId.isEmpty) return;
    try {
      await _outbox.remove(userId, clientId);
    } catch (_) {
      // Best-effort removal; a later successful replay can clean it up.
    }
  }
}
