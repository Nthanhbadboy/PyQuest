# r46 — trích source để đối chiếu

Pin: `71b0fd3fd8fb07c73596ce089fa2e68f6fe87964`. Không phải execution evidence. Các dòng sau lấy nguyên văn; xem SPEC cho proposal.

## `app/lib/modules/robot_maze/maze_workshop_screen.dart` L1–78

```text
1: import 'dart:collection';
2:
3: import 'package:flutter/material.dart';
4:
5: import '../../app/app_scope.dart';
6: import '../../app/settings_sheet.dart';
7: import '../../core/audio_service.dart';
8: import '../../core/events.dart';
9: import '../../data/repositories/state_repositories.dart';
10: import '../../shared/characters/characters.dart';
11: import '../../shared/theme/app_theme.dart';
12: import '../../shared/theme/palette.dart';
13: import '../../shared/widgets/chunky_button.dart';
14: import '../../shared/widgets/common.dart';
15: import '../../shared/widgets/game_icons.dart';
16: import '../../shared/widgets/reward_toast.dart';
17: import '../../shared/widgets/transitions.dart';
18: import 'maze_board.dart';
19: import 'maze_models.dart';
20: import 'maze_play_screen.dart';
21:
22: enum _Tool { wall, water, gem, start, chest, erase }
23:
24: extension on _Tool {
25:   String get label => switch (this) {
26:         _Tool.wall => 'Bụi cây',
27:         _Tool.water => 'Nước',
28:         _Tool.gem => 'Đá quý',
29:         _Tool.start => 'Robo',
30:         _Tool.chest => 'Rương',
31:         _Tool.erase => 'Tẩy',
32:       };
33: }
34:
35: /// Creator Mode for Robot Maze: design a maze, set its rules, prove it can be
36: /// solved (blocks or Python), and keep it in your collection.
37: class MazeWorkshopScreen extends StatefulWidget {
38:   const MazeWorkshopScreen({super.key});
39:
40:   @override
41:   State<MazeWorkshopScreen> createState() => _MazeWorkshopScreenState();
42: }
43:
44: class _MazeWorkshopScreenState extends State<MazeWorkshopScreen> with SingleTickerProviderStateMixin {
45:   static const _template = ['S.....', '.##.#.', '......', '.#.##.', '...*..', '.....C'];
46:
47:   late final AnimationController _time = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
48:   late List<List<String>> _grid = _toGrid(_template);
49:   final TextEditingController _name = TextEditingController(text: 'Mê cung của tôi');
50:   int _limit = 10;
51:   bool _loops = true;
52:   _Tool _tool = _Tool.wall;
53:   int? _id;
54:   bool _verified = false;
55:   bool _dirty = false;
56:   List<CustomLevel> _saved = [];
57:   late MazePlayback _pb = MazePlayback(_level)..reset(_level);
58:   final GlobalKey _boardKey = GlobalKey();
59:
60:   static List<List<String>> _toGrid(List<String> rows) => [for (final r in rows) r.split('')];
61:
62:   MazeLevel get _level => MazeLevel.fromRows(
63:         id: 'draft',
64:         title: _name.text.trim().isEmpty ? 'Mê cung của tôi' : _name.text.trim(),
65:         rows: [for (final r in _grid) r.join()],
66:         commandLimit: _limit,
67:         allowLoops: _loops,
68:       );
69:
70:   @override
71:   void initState() {
72:     super.initState();
73:     WidgetsBinding.instance.addPostFrameCallback((_) => _loadSaved());
74:   }
75:
76:   @override
77:   void dispose() {
78:     _time.dispose();
```

## `app/lib/modules/robot_maze/maze_workshop_screen.dart` L99–227

```text
99:     final y = ((local.dy - g.origin.dy) / g.cell).floor();
100:     if (x < 0 || y < 0 || x >= lvl.width || y >= lvl.height) return;
101:     final current = _grid[y][x];
102:     String next;
103:     switch (_tool) {
104:       case _Tool.wall:
105:         next = '#';
106:       case _Tool.water:
107:         next = '~';
108:       case _Tool.gem:
109:         next = '*';
110:       case _Tool.erase:
111:         next = '.';
112:       case _Tool.start:
113:       case _Tool.chest:
114:         final mark = _tool == _Tool.start ? 'S' : 'C';
115:         for (final row in _grid) {
116:           for (var i = 0; i < row.length; i++) {
117:             if (row[i] == mark) row[i] = '.';
118:           }
119:         }
120:         next = mark;
121:     }
122:     if (current == next) return;
123:     if ((current == 'S' || current == 'C') && _tool != _Tool.start && _tool != _Tool.chest) return;
124:     setState(() {
125:       _grid[y][x] = next;
126:       _dirty = true;
127:       _verified = false;
128:       _refreshBoard();
129:     });
130:     AppScope.of(context).audio.play(Sfx.pop, volume: 0.5);
131:   }
132:
133:   void _resize(int w, int h) {
134:     setState(() {
135:       final g = List.generate(h, (y) => List.generate(w, (x) => (y < _grid.length && x < _grid[0].length) ? _grid[y][x] : '.'));
136:       final flat = g.expand((r) => r).toList();
137:       if (!flat.contains('S')) g[0][0] = 'S';
138:       if (!flat.contains('C')) g[h - 1][w - 1] = 'C';
139:       _grid = g;
140:       _dirty = true;
141:       _verified = false;
142:       _refreshBoard();
143:     });
144:   }
145:
146:   /// BFS: is the chest reachable at all?
147:   bool _solvable(MazeLevel lvl) {
148:     final seen = <Cell>{lvl.start};
149:     final queue = Queue<Cell>()..add(lvl.start);
150:     while (queue.isNotEmpty) {
151:       final c = queue.removeFirst();
152:       if (c == lvl.goal) return true;
153:       for (final d in Dir.values) {
154:         final n = Cell(c.x + d.dx, c.y + d.dy);
155:         if (!lvl.inside(n) || seen.contains(n) || lvl.tileAt(n) != Tile.floor) continue;
156:         seen.add(n);
157:         queue.add(n);
158:       }
159:     }
160:     return false;
161:   }
162:
163:   Future<int> _save({bool? verified}) async {
164:     final s = AppScope.of(context);
165:     final lvl = _level;
166:     final id = await s.customLevels.save(
167:       id: _id,
168:       gameId: RobotMazeContent.gameId,
169:       name: lvl.title,
170:       data: lvl.toJson(),
171:       verified: verified ?? _verified,
172:       at: s.clock.now(),
173:     );
174:     _id = id;
175:     _dirty = false;
176:     await _loadSaved();
177:     return id;
178:   }
179:
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
215:
216:   void _toast(String text) {
217:     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
218:       backgroundColor: PQColors.ink,
219:       content: Text(text, style: PQText.bodyStrong.copyWith(color: Colors.white)),
220:       behavior: SnackBarBehavior.floating,
221:     ));
222:   }
223:
224:   void _newMaze() {
225:     setState(() {
226:       _grid = _toGrid(_template);
227:       _name.text = 'Mê cung mới';
```

## `app/lib/modules/robot_maze/maze_workshop_screen.dart` L250–268

```text
250:
251:   Future<void> _openList() async {
252:     await _loadSaved();
253:     if (!mounted) return;
254:     final picked = await showPQSheet<CustomLevel>(
255:       context,
256:       builder: (ctx) => _SavedList(
257:         saved: _saved,
258:         onDelete: (c) async {
259:           await AppScope.of(context).customLevels.delete(c.id);
260:           if (_id == c.id) _id = null;
261:           await _loadSaved();
262:         },
263:       ),
264:     );
265:     if (picked != null) _load(picked);
266:   }
267:
268:   @override
```

## `app/lib/modules/robot_maze/maze_workshop_screen.dart` L299–320

```text
299:                         height: 44,
300:                         padding: const EdgeInsets.symmetric(horizontal: 12),
301:                         decoration: BoxDecoration(
302:                           color: PQColors.cream,
303:                           borderRadius: BorderRadius.circular(14),
304:                           border: Border.all(color: PQColors.ink, width: 2.2),
305:                         ),
306:                         alignment: Alignment.centerLeft,
307:                         child: TextField(
308:                           key: const ValueKey('workshop_name'),
309:                           controller: _name,
310:                           maxLength: 28,
311:                           style: PQText.bodyStrong,
312:                           decoration: const InputDecoration.collapsed(hintText: 'Tên mê cung').copyWith(counterText: ''),
313:                           onChanged: (_) => setState(() => _dirty = true),
314:                         ),
315:                       ),
316:                     ),
317:                     const SizedBox(width: 8),
318:                     _SizePicker(
319:                       width: lvl.width,
320:                       height: lvl.height,
```

## `app/lib/modules/robot_maze/maze_workshop_screen.dart` L364–390

```text
364:               Padding(
365:                 padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
366:                 child: Row(
367:                   children: [
368:                     Text('Giới hạn 3 sao:', style: PQText.small),
369:                     const SizedBox(width: 6),
370:                     _Stepper(
371:                       value: _limit,
372:                       onChanged: (v) => setState(() {
373:                         _limit = v.clamp(3, 20);
374:                         _dirty = true;
375:                         _verified = false;
376:                       }),
377:                     ),
378:                     const Spacer(),
379:                     GestureDetector(
380:                       onTap: () => setState(() {
381:                         _loops = !_loops;
382:                         _dirty = true;
383:                       }),
384:                       child: Row(
385:                         children: [
386:                           Text('Khối Lặp', style: PQText.small),
387:                           const SizedBox(width: 6),
388:                           PQToggle(value: _loops),
389:                         ],
390:                       ),
```

## `app/lib/modules/robot_maze/maze_workshop_screen.dart` L494–514

```text
494:   }
495: }
496:
497: class _SizePicker extends StatelessWidget {
498:   const _SizePicker({required this.width, required this.height, required this.onChanged});
499:   final int width;
500:   final int height;
501:   final void Function(int w, int h) onChanged;
502:
503:   @override
504:   Widget build(BuildContext context) {
505:     return PopupMenuButton<int>(
506:       tooltip: 'Kích thước',
507:       onSelected: (n) => onChanged(n, n),
508:       itemBuilder: (ctx) => [
509:         for (final n in const [4, 5, 6]) PopupMenuItem(value: n, child: Text('$n × $n', style: PQText.bodyStrong)),
510:       ],
511:       child: Container(
512:         height: 44,
513:         padding: const EdgeInsets.symmetric(horizontal: 10),
514:         decoration: BoxDecoration(
```

## `app/lib/modules/robot_maze/maze_workshop_screen.dart` L565–591

```text
565:                       child: Column(
566:                         crossAxisAlignment: CrossAxisAlignment.start,
567:                         children: [
568:                           Text(c.name, style: PQText.bodyStrong),
569:                           Text(c.verified ? 'Đã giải được' : 'Chưa chứng minh', style: PQText.small),
570:                         ],
571:                       ),
572:                     ),
573:                     ChunkyButton(
574:                       label: 'Mở',
575:                       size: ChunkySize.small,
576:                       tone: PQTone.grape,
577:                       onPressed: () => Navigator.of(context).pop(c),
578:                     ),
579:                     const SizedBox(width: 6),
580:                     RoundIconButton(
581:                       icon: Icons.delete_rounded,
582:                       size: 40,
583:                       tone: PQTone.danger,
584:                       tooltip: 'Xoá',
585:                       onPressed: () async {
586:                         await widget.onDelete(c);
587:                         setState(() => _items.removeWhere((x) => x.id == c.id));
588:                       },
589:                     ),
590:                   ],
591:                 ),
```

## `app/lib/modules/robot_maze/maze_models.dart` L89–126

```text
89:     final gems = <Cell>{};
90:     final tiles = <List<Tile>>[];
91:     for (var y = 0; y < height; y++) {
92:       final row = <Tile>[];
93:       for (var x = 0; x < width; x++) {
94:         final ch = x < rows[y].length ? rows[y][x] : '#';
95:         switch (ch) {
96:           case '#':
97:             row.add(Tile.wall);
98:           case '~':
99:             row.add(Tile.water);
100:           default:
101:             row.add(Tile.floor);
102:             if (ch == 'S') start = Cell(x, y);
103:             if (ch == 'C') goal = Cell(x, y);
104:             if (ch == '*') gems.add(Cell(x, y));
105:         }
106:       }
107:       tiles.add(row);
108:     }
109:     return MazeLevel(
110:       id: id,
111:       title: title,
112:       story: story,
113:       tip: tip,
114:       skill: skill,
115:       width: width,
116:       height: height,
117:       tiles: tiles,
118:       start: start ?? const Cell(0, 0),
119:       goal: goal ?? Cell(width - 1, height - 1),
120:       gems: gems,
121:       commandLimit: commandLimit,
122:       allowLoops: allowLoops,
123:       solution: parseProgramNotation(solution),
124:       index: index,
125:     );
126:   }
```

## `app/lib/modules/robot_maze/maze_models.dart` L185–229

```text
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
212:   return out;
213: }
214:
215: /// Translates blocks into the equivalent PyQuest Python program.
216: String programToPython(List<Block> blocks) {
217:   if (blocks.isEmpty) return '# Chưa có lệnh nào';
218:   final buf = StringBuffer();
219:   for (final b in blocks) {
220:     switch (b) {
221:       case MoveBlock m:
222:         buf.writeln('${m.dir.py}()');
223:       case RepeatBlock r:
224:         buf.writeln('for i in range(${r.times}):');
225:         if (r.body.isEmpty) {
226:           buf.writeln('    pass');
227:         } else {
228:           for (final d in r.body) {
229:             buf.writeln('    ${d.py}()');
```

## `app/lib/modules/robot_maze/maze_models.dart` L281–336

```text
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
```

## `app/lib/modules/robot_maze/maze_models.dart` L342–358

```text
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
```

## `app/lib/modules/robot_maze/maze_play_screen.dart` L480–503

```text
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
```

## `app/lib/modules/robot_maze/maze_play_screen.dart` L892–905

```text
892: class _CustomRunReport {
893:   const _CustomRunReport({required this.won, required this.notices, required this.stars});
894:   final bool won;
895:   final List<RewardNotice> notices;
896:   final int stars;
897: }
898:
899: /// Public view of the custom-run report.
900: typedef CustomRunReport = ({bool won, List<RewardNotice> notices});
901:
902: CustomRunReport? readCustomRunReport(Object? value) {
903:   if (value is _CustomRunReport) return (won: value.won, notices: value.notices);
904:   return null;
905: }
```

## `app/lib/modules/robot_maze/robot_maze_module.dart` L144–151

```text
144:                     ),
145:                     const SizedBox(height: 16),
146:                     _WorkshopCard(
147:                       onOpen: () => Navigator.of(context).push(
148:                         CloudRoute<void>(builder: (_) => const MazeWorkshopScreen(), calm: s.settings.calmMode),
149:                       ),
150:                     ),
151:                   ],
```

## `app/lib/modules/robot_maze/robot_maze_module.dart` L354–366

```text
354:               ),
355:             ],
356:           ),
357:           const SizedBox(height: 10),
358:           ChunkyButton(
359:             key: const ValueKey('open_workshop'),
360:             label: 'Vào xưởng',
361:             icon: Icons.construction_rounded,
362:             tone: PQTone.grape,
363:             expand: true,
364:             trailing: const EnergyCostChip(cost: 0),
365:             onPressed: onOpen,
366:           ),
```

## `app/lib/data/repositories/state_repositories.dart` L173–232

```text
173: class CustomLevel {
174:   const CustomLevel({
175:     required this.id,
176:     required this.gameId,
177:     required this.name,
178:     required this.data,
179:     required this.verified,
180:     required this.updatedAt,
181:   });
182:
183:   final int id;
184:   final String gameId;
185:   final String name;
186:   final Map<String, dynamic> data;
187:   final bool verified;
188:   final DateTime updatedAt;
189: }
190:
191: /// Creations made in Creator Mode.
192: class CustomLevelRepository {
193:   CustomLevelRepository(this._db);
194:   final AppDatabase _db;
195:
196:   Future<List<CustomLevel>> list(String gameId) async {
197:     final rows = await _db.db.query('custom_levels', where: 'game_id = ?', whereArgs: [gameId], orderBy: 'updated_at DESC');
198:     return [for (final r in rows) _fromRow(r)];
199:   }
200:
201:   Future<int> countVerified() async {
202:     final rows = await _db.db.rawQuery('SELECT COUNT(*) AS c FROM custom_levels WHERE verified = 1');
203:     return (rows.first['c'] as int?) ?? 0;
204:   }
205:
206:   Future<int> save({
207:     int? id,
208:     required String gameId,
209:     required String name,
210:     required Map<String, dynamic> data,
211:     required bool verified,
212:     required DateTime at,
213:   }) async {
214:     final values = {
215:       'game_id': gameId,
216:       'name': name,
217:       'data': jsonEncode(data),
218:       'verified': verified ? 1 : 0,
219:       'updated_at': at.millisecondsSinceEpoch,
220:     };
221:     if (id == null) {
222:       return _db.db.insert('custom_levels', {...values, 'created_at': at.millisecondsSinceEpoch});
223:     }
224:     await _db.db.update('custom_levels', values, where: 'id = ?', whereArgs: [id]);
225:     return id;
226:   }
227:
228:   Future<void> delete(int id) async {
229:     await _db.db.delete('custom_levels', where: 'id = ?', whereArgs: [id]);
230:   }
231:
232:   CustomLevel _fromRow(Map<String, Object?> r) => CustomLevel(
```

## `app/assets/config/game_config.json` L3–16

```text
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
```
