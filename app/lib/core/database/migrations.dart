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

/// Version 4 -> 5: Add parent_id for threaded comments
class MigrationV4ToV5 extends Migration {
  const MigrationV4ToV5() : super(4, 5);

  @override
  Future<void> up(Database db) async {
    await db.execute('ALTER TABLE comments ADD COLUMN parent_id TEXT');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_comments_parent_id
      ON comments(parent_id)
    ''');
  }
}

/// Version 5 -> 6: Persist mentorship sessions and journals locally
class MigrationV5ToV6 extends Migration {
  const MigrationV5ToV6() : super(5, 6);

  @override
  Future<void> up(Database db) async {
    // Create mentorship_requests if it doesn't exist yet (fresh installs may
    // never have had this table). The schema already includes the four
    // username/display_name columns we would otherwise add via ALTER.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mentorship_requests (
        id TEXT PRIMARY KEY,
        mentee_id TEXT NOT NULL,
        mentor_id TEXT NOT NULL,
        mentee_username TEXT,
        mentee_display_name TEXT,
        mentor_username TEXT,
        mentor_display_name TEXT,
        topic TEXT,
        message TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (mentee_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (mentor_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Add the columns for installs that already had `mentorship_requests`
    // before this migration. Each ALTER is wrapped so a duplicate-column
    // error (when the table was just created above) does not abort the
    // migration.
    await _addColumnIfMissing(
      db,
      'mentorship_requests',
      'mentee_username',
      'TEXT',
    );
    await _addColumnIfMissing(
      db,
      'mentorship_requests',
      'mentee_display_name',
      'TEXT',
    );
    await _addColumnIfMissing(
      db,
      'mentorship_requests',
      'mentor_username',
      'TEXT',
    );
    await _addColumnIfMissing(
      db,
      'mentorship_requests',
      'mentor_display_name',
      'TEXT',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS mentorship_sessions (
        id TEXT PRIMARY KEY,
        request_id TEXT NOT NULL,
        scheduled_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'scheduled',
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (request_id) REFERENCES mentorship_requests(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_mentorship_sessions_request ON mentorship_sessions(request_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_mentorship_sessions_scheduled ON mentorship_sessions(scheduled_at)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS mentorship_journals (
        id TEXT PRIMARY KEY,
        request_id TEXT,
        author_id TEXT NOT NULL,
        text TEXT NOT NULL,
        mentor_feedback TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (request_id) REFERENCES mentorship_requests(id) ON DELETE SET NULL,
        FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_mentorship_journals_request ON mentorship_journals(request_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_mentorship_journals_author ON mentorship_journals(author_id)',
    );
  }
}

/// Adds [column] to [table] only if it is not already present. SQLite does
/// not support `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`, so we inspect the
/// schema via PRAGMA before executing the ALTER.
Future<void> _addColumnIfMissing(
  Database db,
  String table,
  String column,
  String type,
) async {
  final columns = await db.rawQuery('PRAGMA table_info($table)');
  final exists = columns.any((row) => row['name'] == column);
  if (!exists) {
    await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
  }
}

/// Version 6 -> 7: Add notification grouping count for local fallback
class MigrationV6ToV7 extends Migration {
  const MigrationV6ToV7() : super(6, 7);

  @override
  Future<void> up(Database db) async {
    await db.execute(
      'ALTER TABLE notifications ADD COLUMN merged_count INTEGER NOT NULL DEFAULT 1',
    );
  }
}

/// Registry of all migrations
const List<Migration> migrations = [
  MigrationV1ToV2(),
  MigrationV2ToV3(),
  MigrationV3ToV4(),
  MigrationV4ToV5(),
  MigrationV5ToV6(),
  MigrationV6ToV7(),
];

/// Get migration by version
Migration? getMigration(int fromVersion) {
  return migrations.cast<Migration?>().firstWhere(
    (m) => m?.fromVersion == fromVersion,
    orElse: () => null,
  );
}
