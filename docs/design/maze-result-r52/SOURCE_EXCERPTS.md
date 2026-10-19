# r52 · pinned source excerpts

Pin `bcf2bfc5088ca80f1a6f0fd1d2211032f5ce416a`; full blob SHA256 in source-manifest. Display excerpts only.

## `app/lib/modules/robot_maze/maze_play_screen.dart`

Lines 476–566:
```text
476:       _message = null;
477:     });
478:   }
479:
480:   Future<void> _onWin(RunResult result) async {
481:     final services = AppScope.of(context);
482:     final stars = MazeStars.evaluate(level, result, _commandsUsed);
483:     final cfg = services.config;
484:     final score = stars.score(
485:       complete: cfg.gameInt('robot_maze', 'score_complete', 40),
486:       gems: cfg.gameInt('robot_maze', 'score_all_gems', 30),
487:       limit: cfg.gameInt('robot_maze', 'score_command_limit', 30),
488:     );
489:     final notices = <RewardNotice>[..._pendingNotices];
490:     _pendingNotices.clear();
491:
492:     if (widget.isCustom) {
493:       final outcome = await services.events.emit(StandardEvent(
494:         type: EventTypes.creatorTestRun,
495:         sourceId: 'robot_maze',
496:         data: {'success': true},
497:       ));
498:       notices.addAll(outcome.notices);
499:       if (!mounted) return;
500:       Navigator.of(context).pop(_CustomRunReport(won: true, notices: notices, stars: stars.count));
501:       return;
502:     }
503:
504:     // Different-path secret: compare the visited cells with the previous win.
505:     final signature = result.path.map((c) => '${c.x},${c.y}').join(';');
506:     final key = 'path:${level.id}';
507:     final previous = await services.store.getString('robot_maze', key);
508:     await services.store.setString('robot_maze', key, signature);
509:     final content = services.robotMaze;
510:     final next = level.index + 1 < content.levels.length ? content.levels[level.index + 1] : null;
511:     if (_usedLoop) {
512:       final o = await services.events.emit(StandardEvent(
513:         type: EventTypes.loopUsed,
514:         sourceId: 'robot_maze',
515:         data: {'key': 'robot_maze:${level.id}'},
516:       ));
517:       notices.addAll(o.notices);
518:     }
519:     final outcome = await services.events.emit(StandardEvent(
520:       type: EventTypes.levelCompleted,
521:       sourceId: 'robot_maze',
522:       data: {
523:         'level_id': level.id,
524:         'stars': stars.count,
525:         'score': score,
526:         if (next != null) 'next_level_id': next.id,
527:         'commands': _commandsUsed,
528:         'different_path': previous != null && previous != signature,
529:       },
530:     ));
531:     notices.addAll(outcome.notices);
532:     if (!mounted) return;
533:     final nextRecord = next == null ? null : await services.progress.levelRecord('robot_maze', next.id);
534:     if (!mounted) return;
535:     final nextCost = next == null
536:         ? 0
537:         : (nextRecord == null ? cfg.cost('mini_game_new_level') : cfg.cost('mini_game_replay_completed'));
538:     final gemsLabel = level.gems.isEmpty ? 'Không có đá quý ở màn này' : 'Nhặt đủ ${level.gems.length} đá quý';
539:     final action = await showLevelResult(
540:       context,
541:       LevelResultData(
542:         gameName: 'Mê Cung Robo',
543:         levelTitle: 'Màn ${level.index + 1}: ${level.title}',
544:         success: true,
545:         stars: stars.count,
546:         score: score,
547:         bestScore: outcome.bestScore,
548:         newBest: outcome.newHighScore,
549:         goals: [
550:           const ResultGoal('Đưa Robo tới rương báu', true),
551:           ResultGoal(gemsLabel, stars.allGems),
552:           ResultGoal('Dùng tối đa ${level.commandLimit} lệnh (bạn dùng $_commandsUsed)', stars.withinLimit),
553:         ],
554:         stats: [
555:           ResultStat('Số lệnh', '$_commandsUsed'),
556:           ResultStat('Đá quý', '${result.gems.length}/${level.gems.length}', icon: GameIconKind.gem),
557:           ResultStat('Lần chạy', '$_attempts'),
558:         ],
559:         skill: level.skill,
560:         host: CharacterId.robo,
561:         hostLine: _hostLine(stars),
562:         notices: notices,
563:         primaryLabel: next != null ? 'Màn tiếp theo' : null,
564:         primaryCost: nextCost,
565:         tone: PQTone.grass,
566:       ),
```

## `app/lib/modules/robot_maze/maze_workshop_screen.dart`

Lines 180–214:
```text
180:   Future<void> _testRun({bool code = false}) async {
181:     final s = AppScope.of(context);
182:     final lvl = _level;
183:     if (!_solvable(lvl)) {
184:       s.audio.play(Sfx.bonk);
185:       _toast('Chưa có đường nào từ Robo tới rương! Hãy mở một lối đi nhé.');
186:       return;
187:     }
188:     final id = await _save();
189:     if (!mounted) return;
190:     final result = await Navigator.of(context).push<Object?>(
191:       CloudRoute(
192:         builder: (_) => MazePlayScreen(level: MazeLevel.fromCustomJson(id, lvl.toJson()), customId: id, startInCode: code),
193:         calm: s.settings.calmMode,
194:       ),
195:     );
196:     final report = readCustomRunReport(result);
197:     if (!mounted || report == null || !report.won) return;
198:     final firstVerify = !_verified;
199:     setState(() => _verified = true);
200:     await _save(verified: true);
201:     final notices = [...report.notices];
202:     if (firstVerify) {
203:       final outcome = await s.events.emit(StandardEvent(
204:         type: EventTypes.customGameVerified,
205:         sourceId: RobotMazeContent.gameId,
206:         data: {'custom_id': id},
207:       ));
208:       notices.addAll(outcome.notices);
209:     }
210:     if (!mounted) return;
211:     s.audio.play(Sfx.success);
212:     _toast('Tuyệt! Mê cung "${lvl.title}" đã được chứng minh là giải được.');
213:     if (notices.isNotEmpty) showRewardToasts(context, notices);
214:   }
```

## `app/lib/modules/robot_maze/maze_models.dart`

Lines 343–359:
```text
343: class MazeStars {
344:   const MazeStars({required this.reached, required this.allGems, required this.withinLimit});
345:   final bool reached;
346:   final bool allGems;
347:   final bool withinLimit;
348:
349:   int get count => reached ? 1 + (allGems ? 1 : 0) + (withinLimit ? 1 : 0) : 0;
350:
351:   int score({int complete = 40, int gems = 30, int limit = 30}) =>
352:       reached ? complete + (allGems ? gems : 0) + (withinLimit ? limit : 0) : 0;
353:
354:   static MazeStars evaluate(MazeLevel level, RunResult run, int commandsUsed) => MazeStars(
355:         reached: run.won,
356:         allGems: run.won && run.gems.length == level.gems.length,
357:         withinLimit: run.won && commandsUsed <= level.commandLimit,
358:       );
359: }
```

## `app/lib/data/repositories/progress_repository.dart`

Lines 30–41:
```text
30: }
31:
32: /// Outcome of saving a level result.
33: class LevelSaveResult {
34:   const LevelSaveResult({required this.firstCompletion, required this.previous, required this.current});
35:   final bool firstCompletion;
36:   final LevelRecord? previous;
37:   final LevelRecord current;
38:
39:   bool get improvedStars => current.stars > (previous?.stars ?? 0);
40:   bool get newHighScore => previous != null && current.highScore > previous!.highScore;
41: }
```

Lines 63–105:
```text
63:   /// Stores the best stars / score for a completed level (stars >= 1).
64:   Future<LevelSaveResult> saveLevelResult({
65:     required String gameId,
66:     required String levelId,
67:     required int stars,
68:     required int score,
69:     required DateTime at,
70:   }) async {
71:     return _sql.transaction((txn) async {
72:       final rows = await txn.query('game_results',
73:           where: 'game_id = ? AND level_id = ?', whereArgs: [gameId, levelId], limit: 1);
74:       final previous = rows.isEmpty ? null : LevelRecord.fromRow(rows.first);
75:       if (previous == null) {
76:         await txn.insert('game_results', {
77:           'game_id': gameId,
78:           'level_id': levelId,
79:           'stars': stars,
80:           'high_score': score,
81:           'plays': 1,
82:           'completed_at': at.millisecondsSinceEpoch,
83:         });
84:       } else {
85:         await txn.update(
86:           'game_results',
87:           {
88:             'stars': stars > previous.stars ? stars : previous.stars,
89:             'high_score': score > previous.highScore ? score : previous.highScore,
90:             'plays': previous.plays + 1,
91:           },
92:           where: 'game_id = ? AND level_id = ?',
93:           whereArgs: [gameId, levelId],
94:         );
95:       }
96:       final current = LevelRecord(
97:         gameId: gameId,
98:         levelId: levelId,
99:         stars: previous == null ? stars : (stars > previous.stars ? stars : previous.stars),
100:         highScore: previous == null ? score : (score > previous.highScore ? score : previous.highScore),
101:         plays: (previous?.plays ?? 0) + 1,
102:         completedAt: previous?.completedAt ?? at,
103:       );
104:       return LevelSaveResult(firstCompletion: previous == null, previous: previous, current: current);
105:     });
```

## `app/lib/modules/progress/progress_tracker.dart`

Lines 15–43:
```text
15:     final now = _clock.now();
16:     switch (event.type) {
17:       case EventTypes.levelCompleted:
18:         final levelId = event.get<String>('level_id')!;
19:         final stars = event.get<int>('stars') ?? 1;
20:         final score = event.get<int>('score') ?? 0;
21:         final saved = await _repo.saveLevelResult(
22:           gameId: event.sourceId,
23:           levelId: levelId,
24:           stars: stars,
25:           score: score,
26:           at: now,
27:         );
28:         outcome.firstCompletion = saved.firstCompletion;
29:         outcome.previousStars = saved.previous?.stars ?? 0;
30:         outcome.bestStars = saved.current.stars;
31:         outcome.bestScore = saved.current.highScore;
32:         outcome.newHighScore = saved.newHighScore;
33:         final next = event.get<String>('next_level_id');
34:         if (next != null) {
35:           await _repo.unlockLevel(event.sourceId, next, now);
36:         }
37:       case EventTypes.lessonCompleted:
38:         final lessonId = event.get<String>('lesson_id')!;
39:         final first = await _repo.completeLesson(lessonId, event.get<int>('score') ?? 0, now);
40:         outcome.firstCompletion = first;
41:         final skills = (event.data['skills'] as List?)?.cast<String>() ?? const <String>[];
42:         for (final skill in skills) {
43:           await _repo.learnSkill(skill, now);
```

Lines 54–61:
```text
54:         await _repo.claimOnce('chapter:${event.get<String>('chapter_id')}', now);
55:       case EventTypes.bugFixed:
56:         final first = await _repo.claimOnce('bug:${event.get<String>('puzzle_id')}:${event.get<int>('bug_index')}', now);
57:         outcome.firstCompletion = first;
58:       case EventTypes.customGameVerified:
59:         await _repo.claimOnce('custom:${event.sourceId}:${event.get<int>('custom_id')}', now);
60:       case EventTypes.activityOpened:
61:         await _repo.claimOnce('visited:${event.get<String>('activity_id')}', now);
```

## `app/lib/core/events.dart`

Lines 67–85:
```text
67: enum RewardKind { badge, quest, energy, unlock, item }
68:
69: /// Something to celebrate on a result screen.
70: class RewardNotice {
71:   const RewardNotice({required this.kind, required this.id, required this.title, required this.description});
72:   final RewardKind kind;
73:   final String id;
74:   final String title;
75:   final String description;
76: }
77:
78: class EventOutcome {
79:   final List<RewardNotice> notices = [];
80:   bool firstCompletion = false;
81:   int previousStars = 0;
82:   int bestStars = 0;
83:   int bestScore = 0;
84:   bool newHighScore = false;
85: }
```

Lines 92–118:
```text
92: /// progress tracker → energy → daily quests → achievements.
93: class GameEventHub {
94:   final List<GameEventListener> _listeners = [];
95:   final StreamController<StandardEvent> _controller = StreamController<StandardEvent>.broadcast();
96:
97:   /// Bumped after every processed event so screens can refresh saved data.
98:   final ValueNotifier<int> revision = ValueNotifier<int>(0);
99:
100:   Stream<StandardEvent> get stream => _controller.stream;
101:
102:   void register(GameEventListener listener) => _listeners.add(listener);
103:
104:   Future<EventOutcome> emit(StandardEvent event) async {
105:     final outcome = EventOutcome();
106:     for (final listener in _listeners) {
107:       await listener.onEvent(event, outcome);
108:     }
109:     revision.value++;
110:     _controller.add(event);
111:     return outcome;
112:   }
113:
114:   void dispose() {
115:     _controller.close();
116:     revision.dispose();
117:   }
118: }
```

## `app/lib/shared/widgets/result_screen.dart`

Lines 30–68:
```text
30:
31: /// Data for the shared "Màn tổng kết" (level summary) screen.
32: class LevelResultData {
33:   const LevelResultData({
34:     required this.gameName,
35:     required this.levelTitle,
36:     required this.success,
37:     required this.stars,
38:     required this.host,
39:     required this.hostLine,
40:     this.score,
41:     this.bestScore,
42:     this.newBest = false,
43:     this.goals = const [],
44:     this.stats = const [],
45:     this.skill,
46:     this.notices = const [],
47:     this.primaryLabel,
48:     this.primaryCost = 0,
49:     this.tone = PQTone.grass,
50:   });
51:
52:   final String gameName;
53:   final String levelTitle;
54:   final bool success;
55:   final int stars;
56:   final int? score;
57:   final int? bestScore;
58:   final bool newBest;
59:   final List<ResultGoal> goals;
60:   final List<ResultStat> stats;
61:   final String? skill;
62:   final CharacterId host;
63:   final String hostLine;
64:   final List<RewardNotice> notices;
65:
66:   /// Label of the main button (e.g. "Màn tiếp theo", "Chơi lại"). Null hides it.
67:   final String? primaryLabel;
68:   final int primaryCost;
```

Lines 175–186:
```text
175:                             if (d.newBest) ...[
176:                               const SizedBox(width: 8),
177:                               const PillTag(label: 'Kỷ lục mới!', color: PQColors.berry),
178:                             ],
179:                           ],
180:                         ),
181:                         if (d.bestScore != null && !d.newBest)
182:                           Text('Kỷ lục: ${d.bestScore}', textAlign: TextAlign.center, style: PQText.small),
183:                       ],
184:                       const SizedBox(height: 14),
185:                       if (d.goals.isNotEmpty)
186:                         PQPanel(
```

Lines 218–260:
```text
218:                         const SizedBox(height: 12),
219:                         PQPanel(
220:                           color: const Color(0xFFE8F1FF),
221:                           child: Row(
222:                             children: [
223:                               const Icon(Icons.lightbulb_rounded, color: PQColors.sunDeep, size: 30),
224:                               const SizedBox(width: 10),
225:                               Expanded(
226:                                 child: Column(
227:                                   crossAxisAlignment: CrossAxisAlignment.start,
228:                                   children: [
229:                                     Text('Kỹ năng', style: PQText.small.copyWith(color: PQColors.pyBlue, fontWeight: FontWeight.w900)),
230:                                     Text(d.skill!, style: PQText.bodyStrong.copyWith(fontSize: 16)),
231:                                   ],
232:                                 ),
233:                               ),
234:                             ],
235:                           ),
236:                         ),
237:                       ],
238:                       if (badges.isNotEmpty) ...[
239:                         const SizedBox(height: 12),
240:                         for (final b in badges) _BadgeRow(notice: b),
241:                       ],
242:                       for (final n in others)
243:                         Padding(
244:                           padding: const EdgeInsets.only(top: 10),
245:                           child: PQPanel(
246:                             padding: const EdgeInsets.all(12),
247:                             child: Row(
248:                               children: [
249:                                 GameIcon(n.kind == RewardKind.quest ? GameIconKind.stamp : GameIconKind.energy, size: 36),
250:                                 const SizedBox(width: 10),
251:                                 Expanded(
252:                                   child: Column(
253:                                     crossAxisAlignment: CrossAxisAlignment.start,
254:                                     children: [
255:                                       Text(n.title, style: PQText.bodyStrong),
256:                                       Text(n.description, style: PQText.small),
257:                                     ],
258:                                   ),
259:                                 ),
260:                               ],
```

## `app/lib/shared/widgets/reward_toast.dart`

Lines 13–31:
```text
13: /// Slides celebratory banners (new badge, quest done...) in from the top.
14: void showRewardToasts(BuildContext context, List<RewardNotice> notices) {
15:   final overlay = Overlay.maybeOf(context, rootOverlay: true);
16:   if (overlay == null || notices.isEmpty) return;
17:   final audio = AppScope.maybeOf(context)?.audio;
18:   var delay = Duration.zero;
19:   for (final n in notices) {
20:     Future<void>.delayed(delay, () {
21:       if (!overlay.mounted) return;
22:       audio?.play(n.kind == RewardKind.badge ? Sfx.unlock : Sfx.sparkle);
23:       late OverlayEntry entry;
24:       entry = OverlayEntry(builder: (ctx) => _Toast(notice: n, onDone: () => entry.remove()));
25:       overlay.insert(entry);
26:     });
27:     delay += const Duration(milliseconds: 1600);
28:   }
29: }
30:
31: class _Toast extends StatefulWidget {
```

## `app/lib/modules/achievements/achievement_catalog.dart`

Lines 80–90:
```text
80: /// left out instead of being shown as impossible goals.
81: final List<AchievementDef> achievementCatalog = [
82:   AchievementDef(
83:     id: 'first_steps',
84:     title: 'Bước Chân Đầu Tiên',
85:     description: 'Vượt qua màn chơi đầu tiên trên đảo.',
86:     howTo: 'Thắng một màn bất kỳ trong mini-game.',
87:     icon: Icons.directions_walk_rounded,
88:     color: PQColors.grass,
89:     check: (s, e) => s.totalLevels() >= 1,
90:   ),
```

## `app/lib/modules/daily_quests/daily_quest_service.dart`

Lines 149–158:
```text
149:   Future<bool> claimStamp(String questId) async {
150:     final ok = await _repo.markRewarded(_day, questId);
151:     if (ok) {
152:       _quests = [
153:         for (final q in _quests)
154:           q.def.id == questId ? DailyQuestState(q.def, q.progress, q.completed, true) : q,
155:       ];
156:       _stamps++;
157:       notifyListeners();
158:     }
```

Lines 163–180:
```text
163:   Future<void> onEvent(StandardEvent event, EventOutcome outcome) async {
164:     await ensureToday();
165:     var changed = false;
166:     final updated = <DailyQuestState>[];
167:     for (final q in _quests) {
168:       if (!q.completed && q.def.matches(event)) {
169:         final progress = q.progress + 1;
170:         final done = progress >= q.def.target;
171:         await _repo.update(_day, q.def.id, progress: progress, completed: done);
172:         updated.add(DailyQuestState(q.def, progress, done, q.rewarded));
173:         changed = true;
174:         if (done) {
175:           outcome.notices.add(RewardNotice(
176:             kind: RewardKind.quest,
177:             id: q.def.id,
178:             title: 'Nhiệm vụ hôm nay hoàn thành!',
179:             description: q.def.title,
180:           ));
```

## `app/assets/data/robot_maze_levels.json`

Lines 1–27:
```text
1: {
2:   "game_id": "robot_maze",
3:   "levels": [
4:     {
5:       "id": "rm_01",
6:       "title": "Bước đi đầu tiên",
7:       "story": "Rương báu ở ngay phía trước! Hãy xếp các mũi tên để Robo đi tới rương.",
8:       "tip": "Mỗi mũi tên là một bước. Đếm số ô từ Robo tới rương nhé.",
9:       "skill": "Thứ tự lệnh: máy tính làm đúng từng bước bạn viết.",
10:       "rows": ["#####", "S...C", "#####"],
11:       "command_limit": 4,
12:       "allow_loops": false,
13:       "solution": "R R R R"
14:     },
15:     {
16:       "id": "rm_02",
17:       "title": "Rẽ ở góc đường",
18:       "story": "Đường đi có một khúc rẽ. Nhặt viên đá quý trên đường nữa nhé!",
19:       "tip": "Đi sang phải trước, rồi mới đi xuống.",
20:       "skill": "Lệnh chạy lần lượt từ trái sang phải.",
21:       "rows": ["S.*.", "###.", "###.", "###C"],
22:       "command_limit": 6,
23:       "allow_loops": false,
24:       "solution": "R R R D D D"
25:     },
26:     {
27:       "id": "rm_03",
```

## `app/assets/config/game_config.json`

Lines 1–26:
```text
1: {
2:   "energy": {
3:     "max_initial": 20,
4:     "max_cap": 40,
5:     "regen_minutes_per_unit": 10,
6:     "milestone_bonus": { "chapter:code_apprentice": 5 }
7:   },
8:   "energy_costs": {
9:     "mini_game_new_level": 2,
10:     "mini_game_replay_completed": 0,
11:     "arcade_run": 2,
12:     "creator_mode": 0,
13:     "main_quest_lesson_first": 1,
14:     "main_quest_review": 0,
15:     "chapter_challenge_first": 3
16:   },
17:   "session_reminders_minutes": [30, 45, 60],
18:   "hints": { "light_after_fails": 2, "strong_after_fails": 3, "suggest_practice_after_fails": 4 },
19:   "python_runtime": {
20:     "step_budget": 100000,
21:     "max_call_depth": 50,
22:     "max_output_chars": 10000,
23:     "max_collection_length": 10000
24:   },
25:   "robot_maze": { "step_ms": 380, "score_complete": 40, "score_all_gems": 30, "score_command_limit": 30 },
26:   "dragon_jump": {
```
