import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/models/models.dart';
import '../../core/services/api_service.dart';
import '../../core/services/app_preferences.dart';
import '../mappers/model_mapper.dart';

class UserRepository {
  UserRepository({AppDatabase? database, bool useApi = true})
    : _database = database ?? AppDatabase.instance,
      _useApi = useApi;

  final AppDatabase _database;
  final bool _useApi;

  Future<User?> getCurrentUser() async {
    final userId = AppPreferences.instance.userId;
    if (userId != null) {
      final user = await getUserById(userId);
      if (user != null) return user;
    }

    final cachedUser = AppPreferences.instance.user;
    if (cachedUser != null) {
      final user = ModelMappers.userFromJson(cachedUser);
      await _saveUserToDb(user);
      return user;
    }

    final db = await _database.database;
    final rows = await db.query('users', orderBy: 'created_at ASC', limit: 1);
    if (rows.isEmpty) return null;
    return ModelMappers.userFromRow(rows.first);
  }

  Future<List<User>> getAllUsers() async {
    if (_useApi) {
      final data = await ApiService.instance.get('/users');
      final users =
          data
              .map(
                (json) =>
                    ModelMappers.userFromJson(json as Map<String, dynamic>),
              )
              .toList();
      await _saveUsersToDb(users);
      return users;
    }
    final db = await _database.database;
    final rows = await db.query('users', orderBy: 'created_at DESC');
    return rows.map(ModelMappers.userFromRow).toList();
  }

  Future<List<User>> getTopUsers({int limit = 6}) async {
    if (_useApi) {
      final data = await ApiService.instance.get('/users');
      final users =
          data
              .take(limit)
              .map(
                (json) =>
                    ModelMappers.userFromJson(json as Map<String, dynamic>),
              )
              .toList();
      await _saveUsersToDb(users);
      return users;
    }
    final db = await _database.database;
    final rows = await db.query(
      'users',
      orderBy: 'reputation DESC',
      limit: limit,
    );
    return rows.map(ModelMappers.userFromRow).toList();
  }

  Future<User?> getUserById(String id) async {
    if (_useApi) {
      final data = await ApiService.instance.getObject('/users/$id');
      final user = ModelMappers.userFromJson(data);
      await _saveUserToDb(user);
      return user;
    }
    final db = await _database.database;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ModelMappers.userFromRow(rows.first);
  }

  Future<List<User>> getLeaderboard() async {
    if (_useApi) {
      final data = await ApiService.instance.get('/leaderboard');
      final List<dynamic> dataList = data;
      final users =
          dataList
              .map(
                (item) => ModelMappers.userFromJson(
                  (item as Map<String, dynamic>)['user']
                      as Map<String, dynamic>,
                ),
              )
              .toList();
      await _saveUsersToDb(users);
      return users;
    }
    final db = await _database.database;
    final rows = await db.query('users', orderBy: 'reputation DESC', limit: 20);
    return rows.map(ModelMappers.userFromRow).toList();
  }

  Future<List<User>> searchUsers(String query) async {
    if (query.length < 2) return [];
    if (_useApi) {
      final data = await ApiService.instance.get(
        '/users/search',
        queryParams: {'q': query},
      );
      final users =
          data
              .map(
                (json) =>
                    ModelMappers.userFromJson(json as Map<String, dynamic>),
              )
              .toList();
      return users;
    }
    final db = await _database.database;
    final rows = await db.query(
      'users',
      where: 'username LIKE ? OR display_name LIKE ? OR bio LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'reputation DESC',
      limit: 20,
    );
    return rows.map(ModelMappers.userFromRow).toList();
  }

  Future<bool> toggleFollow(String userId) async {
    if (_useApi) {
      final result = await ApiService.instance.post(
        '/users/$userId/follow',
        {},
      );
      return result['following'] == true;
    }
    final db = await _database.database;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    final isFollowed = (rows.first['is_followed_by_me'] as int? ?? 0) == 1;
    await db.update(
      'users',
      {'is_followed_by_me': isFollowed ? 0 : 1},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return !isFollowed;
  }

  Future<User> updateCurrentUser({
    required String displayName,
    String? bio,
    List<String>? skills,
  }) async {
    final userId = AppPreferences.instance.userId;
    if (userId == null) {
      throw const UnauthenticatedException();
    }

    final data = await ApiService.instance.put('/users/$userId', {
      'displayName': displayName,
      'bio': bio ?? '',
      if (skills != null) 'skills': skills,
    });

    final updatedUser = ModelMappers.userFromJson(data);
    await _saveUserToDb(updatedUser);
    await AppPreferences.instance.saveUser(data);
    return updatedUser;
  }

  Future<void> deleteCurrentUser() async {
    final userId = AppPreferences.instance.userId;
    if (userId == null) {
      throw const UnauthenticatedException();
    }

    await ApiService.instance.delete('/users/$userId');
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    final userId = AppPreferences.instance.userId;
    if (userId == null) {
      throw const UnauthenticatedException();
    }

    final data = await ApiService.instance.put('/users/$userId', {
      'isOnline': isOnline,
    });

    final updatedUser = ModelMappers.userFromJson(data);
    await _saveUserToDb(updatedUser);
    await AppPreferences.instance.saveUser(data);
  }

  Future<void> _saveUsersToDb(List<User> users) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      for (final user in users) {
        await txn.insert(
          'users',
          ModelMappers.userToRow(user),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> _saveUserToDb(User user) async {
    final db = await _database.database;
    await db.insert(
      'users',
      ModelMappers.userToRow(user),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Public mappers for testing
  User fromRow(Map<String, Object?> row) => ModelMappers.userFromRow(row);
  User fromJson(Map<String, dynamic> json) => ModelMappers.userFromJson(json);
  Map<String, dynamic> toRow(User user) => ModelMappers.userToRow(user);
}
