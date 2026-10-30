import 'package:sqflite/sqflite.dart';

import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/services/user_directory.dart';
import 'app_database.dart';

/// Account-scoped profile cache backed by the `profiles` table.
class SqliteProfileRepository implements ProfileRepository {
  SqliteProfileRepository(this._directory, this._database);

  final UserDirectory _directory;
  final AppDatabase _database;

  String get _accountId => _directory.currentUserId ?? '';

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
    final account = _accountId;
    if (account.isEmpty) {
      return {for (final id in ids) id: UserProfile(userId: id)};
    }

    final db = await _database.database;
    final cached = await _loadRows(db, account, ids);
    final missing = forceRefresh
        ? ids.toList()
        : ids.where((id) => !cached.containsKey(id)).toList();
    if (missing.isEmpty) {
      return _withFallbacks(ids, cached);
    }

    try {
      final fetched = await _directory.loadUserProfiles(missing);
      if (fetched.isNotEmpty) {
        await _upsertAll(db, account, fetched.values);
        cached.addAll(fetched);
      }
    } catch (_) {
      // Offline: keep the local row or a userId-only fallback.
    }
    return _withFallbacks(ids, cached);
  }

  @override
  Future<void> updateRemark(String userId, String remark) async {
    final account = _accountId;
    if (account.isEmpty || userId.isEmpty) return;
    final db = await _database.database;
    final current = await _loadRows(db, account, {userId});
    final profile =
        current[userId]?.copyWith(remark: remark) ??
        UserProfile(userId: userId, remark: remark);
    await _upsertAll(db, account, [profile]);
  }

  @override
  Future<void> updateOwnProfile(UserProfile profile) async {
    final account = _accountId;
    if (account.isEmpty || profile.userId.isEmpty) return;
    await _directory.updateUserProfile(profile);
    final db = await _database.database;
    final current = await _loadRows(db, account, {profile.userId});
    await _upsertAll(db, account, [
      current[profile.userId]?.copyWith(
            nickname: profile.nickname,
            avatarUrl: profile.avatarUrl,
            phone: profile.phone,
            email: profile.email,
            birthday: profile.birthday,
            gender: profile.gender,
          ) ??
          profile,
    ]);
  }

  Future<Map<String, UserProfile>> _loadRows(
    Database db,
    String account,
    Set<String> ids,
  ) async {
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.query(
      'profiles',
      where: 'account_id = ? AND user_id IN ($placeholders)',
      whereArgs: [account, ...ids],
    );
    return {
      for (final row in rows)
        row['user_id'] as String: UserProfile(
          userId: row['user_id'] as String,
          nickname: row['nickname'] as String?,
          avatarUrl: row['avatar_url'] as String?,
          remark: row['remark'] as String?,
          phone: row['phone'] as String?,
          email: row['email'] as String?,
          birthday: row['birthday'] as String?,
          gender: (row['gender'] as num?)?.toInt() ?? 0,
        ),
    };
  }

  Future<void> _upsertAll(
    Database db,
    String account,
    Iterable<UserProfile> profiles,
  ) async {
    final updatedAt = DateTime.now().millisecondsSinceEpoch;
    for (final profile in profiles) {
      if (profile.userId.isEmpty) continue;
      await db.insert('profiles', {
        'account_id': account,
        'user_id': profile.userId,
        'nickname': profile.nickname,
        'avatar_url': profile.avatarUrl,
        'remark': profile.remark,
        'phone': profile.phone,
        'email': profile.email,
        'birthday': profile.birthday,
        'gender': profile.gender,
        'updated_at': updatedAt,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Map<String, UserProfile> _withFallbacks(
    Set<String> ids,
    Map<String, UserProfile> cached,
  ) => {for (final id in ids) id: cached[id] ?? UserProfile(userId: id)};
}
