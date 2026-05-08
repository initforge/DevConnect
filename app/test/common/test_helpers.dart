import 'package:devconnect/core/models/models.dart';
import 'package:devconnect/data/repositories/post_repository.dart';

// =============================================================================
// Mock Repository for PostRepository
// =============================================================================

/// A mock implementation of PostRepository for testing that does not
/// depend on real database or API. Override methods to return mock data.
class MockPostRepository extends PostRepository {
  final List<Post> mockPosts;
  final bool shouldThrow;

  MockPostRepository({
    this.mockPosts = const [],
    this.shouldThrow = false,
  }) : super(
          database: null,
          userRepository: null,
          useApi: false,
        );

  @override
  Future<List<Post>> getForYouPosts({String? cursor, int limit = 20}) async {
    if (shouldThrow) throw Exception('Network error');
    return mockPosts;
  }

  @override
  Future<List<Post>> getFollowingPosts({String? cursor, int limit = 20}) async {
    if (shouldThrow) throw Exception('Network error');
    return mockPosts;
  }

  @override
  Future<List<Post>> getTrendingPosts({String? cursor, int limit = 20}) async {
    if (shouldThrow) throw Exception('Network error');
    return mockPosts;
  }
}

// =============================================================================
// Test Data Helpers
// =============================================================================

/// Creates a mock User for testing
User createMockUser({
  String id = 'u1',
  String username = 'testuser',
  String displayName = 'Test User',
  String email = 'test@example.com',
}) {
  return User(
    id: id,
    username: username,
    displayName: displayName,
    email: email,
    createdAt: DateTime(2024, 1, 1),
  );
}

/// Creates a mock Post for testing
Post createMockPost({
  String id = 'p1',
  User? author,
  String title = 'Test Post Title',
  String content = 'This is test post content that should be displayed.',
  PostType type = PostType.article,
  List<String> tags = const ['flutter', 'dart'],
  int likeCount = 10,
  int commentCount = 5,
  int bookmarkCount = 2,
  bool isLikedByMe = false,
  bool isBookmarkedByMe = false,
}) {
  return Post(
    id: id,
    author: author ?? createMockUser(),
    title: title,
    content: content,
    type: type,
    tags: tags,
    likeCount: likeCount,
    commentCount: commentCount,
    bookmarkCount: bookmarkCount,
    isLikedByMe: isLikedByMe,
    isBookmarkedByMe: isBookmarkedByMe,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  );
}

/// Creates a list of mock posts for testing
List<Post> createMockPosts(int count, {User? author}) {
  return List.generate(
    count,
    (i) => createMockPost(
      id: 'p$i',
      author: author ?? createMockUser(id: 'u$i', username: 'user$i'),
      title: 'Post Title $i',
      content: 'Content for post $i',
    ),
  );
}
