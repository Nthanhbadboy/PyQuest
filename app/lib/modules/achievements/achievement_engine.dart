import 'package:flutter/foundation.dart';

import '../../core/clock.dart';
import '../../core/events.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/state_repositories.dart';
import 'achievement_catalog.dart';

/// Evaluates badges after every event. Unlocks are stored once (primary key)
/// so replaying or retrying can never award a badge twice.
class AchievementEngine extends ChangeNotifier implements GameEventListener {
  AchievementEngine({
    required AppDatabase db,
    required AchievementRepository repo,
    required ProgressRepository progress,
    required CustomLevelRepository customLevels,
    required Clock clock,
  })  : _db = db,
        _repo = repo,
        _progress = progress,
        _custom = customLevels,
        _clock = clock;

  final AppDatabase _db;
  final AchievementRepository _repo;
  final ProgressRepository _progress;
  final CustomLevelRepository _custom;
  final Clock _clock;

  Map<String, DateTime> _unlocked = {};
  Map<String, DateTime> get unlocked => Map.unmodifiable(_unlocked);
  int _unseen = 0;
  int get unseenCount => _unseen;

  Future<void> init() async {
    _unlocked = await _repo.unlocked();
    _unseen = await _repo.unseenCount();
  }

  bool isUnlocked(String id) => _unlocked.containsKey(id);

  Future<void> markAllSeen() async {
    await _repo.markAllSeen();
    _unseen = 0;
    notifyListeners();
  }

  Future<ProgressSnapshot> snapshot() async {
    final sql = _db.db;
    final levelRows = await sql.rawQuery(
        'SELECT game_id, COUNT(*) AS c, SUM(CASE WHEN stars >= 3 THEN 1 ELSE 0 END) AS s3 '
        'FROM game_results WHERE stars > 0 GROUP BY game_id');
    final scoreRows = await sql.rawQuery('SELECT game_id, level_id, high_score FROM game_results');
    final storeRows = await sql.rawQuery('SELECT game_id, key, value FROM game_store');
    final claims = <String, int>{};
    for (final prefix in const ['bug:', 'cond_ex:', 'loop:', 'chapter:', 'exercise:']) {
      claims[prefix] = await _progress.countClaims(prefix);
    }
    claims['chapter:code_apprentice'] = await _progress.isClaimed('chapter:code_apprentice') ? 1 : 0;
    final storeInts = <String, int>{};
    for (final r in storeRows) {
      final v = int.tryParse(r['value'] as String);
      if (v != null) storeInts['${r['game_id']}/${r['key']}'] = v;
    }
    return ProgressSnapshot(
      completedLessons: await _progress.completedLessons(),
      completedLevels: {for (final r in levelRows) r['game_id'] as String: (r['c'] as int?) ?? 0},
      threeStarLevels: {for (final r in levelRows) r['game_id'] as String: (r['s3'] as int?) ?? 0},
      bestScores: {for (final r in scoreRows) '${r['game_id']}/${r['level_id']}': r['high_score'] as int},
      claimCounts: claims,
      visitedActivities: await _progress.claimsWithPrefix('visited:'),
      verifiedCreations: await _custom.countVerified(),
      storeInts: storeInts,
    );
  }

  @override
  Future<void> onEvent(StandardEvent event, EventOutcome outcome) async {
    final pending = achievementCatalog.where((a) => !_unlocked.containsKey(a.id)).toList();
    if (pending.isEmpty) return;
    final snap = await snapshot();
    var changed = false;
    for (final def in pending) {
      if (!def.check(snap, event)) continue;
      final now = _clock.now();
      if (await _repo.unlock(def.id, now)) {
        _unlocked[def.id] = now;
        _unseen++;
        changed = true;
        outcome.notices.add(RewardNotice(
          kind: RewardKind.badge,
          id: def.id,
          title: def.title,
          description: def.description,
        ));
      }
    }
    if (changed) notifyListeners();
  }
}
