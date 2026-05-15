import 'package:flutter_test/flutter_test.dart';
import 'package:devconnect/core/models/models.dart';

void main() {
  group('NotificationRepository - Data Models', () {
    test('AppNotification stores all data correctly', () {
      final fromUser = User(
        id: 'u1',
        username: 'testuser',
        displayName: 'Test User',
        email: 'test@test.com',
        createdAt: DateTime(2024, 1, 1),
      );
      final notification = AppNotification(
        id: 'n1',
        type: 'LIKE',
        title: 'Liked your post',
        body: 'User liked your post',
        fromUser: fromUser,
        isRead: true,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(notification.id, 'n1');
      expect(notification.type, 'LIKE');
      expect(notification.title, 'Liked your post');
      expect(notification.body, 'User liked your post');
      expect(notification.fromUser, fromUser);
      expect(notification.isRead, true);
    });

    test('AppNotification can be created without fromUser', () {
      final notification = AppNotification(
        id: 'n1',
        type: 'SYSTEM',
        title: 'System notification',
        body: 'System message',
        fromUser: null,
        isRead: false,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(notification.fromUser, isNull);
      expect(notification.type, 'SYSTEM');
    });

    test('AppNotification isRead defaults to false', () {
      final notification = AppNotification(
        id: 'n1',
        type: 'COMMENT',
        title: 'Comment',
        body: 'Someone commented',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(notification.isRead, false);
    });

    test('AppNotification handles all notification types', () {
      final types = [
        'LIKE',
        'COMMENT',
        'FOLLOW',
        'MENTION',
        'BEST_ANSWER',
        'SYSTEM',
      ];

      for (final type in types) {
        final notification = AppNotification(
          id: 'n1',
          type: type,
          title: 'Test',
          body: 'Test body',
          createdAt: DateTime(2024, 1, 1),
        );
        expect(notification.type, type);
      }
    });
  });
}
