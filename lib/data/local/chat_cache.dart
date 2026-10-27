import 'dart:convert';

import '../../domain/models/chat_conversation.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/services/local_store.dart';

/// Best-effort offline cache for the conversation list and the newest messages.
///
/// Keys are scoped by account so switching users can never show another
/// account's cached chats. Cache failures never break the chat path.
class ChatCache {
  ChatCache(this._store);

  final LocalStore _store;
  static const _maxCachedMessages = 60;
  static const _maxAttachmentPaths = 200;

  String _conversationsKey(String userId) => 'cache.conversations.v1.$userId';

  String _messagesKey(String userId, String conversationId) =>
      'cache.messages.v1.$userId.$conversationId';

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
      final raw = await _store.read(_messagesKey(userId, conversationId));
      if (raw == null) {
        return const ChatMessagePage(items: [], cursor: null, hasMore: false);
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const ChatMessagePage(items: [], cursor: null, hasMore: false);
      }
      final items = decoded
          .whereType<Map>()
          .map(
            (item) => ChatMessage.fromJson(
              item.map((key, value) => MapEntry('$key', value)),
            ),
          )
          .where((message) => message.id.isNotEmpty)
          .toList(growable: false);
      return ChatMessagePage(items: items, cursor: null, hasMore: false);
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
      final start = messages.length > _maxCachedMessages
          ? messages.length - _maxCachedMessages
          : 0;
      final tail = messages.sublist(start);
      await _store.write(
        _messagesKey(userId, conversationId),
        jsonEncode(
          tail.map((message) {
            final json = message.toJson();
            // Download secrets are short-lived credentials; keep them out of
            // plaintext local storage.
            json.remove('secret');
            return json;
          }).toList(),
        ),
      );
    } catch (_) {
      // A cache write must never fail sending/loading.
    }
  }

  Future<void> clearMessages(String userId, String conversationId) async {
    if (userId.isEmpty) return;
    try {
      await _store.remove(_messagesKey(userId, conversationId));
    } catch (_) {
      // Ignore cache cleanup failures.
    }
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
