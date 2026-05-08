import 'package:sqflite/sqflite.dart';
import 'package:devconnect/core/database/app_database.dart';

/// Base repository with common CRUD operations
/// Uses offline-first strategy: reads from local DB, syncs with API
abstract class BaseRepository<T> {
  BaseRepository({
    AppDatabase? database,
    required String tableName,
    required Map<String, dynamic> Function(T) toRow,
    required T Function(Map<String, Object?>) fromRow,
  })  : _database = database ?? AppDatabase.instance,
        _tableName = tableName,
        _toRow = toRow,
        _fromRow = fromRow;

  final AppDatabase _database;
  final String _tableName;
  final Map<String, dynamic> Function(T) _toRow;
  final T Function(Map<String, Object?>) _fromRow;

  /// Get all items from local DB
  Future<List<T>> getAll({
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      _tableName,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    return rows.map(_fromRow).toList();
  }

  /// Get single item by ID
  Future<T?> getById(String id) async {
    final db = await _database.database;
    final rows = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  /// Insert or update item
  Future<void> save(T item) async {
    final db = await _database.database;
    await db.insert(
      _tableName,
      _toRow(item),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Save multiple items
  Future<void> saveAll(List<T> items) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      for (final item in items) {
        await txn.insert(
          _tableName,
          _toRow(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Delete item by ID
  Future<void> delete(String id) async {
    final db = await _database.database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all items
  Future<void> deleteAll() async {
    final db = await _database.database;
    await db.delete(_tableName);
  }

  /// Query with custom where clause
  Future<List<T>> query({
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      _tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    return rows.map(_fromRow).toList();
  }

  /// Count items
  Future<int> count({String? where, List<Object?>? whereArgs}) async {
    final db = await _database.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM $_tableName${where != null ? ' WHERE $where' : ''}',
      whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Update specific fields
  Future<int> update(String id, Map<String, Object?> values) async {
    final db = await _database.database;
    return await db.update(
      _tableName,
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
