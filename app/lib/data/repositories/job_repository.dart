import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../core/services/api_service.dart';
import '../mappers/model_mapper.dart';

class JobRepository {
  JobRepository({AppDatabase? database, bool useApi = true})
      : _database = database ?? AppDatabase.instance,
        _useApi = useApi;

  final AppDatabase _database;
  final bool _useApi;

  Future<List<Job>> getJobs({int limit = 50}) async {
    if (_useApi) {
      final data = await ApiService.instance.get('/api/jobs', queryParams: {'limit': limit});
      final jobs = data.map((json) => ModelMappers.jobFromJson(json as Map<String, dynamic>)).toList();
      await _saveJobsToDb(jobs);
      return jobs;
    }
    final db = await _database.database;
    final rows = await db.query('jobs', orderBy: 'created_at DESC', limit: limit);
    return _jobsFromRows(rows);
  }

  Future<Job?> getJobById(String id) async {
    if (_useApi) {
      final data = await ApiService.instance.getObject('/api/jobs/$id');
      return ModelMappers.jobFromJson(data);
    }
    final db = await _database.database;
    final rows = await db.query('jobs', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return _jobsFromRows(rows).first;
  }

  Future<List<Job>> searchJobs({
    String? query,
    List<String>? techStack,
    bool? remote,
  }) async {
    if (_useApi) {
      final params = <String, dynamic>{};
      if (query != null) params['q'] = query;
      if (techStack != null && techStack.isNotEmpty) params['tech'] = techStack.join(',');
      if (remote != null) params['remote'] = remote;
      final data = await ApiService.instance.get('/api/jobs/search', queryParams: params);
      return data.map((json) => ModelMappers.jobFromJson(json as Map<String, dynamic>)).toList();
    }
    final db = await _database.database;
    final rows = await db.query(
      'jobs',
      where: 'title LIKE ? OR company LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
      limit: 20,
    );
    return _jobsFromRows(rows);
  }

  Future<bool> applyForJob(String jobId) async {
    if (_useApi) {
      await ApiService.instance.post('/api/jobs/$jobId/apply', {});
      return true;
    }
    return true;
  }

  Future<void> _saveJobsToDb(List<Job> jobs) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      for (final job in jobs) {
        await txn.insert('jobs', ModelMappers.jobToRow(job),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  List<Job> _jobsFromRows(List<Map<String, Object?>> rows) {
    return rows.map((row) => Job(
      id: row['id']?.toString() ?? '',
      company: row['company']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      location: row['location']?.toString() ?? '',
      remote: (row['remote'] as int?) == 1,
      salaryRange: row['salary_range']?.toString() ?? '',
      techStack: (row['tech_stack']?.toString() ?? '').split('|').where((e) => e.isNotEmpty).toList(),
      experience: row['experience']?.toString() ?? '',
      matchPercent: row['match_percent'] as int? ?? 0,
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
    )).toList();
  }
}
