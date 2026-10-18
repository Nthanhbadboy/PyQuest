# Source notes r55 — luật nguồn, không phải execution evidence

Pin CODE `6dc8ca8feeed54cc0fa6a82109e3a59d24a16153`. Trích trực tiếp bằng `git show`, giữ số dòng.
Không chạy Dart/SQLite trong r55; không gọi các đề xuất UI là hành vi nguồn.

## `app/lib/modules/catch_stars/stars_game.dart` · 46–195

```dart
46:
47:   Size size = Size.zero;
48:   double get k => size.width / 400;
49:   double get heightUnits => size.height / k;
50:   double get basketY => heightUnits * 0.84;
51:
52:   bool started = false;
53:   bool over = false;
54:   double time = 0;
55:   double basketX = 200;
56:   double targetX = 200;
57:   int hearts;
58:   int score = 0;
59:   int caught = 0;
60:   int combo = 0;
61:   int bestCombo = 0;
62:   double rainbow = 0;
63:   double hurt = 0;
64:   double _spawn = 0.6;
65:   final List<Faller> fallers = [];
66:   final List<Spark> sparks = [];
67:   final List<FloatText> texts = [];
68:   final List<String> events = [];
69:
70:   double get timeLeft => math.max(0, roundSeconds - time);
71:   int get multiplier => math.min(3, 1 + combo ~/ 5) * (rainbow > 0 ? 2 : 1);
72:
73:   void moveTo(double screenX) {
74:     if (size == Size.zero) return;
75:     targetX = (screenX / k).clamp(45.0, 355.0);
76:     started = true;
77:   }
78:
79:   void nudge(double screenDx) {
80:     if (size == Size.zero) return;
81:     targetX = (targetX + screenDx / k).clamp(45.0, 355.0);
82:     started = true;
83:   }
84:
85:   /// Fixed 1/60 s sub-steps keep the round in real time on slow devices.
86:   void update(double frameDt) {
87:     if (size == Size.zero) return;
88:     var remaining = frameDt.clamp(0.0, 0.25);
89:     while (remaining > 1e-6) {
90:       final step = math.min(remaining, 1 / 60);
91:       _step(step);
92:       remaining -= step;
93:     }
94:     notifyListeners();
95:   }
96:
97:   void _step(double dt) {
98:     if (!started || over) {
99:       _updateFx(dt);
100:       return;
101:     }
102:     time += dt;
103:     rainbow = math.max(0, rainbow - dt);
104:     hurt = math.max(0, hurt - dt * 2);
105:     basketX += (targetX - basketX) * math.min(1, dt * 14);
106:
107:     final progress = (time / roundSeconds).clamp(0.0, 1.0);
108:     _spawn -= dt;
109:     if (_spawn <= 0) {
110:       _spawnOne(progress);
111:       _spawn = (0.85 - progress * 0.45) * (0.7 + _rnd.nextDouble() * 0.6);
112:     }
113:     for (final f in fallers) {
114:       f.y += f.vy * dt * (1 + progress * 0.35);
115:       f.x += math.sin(time * 2 + f.sway) * f.sway * dt * 20;
116:       if (!f.done && (f.y - basketY).abs() < 26 && (f.x - basketX).abs() < 52) {
117:         f.done = true;
118:         _catch(f);
119:       }
120:       if (!f.done && f.y > heightUnits + 30) {
121:         f.done = true;
122:         if (f.kind != FallKind.meteor && combo > 0) {
123:           combo = 0;
124:           events.add('miss');
125:         }
126:       }
127:     }
128:     fallers.removeWhere((f) => f.done);
129:     _updateFx(dt);
130:     if (time >= roundSeconds || hearts <= 0) {
131:       over = true;
132:       events.add('over');
133:     }
134:   }
135:
136:   void _spawnOne(double progress) {
137:     final r = _rnd.nextDouble();
138:     FallKind kind;
139:     if (r < 0.14 + progress * 0.12) {
140:       kind = FallKind.meteor;
141:     } else if (r < 0.22 + progress * 0.12) {
142:       kind = FallKind.comet;
143:     } else if (r < 0.28 + progress * 0.12) {
144:       kind = FallKind.golden;
145:     } else if (r < 0.30 + progress * 0.12) {
146:       kind = FallKind.rainbow;
147:     } else {
148:       kind = FallKind.star;
149:     }
150:     final speed = switch (kind) {
151:       FallKind.star => 150 + _rnd.nextDouble() * 70,
152:       FallKind.golden => 120 + _rnd.nextDouble() * 40,
153:       FallKind.comet => 330 + _rnd.nextDouble() * 80,
154:       FallKind.rainbow => 140.0,
155:       FallKind.meteor => 190 + _rnd.nextDouble() * 90,
156:     };
157:     fallers.add(Faller(kind, 40 + _rnd.nextDouble() * 320, -30, speed, kind == FallKind.comet ? 0 : _rnd.nextDouble() * 2));
158:   }
159:
160:   void _catch(Faller f) {
161:     final at = Offset(f.x, basketY - 10);
162:     if (f.kind == FallKind.meteor) {
163:       hearts--;
164:       combo = 0;
165:       hurt = 1;
166:       events.add('hit');
167:       _burst(at, PQColors.coral, 14);
168:       texts.add(FloatText('Ối!', at, PQColors.coral));
169:       return;
170:     }
171:     caught++;
172:     combo++;
173:     bestCombo = math.max(bestCombo, combo);
174:     final base = switch (f.kind) {
175:       FallKind.star => 1,
176:       FallKind.golden => 5,
177:       FallKind.comet => 3,
178:       FallKind.rainbow => 2,
179:       FallKind.meteor => 0,
180:     };
181:     if (f.kind == FallKind.rainbow) {
182:       rainbow = 6;
183:       events.add('rainbow');
184:     }
185:     final gained = base * multiplier;
186:     score += gained;
187:     events.add(f.kind == FallKind.star ? 'catch' : 'bonus');
188:     _burst(at, f.kind == FallKind.comet ? PQColors.sky : PQColors.sun, f.kind == FallKind.star ? 6 : 12);
189:     texts.add(FloatText('+$gained', at, PQColors.sun));
190:   }
191:
192:   void _burst(Offset at, Color c, int n) {
193:     for (var i = 0; i < n; i++) {
194:       final a = _rnd.nextDouble() * math.pi * 2;
195:       final v = 60 + _rnd.nextDouble() * 140;
```

## `app/lib/modules/catch_stars/stars_game.dart` · 320–353

```dart
320:             ..lineTo(c.dx - 10 * k, c.dy + 10 * k)
321:             ..close();
322:           canvas.drawPath(rock, Paint()..color = const Color(0xFF7A5C4F));
323:           canvas.drawPath(rock, _ink(2.2));
324:           canvas.drawCircle(c.translate(-3 * k, 1 * k), 3 * k, Paint()..color = const Color(0xFF5A3F35));
325:       }
326:     }
327:
328:     // Jar on a little cloud
329:     final bx = g.basketX * k;
330:     final by = g.basketY * k;
331:     _cloud(canvas, Offset(bx, by + 26 * k), 60 * k);
332:     final jar = RRect.fromRectAndCorners(
333:       Rect.fromCenter(center: Offset(bx, by + 4 * k), width: 82 * k, height: 50 * k),
334:       bottomLeft: Radius.circular(18 * k),
335:       bottomRight: Radius.circular(18 * k),
336:       topLeft: Radius.circular(6 * k),
337:       topRight: Radius.circular(6 * k),
338:     );
339:     final glow = math.min(1.0, g.caught / 40);
340:     canvas.drawRRect(jar, Paint()..color = Color.lerp(const Color(0x66BFE3FF), const Color(0xCCFFE27A), glow)!);
341:     for (var i = 0; i < math.min(g.caught, 12); i++) {
342:       final sx = bx - 28 * k + (i % 6) * 11 * k;
343:       final sy = by + 18 * k - (i ~/ 6) * 11 * k;
344:       _star(canvas, Offset(sx, sy), 5 * k, PQColors.sun, 0);
345:     }
346:     canvas.drawRRect(jar, _ink(3));
347:     canvas.drawLine(Offset(bx - 30 * k, by - 12 * k), Offset(bx - 30 * k, by + 14 * k), _ink(2.4, Colors.white.withValues(alpha: 0.6)));
348:     final rim = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(bx, by - 21 * k), width: 92 * k, height: 12 * k), Radius.circular(6 * k));
349:     canvas.drawRRect(rim, Paint()..color = PQColors.wood);
350:     canvas.drawRRect(rim, _ink(2.4));
351:     // Robo peeks from behind the jar
352:     canvas.save();
353:     final roboSize = 52 * k;
```

## `app/lib/modules/catch_stars/stars_game.dart` · 400–442

```dart
400:     ..strokeCap = StrokeCap.round;
401:
402:   @override
403:   bool shouldRepaint(StarsPainter old) => old.game != game;
404: }
405:
406: /// A constellation in the Star Atlas collection.
407: class Constellation {
408:   const Constellation(this.id, this.name, this.threshold, this.points, this.lines, this.story);
409:   final String id;
410:   final String name;
411:   final int threshold;
412:   final List<Offset> points; // normalised 0..1
413:   final List<(int, int)> lines;
414:   final String story;
415: }
416:
417: const List<Constellation> constellations = [
418:   Constellation('robo', 'Chòm Robo', 30,
419:       [Offset(0.3, 0.3), Offset(0.7, 0.3), Offset(0.7, 0.65), Offset(0.3, 0.65), Offset(0.5, 0.12), Offset(0.42, 0.45), Offset(0.58, 0.45)],
420:       [(0, 1), (1, 2), (2, 3), (3, 0), (4, 0), (4, 1)], 'Người ta kể rằng Robo đầu tiên được chế tạo dưới chòm sao này.'),
421:   Constellation('pip', 'Chòm Rồng Pip', 80,
422:       [Offset(0.15, 0.6), Offset(0.35, 0.45), Offset(0.55, 0.5), Offset(0.7, 0.3), Offset(0.85, 0.35), Offset(0.45, 0.25), Offset(0.6, 0.7)],
423:       [(0, 1), (1, 2), (2, 3), (3, 4), (1, 5), (5, 3), (2, 6)], 'Một chú rồng con đang dang cánh bay về phía mặt trăng.'),
424:   Constellation('bitsy', 'Chòm Mèo Bitsy', 150,
425:       [Offset(0.3, 0.2), Offset(0.4, 0.35), Offset(0.6, 0.35), Offset(0.7, 0.2), Offset(0.65, 0.6), Offset(0.35, 0.6), Offset(0.85, 0.75)],
426:       [(0, 1), (1, 2), (2, 3), (2, 4), (4, 5), (5, 1), (4, 6)], 'Đôi tai nhọn và chiếc đuôi dài — Bitsy luôn canh chừng những con bọ lỗi.'),
427:   Constellation('py', 'Chòm Rắn Py', 250,
428:       [Offset(0.15, 0.75), Offset(0.3, 0.6), Offset(0.5, 0.65), Offset(0.65, 0.5), Offset(0.55, 0.3), Offset(0.7, 0.18), Offset(0.85, 0.22)],
429:       [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6)], 'Uốn lượn như một dòng code dài, chòm sao của người thầy thông thái.'),
430:   Constellation('chest', 'Chòm Rương Báu', 400,
431:       [Offset(0.25, 0.45), Offset(0.75, 0.45), Offset(0.75, 0.75), Offset(0.25, 0.75), Offset(0.3, 0.3), Offset(0.7, 0.3), Offset(0.5, 0.55)],
432:       [(0, 1), (1, 2), (2, 3), (3, 0), (0, 4), (4, 5), (5, 1)], 'Ai tìm thấy chòm sao này sẽ gặp may mắn khi mở rương.'),
433:   Constellation('rocket', 'Chòm Tên Lửa', 600,
434:       [Offset(0.5, 0.1), Offset(0.62, 0.3), Offset(0.62, 0.65), Offset(0.38, 0.65), Offset(0.38, 0.3), Offset(0.75, 0.8), Offset(0.25, 0.8)],
435:       [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (2, 5), (3, 6)], 'Chỉ đường cho những nhà phát minh muốn bay tới các vì sao.'),
436:   Constellation('whale', 'Chòm Cá Voi', 850,
437:       [Offset(0.1, 0.55), Offset(0.3, 0.4), Offset(0.6, 0.38), Offset(0.85, 0.5), Offset(0.6, 0.65), Offset(0.3, 0.65), Offset(0.9, 0.3)],
438:       [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (3, 6)], 'Một chú cá voi hiền lành bơi giữa biển sao, phun ra những vì sao nhỏ.'),
439:   Constellation('snail', 'Chòm Ốc Sên', 1200,
440:       [Offset(0.2, 0.7), Offset(0.8, 0.7), Offset(0.55, 0.35), Offset(0.4, 0.45), Offset(0.48, 0.55), Offset(0.85, 0.5), Offset(0.9, 0.4)],
441:       [(0, 1), (1, 2), (2, 3), (3, 4), (1, 5), (5, 6)], 'Chậm mà chắc — chòm sao dành cho người kiên nhẫn nhất đảo.'),
442: ];
```

## `app/lib/modules/catch_stars/catch_stars_module.dart` · 377–477

```dart
377:             break;
378:           case 'over':
379:             audio.play(Sfx.whoosh);
380:         }
381:       }
382:       g.events.clear();
383:     }
384:     if (g.over && !_finished) {
385:       _finished = true;
386:       Future<void>.delayed(const Duration(milliseconds: 900), _finish);
387:     }
388:   }
389:
390:   Future<void> _finish() async {
391:     if (!mounted) return;
392:     final s = AppScope.of(context);
393:     final g = _game!;
394:     _ticker.stop();
395:     final thresholds = s.config.gameIntList(kStarsGameId, 'star_scores', const [60, 150, 300]);
396:     final stars = thresholds.where((t) => g.score >= t).length;
397:     final before = await s.store.getInt(kStarsGameId, 'atlas_total');
398:     final after = await s.store.addInt(kStarsGameId, 'atlas_total', g.caught);
399:     final bestCaught = await s.store.getInt(kStarsGameId, 'best_caught');
400:     if (g.caught > bestCaught) await s.store.setInt(kStarsGameId, 'best_caught', g.caught);
401:     final notices = <RewardNotice>[];
402:     for (final c in constellations) {
403:       if (before < c.threshold && after >= c.threshold) {
404:         final o = await s.events.emit(StandardEvent(type: EventTypes.itemCollected, sourceId: kStarsGameId, data: {'item_id': 'const:${c.id}'}));
405:         notices.add(RewardNotice(kind: RewardKind.item, id: c.id, title: 'Chòm sao mới: ${c.name}', description: c.story));
406:         notices.addAll(o.notices);
407:       }
408:     }
409:     var best = g.score;
410:     var newBest = false;
411:     if (stars > 0) {
412:       final outcome = await s.events.emit(StandardEvent(
413:         type: EventTypes.levelCompleted,
414:         sourceId: kStarsGameId,
415:         data: {'level_id': 'run', 'stars': stars, 'score': g.score, 'caught': g.caught},
416:       ));
417:       notices.addAll(outcome.notices);
418:       best = outcome.bestScore;
419:       newBest = outcome.newHighScore || outcome.firstCompletion;
420:     } else {
421:       final r = await s.progress.levelRecord(kStarsGameId, 'run');
422:       best = math.max(best, r?.highScore ?? 0);
423:     }
424:     if (!mounted) return;
425:     final cost = s.config.cost('arcade_run');
426:     final action = await showLevelResult(
427:       context,
428:       LevelResultData(
429:         gameName: 'Hái Sao',
430:         levelTitle: 'Đài Thiên Văn',
431:         success: stars > 0,
432:         stars: stars,
433:         score: g.score,
434:         bestScore: best,
435:         newBest: newBest && stars > 0,
436:         goals: [for (var i = 0; i < thresholds.length; i++) ResultGoal('Đạt ${thresholds[i]} điểm', g.score >= thresholds[i])],
437:         stats: [
438:           ResultStat('Sao đã hái', '${g.caught}'),
439:           ResultStat('Chuỗi dài nhất', '${g.bestCombo}'),
440:           ResultStat('Tổng sao', '$after'),
441:         ],
442:         skill: 'Vòng lặp trò chơi: mỗi khung hình, máy tính cập nhật vị trí, kiểm tra va chạm rồi vẽ lại.',
443:         host: CharacterId.robo,
444:         hostLine: stars > 0
445:             ? 'Đẹp quá! Những ngôi sao bạn hái được đã bay lên bản đồ chòm sao.'
446:             : 'Bầu trời hôm nay hơi khó! Thử đứng chờ ngay dưới ngôi sao rơi nhé.',
447:         notices: notices,
448:         primaryLabel: 'Chơi lại',
449:         primaryCost: cost,
450:         tone: PQTone.night,
451:       ),
452:     );
453:     if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
454:     switch (action) {
455:       case ResultAction.primary:
456:         if (!await spendEnergy(context, cost)) {
457:           if (mounted) Navigator.of(context).pop();
458:           return;
459:         }
460:         if (!mounted) return;
461:         Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const StarsPlayScreen()));
462:       case ResultAction.replay:
463:       case ResultAction.back:
464:         Navigator.of(context).pop();
465:       case ResultAction.map:
466:         Navigator.of(context).popUntil((r) => r.isFirst);
467:     }
468:   }
469:
470:   @override
471:   Widget build(BuildContext context) {
472:     final g = _game!;
473:     return PopScope(
474:       canPop: false,
475:       onPopInvokedWithResult: (didPop, result) {
476:         if (didPop) return;
477:         if (g.started && !g.over) {
```

## `app/lib/modules/catch_stars/catch_stars_module.dart` · 581–600

```dart
581:                             const SizedBox(height: 12),
582:                             ChunkyButton(label: 'Chơi tiếp', tone: PQTone.sun, expand: true, onPressed: () => setState(() => _paused = false)),
583:                             const SizedBox(height: 10),
584:                             ChunkyButton(
585:                               label: 'Kết thúc đêm nay',
586:                               tone: PQTone.parchment,
587:                               expand: true,
588:                               onPressed: () => setState(() {
589:                                 _paused = false;
590:                                 g.time = g.roundSeconds;
591:                               }),
592:                             ),
593:                           ],
594:                         ),
595:                       ),
596:                     ),
597:                   ),
598:                 ),
599:               ),
600:           ],
```

## `app/lib/data/repositories/progress_repository.dart` · 63–105

```dart
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
