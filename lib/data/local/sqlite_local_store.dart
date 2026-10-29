import 'package:sqflite/sqflite.dart';

import '../../domain/services/local_store.dart';
import 'app_database.dart';
import 'shared_preferences_local_store.dart';

/// SQLite-backed [LocalStore].
///
/// Existing repositories already namespace keys by account and domain, so this
/// is a drop-in persistence backend while the normalized tables are introduced
/// incrementally. Old SharedPreferences values are read once and promoted into
/// SQLite, so installing this version does not discard an existing cache.
class SqliteLocalStore implements LocalStore {
  SqliteLocalStore(this._database);

  final AppDatabase _database;
  final SharedPreferencesLocalStore _legacy = SharedPreferencesLocalStore();

  @override
  Future<String?> read(String key) async {
    final db = await _database.database;
    final rows = await db.query(
      'kv',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isNotEmpty) return rows.first['value'] as String?;

    final legacy = await _legacy.read(key);
    if (legacy != null) await write(key, legacy);
    return legacy;
  }

  @override
  Future<void> write(String key, String value) async {
    final db = await _database.database;
    await db.insert('kv', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await _legacy.remove(key);
  }

  @override
  Future<void> remove(String key) async {
    final db = await _database.database;
    await db.delete('kv', where: 'key = ?', whereArgs: [key]);
    await _legacy.remove(key);
  }
}
