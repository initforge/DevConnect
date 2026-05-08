import 'package:sqflite/sqflite.dart';

/// Database migration definitions
/// Use these migrations when schema changes between versions

abstract class Migration {
  final int fromVersion;
  final int toVersion;
  
  const Migration(this.fromVersion, this.toVersion);
  
  Future<void> up(Database db) async {}
  Future<void> down(Database db) async {}
}

/// Version 1 -> 2: Add user preferences table
class MigrationV1ToV2 extends Migration {
  const MigrationV1ToV2() : super(1, 2);

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS user_preferences');
  }
}

/// Version 2 -> 3: Add search history table
class MigrationV2ToV3 extends Migration {
  const MigrationV2ToV3() : super(2, 3);

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_search_history_query 
      ON search_history(query)
    ''');
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS search_history');
  }
}

/// Version 3 -> 4: Add read receipts for messages
class MigrationV3ToV4 extends Migration {
  const MigrationV3ToV4() : super(3, 4);

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS message_read_receipts (
        id TEXT PRIMARY KEY,
        message_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        read_at TEXT NOT NULL,
        FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_read_receipts_message 
      ON message_read_receipts(message_id)
    ''');
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS message_read_receipts');
  }
}

/// Registry of all migrations
const List<Migration> migrations = [
  MigrationV1ToV2(),
  MigrationV2ToV3(),
  MigrationV3ToV4(),
];

/// Get migration by version
Migration? getMigration(int fromVersion) {
  return migrations.cast<Migration?>().firstWhere(
    (m) => m?.fromVersion == fromVersion,
    orElse: () => null,
  );
}
