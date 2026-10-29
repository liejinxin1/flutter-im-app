import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../domain/models/chat_message.dart';
import '../../domain/services/local_store.dart';
import 'app_database.dart';
import 'chat_message_store.dart';

/// SQLite-backed message cache using the normalized `messages` table.
class SqliteChatMessageStore implements ChatMessageStore {
  SqliteChatMessageStore(this._database, {this.legacy});

  static const maxMessages = 60;

  final AppDatabase _database;
  final LocalStore? legacy;

  String _legacyKey(String userId, String conversationId) =>
      'cache.messages.v1.$userId.$conversationId';

  @override
  Future<List<ChatMessage>> load(
    String userId,
    String conversationId, {
    int limit = maxMessages,
  }) async {
    if (userId.isEmpty) return const [];
    final db = await _database.database;
    final rows = await db.query(
      'messages',
      columns: ['payload'],
      where: 'account_id = ? AND conversation_id = ?',
      whereArgs: [userId, conversationId],
      orderBy: 'sent_at DESC',
      limit: limit,
    );
    final items = <ChatMessage>[];
    for (final row in rows) {
      final message = _decode(row['payload'] as String?);
      if (message != null) items.add(message);
    }
    if (items.isNotEmpty) return items.reversed.toList(growable: false);

    final migrated = await _migrateLegacy(userId, conversationId);
    return migrated.length > limit
        ? migrated.sublist(migrated.length - limit)
        : migrated;
  }

  @override
  Future<void> save(
    String userId,
    String conversationId,
    List<ChatMessage> messages,
  ) async {
    if (userId.isEmpty) return;
    final db = await _database.database;
    await db.transaction((txn) async {
      for (final message in messages) {
        await txn.insert('messages', {
          'account_id': userId,
          'conversation_id': conversationId,
          'message_id': message.id,
          'payload': jsonEncode(_encode(message)),
          'sent_at': message.sentAt.millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final stale = await txn.query(
        'messages',
        columns: ['message_id'],
        where: 'account_id = ? AND conversation_id = ?',
        whereArgs: [userId, conversationId],
        orderBy: 'sent_at DESC',
        offset: maxMessages,
      );
      for (final row in stale) {
        await txn.delete(
          'messages',
          where: 'account_id = ? AND conversation_id = ? AND message_id = ?',
          whereArgs: [userId, conversationId, row['message_id']],
        );
      }
    });
  }

  @override
  Future<void> remove(
    String userId,
    String conversationId,
    Set<String> messageIds,
  ) async {
    if (userId.isEmpty || messageIds.isEmpty) return;
    final db = await _database.database;
    final placeholders = List.filled(messageIds.length, '?').join(',');
    await db.delete(
      'messages',
      where:
          'account_id = ? AND conversation_id = ? '
          'AND message_id IN ($placeholders)',
      whereArgs: [userId, conversationId, ...messageIds],
    );
  }

  @override
  Future<void> clear(String userId, String conversationId) async {
    if (userId.isEmpty) return;
    final db = await _database.database;
    await db.delete(
      'messages',
      where: 'account_id = ? AND conversation_id = ?',
      whereArgs: [userId, conversationId],
    );
  }

  Future<List<ChatMessage>> _migrateLegacy(
    String userId,
    String conversationId,
  ) async {
    final legacy = this.legacy;
    if (legacy == null) return const [];
    final key = _legacyKey(userId, conversationId);
    try {
      final raw = await legacy.read(key);
      if (raw == null) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final messages = decoded
          .whereType<Map>()
          .map(
            (item) => ChatMessage.fromJson(
              item.map((key, value) => MapEntry('$key', value)),
            ),
          )
          .where((message) => message.id.isNotEmpty)
          .toList(growable: false);
      if (messages.isNotEmpty) {
        await save(userId, conversationId, messages);
      }
      await legacy.remove(key);
      return messages;
    } catch (_) {
      return const [];
    }
  }

  ChatMessage? _decode(String? raw) {
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return ChatMessage.fromJson(
        decoded.map((key, value) => MapEntry('$key', value)),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, Object?> _encode(ChatMessage message) {
    final json = message.toJson();
    json.remove('secret');
    return json;
  }
}
