import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/services/api_service.dart';
import '../../core/services/app_preferences.dart';

/// Interaction types tracked for recommendation engine.
enum InteractionType { view, like, comment, bookmark }

/// Repository for user-post interactions — offline-first with API sync.
class InteractionRepository {
  InteractionRepository({AppDatabase? database, bool useApi = true})
    : _database = database ?? AppDatabase.instance,
      _useApi = useApi;

  final AppDatabase _database;
  final bool _useApi;

  String? get _currentUserId => AppPreferences.instance.userId;

  /// Track a user interaction with a post.
  ///
  /// Uses INSERT ... ON CONFLICT DO NOTHING semantics to avoid
  /// duplicate tracking for the same user+post+type combination.
  Future<void> trackInteraction({
    required String postId,
    required InteractionType type,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return; // anonymous users: skip tracking

    if (_useApi) {
      try {
        // Map to existing backend endpoints that implicitly track
        switch (type) {
          case InteractionType.view:
            await ApiService.instance.post('/posts/$postId/view', {
              'userId': userId,
            });
          case InteractionType.like:
          case InteractionType.comment:
          case InteractionType.bookmark:
            // These are already tracked by the backend when the
            // corresponding action endpoints are called, so we
            // only store locally here.
            break;
        }
      } catch (error) {
        debugPrint('InteractionRepository.trackInteraction API: $error');
        // Silently fall through to local tracking
      }
    }

    // Always store locally for offline mode
    await _saveLocalInteraction(userId, postId, type);
  }

  /// Fetch all interactions for the current user (for feed personalization).
  Future<List<Map<String, dynamic>>> getUserInteractions() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    if (_useApi) {
      try {
        final data = await ApiService.instance.get('/users/me/interactions');
        return List<Map<String, dynamic>>.from(data);
      } catch (error) {
        debugPrint('InteractionRepository.getUserInteractions API: $error');
      }
    }

    return _fetchLocalInteractions(userId);
  }

  /// Get interaction counts per type for a given user.
  Future<Map<InteractionType, int>> getInteractionCounts() async {
    final userId = _currentUserId;
    if (userId == null) return {};

    final interactions = await getUserInteractions();
    final counts = <InteractionType, int>{};
    for (final interaction in interactions) {
      final typeStr =
          (interaction['interaction_type'] ?? interaction['interactionType'])
              as String?;
      if (typeStr == null) continue;
      final type = InteractionType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => InteractionType.view,
      );
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  // ---- Local SQLite helpers ----

  Future<void> _saveLocalInteraction(
    String userId,
    String postId,
    InteractionType type,
  ) async {
    final db = await _database.database;
    await db.insert('user_post_interactions', {
      'user_id': userId,
      'post_id': postId,
      'interaction_type': type.name,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, dynamic>>> _fetchLocalInteractions(
    String userId,
  ) async {
    final db = await _database.database;
    final rows = await db.query(
      'user_post_interactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows;
  }

  /// Clear all local interactions (e.g., on logout).
  Future<void> clearLocalInteractions() async {
    final db = await _database.database;
    await db.delete('user_post_interactions');
  }
}
