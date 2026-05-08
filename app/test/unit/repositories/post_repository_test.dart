import 'package:flutter_test/flutter_test.dart';
import 'package:devconnect/core/models/models.dart';

void main() {
  group('PostRepository - Data Models', () {
    test('Post stores all data correctly', () {
      final user = User(
        id: 'u1',
        username: 'testuser',
        displayName: 'Test User',
        email: 'test@test.com',
        createdAt: DateTime(2024, 1, 1),
      );
      final post = Post(
        id: 'p1',
        author: user,
        title: 'Test Post',
        content: 'Test content',
        type: PostType.article,
        tags: ['flutter', 'dart'],
        viewCount: 100,
        likeCount: 10,
        commentCount: 5,
        bookmarkCount: 2,
        isLikedByMe: true,
        isBookmarkedByMe: false,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(post.id, 'p1');
      expect(post.author, user);
      expect(post.title, 'Test Post');
      expect(post.content, 'Test content');
      expect(post.type, PostType.article);
      expect(post.tags, ['flutter', 'dart']);
      expect(post.viewCount, 100);
      expect(post.likeCount, 10);
      expect(post.commentCount, 5);
      expect(post.bookmarkCount, 2);
      expect(post.isLikedByMe, true);
      expect(post.isBookmarkedByMe, false);
    });

    test('Post handles default values', () {
      final user = User(
        id: 'u1',
        username: 'testuser',
        displayName: 'Test User',
        email: 'test@test.com',
        createdAt: DateTime(2024, 1, 1),
      );
      final post = Post(
        id: 'p1',
        author: user,
        title: 'Test',
        content: 'Content',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(post.type, PostType.article);
      expect(post.tags, isEmpty);
      expect(post.viewCount, 0);
      expect(post.likeCount, 0);
      expect(post.commentCount, 0);
      expect(post.bookmarkCount, 0);
      expect(post.isLikedByMe, false);
      expect(post.isBookmarkedByMe, false);
    });

    test('Post handles all PostType values', () {
      final user = User(
        id: 'u1',
        username: 'testuser',
        displayName: 'Test User',
        email: 'test@test.com',
        createdAt: DateTime(2024, 1, 1),
      );

      for (final type in PostType.values) {
        final post = Post(
          id: 'p1',
          author: user,
          title: 'Test',
          content: 'Test',
          type: type,
          createdAt: DateTime(2024, 1, 1),
        );
        expect(post.type, type);
      }
    });

    test('PostType enum has all expected values', () {
      expect(PostType.values, contains(PostType.article));
      expect(PostType.values, contains(PostType.snippet));
      expect(PostType.values, contains(PostType.til));
      expect(PostType.values, contains(PostType.question));
      expect(PostType.values, contains(PostType.project));
      expect(PostType.values, contains(PostType.discussion));
      expect(PostType.values.length, 6);
    });
  });
}
