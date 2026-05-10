import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../core/services/api_service.dart';
import '../../core/services/app_preferences.dart';
import 'user_repository.dart';
import '../mappers/model_mapper.dart';

/// FeedType enum for differentiating between feed types
enum FeedType { forYou, following, trending }

extension FeedTypeExtension on FeedType {
  String get displayName {
    switch (this) {
      case FeedType.forYou:
        return 'Dành cho bạn';
      case FeedType.following:
        return 'Đang theo dõi';
      case FeedType.trending:
        return 'Xu hướng';
    }
  }

  String get apiQueryParam {
    switch (this) {
      case FeedType.forYou:
        return 'foryou';
      case FeedType.following:
        return 'following';
      case FeedType.trending:
        return 'trending';
    }
  }
}

class PostRepository {
  PostRepository({
    AppDatabase? database,
    UserRepository? userRepository,
    bool useApi = true,
  }) : _database = database ?? AppDatabase.instance,
       _userRepository = userRepository ?? UserRepository(database: database),
       _useApi = useApi;

  final AppDatabase _database;
  final UserRepository _userRepository;
  final bool _useApi;

  Future<List<Post>> getForYouPosts({String? cursor, int limit = 20}) async {
    if (_useApi) {
      final queryParams = <String, dynamic>{'type': 'foryou', 'limit': limit};
      if (cursor != null) queryParams['cursor'] = cursor;

      final data = await ApiService.instance.get(
        '/api/posts',
        queryParams: queryParams,
      );
      final posts =
          data
              .map(
                (json) =>
                    ModelMappers.postFromJson(json as Map<String, dynamic>),
              )
              .toList();
      await _savePostsToDb(posts);
      return posts;
    }
    return _fetchPosts('SELECT * FROM posts ORDER BY created_at DESC LIMIT ?', [
      limit + 1,
    ]);
  }

  Future<List<Post>> getFollowingPosts({String? cursor, int limit = 20}) async {
    final currentUserId = AppPreferences.instance.user?['id'];

    if (_useApi) {
      final queryParams = <String, dynamic>{
        'type': 'following',
        'limit': limit,
      };
      if (cursor != null) queryParams['cursor'] = cursor;

      final data = await ApiService.instance.get(
        '/api/posts',
        queryParams: queryParams,
      );
      final posts =
          data
              .map(
                (json) =>
                    ModelMappers.postFromJson(json as Map<String, dynamic>),
              )
              .toList();
      await _savePostsToDb(posts);
      return posts;
    }

    if (currentUserId == null) return [];

    return _fetchPosts(
      '''
      SELECT p.* FROM posts p
      INNER JOIN user_follows f ON p.author_id = f.following_id
      WHERE f.follower_id = ?
      ORDER BY p.created_at DESC
      LIMIT ?
      ''',
      [currentUserId, limit + 1],
    );
  }

  Future<List<Post>> getTrendingPosts({String? cursor, int limit = 20}) async {
    if (_useApi) {
      final queryParams = <String, dynamic>{'type': 'trending', 'limit': limit};
      if (cursor != null) queryParams['cursor'] = cursor;

      final data = await ApiService.instance.get(
        '/api/posts',
        queryParams: queryParams,
      );
      final posts =
          data
              .map(
                (json) =>
                    ModelMappers.postFromJson(json as Map<String, dynamic>),
              )
              .toList();
      await _savePostsToDb(posts);
      return posts;
    }

    return _fetchPosts(
      'SELECT * FROM posts ORDER BY like_count DESC, created_at DESC LIMIT ?',
      [limit + 1],
    );
  }

  Future<List<Post>> getPostsByAuthor(
    String authorId, {
    String? cursor,
    int limit = 20,
  }) async {
    if (_useApi) {
      final queryParams = <String, dynamic>{
        'authorId': authorId,
        'limit': limit,
      };
      if (cursor != null) queryParams['cursor'] = cursor;

      final data = await ApiService.instance.get(
        '/api/posts',
        queryParams: queryParams,
      );
      final posts =
          data
              .map(
                (json) =>
                    ModelMappers.postFromJson(json as Map<String, dynamic>),
              )
              .toList();
      await _savePostsToDb(posts);
      return posts;
    }
    return _fetchPosts(
      'SELECT * FROM posts WHERE author_id = ? ORDER BY created_at DESC LIMIT ?',
      [authorId, limit + 1],
    );
  }

  Future<Post?> getPostById(String postId) async {
    if (_useApi) {
      try {
        final data = await ApiService.instance.getObject('/api/posts/$postId');
        final post = ModelMappers.postFromJson(data);
        await _savePostToDb(post);
        return post;
      } catch (error) {
        debugPrint('PostRepository.getPostById API fallback: $error');
      }
    }
    final items = await _fetchPosts(
      'SELECT * FROM posts WHERE id = ? LIMIT 1',
      [postId],
    );
    return items.isEmpty ? null : items.first;
  }

  Future<Post> createPost({
    required String title,
    required String content,
    String? authorId,
    PostType type = PostType.article,
    List<String> tags = const [],
    String? imageUrl,
  }) async {
    final userId = authorId ?? AppPreferences.instance.user?['id'];
    if (userId == null) throw Exception('User not logged in');

    final author = await _userRepository.getUserById(userId);
    if (author == null) throw Exception('User not found');

    final now = DateTime.now();
    final id = 'p${now.millisecondsSinceEpoch}';

    if (_useApi) {
      try {
        final data = await ApiService.instance.post('/api/posts', {
          'title': title,
          'content': content,
          'authorId': userId,
          'type': type.name,
          'tags': tags,
          if (imageUrl != null) 'imageUrl': imageUrl,
        });

        final post = ModelMappers.postFromJson(data);
        await _savePostToDb(post);

        final db = await _database.database;
        await db.rawUpdate(
          'UPDATE users SET post_count = post_count + 1 WHERE id = ?',
          [userId],
        );

        return post;
      } catch (error) {
        debugPrint('PostRepository.createPost API failed: $error');
        rethrow;
      }
    }

    final db = await _database.database;
    final post = Post(
      id: id,
      author: author,
      title: title,
      content: content,
      type: type,
      tags: tags,
      imageUrl: imageUrl,
      createdAt: now,
    );

    await db.insert('posts', ModelMappers.postToRow(post));
    await db.rawUpdate(
      'UPDATE users SET post_count = post_count + 1 WHERE id = ?',
      [userId],
    );

    return post;
  }

  Future<bool> toggleLike(String postId) async {
    if (_useApi) {
      try {
        final result = await ApiService.instance.post(
          '/api/posts/$postId/like',
          {},
        );
        return result['liked'] == true;
      } catch (error) {
        debugPrint('PostRepository.toggleLike API failed: $error');
        rethrow;
      }
    }

    final db = await _database.database;
    final rows = await db.query(
      'posts',
      where: 'id = ?',
      whereArgs: [postId],
      limit: 1,
    );
    if (rows.isEmpty) return false;

    final isLiked = (rows.first['is_liked_by_me'] as int? ?? 0) == 1;
    final currentLikes = (rows.first['like_count'] as int? ?? 0);

    await db.update(
      'posts',
      {
        'is_liked_by_me': isLiked ? 0 : 1,
        'like_count': isLiked ? currentLikes - 1 : currentLikes + 1,
      },
      where: 'id = ?',
      whereArgs: [postId],
    );

    final userId = AppPreferences.instance.user?['id'];
    if (userId == null) return !isLiked;

    if (isLiked) {
      await db.delete(
        'post_likes',
        where: 'post_id = ? AND user_id = ?',
        whereArgs: [postId, userId],
      );
    } else {
      await db.insert('post_likes', {
        'id': 'pl${DateTime.now().millisecondsSinceEpoch}',
        'post_id': postId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    return !isLiked;
  }

  Future<bool> toggleBookmark(String postId) async {
    if (_useApi) {
      try {
        final result = await ApiService.instance.post(
          '/api/posts/$postId/bookmark',
          {},
        );
        return result['bookmarked'] == true;
      } catch (error) {
        debugPrint('PostRepository.toggleBookmark API failed: $error');
        rethrow;
      }
    }

    final db = await _database.database;
    final rows = await db.query(
      'posts',
      where: 'id = ?',
      whereArgs: [postId],
      limit: 1,
    );
    if (rows.isEmpty) return false;

    final isBookmarked = (rows.first['is_bookmarked_by_me'] as int? ?? 0) == 1;
    final currentBookmarks = (rows.first['bookmark_count'] as int? ?? 0);

    await db.update(
      'posts',
      {
        'is_bookmarked_by_me': isBookmarked ? 0 : 1,
        'bookmark_count':
            isBookmarked ? currentBookmarks - 1 : currentBookmarks + 1,
      },
      where: 'id = ?',
      whereArgs: [postId],
    );

    final userId = AppPreferences.instance.user?['id'];
    if (userId == null) return !isBookmarked;

    if (isBookmarked) {
      await db.delete(
        'post_bookmarks',
        where: 'post_id = ? AND user_id = ?',
        whereArgs: [postId, userId],
      );
    } else {
      await db.insert('post_bookmarks', {
        'id': 'pb${DateTime.now().millisecondsSinceEpoch}',
        'post_id': postId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    return !isBookmarked;
  }

  Future<List<Post>> getBookmarkedPosts() async {
    if (_useApi) {
      try {
        final data = await ApiService.instance.get('/api/posts/bookmarked');
        final posts =
            data
                .map(
                  (json) =>
                      ModelMappers.postFromJson(json as Map<String, dynamic>),
                )
                .toList();
        return posts;
      } catch (error) {
        debugPrint('PostRepository.getBookmarkedPosts API fallback: $error');
      }
    }
    return _fetchPosts(
      "SELECT * FROM posts WHERE is_bookmarked_by_me = 1 ORDER BY created_at DESC",
    );
  }

  Future<void> deletePost(String postId) async {
    if (_useApi) {
      try {
        await ApiService.instance.delete('/api/posts/$postId');
      } catch (error) {
        debugPrint('PostRepository.deletePost API failed: $error');
        rethrow;
      }
    }

    final db = await _database.database;
    await db.delete('posts', where: 'id = ?', whereArgs: [postId]);
  }

  Future<void> _savePostsToDb(List<Post> posts) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      for (final post in posts) {
        await txn.insert(
          'posts',
          ModelMappers.postToRow(post),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> _savePostToDb(Post post) async {
    final db = await _database.database;
    await db.insert(
      'posts',
      ModelMappers.postToRow(post),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Post>> _fetchPosts(
    String sql, [
    List<Object?> params = const [],
  ]) async {
    final db = await _database.database;
    final rows = await db.rawQuery(sql, params);
    final posts = <Post>[];

    for (final row in rows) {
      final author = await _userRepository.getUserById(
        row['author_id'] as String,
      );
      if (author == null) continue;

      posts.add(ModelMappers.postFromRow(row, author));
    }
    return posts;
  }
}
