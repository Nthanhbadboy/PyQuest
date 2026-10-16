import 'package:flutter/foundation.dart';

import '../../core/clock.dart';
import '../../core/events.dart';
import '../../data/repositories/state_repositories.dart';

enum QuestCategory { learn, practice, create }

class DailyQuestDef {
  const DailyQuestDef({
    required this.id,
    required this.title,
    required this.category,
    required this.target,
    required this.matches,
    this.requiresBugHunter = false,
  });

  final String id;
  final String title;
  final QuestCategory category;
  final int target;
  final bool Function(StandardEvent e) matches;
  final bool requiresBugHunter;
}

final List<DailyQuestDef> dailyQuestPool = [
  DailyQuestDef(
    id: 'lesson_1',
    title: 'Hoàn thành 1 bài học Main Quest',
    category: QuestCategory.learn,
    target: 1,
    matches: (e) => e.type == EventTypes.lessonCompleted,
  ),
  DailyQuestDef(
    id: 'code_runs_3',
    title: 'Chạy code Python 3 lần',
    category: QuestCategory.learn,
    target: 3,
    matches: (e) => e.type == EventTypes.codeRun,
  ),
  DailyQuestDef(
    id: 'three_stars',
    title: 'Đạt 3 sao ở một màn bất kỳ',
    category: QuestCategory.practice,
    target: 1,
    matches: (e) => e.type == EventTypes.levelCompleted && (e.get<int>('stars') ?? 0) >= 3,
  ),
  DailyQuestDef(
    id: 'maze_2',
    title: 'Vượt qua 2 màn Robot Maze',
    category: QuestCategory.practice,
    target: 2,
    matches: (e) => e.type == EventTypes.levelCompleted && e.sourceId == 'robot_maze',
  ),
  DailyQuestDef(
    id: 'arcade_star',
    title: 'Nhận sao trong Rồng Nhảy hoặc Hái Sao',
    category: QuestCategory.practice,
    target: 1,
    matches: (e) =>
        e.type == EventTypes.levelCompleted && (e.sourceId == 'dragon_jump' || e.sourceId == 'catch_stars'),
  ),
  DailyQuestDef(
    id: 'bug_1',
    title: 'Sửa 1 lỗi cùng Bitsy',
    category: QuestCategory.practice,
    target: 1,
    requiresBugHunter: true,
    matches: (e) => e.type == EventTypes.bugFixed,
  ),
  DailyQuestDef(
    id: 'creator_test',
    title: 'Chạy thử một mê cung trong Xưởng Mê Cung',
    category: QuestCategory.create,
    target: 1,
    matches: (e) => e.type == EventTypes.creatorTestRun,
  ),
  DailyQuestDef(
    id: 'robot_code',
    title: 'Điều khiển Robo bằng code Python',
    category: QuestCategory.create,
    target: 1,
    matches: (e) => e.type == EventTypes.codeRun && e.data['context'] == 'robot' && e.data['success'] == true,
  ),
];

class DailyQuestState {
  const DailyQuestState(this.def, this.progress, this.completed, this.rewarded);
  final DailyQuestDef def;
  final int progress;
  final bool completed;
  final bool rewarded;
}

/// Three quests per local day, reset at local midnight. No streaks, no
/// purchase or ad quests; finishing one gives a stamp of recognition.
class DailyQuestService extends ChangeNotifier implements GameEventListener {
  DailyQuestService(this._repo, this._clock, {required this.isBugHunterUnlocked});

  final DailyQuestRepository _repo;
  final Clock _clock;
  final Future<bool> Function() isBugHunterUnlocked;

  String _day = '';
  List<DailyQuestState> _quests = [];
  int _stamps = 0;

  List<DailyQuestState> get quests => List.unmodifiable(_quests);
  int get totalStamps => _stamps;
  int get claimable => _quests.where((q) => q.completed && !q.rewarded).length;

  Future<void> ensureToday({bool force = false}) async {
    final today = localDayKey(_clock.now());
    if (!force && today == _day && _quests.isNotEmpty) return;
    var rows = await _repo.forDay(today);
    if (rows.isEmpty) {
      await _repo.createDay(today, await _pickFor(today));
      rows = await _repo.forDay(today);
    }
    _day = today;
    _quests = [
      for (final r in rows)
        if (_defById(r.questId) != null) DailyQuestState(_defById(r.questId)!, r.progress, r.completed, r.rewarded),
    ];
    _stamps = await _repo.totalStamps();
    notifyListeners();
  }

  DailyQuestDef? _defById(String id) {
    for (final d in dailyQuestPool) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<List<String>> _pickFor(String day) async {
    final bugUnlocked = await isBugHunterUnlocked();
    final seed = day.codeUnits.fold<int>(7, (h, c) => (h * 31 + c) & 0x7fffffff);
    final picks = <String>[];
    for (final cat in QuestCategory.values) {
      final options = dailyQuestPool.where((q) => q.category == cat && (!q.requiresBugHunter || bugUnlocked)).toList();
      if (options.isEmpty) continue;
      picks.add(options[(seed ~/ (cat.index + 1)) % options.length].id);
    }
    return picks;
  }

  Future<bool> claimStamp(String questId) async {
    final ok = await _repo.markRewarded(_day, questId);
    if (ok) {
      _quests = [
        for (final q in _quests)
          q.def.id == questId ? DailyQuestState(q.def, q.progress, q.completed, true) : q,
      ];
      _stamps++;
      notifyListeners();
    }
    return ok;
  }

  @override
  Future<void> onEvent(StandardEvent event, EventOutcome outcome) async {
    await ensureToday();
    var changed = false;
    final updated = <DailyQuestState>[];
    for (final q in _quests) {
      if (!q.completed && q.def.matches(event)) {
        final progress = q.progress + 1;
        final done = progress >= q.def.target;
        await _repo.update(_day, q.def.id, progress: progress, completed: done);
        updated.add(DailyQuestState(q.def, progress, done, q.rewarded));
        changed = true;
        if (done) {
          outcome.notices.add(RewardNotice(
            kind: RewardKind.quest,
            id: q.def.id,
            title: 'Nhiệm vụ hôm nay hoàn thành!',
            description: q.def.title,
          ));
        }
      } else {
        updated.add(q);
      }
    }
    if (changed) {
      _quests = updated;
      notifyListeners();
    }
  }
}
