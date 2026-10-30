import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

/// On-device SQLite database for account-scoped IM data.
///
/// The first schema version keeps serialized payloads for message content while
/// providing stable relational keys for conversations, messages, profiles,
/// friendships, and request history. Repositories are the only callers; the UI
/// never sees SQLite.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;
  Future<Database>? _opening;

  Future<Database> get database =>
      _database != null ? Future.value(_database) : _opening ??= _open();

  Future<Database> _open() async {
    final directory = await getDatabasesPath();
    final database = await openDatabase(
      path.join(directory, 'agora_im.sqlite'),
      version: 2,
      onCreate: _create,
      onUpgrade: _upgrade,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
    _database = database;
    _opening = null;
    return database;
  }

  Future<void> close() async {
    final database = _database;
    _database = null;
    _opening = null;
    await database?.close();
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE kv (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE profiles (
        account_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        nickname TEXT,
        avatar_url TEXT,
        remark TEXT,
        phone TEXT,
        email TEXT,
        birthday TEXT,
        gender INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (account_id, user_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE friendships (
        account_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        remark TEXT,
        status TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (account_id, user_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE friend_requests (
        account_id TEXT NOT NULL,
        target_key TEXT NOT NULL,
        payload TEXT NOT NULL,
        occurred_at INTEGER,
        PRIMARY KEY (account_id, target_key)
      )
    ''');
    await db.execute('''
      CREATE TABLE conversations (
        account_id TEXT NOT NULL,
        conversation_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        last_activity INTEGER,
        PRIMARY KEY (account_id, conversation_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE messages (
        account_id TEXT NOT NULL,
        conversation_id TEXT NOT NULL,
        message_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        sent_at INTEGER NOT NULL,
        PRIMARY KEY (account_id, conversation_id, message_id)
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_messages_conversation
      ON messages(account_id, conversation_id, sent_at)
    ''');
  }

  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE profiles ADD COLUMN phone TEXT');
      await db.execute('ALTER TABLE profiles ADD COLUMN email TEXT');
      await db.execute('ALTER TABLE profiles ADD COLUMN birthday TEXT');
      await db.execute(
        'ALTER TABLE profiles ADD COLUMN gender INTEGER NOT NULL DEFAULT 0',
      );
    }
  }
}
