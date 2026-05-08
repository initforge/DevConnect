import 'package:flutter_test/flutter_test.dart';
import 'package:devconnect/core/models/models.dart';

void main() {
  group('User Model', () {
    test('User can be created with all fields', () {
      final user = User(
        id: 'u1',
        username: 'testuser',
        displayName: 'Test User',
        email: 'test@test.com',
        avatarUrl: 'https://example.com/avatar.png',
        bio: 'A test user',
        skills: ['Flutter', 'Dart'],
        followerCount: 100,
        followingCount: 50,
        postCount: 25,
        reputation: 500,
        isOnline: true,
        isMentor: false,
        isFollowedByMe: false,
        createdAt: DateTime(2025, 1, 1),
      );

      expect(user.id, 'u1');
      expect(user.username, 'testuser');
      expect(user.displayName, 'Test User');
      expect(user.email, 'test@test.com');
      expect(user.avatarUrl, 'https://example.com/avatar.png');
      expect(user.bio, 'A test user');
      expect(user.skills, ['Flutter', 'Dart']);
      expect(user.followerCount, 100);
      expect(user.followingCount, 50);
      expect(user.postCount, 25);
      expect(user.reputation, 500);
      expect(user.isOnline, true);
      expect(user.isMentor, false);
      expect(user.isFollowedByMe, false);
    });

    test('User can be created with default values', () {
      final user = User(
        id: 'u1',
        username: 'user1',
        displayName: 'User One',
        email: 'user1@test.com',
        createdAt: DateTime(2025, 1, 1),
      );

      expect(user.skills, isEmpty);
      expect(user.followerCount, 0);
      expect(user.followingCount, 0);
      expect(user.postCount, 0);
      expect(user.reputation, 0);
      expect(user.isOnline, false);
      expect(user.isMentor, false);
      expect(user.isFollowedByMe, false);
    });

    test('User equality works correctly', () {
      final user1 = User(
        id: 'u1',
        username: 'user1',
        displayName: 'User One',
        email: 'user1@test.com',
        createdAt: DateTime(2025, 1, 1),
      );

      final user2 = User(
        id: 'u1',
        username: 'different',
        displayName: 'Different Name',
        email: 'different@test.com',
        createdAt: DateTime(2025, 2, 2),
      );

      expect(user1, equals(user2));
    });

    test('Users with different ids are not equal', () {
      final user1 = User(
        id: 'u1',
        username: 'user1',
        displayName: 'User One',
        email: 'user1@test.com',
        createdAt: DateTime(2025, 1, 1),
      );

      final user2 = User(
        id: 'u2',
        username: 'user1',
        displayName: 'User One',
        email: 'user1@test.com',
        createdAt: DateTime(2025, 1, 1),
      );

      expect(user1, isNot(equals(user2)));
    });
  });

  group('Post Model', () {
    late User author;

    setUp(() {
      author = User(
        id: 'u1',
        username: 'testuser',
        displayName: 'Test User',
        email: 'test@test.com',
        createdAt: DateTime(2025, 1, 1),
      );
    });

    test('Post can be created with all fields', () {
      final post = Post(
        id: 'p1',
        author: author,
        title: 'Test Post',
        content: 'This is test content',
        type: PostType.article,
        tags: ['Flutter', 'Testing'],
        imageUrl: 'https://example.com/image.png',
        viewCount: 1000,
        likeCount: 50,
        commentCount: 10,
        bookmarkCount: 5,
        isLikedByMe: true,
        isBookmarkedByMe: false,
        createdAt: DateTime(2025, 1, 15),
      );

      expect(post.id, 'p1');
      expect(post.author, author);
      expect(post.title, 'Test Post');
      expect(post.content, 'This is test content');
      expect(post.type, PostType.article);
      expect(post.tags, ['Flutter', 'Testing']);
      expect(post.imageUrl, 'https://example.com/image.png');
      expect(post.viewCount, 1000);
      expect(post.likeCount, 50);
      expect(post.commentCount, 10);
      expect(post.isLikedByMe, true);
      expect(post.isBookmarkedByMe, false);
    });

    test('Post can be created with default values', () {
      final post = Post(
        id: 'p2',
        author: author,
        title: 'Minimal Post',
        content: 'Content',
        createdAt: DateTime(2025, 1, 15),
      );

      expect(post.type, PostType.article);
      expect(post.tags, isEmpty);
      expect(post.imageUrl, isNull);
      expect(post.viewCount, 0);
      expect(post.likeCount, 0);
      expect(post.commentCount, 0);
      expect(post.bookmarkCount, 0);
      expect(post.isLikedByMe, false);
      expect(post.isBookmarkedByMe, false);
    });

    test('Post equality is based on id only', () {
      final post1 = Post(
        id: 'p1',
        author: author,
        title: 'Post One',
        content: 'Content one',
        createdAt: DateTime(2025, 1, 1),
      );

      final post2 = Post(
        id: 'p1',
        author: author,
        title: 'Different Title',
        content: 'Different content',
        createdAt: DateTime(2025, 2, 2),
      );

      expect(post1, equals(post2));
    });

    test('PostType enum has all expected values', () {
      expect(PostType.values, contains(PostType.article));
      expect(PostType.values, contains(PostType.snippet));
      expect(PostType.values, contains(PostType.til));
      expect(PostType.values, contains(PostType.question));
      expect(PostType.values, contains(PostType.project));
      expect(PostType.values, contains(PostType.discussion));
    });

    test('PostType enum has correct number of values', () {
      expect(PostType.values.length, 6);
    });
  });

  group('Comment Model', () {
    late User author;

    setUp(() {
      author = User(
        id: 'u1',
        username: 'testuser',
        displayName: 'Test User',
        email: 'test@test.com',
        createdAt: DateTime(2025, 1, 1),
      );
    });

    test('Comment can be created with all fields', () {
      final comment = Comment(
        id: 'c1',
        author: author,
        content: 'This is a test comment',
        depth: 0,
        upvotes: 5,
        replyCount: 2,
        isBest: true,
        createdAt: DateTime(2025, 1, 10),
      );

      expect(comment.id, 'c1');
      expect(comment.author, author);
      expect(comment.content, 'This is a test comment');
      expect(comment.depth, 0);
      expect(comment.upvotes, 5);
      expect(comment.replyCount, 2);
      expect(comment.isBest, true);
    });

    test('Comment can be created with default values', () {
      final comment = Comment(
        id: 'c2',
        author: author,
        content: 'Simple comment',
        createdAt: DateTime(2025, 1, 10),
      );

      expect(comment.depth, 0);
      expect(comment.upvotes, 0);
      expect(comment.replyCount, 0);
      expect(comment.isBest, false);
    });

    test('Comment can have nested replies with depth', () {
      final reply = Comment(
        id: 'c3',
        author: author,
        content: 'This is a reply',
        depth: 1,
        createdAt: DateTime(2025, 1, 10),
      );

      expect(reply.depth, 1);
      expect(reply.isBest, false);
    });
  });

  group('Message Model', () {
    test('Message can be created with text type', () {
      final message = Message(
        id: 'm1',
        senderId: 'u1',
        content: 'Hello world',
        type: MessageType.text,
        isRead: false,
        createdAt: DateTime(2025, 1, 1),
      );

      expect(message.id, 'm1');
      expect(message.senderId, 'u1');
      expect(message.content, 'Hello world');
      expect(message.type, MessageType.text);
      expect(message.codeLanguage, isNull);
      expect(message.codeSource, isNull);
      expect(message.reactions, isEmpty);
      expect(message.isRead, false);
    });

    test('Message can be created with code type', () {
      final message = Message(
        id: 'm2',
        senderId: 'u1',
        content: 'print("Hello")',
        type: MessageType.code,
        codeLanguage: 'python',
        codeSource: 'print("Hello")',
        isRead: true,
        createdAt: DateTime(2025, 1, 1),
      );

      expect(message.type, MessageType.code);
      expect(message.codeLanguage, 'python');
      expect(message.codeSource, 'print("Hello")');
      expect(message.isRead, true);
    });

    test('Message can be created with image type', () {
      final message = Message(
        id: 'm3',
        senderId: 'u2',
        content: 'https://example.com/image.png',
        type: MessageType.image,
        isRead: false,
        createdAt: DateTime(2025, 1, 2),
      );

      expect(message.type, MessageType.image);
      expect(message.content, 'https://example.com/image.png');
    });

    test('Message can be created with reactions', () {
      final message = Message(
        id: 'm4',
        senderId: 'u1',
        content: 'Message with reactions',
        type: MessageType.text,
        reactions: ['thumbs_up', 'heart'],
        isRead: false,
        createdAt: DateTime(2025, 1, 1),
      );

      expect(message.reactions, ['thumbs_up', 'heart']);
      expect(message.reactions.length, 2);
    });

    test('Message can be created with default values', () {
      final message = Message(
        id: 'm5',
        senderId: 'u1',
        content: 'Minimal message',
        createdAt: DateTime(2025, 1, 1),
      );

      expect(message.type, MessageType.text);
      expect(message.isRead, false);
      expect(message.reactions, isEmpty);
    });

    test('MessageType enum has all expected values', () {
      expect(MessageType.values, contains(MessageType.text));
      expect(MessageType.values, contains(MessageType.image));
      expect(MessageType.values, contains(MessageType.code));
      expect(MessageType.values.length, 3);
    });
  });

  group('Job Model', () {
    test('Job can be created with all fields', () {
      final job = Job(
        id: 'j1',
        company: 'TechCorp',
        title: 'Flutter Developer',
        location: 'Ho Chi Minh City',
        remote: true,
        salaryRange: '\$1,500 - \$2,500',
        techStack: ['Flutter', 'Dart', 'Firebase'],
        experience: '2-4 years',
        matchPercent: 92,
        createdAt: DateTime(2025, 1, 1),
      );

      expect(job.id, 'j1');
      expect(job.company, 'TechCorp');
      expect(job.title, 'Flutter Developer');
      expect(job.location, 'Ho Chi Minh City');
      expect(job.remote, true);
      expect(job.salaryRange, '\$1,500 - \$2,500');
      expect(job.techStack, ['Flutter', 'Dart', 'Firebase']);
      expect(job.experience, '2-4 years');
      expect(job.matchPercent, 92);
    });

    test('Job can be created with default values', () {
      final job = Job(
        id: 'j2',
        company: 'Startup',
        title: 'Junior Dev',
        location: 'Hanoi',
        salaryRange: '\$500 - \$800',
        experience: '0-2 years',
        createdAt: DateTime(2025, 1, 1),
      );

      expect(job.remote, false);
      expect(job.techStack, isEmpty);
      expect(job.matchPercent, 0);
    });

    test('Job match percentage can be high', () {
      final job = Job(
        id: 'j3',
        company: 'BigTech',
        title: 'Senior Flutter',
        location: 'SF',
        salaryRange: '\$3,000 - \$5,000',
        experience: '5+ years',
        matchPercent: 98,
        createdAt: DateTime(2025, 1, 1),
      );

      expect(job.matchPercent, 98);
    });
  });

  group('Project Model', () {
    late User owner;

    setUp(() {
      owner = User(
        id: 'u1',
        username: 'owner',
        displayName: 'Project Owner',
        email: 'owner@test.com',
        createdAt: DateTime(2025, 1, 1),
      );
    });

    test('Project can be created with all fields', () {
      final project = Project(
        id: 'proj1',
        owner: owner,
        title: 'My Project',
        description: 'A great project',
        techStack: ['Flutter', 'Node.js'],
        status: 'ACTIVE',
        memberCount: 3,
        maxMembers: 5,
        createdAt: DateTime(2025, 1, 1),
      );

      expect(project.id, 'proj1');
      expect(project.owner, owner);
      expect(project.title, 'My Project');
      expect(project.description, 'A great project');
      expect(project.techStack, ['Flutter', 'Node.js']);
      expect(project.status, 'ACTIVE');
      expect(project.memberCount, 3);
      expect(project.maxMembers, 5);
    });

    test('Project can be created with default values', () {
      final project = Project(
        id: 'proj2',
        owner: owner,
        title: 'Default Project',
        description: 'Test project',
        createdAt: DateTime(2025, 1, 1),
      );

      expect(project.techStack, isEmpty);
      expect(project.status, 'LOOKING_FOR_MEMBERS');
      expect(project.memberCount, 1);
      expect(project.maxMembers, 5);
    });
  });

  group('Conversation Model', () {
    late User otherUser;

    setUp(() {
      otherUser = User(
        id: 'u2',
        username: 'other',
        displayName: 'Other User',
        email: 'other@test.com',
        createdAt: DateTime(2025, 1, 1),
      );
    });

    test('Conversation can be created with all fields', () {
      final conversation = Conversation(
        id: 'conv1',
        otherUser: otherUser,
        lastMessage: 'Hello there!',
        unreadCount: 3,
        updatedAt: DateTime(2025, 1, 15),
      );

      expect(conversation.id, 'conv1');
      expect(conversation.otherUser, otherUser);
      expect(conversation.lastMessage, 'Hello there!');
      expect(conversation.unreadCount, 3);
      expect(conversation.updatedAt, DateTime(2025, 1, 15));
    });

    test('Conversation unreadCount defaults to zero', () {
      final conversation = Conversation(
        id: 'conv2',
        otherUser: otherUser,
        lastMessage: 'Already read',
        updatedAt: DateTime(2025, 1, 15),
      );

      expect(conversation.unreadCount, 0);
    });
  });

  group('LeaderboardEntry Model', () {
    late User user;

    setUp(() {
      user = User(
        id: 'u1',
        username: 'topuser',
        displayName: 'Top User',
        email: 'top@test.com',
        createdAt: DateTime(2025, 1, 1),
      );
    });

    test('LeaderboardEntry can be created with all fields', () {
      final entry = LeaderboardEntry(
        rank: 1,
        user: user,
        points: 5000,
        rankChange: 2,
      );

      expect(entry.rank, 1);
      expect(entry.user, user);
      expect(entry.points, 5000);
      expect(entry.rankChange, 2);
    });

    test('LeaderboardEntry default rankChange is zero', () {
      final entry = LeaderboardEntry(
        rank: 5,
        user: user,
        points: 1000,
      );

      expect(entry.rankChange, 0);
    });

    test('LeaderboardEntry with negative rankChange shows drop', () {
      final entry = LeaderboardEntry(
        rank: 10,
        user: user,
        points: 500,
        rankChange: -3,
      );

      expect(entry.rankChange, -3);
    });
  });

  group('AppNotification Model', () {
    test('AppNotification can be created with all fields', () {
      final fromUser = User(
        id: 'u1',
        username: 'actor',
        displayName: 'Actor User',
        email: 'actor@test.com',
        createdAt: DateTime(2025, 1, 1),
      );

      final notification = AppNotification(
        id: 'n1',
        type: 'like',
        title: 'New Like',
        body: 'User liked your post',
        fromUser: fromUser,
        isRead: false,
        createdAt: DateTime(2025, 1, 15),
      );

      expect(notification.id, 'n1');
      expect(notification.type, 'like');
      expect(notification.title, 'New Like');
      expect(notification.body, 'User liked your post');
      expect(notification.fromUser, fromUser);
      expect(notification.isRead, false);
    });

    test('AppNotification can be created without fromUser', () {
      final notification = AppNotification(
        id: 'n2',
        type: 'system',
        title: 'System Update',
        body: 'App updated to v2.0',
        isRead: true,
        createdAt: DateTime(2025, 1, 15),
      );

      expect(notification.fromUser, isNull);
      expect(notification.isRead, true);
    });

    test('AppNotification isRead defaults to false', () {
      final notification = AppNotification(
        id: 'n3',
        type: 'comment',
        title: 'New Comment',
        body: 'Someone commented',
        createdAt: DateTime(2025, 1, 15),
      );

      expect(notification.isRead, false);
    });
  });
}