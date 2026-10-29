import 'dart:convert';

import '../../domain/models/chat_conversation.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/services/local_store.dart';
import 'chat_message_store.dart';

/// Best-effort offline cache for the conversation list and the newest messages.
///
/// Keys are scoped by account so switching users can never show another
/// account's cached chats. Cache failures never break the chat path.
class ChatCache {
  ChatCache(this._store, {ChatMessageStore? messageStore})
    : _messages = messageStore ?? KvChatMessageStore(_store);

  final LocalStore _store;
  final ChatMessageStore _messages;
  static const _maxCachedConversations = 80;
  static const _maxAttachmentPaths = 200;

  String _conversationsKey(String userId) => 'cache.conversations.v1.$userId';

  String _deletedKey(String userId, String conversationId) =>
      'cache.deleted.v1.$userId.$conversationId';

  String _legacyMessagesKey(String userId, String conversationId) =>
      'cache.messages.v1.$userId.$conversationId';

  String _recalledKey(String userId, String conversationId) =>
      'cache.recalled.v1.$userId.$conversationId';

  String _conversationIndexKey(String userId) =>
      'cache.message_index.v1.$userId';

  String _attachmentPathsKey(String userId) =>
      'cache.attachment_paths.v1.$userId';

  Future<List<ChatConversation>> loadConversations(String userId) async {
    if (userId.isEmpty) return const [];
    try {
      final raw = await _store.read(_conversationsKey(userId));
      if (raw == null) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (item) => ChatConversation.fromJson(
              item.map((key, value) => MapEntry('$key', value)),
            ),
          )
          .where((conversation) => conversation.id.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveConversations(
    String userId,
    List<ChatConversation> conversations,
  ) async {
    if (userId.isEmpty) return;
    try {
      await _store.write(
        _conversationsKey(userId),
        jsonEncode(conversations.map((item) => item.toJson()).toList()),
      );
    } catch (_) {
      // A cache write must never fail the user's refresh.
    }
  }

  Future<ChatMessagePage> loadMessages(
    String userId,
    String conversationId,
  ) async {
    if (userId.isEmpty) {
      return const ChatMessagePage(items: [], cursor: null, hasMore: false);
    }
    try {
      final items = await _messages.load(userId, conversationId);
      return ChatMessagePage(
        items: await _applyOverrides(userId, conversationId, items),
        cursor: null,
        hasMore: false,
      );
    } catch (_) {
      return const ChatMessagePage(items: [], cursor: null, hasMore: false);
    }
  }

  Future<void> saveMessages(
    String userId,
    String conversationId,
    List<ChatMessage> messages,
  ) async {
    if (userId.isEmpty) return;
    try {
      final visible = await _applyOverrides(userId, conversationId, messages);
      await _messages.save(userId, conversationId, visible);
      await _touchConversation(userId, conversationId);
    } catch (_) {
      // A cache write must never fail sending/loading.
    }
  }

  Future<void> _touchConversation(String userId, String conversationId) async {
    final index = await _loadConversationIndex(userId);
    index[conversationId] = DateTime.now().millisecondsSinceEpoch;
    if (index.length > _maxCachedConversations) {
      final entries = index.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      final stale = entries.take(index.length - _maxCachedConversations);
      for (final entry in stale) {
        await _messages.clear(userId, entry.key);
        await _store.remove(_legacyMessagesKey(userId, entry.key));
        await _store.remove(_deletedKey(userId, entry.key));
        await _store.remove(_recalledKey(userId, entry.key));
        index.remove(entry.key);
      }
    }
    await _store.write(_conversationIndexKey(userId), jsonEncode(index));
  }

  Future<Map<String, int>> _loadConversationIndex(String userId) async {
    try {
      final raw = await _store.read(_conversationIndexKey(userId));
      if (raw == null) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          '${entry.key}': (entry.value as num?)?.toInt() ?? 0,
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> clearMessages(String userId, String conversationId) async {
    if (userId.isEmpty) return;
    try {
      await _messages.clear(userId, conversationId);
      await _store.remove(_legacyMessagesKey(userId, conversationId));
    } catch (_) {
      // Ignore cache cleanup failures.
    }
  }

  Future<void> removeMessages(
    String userId,
    String conversationId,
    Set<String> messageIds,
  ) async {
    if (userId.isEmpty || messageIds.isEmpty) return;
    try {
      await _addIds(_deletedKey(userId, conversationId), messageIds);
      await _messages.remove(userId, conversationId, messageIds);
    } catch (_) {
      // Cache cleanup is best effort.
    }
  }

  /// Persists a recall so re-entering the chat cannot resurrect the old body.
  Future<void> markRecalled(
    String userId,
    String conversationId,
    String messageId,
  ) async {
    if (userId.isEmpty || messageId.isEmpty) return;
    try {
      await _addIds(_recalledKey(userId, conversationId), {messageId});
      final page = await loadMessages(userId, conversationId);
      await saveMessages(userId, conversationId, page.items);
    } catch (_) {
      // Recall persistence is best effort.
    }
  }

  /// Applies local delete tombstones and recall overrides to a server page.
  Future<List<ChatMessage>> applyOverrides(
    String userId,
    String conversationId,
    List<ChatMessage> messages,
  ) => _applyOverrides(userId, conversationId, messages);

  Future<List<ChatMessage>> _applyOverrides(
    String userId,
    String conversationId,
    List<ChatMessage> messages,
  ) async {
    if (messages.isEmpty) return messages;
    final deleted = await _loadIds(_deletedKey(userId, conversationId));
    final recalled = await _loadIds(_recalledKey(userId, conversationId));
    if (deleted.isEmpty && recalled.isEmpty) return messages;
    return messages
        .where((message) => !deleted.contains(message.id))
        .map((message) {
          if (!recalled.contains(message.id)) return message;
          if (message.content is SystemMessageContent) return message;
          return message.copyWith(
            content: const SystemMessageContent(text: '', systemType: 'recall'),
            deliveryState: ChatMessageDeliveryState.sent,
          );
        })
        .toList(growable: false);
  }

  Future<Set<String>> _loadIds(String key) async {
    try {
      final raw = await _store.read(key);
      if (raw == null) return <String>{};
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return decoded.whereType<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _addIds(String key, Set<String> ids) async {
    final existing = await _loadIds(key);
    existing.addAll(ids);
    final kept = existing.length > 500
        ? existing.toList().sublist(existing.length - 500).toSet()
        : existing;
    await _store.write(key, jsonEncode(kept.toList()));
  }

  /// Loads the device-local attachment paths remembered for [userId].
  ///
  /// Server history never carries downloaded file paths, so they are stored
  /// separately and merged back whenever a conversation page is reloaded.
  Future<Map<String, Map<String, String>>> loadAttachmentPaths(
    String userId,
  ) async {
    if (userId.isEmpty) return const {};
    try {
      final raw = await _store.read(_attachmentPathsKey(userId));
      if (raw == null) return const {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      final result = <String, Map<String, String>>{};
      decoded.forEach((key, value) {
        if (value is! Map) return;
        final paths = <String, String>{};
        final localPath = value['localPath'];
        final thumbnailLocalPath = value['thumbnailLocalPath'];
        if (localPath is String && localPath.isNotEmpty) {
          paths['localPath'] = localPath;
        }
        if (thumbnailLocalPath is String && thumbnailLocalPath.isNotEmpty) {
          paths['thumbnailLocalPath'] = thumbnailLocalPath;
        }
        if (paths.isNotEmpty) result['$key'] = paths;
      });
      return result;
    } catch (_) {
      return const {};
    }
  }

  /// Fills cached attachment paths into freshly loaded server messages.
  Future<List<ChatMessage>> mergeAttachmentPaths(
    String userId,
    List<ChatMessage> messages,
  ) async {
    if (messages.isEmpty) return messages;
    final paths = await loadAttachmentPaths(userId);
    if (paths.isEmpty) return messages;
    return messages
        .map((message) {
          final cached = paths[message.id];
          if (cached == null) return message;
          final localPath = _nonEmpty(message.localPath) ?? cached['localPath'];
          final thumbnailLocalPath =
              _nonEmpty(message.thumbnailLocalPath) ??
              cached['thumbnailLocalPath'];
          if (localPath == message.localPath &&
              thumbnailLocalPath == message.thumbnailLocalPath) {
            return message;
          }
          return message.copyWith(
            content: message.content.withAttachmentPaths(
              localPath: localPath,
              thumbnailLocalPath: thumbnailLocalPath,
            ),
          );
        })
        .toList(growable: false);
  }

  /// Remembers the downloaded path(s) of one attachment message.
  Future<void> saveAttachmentPath(
    String userId,
    String messageId, {
    String? localPath,
    String? thumbnailLocalPath,
  }) async {
    if (userId.isEmpty || messageId.isEmpty) return;
    final local = _nonEmpty(localPath);
    final thumbnail = _nonEmpty(thumbnailLocalPath);
    if (local == null && thumbnail == null) return;
    try {
      final paths = await loadAttachmentPaths(userId);
      final merged = <String, Map<String, String>>{...paths};
      final existing = merged[messageId] ?? const <String, String>{};
      final resolvedLocal = local ?? existing['localPath'];
      final resolvedThumbnail = thumbnail ?? existing['thumbnailLocalPath'];
      merged[messageId] = {
        'localPath': ?resolvedLocal,
        'thumbnailLocalPath': ?resolvedThumbnail,
      };
      final entries = merged.entries.toList(growable: false);
      final kept = entries.length > _maxAttachmentPaths
          ? entries.sublist(entries.length - _maxAttachmentPaths)
          : entries;
      await _store.write(
        _attachmentPathsKey(userId),
        jsonEncode({for (final entry in kept) entry.key: entry.value}),
      );
    } catch (_) {
      // Path persistence is best effort and must never break the chat path.
    }
  }

  String? _nonEmpty(String? value) =>
      value == null || value.isEmpty ? null : value;
}
