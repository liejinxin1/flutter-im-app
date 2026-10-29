import 'dart:convert';

import '../../domain/models/chat_message.dart';
import '../../domain/services/local_store.dart';

/// Persistence seam for cached messages.
///
/// Implementations must keep data account-scoped and return messages in
/// ascending `sentAt` order.
abstract interface class ChatMessageStore {
  Future<List<ChatMessage>> load(
    String userId,
    String conversationId, {
    int limit = 60,
  });

  Future<void> save(
    String userId,
    String conversationId,
    List<ChatMessage> messages,
  );

  Future<void> remove(
    String userId,
    String conversationId,
    Set<String> messageIds,
  );

  Future<void> clear(String userId, String conversationId);
}

/// JSON fallback used on Web and in tests.
class KvChatMessageStore implements ChatMessageStore {
  KvChatMessageStore(this._store);

  static const defaultLoadLimit = 60;

  final LocalStore _store;

  String _key(String userId, String conversationId) =>
      'cache.messages.v1.$userId.$conversationId';

  @override
  Future<List<ChatMessage>> load(
    String userId,
    String conversationId, {
    int limit = defaultLoadLimit,
  }) async {
    if (userId.isEmpty) return const [];
    try {
      final raw = await _store.read(_key(userId, conversationId));
      if (raw == null) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final items = decoded
          .whereType<Map>()
          .map(
            (item) => ChatMessage.fromJson(
              item.map((key, value) => MapEntry('$key', value)),
            ),
          )
          .where((message) => message.id.isNotEmpty)
          .toList(growable: false);
      final start = items.length > limit ? items.length - limit : 0;
      return items.sublist(start);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> save(
    String userId,
    String conversationId,
    List<ChatMessage> messages,
  ) async {
    if (userId.isEmpty) return;
    await _store.write(
      _key(userId, conversationId),
      jsonEncode(messages.map(_encode).toList()),
    );
  }

  @override
  Future<void> remove(
    String userId,
    String conversationId,
    Set<String> messageIds,
  ) async {
    if (messageIds.isEmpty) return;
    final existing = await load(userId, conversationId, limit: 1 << 30);
    await save(
      userId,
      conversationId,
      existing
          .where((message) => !messageIds.contains(message.id))
          .toList(growable: false),
    );
  }

  @override
  Future<void> clear(String userId, String conversationId) async {
    if (userId.isEmpty) return;
    await _store.remove(_key(userId, conversationId));
  }

  Map<String, Object?> _encode(ChatMessage message) {
    final json = message.toJson();
    json.remove('secret');
    return json;
  }
}
