import 'package:flutter_test/flutter_test.dart';
import 'package:devconnect/core/models/models.dart';

void main() {
  group('ChatRepository - Data Models', () {
    test('Conversation stores data correctly', () {
      final user = User(
        id: 'u1',
        username: 'testuser',
        displayName: 'Test User',
        email: 'test@test.com',
        createdAt: DateTime(2024, 1, 1),
      );
      final conversation = Conversation(
        id: 'conv1',
        otherUser: user,
        lastMessage: 'Hello there!',
        unreadCount: 3,
        updatedAt: DateTime(2024, 1, 1, 12, 0),
      );

      expect(conversation.id, 'conv1');
      expect(conversation.otherUser, user);
      expect(conversation.lastMessage, 'Hello there!');
      expect(conversation.unreadCount, 3);
    });

    test('Conversation unreadCount defaults to zero', () {
      final user = User(
        id: 'u1',
        username: 'testuser',
        displayName: 'Test User',
        email: 'test@test.com',
        createdAt: DateTime(2024, 1, 1),
      );
      final conversation = Conversation(
        id: 'conv1',
        otherUser: user,
        lastMessage: 'Hello!',
        updatedAt: DateTime(2024, 1, 1),
      );

      expect(conversation.unreadCount, 0);
    });
  });

  group('ChatRepository - Message Model', () {
    test('Message can be created with all fields', () {
      final message = Message(
        id: 'm1',
        senderId: 'u1',
        content: 'Test content',
        type: MessageType.code,
        codeLanguage: 'dart',
        codeSource: 'void main() {}',
        reactions: ['thumbs_up'],
        isRead: true,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(message.id, 'm1');
      expect(message.senderId, 'u1');
      expect(message.content, 'Test content');
      expect(message.type, MessageType.code);
      expect(message.codeLanguage, 'dart');
      expect(message.codeSource, 'void main() {}');
      expect(message.reactions, ['thumbs_up']);
      expect(message.isRead, true);
    });

    test('Message can be created with text type', () {
      final message = Message(
        id: 'm1',
        senderId: 'u1',
        content: 'Hello!',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(message.type, MessageType.text);
      expect(message.isRead, false);
    });

    test('Message can be created with image type', () {
      final message = Message(
        id: 'm1',
        senderId: 'u1',
        content: 'Check this out!',
        type: MessageType.image,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(message.type, MessageType.image);
    });

    test('Message can have reactions', () {
      final message = Message(
        id: 'm1',
        senderId: 'u1',
        content: 'Great post!',
        reactions: ['thumbs_up', 'heart', 'fire'],
        createdAt: DateTime(2024, 1, 1),
      );

      expect(message.reactions.length, 3);
      expect(message.reactions, contains('thumbs_up'));
      expect(message.reactions, contains('heart'));
      expect(message.reactions, contains('fire'));
    });

    test('Message reactions default to empty list', () {
      final message = Message(
        id: 'm1',
        senderId: 'u1',
        content: 'Test',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(message.reactions, isEmpty);
    });

    test('MessageType enum has all expected values', () {
      expect(MessageType.values, contains(MessageType.text));
      expect(MessageType.values, contains(MessageType.image));
      expect(MessageType.values, contains(MessageType.code));
      expect(MessageType.values.length, 3);
    });
  });
}
