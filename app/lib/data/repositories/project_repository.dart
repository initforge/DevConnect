import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../core/services/api_service.dart';
import '../mappers/model_mapper.dart';

class ProjectRepository {
  ProjectRepository({AppDatabase? database, bool useApi = true})
    : _database = database ?? AppDatabase.instance,
      _useApi = useApi;

  final AppDatabase _database;
  final bool _useApi;

  Future<List<Project>> getProjects({int limit = 50}) async {
    if (_useApi) {
      final data = await ApiService.instance.get(
        '/api/projects',
        queryParams: {'limit': limit},
      );
      final projects =
          data
              .map(
                (json) =>
                    ModelMappers.projectFromJson(json as Map<String, dynamic>),
              )
              .toList();
      await _saveProjectsToDb(projects);
      return projects;
    }
    final db = await _database.database;
    final rows = await db.query(
      'projects',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return _projectsFromRows(rows);
  }

  Future<Project?> getProjectById(String id) async {
    if (_useApi) {
      final data = await ApiService.instance.getObject('/api/projects/$id');
      return ModelMappers.projectFromJson(data);
    }
    final db = await _database.database;
    final rows = await db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _projectsFromRows(rows).first;
  }

  Future<List<Project>> searchProjects(String query) async {
    if (_useApi) {
      final data = await ApiService.instance.get(
        '/api/projects/search',
        queryParams: {'q': query},
      );
      return data
          .map(
            (json) =>
                ModelMappers.projectFromJson(json as Map<String, dynamic>),
          )
          .toList();
    }
    final db = await _database.database;
    final rows = await db.query(
      'projects',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
      limit: 20,
    );
    return _projectsFromRows(rows);
  }

  Future<bool> joinProject(String projectId) async {
    if (_useApi) {
      final result = await ApiService.instance.post(
        '/api/projects/$projectId/join',
        {},
      );
      return result['joined'] == true || result['success'] == true;
    }
    final db = await _database.database;
    await db.rawUpdate(
      'UPDATE projects SET member_count = member_count + 1 WHERE id = ?',
      [projectId],
    );
    return true;
  }

  Future<Project> createProject({
    required String title,
    required String description,
    required List<String> techStack,
    required int maxMembers,
  }) async {
    if (_useApi) {
      final data = await ApiService.instance.post('/api/projects', {
        'title': title,
        'description': description,
        'techStack': techStack,
        'maxMembers': maxMembers,
      });
      final project = ModelMappers.projectFromJson(data);
      await _saveProjectsToDb([project]);
      return project;
    }

    throw UnsupportedError('Project creation requires API mode');
  }

  Future<void> _saveProjectsToDb(List<Project> projects) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      for (final project in projects) {
        await txn.insert(
          'projects',
          ModelMappers.projectToRow(project),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  List<Project> _projectsFromRows(List<Map<String, Object?>> rows) {
    return rows
        .map(
          (row) => Project(
            id: row['id']?.toString() ?? '',
            owner: User(
              id: row['owner_id']?.toString() ?? '',
              username: '',
              displayName: 'Unknown',
              email: '',
              createdAt: DateTime.now(),
            ),
            title: row['title']?.toString() ?? '',
            description: row['description']?.toString() ?? '',
            techStack:
                (row['tech_stack']?.toString() ?? '')
                    .split('|')
                    .where((e) => e.isNotEmpty)
                    .toList(),
            status: row['status']?.toString() ?? 'LOOKING_FOR_MEMBERS',
            memberCount: row['member_count'] as int? ?? 0,
            maxMembers: row['max_members'] as int? ?? 5,
            createdAt:
                DateTime.tryParse(row['created_at']?.toString() ?? '') ??
                DateTime.now(),
          ),
        )
        .toList();
  }
}
