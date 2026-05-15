import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../core/services/api_service.dart';
import '../mappers/model_mapper.dart';

class LeaderboardRepository {
  LeaderboardRepository({AppDatabase? database, bool useApi = true})
    : _database = database ?? AppDatabase.instance,
      _useApi = useApi;

  final AppDatabase _database;
  final bool _useApi;

  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 50}) async {
    if (_useApi) {
      final data = await ApiService.instance.get(
        '/leaderboard',
        queryParams: {'limit': limit},
      );
      final entries =
          data
              .map(
                (item) =>
                    LeaderboardEntry.fromJson(item as Map<String, dynamic>),
              )
              .toList();
      await _saveUsersToDb(entries.map((e) => e.user).toList());
      return entries;
    }

    final db = await _database.database;
    final rows = await db.query(
      'users',
      orderBy: 'reputation DESC',
      limit: limit,
    );
    return rows.asMap().entries.map((entry) {
      final user = ModelMappers.userFromRow(entry.value);
      return LeaderboardEntry(
        rank: entry.key + 1,
        user: user,
        points: user.reputation,
        rankChange: 0,
      );
    }).toList();
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
}
