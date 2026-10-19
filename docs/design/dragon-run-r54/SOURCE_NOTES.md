# Source notes r54 — facts không thay thế execution evidence

Pin CODE `6dc8ca8feeed54cc0fa6a82109e3a59d24a16153`. Các đoạn dưới lấy trực tiếp bằnggit show, giữline numbers.
R54 không chạyFlutter hoặc sửa các file này. Dữ liệu nghiên cứu nằm trongRAM.

## app/lib/modules/dragon_jump/dragon_game.dart · 80–113

```dart
80:   double invulnerable = 0;
81:   double shake = 0;
82:   int coins = 0;
83:   int gems = 0;
84:   double runCycle = 0;
85:   double flapT = 0;
86:   double _nextSpawn = 0;
87:   double overT = 0;
88: 
89:   final List<Obstacle> obstacles = [];
90:   final List<Pickup> pickups = [];
91:   final List<Particle> particles = [];
92: 
93:   /// Events the screen turns into sounds.
94:   final List<String> events = [];
95: 
96:   int get distanceMeters => (distance / 50).floor();
97:   int get score => distanceMeters + coins * 3;
98:   bool get onGround => pipY <= 0.001 && vy <= 0;
99: 
100:   void start() {
101:     phase = DragonPhase.running;
102:     speed = startSpeed;
103:     _nextSpawn = 380;
104:     notifyListeners();
105:   }
106: 
107:   void jump() {
108:     if (phase == DragonPhase.ready) start();
109:     if (phase != DragonPhase.running) return;
110:     if (onGround) {
111:       jumpsUsed = 0;
112:     }
113:     if (jumpsUsed >= maxJumps) return;
```

## app/lib/modules/dragon_jump/dragon_game.dart · 200–224

```dart
200:     } else if (roll < 0.76) {
201:       _obstacle(ObstacleKind.beetle, x, lift: 70 + _rnd.nextDouble() * 30);
202:       _coinLine(x - 30, 4, 18);
203:     } else if (roll < 0.88 && difficulty > 0.3) {
204:       _obstacle(ObstacleKind.rock, x);
205:       _obstacle(ObstacleKind.rock, x + 210 + 60 * (1 - difficulty));
206:     } else {
207:       _coinArc(x, 8, 120);
208:       if (_rnd.nextDouble() < 0.25) pickups.add(Pickup(x + 120, 210, gem: true));
209:     }
210:     final gap = 330 + _rnd.nextDouble() * 220 - difficulty * 120;
211:     _nextSpawn = gap * (speed / startSpeed).clamp(1.0, 1.6);
212:   }
213: 
214:   void _obstacle(ObstacleKind kind, double x, {double lift = 0}) {
215:     final (w, h) = switch (kind) {
216:       ObstacleKind.rock => (48.0, 44.0),
217:       ObstacleKind.bush => (74.0, 38.0),
218:       ObstacleKind.pillar => (36.0, 84.0),
219:       ObstacleKind.beetle => (46.0, 32.0),
220:     };
221:     obstacles.add(Obstacle(kind, x, w, h, lift));
222:   }
223: 
224:   void _coinLine(double x, int n, double height) {
```

## app/lib/modules/dragon_jump/dragon_game.dart · 245–304

```dart
245:         continue;
246:       }
247:       if (magnet) {
248:         final pos = Offset(p.x, p.y);
249:         final d = (pos - center).distance;
250:         if (d < 130 && d > 1 && p.x > -20) {
251:           final step = math.min(d, 420 * dt);
252:           final dir = (center - pos) / d;
253:           p.x += dir.dx * step;
254:           p.y += dir.dy * step;
255:         }
256:       }
257:       if ((Offset(p.x, p.y) - center).distance < 34) {
258:         p.taken = true;
259:         if (p.gem) {
260:           gems++;
261:           coins += 5;
262:           events.add('gem');
263:         } else {
264:           coins += 1;
265:           events.add('coin');
266:         }
267:         _sparkle(Offset(p.x, p.y), p.gem ? PQColors.sea : PQColors.sun);
268:       }
269:     }
270:     if (invulnerable > 0) return;
271:     for (final o in obstacles) {
272:       final left = o.x + o.w * 0.12;
273:       final right = o.x + o.w * 0.88;
274:       final bottom = o.lift + o.h * 0.04;
275:       final top = o.lift + o.h * 0.86;
276:       final overlapX = right > -20 && left < 20;
277:       final overlapY = top > pipY + 8 && bottom < pipY + 52;
278:       if (overlapX && overlapY) {
279:         _hit();
280:         return;
281:       }
282:     }
283:   }
284: 
285:   void _hit() {
286:     hearts--;
287:     shake = 1;
288:     events.add('hit');
289:     _sparkle(Offset(0, pipY + 30), PQColors.danger, count: 14);
290:     if (hearts <= 0) {
291:       phase = DragonPhase.over;
292:       vy = 700;
293:       events.add('over');
294:     } else {
295:       invulnerable = 1.5;
296:       vy = math.max(vy, 450);
297:     }
298:   }
299: 
300:   // ---------------------------------------------------------- particles
301: 
302:   void _dust(int n, bool air) {
303:     for (var i = 0; i < n; i++) {
304:       particles.add(Particle(
```

## app/lib/modules/dragon_jump/dragon_jump_module.dart · 32–42

```dart
32: }
33: 
34: const List<DragonItem> dragonItems = [
35:   DragonItem('heart', 'Trái tim thứ tư', 'Bắt đầu mỗi lượt với 4 trái tim.', 120, icon: Icons.favorite_rounded),
36:   DragonItem('magnet', 'Nam châm vàng', 'Hút những đồng xu ở gần về phía Pip.', 150, icon: Icons.attractions_rounded),
37:   DragonItem('wings', 'Đôi cánh lớn', 'Pip nhảy được 3 lần liên tiếp trên không.', 200, icon: Icons.air_rounded),
38:   DragonItem('party', 'Mũ tiệc', 'Một chiếc mũ vui nhộn cho Pip.', 60, isHat: true),
39:   DragonItem('scarf', 'Khăn quàng', 'Khăn bay phấp phới khi chạy.', 80, isHat: true),
40:   DragonItem('goggles', 'Kính phi công', 'Sẵn sàng cho những cú bay cao.', 100, isHat: true),
41:   DragonItem('wizard', 'Mũ phù thuỷ', 'Rồng phép thuật của đảo.', 150, isHat: true),
42:   DragonItem('crown', 'Vương miện', 'Dành cho nhà vô địch Núi Lửa.', 250, isHat: true),
```

## app/lib/modules/dragon_jump/dragon_jump_module.dart · 130–143

```dart
130:     ));
131:     if (mounted) await _load();
132:   }
133: 
134:   Future<void> _openShop() async {
135:     await showPQSheet<void>(context, builder: (ctx) => DragonShop(onChanged: _load));
136:     if (mounted) await _load();
137:   }
138: 
139:   @override
140:   Widget build(BuildContext context) {
141:     final s = AppScope.of(context);
142:     final l = _loadout;
143:     final thresholds = s.config.gameIntList(kDragonGameId, 'star_scores', const [150, 300, 500]);
```

## app/lib/modules/dragon_jump/dragon_jump_module.dart · 459–487

```dart
459:   Future<void> _finish() async {
460:     final s = AppScope.of(context);
461:     final g = _game!;
462:     _ticker.stop();
463:     final thresholds = s.config.gameIntList(kDragonGameId, 'star_scores', const [150, 300, 500]);
464:     final score = g.score;
465:     final stars = thresholds.where((t) => score >= t).length;
466:     await s.store.addInt(kDragonGameId, 'coins', g.coins);
467:     await s.store.addInt(kDragonGameId, 'runs', 1);
468:     final notices = <RewardNotice>[];
469:     var best = score;
470:     var newBest = false;
471:     if (stars > 0) {
472:       final outcome = await s.events.emit(StandardEvent(
473:         type: EventTypes.levelCompleted,
474:         sourceId: kDragonGameId,
475:         data: {'level_id': 'run', 'stars': stars, 'score': score},
476:       ));
477:       notices.addAll(outcome.notices);
478:       best = outcome.bestScore;
479:       newBest = outcome.newHighScore || outcome.firstCompletion;
480:     } else {
481:       final r = await s.progress.levelRecord(kDragonGameId, 'run');
482:       best = r?.highScore ?? score;
483:     }
484:     if (!mounted) return;
485:     final cost = s.config.cost('arcade_run');
486:     final action = await showLevelResult(
487:       context,
```

## app/lib/modules/dragon_jump/dragon_jump_module.dart · 646–656

```dart
646:                               label: 'Thoát lượt chơi',
647:                               tone: PQTone.parchment,
648:                               expand: true,
649:                               onPressed: () {
650:                                 setState(() => _paused = false);
651:                                 g.hearts = 0;
652:                                 g.phase = DragonPhase.over;
653:                                 g.overT = 1.3;
654:                               },
655:                             ),
656:                           ],
```

## app/lib/data/repositories/progress_repository.dart · 62–74

```dart
62: 
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
```

## Design distinctions

- Source chốtcoins/runs rồi emit, không receipt-reconcile UI hoặc outertransaction trong_finish. Mockreceipt ởstudy không chứng minh exactlyonce.
- Zero-star không emit levelCompleted; fallbackbestScore không cónghĩa recordmới đãlưu.
- Finish trongpause gọi đườngkếtthúc; không diễn giải thành discardcoins.
- GameConfig chứa coin_value1 nhưng runtime pickup/score hiện dùng+1/+5 và×3 trực tiếp.
- SourcePainter vẽcontinuousground; conceptW05 cóplatformgaps không phù hợpluật hiện tại.
