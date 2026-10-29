import 'dart:convert';

import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/services/local_store.dart';
import '../../domain/services/user_directory.dart';

/// Profile repository with a JSON cache.
///
/// Fetches only IDs that are missing from the cache, and falls back to a
/// userId-only profile when the SDK/server is unavailable.
class PrefsProfileRepository implements ProfileRepository {
  PrefsProfileRepository(this._directory, this._store);

  final UserDirectory _directory;
  final LocalStore _store;

  final Map<String, UserProfile> _cache = {};
  bool _cacheLoaded = false;
  String? _cacheAccountId;
  Future<void>? _loadingCache;
  Future<void>? _persisting;

  String _cacheKey(String accountId) => 'profiles.v2.$accountId';

  Future<void> _ensureCache() async {
    final accountId = _directory.currentUserId ?? '';
    if (_cacheLoaded && _cacheAccountId == accountId) return;
    _cache.clear();
    _cacheLoaded = false;
    _cacheAccountId = accountId;
    final pending = _loadingCache ??= () async {
      try {
        final raw = await _store.read(_cacheKey(accountId));
        if (raw != null) {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            for (final entry in decoded.entries) {
              final value = entry.value;
              if (value is Map) {
                final profile = UserProfile.fromJson(
                  value.map((key, item) => MapEntry('$key', item)),
                );
                if (profile.userId.isNotEmpty) {
                  _cache[profile.userId] = profile;
                }
              }
            }
          }
        }
      } catch (_) {
        // Corrupt or unavailable cache: start empty and refetch.
      } finally {
        _cacheLoaded = true;
        _loadingCache = null;
      }
    }();
    await pending;
  }

  Future<void> _persist() {
    return _persisting ??= () async {
      try {
        await _store.write(
          _cacheKey(_cacheAccountId ?? ''),
          jsonEncode(_cache.map((key, value) => MapEntry(key, value.toJson()))),
        );
      } catch (_) {
        // Profile cache is best-effort.
      } finally {
        _persisting = null;
      }
    }();
  }

  @override
  Future<UserProfile> load(String userId, {bool forceRefresh = false}) async {
    final profiles = await loadAll([userId], forceRefresh: forceRefresh);
    return profiles[userId] ?? UserProfile(userId: userId);
  }

  @override
  Future<Map<String, UserProfile>> loadAll(
    Iterable<String> userIds, {
    bool forceRefresh = false,
  }) async {
    final ids = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (ids.isEmpty) return const {};

    await _ensureCache();
    final missing = forceRefresh || ids.any((id) => !_cache.containsKey(id))
        ? ids.where((id) => forceRefresh || !_cache.containsKey(id)).toList()
        : const <String>[];

    if (missing.isNotEmpty) {
      try {
        final fetched = await _directory.loadUserProfiles(missing);
        if (fetched.isNotEmpty) {
          _cache.addAll(fetched);
          await _persist();
        }
      } catch (_) {
        // Offline or unsupported platform: return cache/userId fallbacks.
      }
    }

    return {for (final id in ids) id: _cache[id] ?? UserProfile(userId: id)};
  }

  @override
  Future<void> updateRemark(String userId, String remark) async {
    await _ensureCache();
    final current = _cache[userId] ?? UserProfile(userId: userId);
    _cache[userId] = current.copyWith(remark: remark);
    await _persist();
  }
}
