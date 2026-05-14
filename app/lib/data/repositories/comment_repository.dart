import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../core/services/api_service.dart';
import '../../core/services/app_preferences.dart';
import '../mappers/model_mapper.dart';

class CommentRepository {
  CommentRepository({AppDatabase? database, bool useApi = true})
    : _database = database ?? AppDatabase.instance,
      _useApi = useApi;

  final AppDatabase _database;
  final bool _useApi;

  Future<List<Comment>> getComments(String postId) async {
    if (_useApi) {
      final data = await ApiService.instance.get('/posts/$postId/comments');
      return data
          .map(
            (json) =>
                ModelMappers.commentFromJson(json as Map<String, dynamic>),
          )
          .toList();
    }
    final db = await _database.database;
    final rows = await db.query(
      'comments',
      where: 'post_id = ?',
      whereArgs: [postId],
      orderBy: 'created_at ASC',
    );
    return _commentsFromRows(rows);
  }

  // Alias for getComments - used by screens
  Future<List<Comment>> getCommentsForPost(String postId) =>
      getComments(postId);

  // Alias for addComment - used by screens
  Future<Comment> createComment({
    required String postId,
    required String content,
    String? parentId,
  }) => addComment(postId: postId, content: content, parentId: parentId);

  Future<Comment> addComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    final userId = AppPreferences.instance.userId;
    if (userId == null) throw Exception('User not logged in');

    if (_useApi) {
      final data = await ApiService.instance.post('/posts/$postId/comments', {
        'content': content,
        if (parentId != null) 'parentId': parentId,
      });
      return ModelMappers.commentFromJson(data);
    }

    final db = await _database.database;
    final now = DateTime.now();
    final id = 'c${now.millisecondsSinceEpoch}';
    final depth = parentId != null ? 1 : 0;

    final comment = Comment(
      id: id,
      parentId: parentId,
      author: User(
        id: userId,
        username: '',
        displayName: 'You',
        email: '',
        createdAt: DateTime.now(),
      ),
      content: content,
      depth: depth,
      createdAt: now,
    );

    await db.insert('comments', {
      'id': id,
      'post_id': postId,
      'parent_id': parentId,
      'author_id': userId,
      'content': content,
      'depth': depth,
      'upvotes': 0,
      'reply_count': 0,
      'is_best': 0,
      'created_at': now.toIso8601String(),
    });

    return comment;
  }

  Future<void> upvoteComment(String commentId) async {
    if (_useApi) {
      await ApiService.instance.post('/comments/$commentId/vote', {});
    }
    final db = await _database.database;
    await db.rawUpdate(
      'UPDATE comments SET upvotes = upvotes + 1 WHERE id = ?',
      [commentId],
    );
  }

  Future<void> markBestAnswer({
    required String postId,
    required String commentId,
  }) async {
    if (_useApi) {
      await ApiService.instance.patch(
        '/posts/$postId/comments/$commentId/best-answer',
        {},
      );
    }

    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.update(
        'comments',
        {'is_best': 0},
        where: 'post_id = ?',
        whereArgs: [postId],
      );
      await txn.update(
        'comments',
        {'is_best': 1},
        where: 'id = ?',
        whereArgs: [commentId],
      );
    });
  }

  List<Comment> _commentsFromRows(List<Map<String, Object?>> rows) {
    return rows
        .map(
          (row) => Comment(
            id: row['id']?.toString() ?? '',
            parentId: row['parent_id']?.toString(),
            author: User(
              id: row['author_id']?.toString() ?? '',
              username: '',
              displayName: 'Unknown',
              email: '',
              createdAt: DateTime.now(),
            ),
            content: row['content']?.toString() ?? '',
            depth: row['depth'] as int? ?? 0,
            upvotes: row['upvotes'] as int? ?? 0,
            replyCount: row['reply_count'] as int? ?? 0,
            isBest: (row['is_best'] as int?) == 1,
            createdAt:
                DateTime.tryParse(row['created_at']?.toString() ?? '') ??
                DateTime.now(),
          ),
        )
        .toList();
  }
}
