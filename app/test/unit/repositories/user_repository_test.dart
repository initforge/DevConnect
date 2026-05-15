import 'package:flutter_test/flutter_test.dart';
import 'package:devconnect/data/repositories/user_repository.dart';

void main() {
  late UserRepository repository;

  setUp(() {
    repository = UserRepository();
  });

  group('UserRepository - fromRow()', () {
    test('maps row to User model correctly', () {
      final user = repository.fromRow({
        'id': 'u1',
        'username': 'minhdev',
        'display_name': 'Minh Nguyễn',
        'email': 'minh@dev.com',
        'avatar_url': null,
        'bio': 'Flutter developer',
        'skills': 'Flutter|Dart',
        'follower_count': 12,
        'following_count': 5,
        'post_count': 3,
        'reputation': 200,
        'is_online': 1,
        'is_mentor': 0,
        'is_followed_by_me': 0,
        'created_at': '2025-01-01T00:00:00.000Z',
      });

      expect(user.id, 'u1');
      expect(user.username, 'minhdev');
      expect(user.displayName, 'Minh Nguyễn');
      expect(user.email, 'minh@dev.com');
      expect(user.avatarUrl, isNull);
      expect(user.bio, 'Flutter developer');
      expect(user.skills, ['Flutter', 'Dart']);
      expect(user.followerCount, 12);
      expect(user.followingCount, 5);
      expect(user.postCount, 3);
      expect(user.reputation, 200);
      expect(user.isOnline, true);
      expect(user.isMentor, false);
      expect(user.isFollowedByMe, false);
    });

    test('handles missing optional fields with defaults', () {
      final user = repository.fromRow({
        'id': 'u2',
        'username': 'test',
        'display_name': 'Test User',
        'email': 'test@test.com',
        'created_at': '2025-01-01T00:00:00.000Z',
      });

      expect(user.avatarUrl, isNull);
      expect(user.bio, isNull);
      expect(user.skills, isEmpty);
      expect(user.followerCount, 0);
      expect(user.followingCount, 0);
      expect(user.postCount, 0);
      expect(user.reputation, 0);
      expect(user.isOnline, false);
      expect(user.isMentor, false);
      expect(user.isFollowedByMe, false);
    });

    test('parses is_online 0 as false', () {
      final user = repository.fromRow({
        'id': 'u3',
        'username': 'offline',
        'display_name': 'Offline User',
        'email': 'offline@test.com',
        'is_online': 0,
        'is_mentor': 1,
        'is_followed_by_me': 1,
        'created_at': '2025-01-01T00:00:00.000Z',
      });

      expect(user.isOnline, false);
      expect(user.isMentor, true);
      expect(user.isFollowedByMe, true);
    });

    test('parses skills with pipe separator', () {
      final user = repository.fromRow({
        'id': 'u4',
        'username': 'fullstack',
        'display_name': 'Full Stack',
        'email': 'full@test.com',
        'skills': 'Flutter|Dart|Node.js|PostgreSQL',
        'created_at': '2025-01-01T00:00:00.000Z',
      });

      expect(user.skills, ['Flutter', 'Dart', 'Node.js', 'PostgreSQL']);
    });
  });

  group('UserRepository - fromJson()', () {
    test('maps API JSON to User model correctly', () {
      final user = repository.fromJson({
        'id': 'u1',
        'username': 'minhdev',
        'displayName': 'Minh Nguyễn',
        'email': 'minh@dev.com',
        'avatarUrl': 'https://example.com/avatar.png',
        'bio': 'Flutter developer',
        'skills': ['Flutter', 'Dart'],
        'followerCount': 12,
        'followingCount': 5,
        'postCount': 3,
        'reputation': 200,
        'isOnline': true,
        'isMentor': false,
        'isFollowedByMe': false,
        'createdAt': '2025-01-01T00:00:00.000Z',
      });

      expect(user.id, 'u1');
      expect(user.username, 'minhdev');
      expect(user.displayName, 'Minh Nguyễn');
      expect(user.email, 'minh@dev.com');
      expect(user.avatarUrl, 'https://example.com/avatar.png');
      expect(user.bio, 'Flutter developer');
      expect(user.skills, ['Flutter', 'Dart']);
      expect(user.followerCount, 12);
      expect(user.isOnline, true);
      expect(user.isMentor, false);
    });

    test('handles missing optional fields with defaults', () {
      final user = repository.fromJson({
        'id': 'u2',
        'username': 'test',
        'displayName': 'Test User',
        'email': 'test@test.com',
        'createdAt': '2025-01-01T00:00:00.000Z',
      });

      expect(user.avatarUrl, isNull);
      expect(user.bio, isNull);
      expect(user.skills, isEmpty);
      expect(user.followerCount, 0);
      expect(user.followingCount, 0);
      expect(user.postCount, 0);
      expect(user.reputation, 0);
      expect(user.isOnline, false);
      expect(user.isMentor, false);
      expect(user.isFollowedByMe, false);
    });

    test('handles null skills list', () {
      final user = repository.fromJson({
        'id': 'u3',
        'username': 'nullskills',
        'displayName': 'Null Skills',
        'email': 'null@test.com',
        'skills': null,
        'createdAt': '2025-01-01T00:00:00.000Z',
      });

      expect(user.skills, isEmpty);
    });

    test('handles invalid date with fallback to now', () {
      final before = DateTime.now();
      final user = repository.fromJson({
        'id': 'u4',
        'username': 'baddate',
        'displayName': 'Bad Date',
        'email': 'bad@test.com',
        'createdAt': 'invalid-date',
      });
      final after = DateTime.now();

      expect(
        user.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        user.createdAt.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });
  });

  group('UserRepository - toRow()', () {
    test('maps User to database row correctly', () {
      final user = repository.fromRow({
        'id': 'u1',
        'username': 'minhdev',
        'display_name': 'Minh Nguyễn',
        'email': 'minh@dev.com',
        'skills': 'Flutter|Dart',
        'follower_count': 12,
        'following_count': 5,
        'post_count': 3,
        'reputation': 200,
        'is_online': 1,
        'is_mentor': 0,
        'is_followed_by_me': 0,
        'created_at': '2025-01-01T00:00:00.000Z',
      });

      final row = repository.toRow(user);

      expect(row['id'], 'u1');
      expect(row['username'], 'minhdev');
      expect(row['display_name'], 'Minh Nguyễn');
      expect(row['email'], 'minh@dev.com');
      expect(row['skills'], 'Flutter|Dart');
      expect(row['follower_count'], 12);
      expect(row['following_count'], 5);
      expect(row['post_count'], 3);
      expect(row['reputation'], 200);
      expect(row['is_online'], 1);
      expect(row['is_mentor'], 0);
      expect(row['is_followed_by_me'], 0);
    });

    test('converts boolean isOnline to integer for database', () {
      final user = repository.fromRow({
        'id': 'u1',
        'username': 'test',
        'display_name': 'Test',
        'email': 'test@test.com',
        'is_online': 1,
        'is_mentor': 0,
        'is_followed_by_me': 0,
        'created_at': '2025-01-01T00:00:00.000Z',
      });

      final row = repository.toRow(user);

      expect(row['is_online'], 1);
      expect(row['is_mentor'], 0);
      expect(row['is_followed_by_me'], 0);
    });

    test('handles null avatarUrl and bio', () {
      final user = repository.fromRow({
        'id': 'u1',
        'username': 'test',
        'display_name': 'Test',
        'email': 'test@test.com',
        'created_at': '2025-01-01T00:00:00.000Z',
      });

      final row = repository.toRow(user);

      expect(row['avatar_url'], isNull);
      expect(row['bio'], isNull);
    });

    test('stores skills as pipe-separated string', () {
      final user = repository.fromJson({
        'id': 'u1',
        'username': 'test',
        'displayName': 'Test',
        'email': 'test@test.com',
        'skills': ['Flutter', 'Dart', 'Go'],
        'createdAt': '2025-01-01T00:00:00.000Z',
      });

      final row = repository.toRow(user);

      expect(row['skills'], 'Flutter|Dart|Go');
    });
  });
}
