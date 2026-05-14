import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../core/services/api_service.dart';
import '../../core/services/app_preferences.dart';
import '../mappers/model_mapper.dart';

class JobRepository {
  JobRepository({AppDatabase? database, bool useApi = true})
      : _database = database ?? AppDatabase.instance,
        _useApi = useApi;

  final AppDatabase _database;
  final bool _useApi;

  Future<List<Job>> getJobs({int limit = 50}) async {
    if (_useApi) {
      final data = await ApiService.instance.get('/jobs', queryParams: {'limit': limit});
      final jobs = data.map((json) {
        final job = ModelMappers.jobFromJson(json as Map<String, dynamic>);
        final currentUser = _getCurrentUser();
        final computedMatch = currentUser != null ? _computeMatchPercent(job, currentUser) : job.matchPercent;
        return job.copyWith(matchPercent: computedMatch);
      }).toList();
      await _saveJobsToDb(jobs);
      return jobs;
    }
    final db = await _database.database;
    final rows = await db.query('jobs', orderBy: 'created_at DESC', limit: limit);
    return _jobsFromRows(rows);
  }

  Future<Job?> getJobById(String id) async {
    if (_useApi) {
      final data = await ApiService.instance.getObject('/jobs/$id');
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
      final data = await ApiService.instance.get('/jobs/search', queryParams: params);
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

  Future<Job> createJob({
    required String title,
    required String company,
    required String location,
    required bool remote,
    required String salaryRange,
    required List<String> techStack,
    required String experience,
  }) async {
    if (_useApi) {
      final data = await ApiService.instance.post('/jobs', {
        'title': title,
        'company': company,
        'location': location,
        'remote': remote,
        'salaryRange': salaryRange,
        'techStack': techStack,
        'experience': experience,
      });
      final job = ModelMappers.jobFromJson(data);
      await _saveJobsToDb([job]);
      return job;
    }
    throw UnsupportedError('Job creation requires API mode');
  }

  Future<bool> applyForJob(String jobId) async {
    if (_useApi) {
      await ApiService.instance.post('/jobs/$jobId/apply', {});
      return true;
    }
    return true;
  }

  Future<List<Application>> getMyApplications() async {
    final data = await ApiService.instance.get('/users/me/applications');
    return data.map((json) => Application.fromJson(json as Map<String, dynamic>)).toList();
  }

  int _computeMatchPercent(Job job, User currentUser) {
    if (currentUser.skills.isEmpty || job.techStack.isEmpty) return 0;
    final userSkills = currentUser.skills.map((s) => s.toLowerCase()).toSet();
    final jobSkills = job.techStack.map((s) => s.toLowerCase()).toSet();
    final overlap = userSkills.intersection(jobSkills);
    return jobSkills.isNotEmpty ? ((overlap.length / jobSkills.length) * 100).round() : 0;
  }

  User? _getCurrentUser() {
    try {
      final userData = AppPreferences.instance.user;
      if (userData == null) return null;
      return User.fromJson(userData);
    } catch (_) {
      return null;
    }
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
