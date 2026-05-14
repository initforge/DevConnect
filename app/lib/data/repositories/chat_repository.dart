import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../core/services/api_service.dart';
import '../../core/services/app_preferences.dart';
import '../mappers/model_mapper.dart';

class ChatRepository {
  ChatRepository({AppDatabase? database, bool useApi = true})
    : _database = database ?? AppDatabase.instance,
      _useApi = useApi;

  final AppDatabase _database;
  final bool _useApi;

  Future<List<Conversation>> getConversations() async {
    if (_useApi) {
      try {
        final data = await ApiService.instance.get('/chat/conversations');
        final conversations =
            data
                .map(
                  (json) => ModelMappers.conversationFromJson(
                    json as Map<String, dynamic>,
                  ),
                )
                .toList();
        await _saveConversationsToDb(conversations);
        return conversations;
      } catch (_) {
        rethrow;
      }
    }
    final db = await _database.database;
    final rows = await db.query('conversations', orderBy: 'updated_at DESC');
    return _conversationsFromRows(rows);
  }

  Future<Conversation?> getConversationById(String id) async {
    if (_useApi) {
      try {
        final data = await ApiService.instance.getObject(
          '/chat/conversations/$id',
        );
        if (data.isNotEmpty) {
          return ModelMappers.conversationFromJson(data);
        }
      } catch (_) {
        rethrow;
      }
    }
    final db = await _database.database;
    final rows = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final convs = await _conversationsFromRows(rows);
    return convs.isEmpty ? null : convs.first;
  }

  Future<List<Message>> getMessages(
    String conversationId, {
    int limit = 50,
  }) async {
    if (_useApi) {
      try {
        final data = await ApiService.instance.get(
          '/chat/conversations/$conversationId/messages',
          queryParams: {'limit': limit},
        );
        return data.map((json) {
          final reactions = json['reactions'];
          List<String> reactionsList = [];
          if (reactions is List) {
            reactionsList = reactions.map((e) => e.toString()).toList();
          } else if (reactions is String) {
            reactionsList =
                reactions.split('|').where((e) => e.isNotEmpty).toList();
          }

          final isRead = json['isRead'] ?? json['is_read'];
          final isReadBool = isRead == true || isRead == 1 || isRead == 'true';

          return Message(
            id: json['id']?.toString() ?? '',
            senderId:
                json['senderId']?.toString() ??
                json['sender_id']?.toString() ??
                '',
            content: json['content']?.toString() ?? '',
            type: MessageType.values.firstWhere(
              (e) => e.name == (json['type']?.toString() ?? 'text'),
              orElse: () => MessageType.text,
            ),
            codeLanguage: json['codeLanguage']?.toString(),
            codeSource: json['codeSource']?.toString(),
            reactions: reactionsList,
            isRead: isReadBool,
            createdAt:
                DateTime.tryParse(
                  json['createdAt']?.toString() ??
                      json['created_at']?.toString() ??
                      '',
                ) ??
                DateTime.now(),
          );
        }).toList();
      } catch (_) {
        rethrow;
      }
    }
    final db = await _database.database;
    final rows = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows
        .map(
          (row) => Message(
            id: row['id']?.toString() ?? '',
            senderId: row['sender_id']?.toString() ?? '',
            content: row['content']?.toString() ?? '',
            type: MessageType.values.firstWhere(
              (e) => e.name == (row['type']?.toString() ?? 'text'),
              orElse: () => MessageType.text,
            ),
            codeLanguage: row['code_language']?.toString(),
            codeSource: row['code_source']?.toString(),
            reactions:
                (row['reactions']?.toString() ?? '')
                    .split('|')
                    .where((e) => e.isNotEmpty)
                    .toList(),
            isRead: (row['is_read'] as int?) == 1,
            createdAt:
                DateTime.tryParse(row['created_at']?.toString() ?? '') ??
                DateTime.now(),
          ),
        )
        .toList();
  }

  Future<Message> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
    String? codeLanguage,
    String? codeSource,
  }) async {
    final userId = AppPreferences.instance.userId;
    if (userId == null) throw Exception('User not logged in');

    if (_useApi) {
      final data = await ApiService.instance
          .post('/chat/conversations/$conversationId/messages', {
            'content': content,
            'type': type.name,
            if (codeLanguage != null) 'codeLanguage': codeLanguage,
            if (codeSource != null) 'codeSource': codeSource,
          });
      return Message(
        id: data['id']?.toString() ?? '',
        senderId: userId,
        content: content,
        type: type,
        codeLanguage: codeLanguage,
        codeSource: codeSource,
        createdAt: DateTime.now(),
      );
    }

    final db = await _database.database;
    final now = DateTime.now();
    final id = 'm${now.millisecondsSinceEpoch}';
    final message = Message(
      id: id,
      senderId: userId,
      content: content,
      type: type,
      codeLanguage: codeLanguage,
      codeSource: codeSource,
      createdAt: now,
    );

    await db.insert('messages', {
      'id': message.id,
      'conversation_id': conversationId,
      'sender_id': message.senderId,
      'content': message.content,
      'type': message.type.name,
      'code_language': message.codeLanguage,
      'code_source': message.codeSource,
      'reactions': '',
      'is_read': 0,
      'created_at': message.createdAt.toIso8601String(),
    });

    await db.update(
      'conversations',
      {'last_message': content, 'updated_at': now.toIso8601String()},
      where: 'id = ?',
      whereArgs: [conversationId],
    );

    return message;
  }

  Future<Message> addReaction({
    required String conversationId,
    required String messageId,
    required String reaction,
  }) async {
    if (_useApi) {
      final data = await ApiService.instance.post(
        '/chat/conversations/$conversationId/messages/$messageId/reactions',
        {'reaction': reaction},
      );
      if (data.isNotEmpty) {
        final reactions = data['reactions'];
        final parsedReactions =
            reactions is List
                ? reactions.map((e) => e.toString()).toList()
                : reactions
                        ?.toString()
                        .split('|')
                        .where((e) => e.isNotEmpty)
                        .toList() ??
                    const <String>[];
        return Message(
          id: data['id']?.toString() ?? messageId,
          senderId:
              data['senderId']?.toString() ??
              data['sender_id']?.toString() ??
              '',
          content: data['content']?.toString() ?? '',
          type: MessageType.values.firstWhere(
            (e) => e.name == (data['type']?.toString() ?? 'text'),
            orElse: () => MessageType.text,
          ),
          codeLanguage: data['codeLanguage']?.toString(),
          codeSource: data['codeSource']?.toString(),
          reactions: parsedReactions,
          isRead: data['isRead'] == true || data['is_read'] == 1,
          createdAt:
              DateTime.tryParse(
                data['createdAt']?.toString() ??
                    data['created_at']?.toString() ??
                    '',
              ) ??
              DateTime.now(),
        );
      }
      throw const FormatException('Invalid reaction response shape.');
    }

    final db = await _database.database;
    final rows = await db.query(
      'messages',
      where: 'id = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    final current =
        rows.isNotEmpty
            ? (rows.first['reactions']?.toString() ?? '')
                .split('|')
                .where((e) => e.isNotEmpty)
                .toSet()
            : <String>{};
    if (current.contains(reaction)) {
      current.remove(reaction);
    } else {
      current.add(reaction);
    }
    await db.update(
      'messages',
      {'reactions': current.join('|')},
      where: 'id = ?',
      whereArgs: [messageId],
    );
    final messages = await getMessages(conversationId);
    return messages.firstWhere((message) => message.id == messageId);
  }

  Future<void> markAsRead(String conversationId) async {
    if (_useApi) {
      await ApiService.instance.patch(
        '/chat/conversations/$conversationId/read',
        {},
      );
    }
    final db = await _database.database;
    await db.update(
      'messages',
      {'is_read': 1},
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );
    await db.update(
      'conversations',
      {'unread_count': 0},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<void> _saveConversationsToDb(List<Conversation> conversations) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      for (final conv in conversations) {
        await txn.insert('conversations', {
          'id': conv.id,
          'other_user_id': conv.otherUser.id,
          'last_message': conv.lastMessage,
          'unread_count': conv.unreadCount,
          'updated_at': conv.updatedAt.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Conversation>> _conversationsFromRows(
    List<Map<String, Object?>> rows,
  ) async {
    // This is a simplified version - in production you'd join with users table
    return rows
        .map(
          (row) => Conversation(
            id: row['id']?.toString() ?? '',
            otherUser: User(
              id: row['other_user_id']?.toString() ?? '',
              username: '',
              displayName: 'Unknown User',
              email: '',
              createdAt: DateTime.now(),
            ),
            lastMessage: row['last_message']?.toString() ?? '',
            unreadCount: row['unread_count'] as int? ?? 0,
            updatedAt:
                DateTime.tryParse(row['updated_at']?.toString() ?? '') ??
                DateTime.now(),
          ),
        )
        .toList();
  }

  // Additional methods used by screens

  Future<List<User>> getOnlineUsers() async {
    if (_useApi) {
      try {
        final data = await ApiService.instance.get('/users');
        final users =
            data
                .map(
                  (json) =>
                      ModelMappers.userFromJson(json as Map<String, dynamic>),
                )
                .toList();
        return users.where((u) => u.isOnline).toList();
      } catch (_) {
        rethrow;
      }
    }
    final db = await _database.database;
    final rows = await db.query('users', where: 'is_online = 1');
    return rows.map(ModelMappers.userFromRow).toList();
  }

  Future<User?> getConversationOtherUser(String conversationId) async {
    final conv = await getConversationById(conversationId);
    return conv?.otherUser;
  }

  Future<void> markConversationRead(String conversationId) async {
    await markAsRead(conversationId);
  }

  Future<void> deleteConversation(String conversationId) async {
    if (_useApi) {
      await ApiService.instance.delete('/chat/conversations/$conversationId');
    }

    final db = await _database.database;
    await db.delete(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );
    await db.delete(
      'conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }
}
