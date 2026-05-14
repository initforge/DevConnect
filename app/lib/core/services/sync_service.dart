import 'dart:async';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/models.dart';
import 'api_service.dart';
import 'network_info.dart';

/// SyncResult encapsulates the outcome of a sync operation.
class SyncResult {
  final bool success;
  final int pulled;
  final int pushed;
  final String? error;

  const SyncResult({
    required this.success,
    this.pulled = 0,
    this.pushed = 0,
    this.error,
  });

  factory SyncResult.success({int pulled = 0, int pushed = 0}) =>
      SyncResult(success: true, pulled: pulled, pushed: pushed);

  factory SyncResult.failure(String error) =>
      SyncResult(success: false, error: error);
}

/// SyncService orchestrates bidirectional sync between local SQLite and the backend.
/// It operates offline-first: reads always hit local DB; writes are queued and
/// replayed to the API when connectivity is available.  Server wins on conflict.
class SyncService {
  SyncService({AppDatabase? database, NetworkInfo? networkInfo})
    : _database = database ?? AppDatabase.instance,
      _networkInfo = networkInfo ?? NetworkInfoImpl();

  final AppDatabase _database;
  final NetworkInfo _networkInfo;

  ApiService get _api => ApiService.instance;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  // ---------------------------------------------------------------------------
  // Public entry-points
  // ---------------------------------------------------------------------------

  /// Pulls all entity tables from the backend and overwrites local DB.
  /// Safe to call multiple times; only runs once at a time.
  Future<SyncResult> pullAll() async {
    if (_isSyncing) return SyncResult.success();
    _isSyncing = true;
    try {
      if (!await _networkInfo.isConnected) {
        return SyncResult.success(); // offline – nothing to pull
      }
      int pulled = 0;
      await _pullUsers();
      pulled++;
      await _pullPosts();
      pulled++;
      await _pullComments();
      pulled++;
      await _pullProjects();
      pulled++;
      await _pullJobs();
      pulled++;
      await _pullConversations();
      pulled++;
      await _pullNotifications();
      pulled++;
      _lastSyncTime = DateTime.now();
      return SyncResult.success(pulled: pulled);
    } catch (e) {
      return SyncResult.failure(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// Pushes locally-created / locally-updated records to the backend.
  Future<SyncResult> pushAll() async {
    if (_isSyncing) return SyncResult.success();
    _isSyncing = true;
    try {
      if (!await _networkInfo.isConnected) {
        return SyncResult.success();
      }
      int pushed = 0;
      pushed += await _pushPendingPosts();
      pushed += await _pushPendingComments();
      return SyncResult.success(pushed: pushed);
    } catch (e) {
      return SyncResult.failure(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// Convenience: pull + push in one shot.
  Future<SyncResult> syncAll() async {
    final pull = await pullAll();
    if (!pull.success) return pull;
    final push = await pushAll();
    return SyncResult.success(pulled: pull.pulled, pushed: push.pushed);
  }

  // ---------------------------------------------------------------------------
  // Pull helpers – each overwrites its table with server data
  // ---------------------------------------------------------------------------

  Future<void> _pullUsers() async {
    final data = await _api.getAny('/users');
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete('users');
      for (final json in data) {
        await txn.insert(
          'users',
          _userToRow(_mapApiUser(json)),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> _pullPosts() async {
    final data = await _api.getAny('/posts');
    final items =
        data is List
            ? data
            : ((data as Map<String, dynamic>)['data'] as List? ?? []);
    final db = await _database.database;
    await db.transaction((txn) async {
      // Only delete posts that are synced (not pending upload)
      await txn.delete('posts', where: 'is_pending_sync = 0');
      for (final json in items) {
        final authorId = (json['author'] as Map<String, dynamic>?)?['id'] ?? '';
        await txn.insert('posts', {
          'id': json['id'],
          'author_id': authorId,
          'title': json['title'] ?? '',
          'content': json['content'] ?? '',
          'type': json['type'] ?? 'article',
          'tags': (json['tags'] as List?)?.join('|') ?? '',
          'image_url': json['imageUrl'],
          'view_count': json['viewCount'] ?? 0,
          'like_count': json['likeCount'] ?? 0,
          'comment_count': json['commentCount'] ?? 0,
          'bookmark_count': json['bookmarkCount'] ?? 0,
          'is_liked_by_me': (json['isLikedByMe'] == true) ? 1 : 0,
          'is_bookmarked_by_me': (json['isBookmarkedByMe'] == true) ? 1 : 0,
          'is_pending_sync': 0,
          'sync_dirty': 0,
          'created_at': json['createdAt'] ?? DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> _pullComments() async {
    // The backend exposes /posts/{postId}/comments for each post.
    // We collect all known post IDs and pull comments per post.
    final db = await _database.database;
    final postRows = await db.query('posts', columns: ['id']);
    for (final postRow in postRows) {
      final postId = postRow['id'] as String;
      try {
        final data = await _api.getAny('/posts/$postId/comments');
        await db.transaction((txn) async {
          // Remove old synced comments for this post only
          await txn.delete(
            'comments',
            where: 'post_id = ? AND is_pending_sync = 0',
            whereArgs: [postId],
          );
          for (final json in data) {
            final authorId =
                (json['author'] as Map<String, dynamic>?)?['id'] ?? '';
            await txn.insert('comments', {
              'id': json['id'],
              'post_id': postId,
              'parent_id': json['parentId'] ?? json['parent_id'],
              'author_id': authorId,
              'content': json['content'] ?? '',
              'depth': json['depth'] ?? 0,
              'upvotes': json['upvotes'] ?? 0,
              'reply_count': json['replyCount'] ?? 0,
              'is_best': (json['isBest'] == true) ? 1 : 0,
              'is_pending_sync': 0,
              'sync_dirty': 0,
              'created_at':
                  json['createdAt'] ?? DateTime.now().toIso8601String(),
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        });
      } catch (_) {
        // Some posts may not have comments endpoint; skip gracefully
      }
    }
  }

  Future<void> _pullProjects() async {
    final data = await _api.getAny('/projects');
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete('projects');
      for (final json in data) {
        final ownerId = (json['owner'] as Map<String, dynamic>?)?['id'] ?? '';
        await txn.insert('projects', {
          'id': json['id'],
          'owner_id': ownerId,
          'title': json['title'] ?? '',
          'description': json['description'] ?? '',
          'tech_stack': (json['techStack'] as List?)?.join('|') ?? '',
          'status': json['status'] ?? 'LOOKING_FOR_MEMBERS',
          'member_count': json['memberCount'] ?? 0,
          'max_members': json['maxMembers'] ?? 5,
          'created_at': json['createdAt'] ?? DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> _pullJobs() async {
    final data = await _api.getAny('/jobs');
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete('jobs');
      for (final json in data) {
        await txn.insert('jobs', {
          'id': json['id'],
          'company': json['company'] ?? '',
          'title': json['title'] ?? '',
          'location': json['location'] ?? '',
          'remote': (json['remote'] == true) ? 1 : 0,
          'salary_range': json['salaryRange'] ?? '',
          'tech_stack': (json['techStack'] as List?)?.join('|') ?? '',
          'experience': json['experience'] ?? '',
          'match_percent': json['matchPercent'] ?? 0,
          'created_at': json['createdAt'] ?? DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> _pullConversations() async {
    final data = await _api.getAny('/conversations');
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete('conversations');
      for (final json in data) {
        final otherUserId =
            (json['otherUser'] as Map<String, dynamic>?)?['id'] ?? '';
        await txn.insert('conversations', {
          'id': json['id'],
          'other_user_id': otherUserId,
          'last_message': json['lastMessage'] ?? '',
          'unread_count': json['unreadCount'] ?? 0,
          'updated_at': json['updatedAt'] ?? DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> _pullNotifications() async {
    final data = await _api.getAny('/notifications');
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete('notifications');
      for (final json in data) {
        await txn.insert('notifications', {
          'id': json['id'],
          'type': json['type'] ?? '',
          'title': json['title'] ?? '',
          'body': json['body'] ?? '',
          'from_user_id': (json['fromUser'] as Map<String, dynamic>?)?['id'],
          'is_read': (json['isRead'] == true) ? 1 : 0,
          'created_at': json['createdAt'] ?? DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Push helpers – send locally-created records to the server
  // ---------------------------------------------------------------------------

  Future<int> _pushPendingPosts() async {
    final db = await _database.database;
    final pending = await db.query(
      'posts',
      where: 'is_pending_sync = 1',
      limit: 50,
    );
    int pushed = 0;
    for (final row in pending) {
      try {
        await _api.post('/posts', {
          'title': row['title'],
          'content': row['content'],
          'authorId': row['author_id'],
          'type': row['type'],
          'tags': (row['tags'] as String?)?.split('|') ?? [],
        });
        await db.update(
          'posts',
          {'is_pending_sync': 0},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
        pushed++;
      } catch (_) {}
    }
    return pushed;
  }

  Future<int> _pushPendingComments() async {
    final db = await _database.database;
    final pending = await db.query(
      'comments',
      where: 'is_pending_sync = 1',
      limit: 50,
    );
    int pushed = 0;
    for (final row in pending) {
      try {
        final postId = row['post_id'] as String;
        await _api.post('/posts/$postId/comments', {
          'content': row['content'],
          'authorId': row['author_id'],
        });
        await db.update(
          'comments',
          {'is_pending_sync': 0},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
        pushed++;
      } catch (_) {}
    }
    return pushed;
  }

  // ---------------------------------------------------------------------------
  // Mappers – API JSON → local DB row
  // ---------------------------------------------------------------------------

  Map<String, Object?> _userToRow(User u) {
    return {
      'id': u.id,
      'username': u.username,
      'display_name': u.displayName,
      'email': u.email,
      'avatar_url': u.avatarUrl,
      'bio': u.bio,
      'skills': u.skills.join('|'),
      'follower_count': u.followerCount,
      'following_count': u.followingCount,
      'post_count': u.postCount,
      'reputation': u.reputation,
      'is_online': u.isOnline ? 1 : 0,
      'is_mentor': u.isMentor ? 1 : 0,
      'is_followed_by_me': u.isFollowedByMe ? 1 : 0,
      'created_at': u.createdAt.toIso8601String(),
    };
  }

  User _mapApiUser(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      displayName: json['displayName'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      bio: json['bio'],
      skills: List<String>.from(json['skills'] ?? []),
      followerCount: json['followerCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      postCount: json['postCount'] ?? 0,
      reputation: json['reputation'] ?? 0,
      isOnline: json['isOnline'] ?? false,
      isMentor: json['isMentor'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
