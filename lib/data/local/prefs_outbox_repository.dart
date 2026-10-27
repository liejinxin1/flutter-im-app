import 'dart:async';
import 'dart:convert';

import '../../domain/models/outbox_message.dart';
import '../../domain/repositories/outbox_repository.dart';
import '../../domain/services/local_store.dart';

/// JSON-in-SharedPreferences outbox, serialized per instance so concurrent
/// sends cannot lose each other's entries.
class PrefsOutboxRepository implements OutboxRepository {
  PrefsOutboxRepository(this._store);

  final LocalStore _store;
  Future<void> _tail = Future<void>.value();
  static const _maxEntries = 100;

  String _key(String userId) => 'outbox.v1.$userId';

  Future<T> _guarded<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    final previous = _tail;
    _tail = completer.future.then<void>((_) {}, onError: (_) {});
    unawaited(
      previous.then((_) async {
        try {
          completer.complete(await action());
        } catch (error, stackTrace) {
          completer.completeError(error, stackTrace);
        }
      }),
    );
    return completer.future;
  }

  Future<List<OutboxMessage>> _read(String userId) async {
    if (userId.isEmpty) return const [];
    try {
      final raw = await _store.read(_key(userId));
      if (raw == null) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (item) => OutboxMessage.fromJson(
              item.map((key, value) => MapEntry('$key', value)),
            ),
          )
          .where((entry) => entry.clientId.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _write(String userId, List<OutboxMessage> entries) async {
    if (userId.isEmpty) return;
    try {
      if (entries.isEmpty) {
        await _store.remove(_key(userId));
        return;
      }
      final capped = entries.length > _maxEntries
          ? entries.sublist(entries.length - _maxEntries)
          : entries;
      await _store.write(
        _key(userId),
        jsonEncode(capped.map((entry) => entry.toJson()).toList()),
      );
    } catch (_) {
      // Local persistence is best-effort; the in-memory message still shows.
    }
  }

  @override
  Future<List<OutboxMessage>> load(String userId, {String? conversationId}) =>
      _guarded(() async {
        final entries = await _read(userId);
        if (conversationId == null) return entries;
        return entries
            .where((entry) => entry.conversationId == conversationId)
            .toList(growable: false);
      });

  @override
  Future<void> save(String userId, OutboxMessage message) => _guarded(() async {
    final entries = await _read(userId);
    final withoutDuplicate =
        entries
            .where((entry) => entry.clientId != message.clientId)
            .toList(growable: true)
          ..add(message);
    await _write(userId, withoutDuplicate);
  });

  @override
  Future<void> remove(String userId, String clientId) => _guarded(() async {
    final entries = await _read(userId);
    final remaining = entries
        .where((entry) => entry.clientId != clientId)
        .toList(growable: false);
    if (remaining.length == entries.length) return;
    await _write(userId, remaining);
  });
}
