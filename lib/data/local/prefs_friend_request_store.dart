import 'dart:convert';

import '../../domain/models/friend_request_update.dart';
import '../../domain/repositories/friend_request_store.dart';
import '../../domain/services/local_store.dart';

/// Persists received friend requests per account.
///
/// The SDK only emits live invitation events, so without this store pending
/// requests disappear when the app restarts.
class PrefsFriendRequestStore implements FriendRequestStore {
  PrefsFriendRequestStore(this._store);

  final LocalStore _store;

  String _key(String userId) => 'friend-requests.v1.$userId';

  @override
  Future<List<FriendRequestUpdate>> load(String userId) async {
    if (userId.isEmpty) return const [];
    try {
      final raw = await _store.read(_key(userId));
      if (raw == null) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (item) => FriendRequestUpdate.fromJson(
              item.map((key, value) => MapEntry('$key', value)),
            ),
          )
          .where((request) => request.userId.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> save(String userId, List<FriendRequestUpdate> requests) async {
    if (userId.isEmpty) return;
    try {
      if (requests.isEmpty) {
        await _store.remove(_key(userId));
        return;
      }
      await _store.write(
        _key(userId),
        jsonEncode(requests.map((request) => request.toJson()).toList()),
      );
    } catch (_) {
      // Best-effort persistence; the live in-memory list still works.
    }
  }
}
