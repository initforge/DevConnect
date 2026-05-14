import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../core/services/api_service.dart';
import '../mappers/model_mapper.dart';

class NotificationRepository {
  NotificationRepository({AppDatabase? database, bool useApi = true})
    : _database = database ?? AppDatabase.instance,
      _useApi = useApi;

  final AppDatabase _database;
  final bool _useApi;

  Future<List<AppNotification>> getNotifications({int limit = 50}) async {
    if (_useApi) {
      try {
        final data = await ApiService.instance.get(
          '/notifications',
          queryParams: {'limit': limit},
        );
        final notifications =
            data
                .map(
                  (json) => ModelMappers.notificationFromJson(
                    json as Map<String, dynamic>,
                  ),
                )
                .toList();
        await _saveNotificationsToDb(notifications);
        return notifications;
      } catch (_) {
        rethrow;
      }
    }
    final db = await _database.database;
    final rows = await db.query(
      'notifications',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return _notificationsFromRows(rows);
  }

  Future<void> markAsRead(String notificationId) async {
    if (_useApi) {
      await ApiService.instance.patch(
        '/notifications/$notificationId/read',
        {},
      );
    }
    final db = await _database.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  Future<void> markAllAsRead() async {
    if (_useApi) {
      await ApiService.instance.patch('/notifications/read-all', {});
    }
    final db = await _database.database;
    await db.update('notifications', {'is_read': 1});
  }

  Future<int> getUnreadCount() async {
    if (_useApi) {
      try {
        final data = await ApiService.instance.getObject(
          '/notifications/count',
        );
        return data['count'] as int? ?? 0;
      } catch (_) {
        rethrow;
      }
    }
    final db = await _database.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM notifications WHERE is_read = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> _saveNotificationsToDb(
    List<AppNotification> notifications,
  ) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      for (final notification in notifications) {
        await txn.insert('notifications', {
          'id': notification.id,
          'type': notification.type,
          'title': notification.title,
          'body': notification.body,
          'from_user_id': notification.fromUser?.id,
          'is_read': notification.isRead ? 1 : 0,
          'merged_count': notification.mergedCount,
          'created_at': notification.createdAt.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  List<AppNotification> _notificationsFromRows(
    List<Map<String, Object?>> rows,
  ) {
    return rows
        .map(
          (row) => AppNotification(
            id: row['id']?.toString() ?? '',
            type: row['type']?.toString() ?? '',
            title: row['title']?.toString() ?? '',
            body: row['body']?.toString() ?? '',
            fromUser: null,
            isRead: (row['is_read'] as int?) == 1,
            mergedCount: row['merged_count'] as int? ?? 1,
            createdAt:
                DateTime.tryParse(row['created_at']?.toString() ?? '') ??
                DateTime.now(),
          ),
        )
        .toList();
  }
}
