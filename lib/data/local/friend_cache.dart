import 'package:sqflite/sqflite.dart';

import '../../domain/models/user_profile.dart';
import 'app_database.dart';

/// SQLite cache for contact relationships and remarks.
class FriendCache {
  FriendCache(this._database);

  final AppDatabase _database;

  Future<List<UserProfile>> load(String accountId) async {
    if (accountId.isEmpty) return const [];
    final db = await _database.database;
    final rows = await db.rawQuery(
      '''
      SELECT f.user_id, f.remark, p.nickname, p.avatar_url
      FROM friendships f
      LEFT JOIN profiles p
        ON p.account_id = f.account_id AND p.user_id = f.user_id
      WHERE f.account_id = ?
      ORDER BY f.updated_at DESC
      ''',
      [accountId],
    );
    return [
      for (final row in rows)
        UserProfile(
          userId: row['user_id'] as String,
          nickname: row['nickname'] as String?,
          avatarUrl: row['avatar_url'] as String?,
          remark: row['remark'] as String?,
        ),
    ];
  }

  Future<void> saveAll(String accountId, Iterable<UserProfile> contacts) async {
    if (accountId.isEmpty) return;
    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final contact in contacts) {
      if (contact.userId.isEmpty) continue;
      await db.insert('friendships', {
        'account_id': accountId,
        'user_id': contact.userId,
        'remark': contact.remark,
        'status': 'accepted',
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert('profiles', {
        'account_id': accountId,
        'user_id': contact.userId,
        'nickname': contact.nickname,
        'avatar_url': contact.avatarUrl,
        'remark': contact.remark,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> updateRemark(
    String accountId,
    String userId,
    String remark,
  ) async {
    if (accountId.isEmpty || userId.isEmpty) return;
    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = await db.update(
      'friendships',
      {'remark': remark, 'updated_at': now},
      where: 'account_id = ? AND user_id = ?',
      whereArgs: [accountId, userId],
    );
    if (updated == 0) {
      await db.insert('friendships', {
        'account_id': accountId,
        'user_id': userId,
        'remark': remark,
        'status': 'accepted',
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await db.update(
      'profiles',
      {'remark': remark, 'updated_at': now},
      where: 'account_id = ? AND user_id = ?',
      whereArgs: [accountId, userId],
    );
  }
}
