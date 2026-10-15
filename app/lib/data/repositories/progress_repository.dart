import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';

class LevelRecord {
  const LevelRecord({
    required this.gameId,
    required this.levelId,
    required this.stars,
    required this.highScore,
    required this.plays,
    required this.completedAt,
  });

  final String gameId;
  final String levelId;
  final int stars;
  final int highScore;
  final int plays;
  final DateTime completedAt;

  static LevelRecord fromRow(Map<String, Object?> row) => LevelRecord(
        gameId: row['game_id'] as String,
        levelId: row['level_id'] as String,
        stars: row['stars'] as int,
        highScore: row['high_score'] as int,
        plays: row['plays'] as int,
        completedAt: DateTime.fromMillisecondsSinceEpoch(row['completed_at'] as int),
      );
}

/// Outcome of saving a level result.
class LevelSaveResult {
  const LevelSaveResult({required this.firstCompletion, required this.previous, required this.current});
  final bool firstCompletion;
  final LevelRecord? previous;
  final LevelRecord current;

  bool get improvedStars => current.stars > (previous?.stars ?? 0);
  bool get newHighScore => previous != null && current.highScore > previous!.highScore;
}

/// Levels, lessons, skills and idempotent reward claims.
class ProgressRepository {
  ProgressRepository(this._db);

  final AppDatabase _db;
  Database get _sql => _db.db;

  // ------------------------------------------------------------ levels

  Future<LevelRecord?> levelRecord(String gameId, String levelId) async {
    final rows = await _sql.query('game_results',
        where: 'game_id = ? AND level_id = ?', whereArgs: [gameId, levelId], limit: 1);
    return rows.isEmpty ? null : LevelRecord.fromRow(rows.first);
  }

  Future<Map<String, LevelRecord>> levelRecords(String gameId) async {
    final rows = await _sql.query('game_results', where: 'game_id = ?', whereArgs: [gameId]);
    return {for (final r in rows) r['level_id'] as String: LevelRecord.fromRow(r)};
  }

  /// Stores the best stars / score for a completed level (stars >= 1).
  Future<LevelSaveResult> saveLevelResult({
    required String gameId,
    required String levelId,
    required int stars,
    required int score,
    required DateTime at,
  }) async {
    return _sql.transaction((txn) async {
      final rows = await txn.query('game_results',
          where: 'game_id = ? AND level_id = ?', whereArgs: [gameId, levelId], limit: 1);
      final previous = rows.isEmpty ? null : LevelRecord.fromRow(rows.first);
      if (previous == null) {
        await txn.insert('game_results', {
          'game_id': gameId,
          'level_id': levelId,
          'stars': stars,
          'high_score': score,
          'plays': 1,
          'completed_at': at.millisecondsSinceEpoch,
        });
      } else {
        await txn.update(
          'game_results',
          {
            'stars': stars > previous.stars ? stars : previous.stars,
            'high_score': score > previous.highScore ? score : previous.highScore,
            'plays': previous.plays + 1,
          },
          where: 'game_id = ? AND level_id = ?',
          whereArgs: [gameId, levelId],
        );
      }
      final current = LevelRecord(
        gameId: gameId,
        levelId: levelId,
        stars: previous == null ? stars : (stars > previous.stars ? stars : previous.stars),
        highScore: previous == null ? score : (score > previous.highScore ? score : previous.highScore),
        plays: (previous?.plays ?? 0) + 1,
        completedAt: previous?.completedAt ?? at,
      );
      return LevelSaveResult(firstCompletion: previous == null, previous: previous, current: current);
    });
  }

  Future<void> unlockLevel(String gameId, String levelId, DateTime at) async {
    await _sql.insert(
      'unlocked_levels',
      {'game_id': gameId, 'level_id': levelId, 'unlocked_at': at.millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<Set<String>> unlockedLevels(String gameId) async {
    final rows = await _sql.query('unlocked_levels', columns: ['level_id'], where: 'game_id = ?', whereArgs: [gameId]);
    return {for (final r in rows) r['level_id'] as String};
  }

  Future<int> completedLevelCount({String? gameId}) async {
    final rows = gameId == null
        ? await _sql.rawQuery('SELECT COUNT(*) AS c FROM game_results WHERE stars > 0')
        : await _sql.rawQuery('SELECT COUNT(*) AS c FROM game_results WHERE stars > 0 AND game_id = ?', [gameId]);
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<int> totalStars({String? gameId}) async {
    final rows = gameId == null
        ? await _sql.rawQuery('SELECT SUM(stars) AS s FROM game_results')
        : await _sql.rawQuery('SELECT SUM(stars) AS s FROM game_results WHERE game_id = ?', [gameId]);
    return (rows.first['s'] as int?) ?? 0;
  }

  // ----------------------------------------------------------- lessons

  /// Returns true the first time a lesson is completed.
  Future<bool> completeLesson(String lessonId, int score, DateTime at) async {
    return _sql.transaction((txn) async {
      final rows = await txn.query('progress', where: 'lesson_id = ?', whereArgs: [lessonId], limit: 1);
      if (rows.isEmpty) {
        await txn.insert('progress', {
          'lesson_id': lessonId,
          'best_score': score,
          'completed_at': at.millisecondsSinceEpoch,
        });
        return true;
      }
      final best = rows.first['best_score'] as int;
      if (score > best) {
        await txn.update('progress', {'best_score': score}, where: 'lesson_id = ?', whereArgs: [lessonId]);
      }
      return false;
    });
  }

  Future<Set<String>> completedLessons() async {
    final rows = await _sql.query('progress', columns: ['lesson_id']);
    return {for (final r in rows) r['lesson_id'] as String};
  }

  Future<Map<String, DateTime>> lessonCompletionTimes() async {
    final rows = await _sql.query('progress', columns: ['lesson_id', 'completed_at']);
    return {
      for (final r in rows) r['lesson_id'] as String: DateTime.fromMillisecondsSinceEpoch(r['completed_at'] as int),
    };
  }

  Future<void> learnSkill(String skillId, DateTime at) async {
    await _sql.insert('skills', {'skill_id': skillId, 'learned_at': at.millisecondsSinceEpoch},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<Set<String>> learnedSkills() async {
    final rows = await _sql.query('skills', columns: ['skill_id']);
    return {for (final r in rows) r['skill_id'] as String};
  }

  // ------------------------------------------------------ reward claims

  /// Idempotent: returns true only the first time [rewardKey] is claimed.
  Future<bool> claimOnce(String rewardKey, DateTime at) async {
    return _sql.transaction((txn) async {
      final rows = await txn.query('reward_claims',
          columns: ['reward_key'], where: 'reward_key = ?', whereArgs: [rewardKey], limit: 1);
      if (rows.isNotEmpty) return false;
      await txn.insert('reward_claims', {'reward_key': rewardKey, 'awarded_at': at.millisecondsSinceEpoch});
      return true;
    });
  }

  Future<bool> isClaimed(String rewardKey) async {
    final rows = await _sql.query('reward_claims', where: 'reward_key = ?', whereArgs: [rewardKey], limit: 1);
    return rows.isNotEmpty;
  }

  Future<int> countClaims(String prefix) async {
    final rows = await _sql.rawQuery(
        'SELECT COUNT(*) AS c FROM reward_claims WHERE substr(reward_key, 1, ?) = ?', [prefix.length, prefix]);
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<Set<String>> claimsWithPrefix(String prefix) async {
    final rows = await _sql.rawQuery(
        'SELECT reward_key FROM reward_claims WHERE substr(reward_key, 1, ?) = ?', [prefix.length, prefix]);
    return {for (final r in rows) (r['reward_key'] as String).substring(prefix.length)};
  }
}
