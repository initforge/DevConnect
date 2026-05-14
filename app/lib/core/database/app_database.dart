import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/seed_data.dart';
import 'migrations.dart';

/// Database seeding option - controls whether to seed on first open
enum DatabaseSeedMode {
  none, // Never seed - production
  minimal, // Only essential tables (users)
  full, // All seed data
}

/// AppDatabase - SQLite local-first database for DevConnect
///
/// Schema aligned with PostgreSQL backend for seamless sync.
/// Indexes added for scaling to 1000+ concurrent users.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;
  DatabaseSeedMode _seedMode = DatabaseSeedMode.full;

  /// Configure seed mode before first database access
  void configure({DatabaseSeedMode seedMode = DatabaseSeedMode.full}) {
    _seedMode = seedMode;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'devconnect_midterm.db');

    final db = await openDatabase(
      path,
      version: migrations.isEmpty ? 1 : migrations.last.toVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    // Seed if needed based on mode
    if (_seedMode != DatabaseSeedMode.none) {
      await _seedIfNeeded(db);
    }

    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createAllTables(db);
    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Run migrations sequentially
    for (int v = oldVersion; v < newVersion; v++) {
      final migration = getMigration(v);
      if (migration != null) {
        await migration.up(db);
      }
    }
  }

  Future<void> _createAllTables(Database db) async {
    // Users table - aligned with PostgreSQL
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        display_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        avatar_url TEXT,
        bio TEXT,
        skills TEXT NOT NULL DEFAULT '',
        follower_count INTEGER NOT NULL DEFAULT 0,
        following_count INTEGER NOT NULL DEFAULT 0,
        post_count INTEGER NOT NULL DEFAULT 0,
        reputation INTEGER NOT NULL DEFAULT 0,
        is_online INTEGER NOT NULL DEFAULT 0,
        is_mentor INTEGER NOT NULL DEFAULT 0,
        is_followed_by_me INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Posts table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS posts (
        id TEXT PRIMARY KEY,
        author_id TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'article',
        tags TEXT NOT NULL DEFAULT '',
        image_url TEXT,
        view_count INTEGER NOT NULL DEFAULT 0,
        like_count INTEGER NOT NULL DEFAULT 0,
        comment_count INTEGER NOT NULL DEFAULT 0,
        bookmark_count INTEGER NOT NULL DEFAULT 0,
        is_liked_by_me INTEGER NOT NULL DEFAULT 0,
        is_bookmarked_by_me INTEGER NOT NULL DEFAULT 0,
        is_pending_sync INTEGER NOT NULL DEFAULT 0,
        sync_dirty INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (author_id) REFERENCES users(id)
      )
    ''');

    // Comments table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS comments (
        id TEXT PRIMARY KEY,
        post_id TEXT NOT NULL,
        parent_id TEXT,
        author_id TEXT NOT NULL,
        content TEXT NOT NULL,
        depth INTEGER NOT NULL DEFAULT 0,
        upvotes INTEGER NOT NULL DEFAULT 0,
        reply_count INTEGER NOT NULL DEFAULT 0,
        is_best INTEGER NOT NULL DEFAULT 0,
        is_pending_sync INTEGER NOT NULL DEFAULT 0,
        sync_dirty INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
        FOREIGN KEY (parent_id) REFERENCES comments(id) ON DELETE CASCADE,
        FOREIGN KEY (author_id) REFERENCES users(id)
      )
    ''');

    // Notifications table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        from_user_id TEXT,
        is_read INTEGER NOT NULL DEFAULT 0,
        merged_count INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // Projects table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS projects (
        id TEXT PRIMARY KEY,
        owner_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        tech_stack TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'LOOKING_FOR_MEMBERS',
        member_count INTEGER NOT NULL DEFAULT 1,
        max_members INTEGER NOT NULL DEFAULT 5,
        created_at TEXT NOT NULL,
        FOREIGN KEY (owner_id) REFERENCES users(id)
      )
    ''');

    // Jobs table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS jobs (
        id TEXT PRIMARY KEY,
        company TEXT NOT NULL,
        title TEXT NOT NULL,
        location TEXT NOT NULL,
        remote INTEGER NOT NULL DEFAULT 0,
        salary_range TEXT NOT NULL,
        tech_stack TEXT NOT NULL DEFAULT '',
        experience TEXT NOT NULL,
        match_percent INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Conversations table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS conversations (
        id TEXT PRIMARY KEY,
        other_user_id TEXT NOT NULL,
        last_message TEXT NOT NULL DEFAULT '',
        unread_count INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (other_user_id) REFERENCES users(id)
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'text',
        code_language TEXT,
        code_source TEXT,
        reactions TEXT NOT NULL DEFAULT '',
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
        FOREIGN KEY (sender_id) REFERENCES users(id)
      )
    ''');

    // User follows junction table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_follows (
        id TEXT PRIMARY KEY,
        follower_id TEXT NOT NULL,
        following_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(follower_id, following_id),
        FOREIGN KEY (follower_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (following_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Post likes junction table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS post_likes (
        id TEXT PRIMARY KEY,
        post_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(post_id, user_id),
        FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Post bookmarks junction table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS post_bookmarks (
        id TEXT PRIMARY KEY,
        post_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(post_id, user_id),
        FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Mentorship requests
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

    // Mentorship sessions (scheduled video / async sessions for a request)
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

    // Mentorship journals (mentee notes + optional mentor feedback)
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
  }

  Future<void> _createIndexes(Database db) async {
    // Users indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_users_reputation ON users(reputation DESC)',
    );

    // Posts indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_posts_author_id ON posts(author_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_posts_type ON posts(type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_posts_like_count ON posts(like_count DESC)',
    );

    // Comments indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_comments_post_id ON comments(post_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_comments_parent_id ON comments(parent_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_comments_author_id ON comments(author_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_comments_created_at ON comments(created_at ASC)',
    );

    // Notifications indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notifications_from_user_id ON notifications(from_user_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC)',
    );

    // Messages indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at ASC)',
    );

    // Conversations indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_conversations_updated_at ON conversations(updated_at DESC)',
    );

    // Junction table indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_user_follows_follower ON user_follows(follower_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_user_follows_following ON user_follows(following_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_post_likes_post ON post_likes(post_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_post_likes_user ON post_likes(user_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_post_bookmarks_post ON post_bookmarks(post_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_post_bookmarks_user ON post_bookmarks(user_id)',
    );

    // User-post interactions table (recommendation engine)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_post_interactions (
        user_id TEXT NOT NULL,
        post_id TEXT NOT NULL,
        interaction_type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        PRIMARY KEY (user_id, post_id, interaction_type),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_interactions_user ON user_post_interactions(user_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_interactions_post ON user_post_interactions(post_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_interactions_type ON user_post_interactions(interaction_type)',
    );
  }

  Future<void> _seedIfNeeded(Database db) async {
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM users'),
        ) ??
        0;
    if (count > 0 && _seedMode != DatabaseSeedMode.full) {
      return; // Data exists, skip seeding
    }

    if (_seedMode == DatabaseSeedMode.minimal) {
      await _seedMinimal(db);
    } else if (_seedMode == DatabaseSeedMode.full) {
      await _seedAll(db);
    }
  }

  Future<void> _seedMinimal(Database db) async {
    for (final user in SeedData.users.take(6)) {
      await db.insert('users', {
        'id': user.id,
        'username': user.username,
        'display_name': user.displayName,
        'email': user.email,
        'avatar_url': user.avatarUrl,
        'bio': user.bio,
        'skills': user.skills.join('|'),
        'follower_count': user.followerCount,
        'following_count': user.followingCount,
        'post_count': user.postCount,
        'reputation': user.reputation,
        'is_online': user.isOnline ? 1 : 0,
        'is_mentor': user.isMentor ? 1 : 0,
        'is_followed_by_me': user.isFollowedByMe ? 1 : 0,
        'created_at': user.createdAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _seedAll(Database db) async {
    // Seed users
    for (final user in SeedData.users) {
      await db.insert('users', {
        'id': user.id,
        'username': user.username,
        'display_name': user.displayName,
        'email': user.email,
        'avatar_url': user.avatarUrl,
        'bio': user.bio,
        'skills': user.skills.join('|'),
        'follower_count': user.followerCount,
        'following_count': user.followingCount,
        'post_count': user.postCount,
        'reputation': user.reputation,
        'is_online': user.isOnline ? 1 : 0,
        'is_mentor': user.isMentor ? 1 : 0,
        'is_followed_by_me': user.isFollowedByMe ? 1 : 0,
        'created_at': user.createdAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Seed posts
    for (final post in SeedData.posts) {
      await db.insert('posts', {
        'id': post.id,
        'author_id': post.author.id,
        'title': post.title,
        'content': post.content,
        'type': post.type.name,
        'tags': post.tags.join('|'),
        'image_url': post.imageUrl,
        'view_count': post.viewCount,
        'like_count': post.likeCount,
        'comment_count': post.commentCount,
        'bookmark_count': post.bookmarkCount,
        'is_liked_by_me': post.isLikedByMe ? 1 : 0,
        'is_bookmarked_by_me': post.isBookmarkedByMe ? 1 : 0,
        'created_at': post.createdAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Seed comments
    for (final comment in SeedData.comments) {
      await db.insert('comments', {
        'id': comment.id,
        'post_id': 'p1',
        'parent_id': comment.parentId,
        'author_id': comment.author.id,
        'content': comment.content,
        'depth': comment.depth,
        'upvotes': comment.upvotes,
        'reply_count': comment.replyCount,
        'is_best': comment.isBest ? 1 : 0,
        'created_at': comment.createdAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Seed notifications
    for (final notification in SeedData.notifications) {
      await db.insert('notifications', {
        'id': notification.id,
        'type': notification.type,
        'title': notification.title,
        'body': notification.body,
        'from_user_id': notification.fromUser?.id,
        'is_read': notification.isRead ? 1 : 0,
        'created_at': notification.createdAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Seed projects
    for (final project in SeedData.projects) {
      await db.insert('projects', {
        'id': project.id,
        'owner_id': project.owner.id,
        'title': project.title,
        'description': project.description,
        'tech_stack': project.techStack.join('|'),
        'status': project.status,
        'member_count': project.memberCount,
        'max_members': project.maxMembers,
        'created_at': project.createdAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Seed jobs
    for (final job in SeedData.jobs) {
      await db.insert('jobs', {
        'id': job.id,
        'company': job.company,
        'title': job.title,
        'location': job.location,
        'remote': job.remote ? 1 : 0,
        'salary_range': job.salaryRange,
        'tech_stack': job.techStack.join('|'),
        'experience': job.experience,
        'match_percent': job.matchPercent,
        'created_at': job.createdAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Seed conversations
    for (final conversation in SeedData.conversations) {
      await db.insert('conversations', {
        'id': conversation.id,
        'other_user_id': conversation.otherUser.id,
        'last_message': conversation.lastMessage,
        'unread_count': conversation.unreadCount,
        'updated_at': conversation.updatedAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Seed messages
    for (final message in SeedData.messages) {
      await db.insert('messages', {
        'id': message.id,
        'conversation_id': 'conv1',
        'sender_id': message.senderId,
        'content': message.content,
        'type': message.type.name,
        'code_language': message.codeLanguage,
        'code_source': message.codeSource,
        'reactions': message.reactions.join('|'),
        'is_read': message.isRead ? 1 : 0,
        'created_at': message.createdAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Seed follows
    await db.insert('user_follows', {
      'id': 'f1',
      'follower_id': 'u1',
      'following_id': 'u2',
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // Seed post likes
    await db.insert('post_likes', {
      'id': 'pl1',
      'post_id': 'p1',
      'user_id': 'u1',
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // Seed post bookmarks
    await db.insert('post_bookmarks', {
      'id': 'pb1',
      'post_id': 'p1',
      'user_id': 'u1',
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Clear all data and reset database
  Future<void> reset() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('user_post_interactions');
      await txn.delete('post_bookmarks');
      await txn.delete('post_likes');
      await txn.delete('user_follows');
      await txn.delete('messages');
      await txn.delete('conversations');
      await txn.delete('jobs');
      await txn.delete('projects');
      await txn.delete('notifications');
      await txn.delete('comments');
      await txn.delete('posts');
      await txn.delete('users');
    });
  }

  /// Run database vacuum to optimize storage
  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }
}
