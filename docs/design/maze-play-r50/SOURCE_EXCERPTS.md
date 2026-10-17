# Pinned source excerpts — r50

Exact CODE `de01a490743982356ad5240d77ea99e9dbf8c7f5`. Read-only references; not an imported runtime patch.

## app/lib/modules/robot_maze/maze_models.dart L157–L211

```text
157:         story: 'Mê cung do chính bạn thiết kế. Hãy chứng minh nó giải được!',
158:         tip: 'Bạn là người tạo ra mê cung này — bạn biết đường mà!',
159:         skill: 'Thiết kế trò chơi và kiểm tra rằng nó chơi được.',
160:       );
161: }
162:
163: // ----------------------------------------------------------------- program
164:
165: sealed class Block {
166:   const Block();
167:   int get commandCount;
168: }
169:
170: class MoveBlock extends Block {
171:   const MoveBlock(this.dir);
172:   final Dir dir;
173:   @override
174:   int get commandCount => 1;
175: }
176:
177: class RepeatBlock extends Block {
178:   RepeatBlock(this.times, [List<Dir>? body]) : body = body ?? <Dir>[];
179:   int times;
180:   final List<Dir> body;
181:   @override
182:   int get commandCount => 1 + body.length;
183: }
184:
185: /// One executed step and the block it came from (for highlighting).
186: class StepRef {
187:   const StepRef(this.dir, this.blockIndex, [this.innerIndex]);
188:   final Dir dir;
189:   final int blockIndex;
190:   final int? innerIndex;
191: }
192:
193: int commandCount(List<Block> blocks) => blocks.fold(0, (a, b) => a + b.commandCount);
194:
195: bool usesLoop(List<Block> blocks) => blocks.any((b) => b is RepeatBlock && b.body.isNotEmpty && b.times > 1);
196:
197: List<StepRef> expandProgram(List<Block> blocks) {
198:   final out = <StepRef>[];
199:   for (var i = 0; i < blocks.length; i++) {
200:     final b = blocks[i];
201:     switch (b) {
202:       case MoveBlock m:
203:         out.add(StepRef(m.dir, i));
204:       case RepeatBlock r:
205:         for (var t = 0; t < r.times; t++) {
206:           for (var j = 0; j < r.body.length; j++) {
207:             out.add(StepRef(r.body[j], i, j));
208:           }
209:         }
210:     }
211:   }
```

## app/lib/modules/robot_maze/maze_models.dart L274–L367

```text
274: }
275:
276: /// Step-by-step simulation shared by blocks and Python code mode.
277: class MazeSimulation {
278:   MazeSimulation(this.level) : position = level.start, path = [level.start];
279:
280:   final MazeLevel level;
281:   Cell position;
282:   final List<Cell> path;
283:   final List<Dir> moves = [];
284:   final Set<Cell> gems = {};
285:   RunOutcome? outcome;
286:   static const int maxMoves = 200;
287:
288:   bool get finished => outcome != null;
289:
290:   /// Performs one move. Returns false when the run ended (win or crash).
291:   bool move(Dir d) {
292:     if (finished) return false;
293:     if (moves.length >= maxMoves) {
294:       outcome = RunOutcome.tooLong;
295:       return false;
296:     }
297:     moves.add(d);
298:     final next = Cell(position.x + d.dx, position.y + d.dy);
299:     if (!level.inside(next)) {
300:       outcome = RunOutcome.edge;
301:       return false;
302:     }
303:     final tile = level.tileAt(next);
304:     if (tile == Tile.wall) {
305:       outcome = RunOutcome.wall;
306:       return false;
307:     }
308:     position = next;
309:     path.add(next);
310:     if (tile == Tile.water) {
311:       outcome = RunOutcome.water;
312:       return false;
313:     }
314:     if (level.gems.contains(next)) gems.add(next);
315:     if (next == level.goal) {
316:       outcome = RunOutcome.win;
317:       return false;
318:     }
319:     return true;
320:   }
321:
322:   RunResult finish() {
323:     final o = outcome ?? RunOutcome.notThere;
324:     return RunResult(
325:       outcome: o,
326:       path: List.of(path),
327:       gems: Set.of(gems),
328:       failStep: o == RunOutcome.win ? -1 : moves.length - 1,
329:     );
330:   }
331:
332:   static RunResult runMoves(MazeLevel level, List<Dir> dirs) {
333:     final sim = MazeSimulation(level);
334:     for (final d in dirs) {
335:       if (!sim.move(d)) break;
336:     }
337:     return sim.finish();
338:   }
339: }
340:
341: /// Star rules for Robot Maze (each star is independent and visible up front):
342: /// ★ reach the chest · ★★ collect every gem · ★★★ use at most N commands.
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
360:
361: class RobotMazeContent {
362:   RobotMazeContent(this.levels);
363:
364:   final List<MazeLevel> levels;
365:   static const String gameId = 'robot_maze';
366:
367:   static Future<RobotMazeContent> load(AssetBundle bundle) async {
```

## app/lib/modules/robot_maze/maze_play_screen.dart L112–L159

```text
112:         for (final b in p) b is RepeatBlock ? RepeatBlock(b.times, List.of(b.body)) : b,
113:       ];
114:
115:   void _remember() {
116:     _history.add(_clone(_program));
117:     if (_history.length > 40) _history.removeAt(0);
118:   }
119:
120:   void _resetBoardIfNeeded() {
121:     if (_phase == _Phase.won || _phase == _Phase.failed) {
122:       _phase = _Phase.editing;
123:       _pb.reset(level);
124:     }
125:   }
126:
127:   void _addMove(Dir d) {
128:     if (_phase == _Phase.running) return;
129:     AppScope.of(context).audio.play(Sfx.pop);
130:     setState(() {
131:       _resetBoardIfNeeded();
132:       _remember();
133:       if (_openLoop != null) {
134:         if (_openLoop!.body.length < 6) _openLoop!.body.add(d);
135:       } else if (commandCount(_program) < 30) {
136:         _program.add(MoveBlock(d));
137:       }
138:     });
139:     _scrollStripToEnd();
140:   }
141:
142:   void _addLoop() {
143:     if (_phase == _Phase.running || _openLoop != null) return;
144:     AppScope.of(context).audio.play(Sfx.pop);
145:     setState(() {
146:       _resetBoardIfNeeded();
147:       _remember();
148:       final loop = RepeatBlock(2);
149:       _program.add(loop);
150:       _openLoop = loop;
151:     });
152:     _scrollStripToEnd();
153:   }
154:
155:   void _closeLoop() {
156:     setState(() {
157:       if (_openLoop != null && _openLoop!.body.isEmpty) {
158:         _program.remove(_openLoop);
159:       }
```

## app/lib/modules/robot_maze/maze_play_screen.dart L482–L597

```text
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
567:     );
568:     if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
569:     switch (action) {
570:       case ResultAction.primary:
571:         if (next == null) {
572:           Navigator.of(context).pop();
573:           return;
574:         }
575:         if (!await spendEnergy(context, nextCost)) {
576:           if (mounted) Navigator.of(context).pop();
577:           return;
578:         }
579:         if (!mounted) return;
580:         Navigator.of(context).pushReplacement(
581:           MaterialPageRoute<void>(builder: (_) => MazePlayScreen(level: next)),
582:         );
583:       case ResultAction.replay:
584:         _tryAgain();
585:       case ResultAction.back:
586:         Navigator.of(context).pop();
587:       case ResultAction.map:
588:         Navigator.of(context).popUntil((r) => r.isFirst);
589:     }
590:   }
591:
592:   String _hostLine(MazeStars s) {
593:     if (s.count == 3) return 'Tuyệt vời! Chương trình của bạn vừa đúng vừa gọn gàng!';
594:     if (!s.allGems) return 'Mình tới rương rồi! Lần sau thử nhặt hết đá quý trên đường nhé.';
595:     if (!s.withinLimit) {
596:       return level.allowLoops
597:           ? 'Hay lắm! Thử dùng khối Lặp lại để chương trình ngắn hơn nhé.'
```

## app/lib/modules/robot_maze/robot_maze_module.dart L88–L110

```text
88:     final r = await _services!.progress.levelRecords(RobotMazeContent.gameId);
89:     if (mounted) setState(() => _records = r);
90:   }
91:
92:   bool _unlocked(List<MazeLevel> levels, int i) => i == 0 || _records.containsKey(levels[i - 1].id);
93:
94:   Future<void> _openLevel(MazeLevel level) async {
95:     final s = AppScope.of(context);
96:     final completed = _records.containsKey(level.id);
97:     final cost = completed ? s.config.cost('mini_game_replay_completed') : s.config.cost('mini_game_new_level');
98:     if (!await spendEnergy(context, cost)) return;
99:     if (!mounted) return;
100:     await Navigator.of(context).push(CloudRoute<void>(builder: (_) => MazePlayScreen(level: level), calm: s.settings.calmMode));
101:   }
102:
103:   @override
104:   Widget build(BuildContext context) {
105:     final s = AppScope.of(context);
106:     final levels = s.robotMaze.levels;
107:     final stars = _records.values.fold<int>(0, (a, r) => a + r.stars);
108:     final firstOpen = List.generate(levels.length, (i) => i).firstWhere(
109:           (i) => _unlocked(levels, i) && !_records.containsKey(levels[i].id),
110:           orElse: () => -1,
```

## app/assets/config/game_config.json L1–L36

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
27:     "star_scores": [150, 300, 500],
28:     "start_speed": 250,
29:     "max_speed": 540,
30:     "speed_gain_per_sec": 5,
31:     "hearts": 3,
32:     "coin_value": 1
33:   },
34:   "catch_stars": { "round_seconds": 45, "star_scores": [60, 150, 300], "hearts": 3 },
35:   "bug_hunter": { "three_star_seconds": 60 }
36: }
```
