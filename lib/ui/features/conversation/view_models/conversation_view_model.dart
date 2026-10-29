import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../domain/models/chat_conversation.dart';
import '../../../../domain/models/chat_message.dart';
import '../../../../domain/repositories/chat_repository.dart';
import '../../../../domain/repositories/outbox_repository.dart';
import '../../../../domain/services/app_settings.dart';
import '../../../../domain/services/media_gateway.dart';
import '../../../core/localization/app_error.dart';
import '../../../core/view_model.dart';

/// Owns one conversation timeline: paging, optimistic sends, updates, retry.
///
/// The ViewModel never imports the Agora SDK. The only data dependency is the
/// [ChatRepository] contract.
class ConversationViewModel extends ViewModel {
  ConversationViewModel(
    this._repository,
    this._outbox, {
    required this.conversationId,
    required this.currentUserId,
    this.kind = ChatConversationKind.direct,
    this.media,
    this.settings,
  }) {
    _incomingSubscription = _repository.incomingMessages.listen(_onIncoming);
    _updatesSubscription = _repository.messageUpdates.listen(_onUpdate);
  }

  static const pageSize = 30;
  static const _thumbnailTimeout = Duration(seconds: 5);
  static const _attachmentTimeout = Duration(seconds: 30);
  final ChatRepository _repository;
  final OutboxRepository _outbox;

  /// Used to verify that cached attachment files still exist on this device.
  final MediaGateway? media;
  final AppSettings? settings;
  final String conversationId;
  final String currentUserId;
  final ChatConversationKind kind;
  late final StreamSubscription<ChatMessage> _incomingSubscription;
  late final StreamSubscription<ChatMessage> _updatesSubscription;
  final Set<String> _prefetching = {};
  int _localSequence = 0;

  List<ChatMessage> _messages = const [];
  List<ChatMessage> get messages => _messages;
  String? _cursor;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isLoadingOlder = false;
  bool get isLoadingOlder => _isLoadingOlder;
  AppError? _error;
  AppError? get error => _error;

  Future<void> loadInitial() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Show the account-scoped local snapshot immediately. The network page
      // is merged afterwards, so entering a known chat never flashes a blank
      // loading screen.
      final cached = await _repository.loadCachedMessages(
        conversationId,
        limit: pageSize,
      );
      if (isDisposed) return;
      if (cached.items.isNotEmpty) {
        _messages = _mergeLoadedPage(cached.items);
        _isLoading = false;
        notifyListeners();
      }

      final showNetwork =
          await settings?.showNetworkHistory(currentUserId) ?? true;
      if (isDisposed) return;
      if (!showNetwork) {
        _hasMore = false;
        _cursor = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final page = await _repository.loadMessages(
        conversationId,
        kind: kind,
        limit: pageSize,
      );
      if (isDisposed) return;
      _messages = _mergeLoadedPage(page.items);
      final pending = await _loadPendingOutbox();
      if (isDisposed) return;
      _messages = _mergePending(_messages, pending);
      _cursor = page.cursor;
      _hasMore = page.hasMore;
      _prefetchAttachments(_messages);
      try {
        await _repository.markConversationRead(conversationId, kind: kind);
      } catch (_) {
        // Reading a local snapshot must still work while offline.
      }
    } catch (error) {
      if (_messages.isEmpty) _error = AppError.from(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<ChatMessage>> _loadPendingOutbox() async {
    try {
      final entries = await _outbox.load(
        currentUserId,
        conversationId: conversationId,
      );
      return entries
          .map((entry) => entry.toPendingMessage())
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  List<ChatMessage> _mergePending(
    List<ChatMessage> base,
    List<ChatMessage> pending,
  ) {
    if (pending.isEmpty) return base;
    final ids = base.map((message) => message.id).toSet();
    final clientIds = base
        .map((message) => message.clientId)
        .whereType<String>()
        .toSet();
    final missing = pending.where(
      (message) =>
          !ids.contains(message.id) &&
          (message.clientId == null || !clientIds.contains(message.clientId)),
    );
    final merged = <ChatMessage>[...base, ...missing]
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return merged;
  }

  /// Keeps local/cached and optimistic messages that are not present in a
  /// freshly loaded network page.
  List<ChatMessage> _mergeLoadedPage(List<ChatMessage> loaded) {
    final loadedIds = loaded.map((message) => message.id).toSet();
    final loadedClientIds = loaded
        .map((message) => message.clientId)
        .whereType<String>()
        .toSet();
    final existing = _messages.where((message) {
      if (loadedIds.contains(message.id)) return false;
      final clientId = message.clientId;
      return clientId == null || !loadedClientIds.contains(clientId);
    });
    return [...loaded, ...existing]
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
  }

  Future<int> loadOlder() async {
    if (_isLoadingOlder || !_hasMore || _isLoading) return 0;
    _isLoadingOlder = true;
    notifyListeners();
    try {
      final page = await _repository.loadMessages(
        conversationId,
        kind: kind,
        cursor: _cursor,
        limit: pageSize,
      );
      if (isDisposed) return 0;
      final existingIds = _messages.map((message) => message.id).toSet();
      final existingClientIds = _messages
          .map((message) => message.clientId)
          .whereType<String>()
          .toSet();
      final older = page.items
          .where(
            (message) =>
                !existingIds.contains(message.id) &&
                (message.clientId == null ||
                    !existingClientIds.contains(message.clientId)),
          )
          .toList(growable: false);
      _messages = [...older, ..._messages];
      _cursor = page.cursor;
      _hasMore = page.hasMore && older.isNotEmpty;
      _prefetchAttachments(older);
      notifyListeners();
      return older.length;
    } catch (error) {
      _error = AppError.from(error);
      notifyListeners();
      return 0;
    } finally {
      _isLoadingOlder = false;
      notifyListeners();
    }
  }

  Future<void> send(String text, {ChatMessageQuote? quote}) async {
    final content = text.trim();
    if (content.isEmpty) return;

    final localId = _nextLocalId();
    final outgoing = ChatMessage(
      id: localId,
      conversationId: conversationId,
      senderId: currentUserId,
      content: TextMessageContent(content, quote: quote),
      sentAt: DateTime.now(),
      deliveryState: ChatMessageDeliveryState.sending,
      isOutgoing: true,
      clientId: localId,
    );
    _messages = [..._messages, outgoing];
    _error = null;
    notifyListeners();
    await _sendExisting(outgoing);
  }

  Future<void> retry(String messageId) async {
    final index = _messages.indexWhere((message) => message.id == messageId);
    if (index == -1) return;

    final message = _messages[index].copyWith(
      deliveryState: ChatMessageDeliveryState.sending,
    );
    _replaceAt(index, message);
    if (message.content is TextMessageContent) {
      await _sendExisting(message);
      return;
    }

    final localPath = message.localPath;
    if (localPath == null || localPath.isEmpty) {
      _error = const AppError(AppErrorCode.attachmentPathExpired);
      notifyListeners();
      return;
    }
    await _sendAttachment(message);
  }

  Future<bool> deleteMessages(Iterable<String> messageIds) async {
    final ids = messageIds.toSet();
    if (ids.isEmpty) return false;
    final deleted = _messages
        .where((message) => ids.contains(message.id))
        .toList(growable: false);
    if (deleted.isEmpty) return false;
    try {
      await _repository.deleteMessages(deleted, kind: kind);
      _messages = _messages
          .where((message) => !ids.contains(message.id))
          .toList(growable: false);
      notifyListeners();
      return true;
    } catch (error) {
      _error = AppError.from(error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> recallMessage(String messageId) async {
    final index = _messages.indexWhere((message) => message.id == messageId);
    if (index == -1) return false;
    final message = _messages[index];
    if (!message.isOutgoing ||
        (message.deliveryState != ChatMessageDeliveryState.sent &&
            message.deliveryState != ChatMessageDeliveryState.delivered &&
            message.deliveryState != ChatMessageDeliveryState.read)) {
      return false;
    }
    try {
      await _repository.recallMessage(message);
      _replaceAt(
        index,
        message.copyWith(
          content: const SystemMessageContent(text: '', systemType: 'recall'),
          deliveryState: ChatMessageDeliveryState.sent,
        ),
      );
      return true;
    } catch (error) {
      _error = AppError.from(error);
      notifyListeners();
      return false;
    }
  }

  Future<int> forwardMessages(
    Iterable<String> messageIds,
    String toConversationId, {
    ChatConversationKind kind = ChatConversationKind.direct,
  }) async {
    final ids = messageIds.toSet();
    if (ids.isEmpty) return 0;
    var forwarded = 0;
    try {
      for (final message in _messages.where((item) => ids.contains(item.id))) {
        var source = message;
        final content = message.content;
        if (content is AttachmentMessageContent &&
            (content.localPath == null || content.localPath!.isEmpty)) {
          final path = await _repository.downloadAttachment(message);
          if (path == null || path.isEmpty) {
            throw StateError('附件尚未下载，暂时无法转发。');
          }
          source = message.copyWith(
            content: content.withAttachmentPaths(localPath: path),
          );
        }
        await _repository.forwardMessage(source, toConversationId, kind: kind);
        forwarded++;
      }
    } catch (error) {
      _error = AppError.from(error);
      notifyListeners();
    }
    return forwarded;
  }

  Future<void> sendImage(String path) =>
      _sendMedia(content: ImageMessageContent(localPath: path));

  Future<void> sendVoice(String path, int durationSeconds) => _sendMedia(
    content: VoiceMessageContent(
      localPath: path,
      durationSeconds: durationSeconds,
    ),
  );

  Future<void> sendFile(
    String path, {
    String? fileName,
    int fileSizeBytes = 0,
    String? mimeType,
  }) => _sendMedia(
    content: FileMessageContent(
      localPath: path,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      mimeType: mimeType,
    ),
  );

  Future<void> _sendMedia({required ChatMessageContent content}) async {
    final localId = _nextLocalId();
    final pending = ChatMessage(
      id: localId,
      conversationId: conversationId,
      senderId: currentUserId,
      content: content,
      sentAt: DateTime.now(),
      deliveryState: ChatMessageDeliveryState.sending,
      isOutgoing: true,
      clientId: localId,
    );
    _messages = [..._messages, pending];
    _error = null;
    notifyListeners();
    await _sendAttachment(pending);
  }

  Future<void> _sendAttachment(ChatMessage pending) async {
    try {
      final clientId = pending.clientId ?? pending.id;
      final sent = switch (pending.content) {
        ImageMessageContent() => await _repository.sendImage(
          conversationId,
          pending.localPath!,
          kind: kind,
          clientId: clientId,
        ),
        VoiceMessageContent() => await _repository.sendVoice(
          conversationId,
          pending.localPath!,
          durationSeconds: pending.durationSeconds,
          kind: kind,
          clientId: clientId,
        ),
        FileMessageContent(
          :final fileName,
          :final fileSizeBytes,
          :final mimeType,
        ) =>
          await _repository.sendFile(
            conversationId,
            pending.localPath!,
            fileName: fileName,
            fileSizeBytes: fileSizeBytes,
            mimeType: mimeType,
            kind: kind,
            clientId: clientId,
          ),
        _ => throw UnsupportedError(
          'Sending ${pending.content.kind.name} messages is not supported yet.',
        ),
      };
      final index = _messages.indexWhere(
        (message) => message.id == pending.id || message.clientId == clientId,
      );
      if (index != -1) {
        _error = null;
        _replaceAt(
          index,
          sent.copyWith(
            clientId: clientId,
            content: sent.content.withAttachmentPaths(
              localPath: pending.localPath,
            ),
          ),
        );
      }
    } catch (error) {
      final index = _messages.indexWhere(
        (message) =>
            message.id == pending.id || message.clientId == pending.clientId,
      );
      if (index != -1) {
        _replaceAt(
          index,
          pending.copyWith(deliveryState: ChatMessageDeliveryState.failed),
        );
      }
      _error = AppError.from(error);
      notifyListeners();
    }
  }

  Future<void> _sendExisting(ChatMessage pending) async {
    try {
      final clientId = pending.clientId ?? pending.id;
      final sent = await _repository.sendText(
        conversationId,
        pending.text,
        quote: pending.content is TextMessageContent
            ? (pending.content as TextMessageContent).quote
            : null,
        kind: kind,
        clientId: clientId,
      );
      final index = _messages.indexWhere(
        (message) => message.id == pending.id || message.clientId == clientId,
      );
      if (index != -1) {
        _error = null;
        _replaceAt(index, sent.copyWith(clientId: clientId));
      }
    } catch (error) {
      final index = _messages.indexWhere(
        (message) =>
            message.id == pending.id || message.clientId == pending.clientId,
      );
      if (index != -1) {
        _replaceAt(
          index,
          pending.copyWith(deliveryState: ChatMessageDeliveryState.failed),
        );
      }
      _error = AppError.from(error);
      notifyListeners();
    }
  }

  /// Resolves a remote attachment and caches the local path on the message.
  ///
  /// Used by both the image bubble and the voice player.
  Future<String?> downloadAttachment(ChatMessage message) async {
    try {
      final path = await _repository.downloadAttachment(message);
      if (path == null || path.isEmpty) return null;
      final index = _messages.indexWhere((item) => item.id == message.id);
      if (index != -1) {
        _replaceAt(
          index,
          _messages[index].copyWith(
            content: _messages[index].content.withAttachmentPaths(
              localPath: path,
            ),
          ),
        );
      }
      return path;
    } catch (error) {
      _error = AppError.from(error);
      notifyListeners();
      return null;
    }
  }

  /// Returns a local path for the full-size preview, downloading the original
  /// image when only the thumbnail is cached.
  Future<String?> resolveImagePath(ChatMessage message) async {
    final localPath = message.localPath;
    if (localPath != null && localPath.isNotEmpty) return localPath;
    final content = message.content;
    final remotePath = content is ImageMessageContent
        ? content.remotePath
        : null;
    if (remotePath != null && remotePath.startsWith(RegExp(r'https?://'))) {
      return remotePath;
    }
    return downloadAttachment(message);
  }

  /// Pre-downloads attachments so images render and voice messages play
  /// without a manual trigger. Failures stay silent and keep the manual path.
  void _prefetchAttachments(Iterable<ChatMessage> messages) {
    for (final message in messages) {
      if (message.content is! ImageMessageContent &&
          message.content is! VoiceMessageContent) {
        continue;
      }
      if (!_prefetching.add(message.id)) continue;
      if (message.content is ImageMessageContent) {
        unawaited(_loadImage(message));
      } else {
        unawaited(_loadVoice(message));
      }
    }
  }

  /// A cached path only counts when the file still exists on this device;
  /// otherwise the message is treated as not downloaded and re-fetched.
  Future<bool> _hasRenderableImage(ChatMessage message) async =>
      await _fileExists(message.localPath) ||
      await _fileExists(message.thumbnailLocalPath);

  Future<bool> _fileExists(String? path) async {
    if (path == null || path.isEmpty) return false;
    final gateway = media;
    if (gateway == null) return true;
    try {
      return await gateway.fileExists(path);
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadImage(ChatMessage message) async {
    try {
      if (await _hasRenderableImage(message)) return;
      if (isDisposed) return;
      String? thumbnailPath;
      try {
        thumbnailPath = await _repository
            .downloadThumbnail(message)
            .timeout(_thumbnailTimeout);
      } catch (error) {
        debugPrint('thumbnail download failed for ${message.id}: $error');
      }
      if (isDisposed) return;
      if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
        _applyLocalPath(message.id, thumbnailLocalPath: thumbnailPath);
        return;
      }
      // No usable thumbnail: download the original so the bubble still
      // renders without a manual tap.
      final localPath = await _downloadAttachment(message);
      if (isDisposed || localPath == null || localPath.isEmpty) return;
      _applyLocalPath(message.id, localPath: localPath);
    } finally {
      _prefetching.remove(message.id);
    }
  }

  Future<void> _loadVoice(ChatMessage message) async {
    try {
      if (await _fileExists(message.localPath)) return;
      if (isDisposed) return;
      final localPath = await _downloadAttachment(message);
      if (isDisposed || localPath == null || localPath.isEmpty) return;
      _applyLocalPath(message.id, localPath: localPath);
    } finally {
      _prefetching.remove(message.id);
    }
  }

  Future<String?> _downloadAttachment(ChatMessage message) async {
    try {
      return await _repository
          .downloadAttachment(message)
          .timeout(_attachmentTimeout);
    } catch (error) {
      debugPrint('attachment download failed for ${message.id}: $error');
      return null;
    }
  }

  void _applyLocalPath(
    String messageId, {
    String? localPath,
    String? thumbnailLocalPath,
  }) {
    final index = _messages.indexWhere((item) => item.id == messageId);
    if (index == -1) return;
    final current = _messages[index];
    _replaceAt(
      index,
      current.copyWith(
        content: current.content.withAttachmentPaths(
          localPath: localPath,
          thumbnailLocalPath: thumbnailLocalPath,
        ),
      ),
    );
  }

  void _onIncoming(ChatMessage message) {
    if (message.conversationId != conversationId) return;

    final clientId = message.clientId;
    final index = _messages.indexWhere(
      (item) =>
          item.id == message.id ||
          (clientId != null &&
              clientId.isNotEmpty &&
              item.clientId == clientId),
    );

    if (index == -1) {
      _messages = [..._messages, message];
      _prefetchAttachments([message]);
      notifyListeners();
    } else {
      final current = _messages[index];
      // The SDK echo of our own optimistic message should replace the local
      // copy instead of appending a duplicate bubble.
      if (current.deliveryState == ChatMessageDeliveryState.sending ||
          current.deliveryState == ChatMessageDeliveryState.created ||
          current.deliveryState == ChatMessageDeliveryState.failed) {
        _replaceAt(index, message);
      }
    }

    unawaited(_repository.markConversationRead(conversationId, kind: kind));
  }

  void _onUpdate(ChatMessage update) {
    if (update.conversationId != conversationId) return;
    final index = _messages.indexWhere(
      (message) =>
          message.id == update.id ||
          (update.clientId != null && message.clientId == update.clientId),
    );
    if (index == -1) return;

    final current = _messages[index];
    _replaceAt(
      index,
      update.copyWith(
        clientId: update.clientId ?? current.clientId,
        content: mergeChatMessageContent(current.content, update.content),
      ),
    );
  }

  void _replaceAt(int index, ChatMessage message) {
    if (index < 0 || index >= _messages.length) return;
    final updated = [..._messages];
    updated[index] = message;
    _messages = updated;
    notifyListeners();
  }

  String _nextLocalId() =>
      'local-${DateTime.now().microsecondsSinceEpoch}-${_localSequence++}';

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _incomingSubscription.cancel();
    _updatesSubscription.cancel();
    super.dispose();
  }
}
