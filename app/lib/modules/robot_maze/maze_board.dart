import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../shared/characters/characters.dart';
import '../../shared/theme/palette.dart';
import '../../shared/widgets/game_icons.dart';
import '../../shared/widgets/sprite_cache.dart';
import 'maze_models.dart';

/// Mutable visual state of a maze run (robot position, effects, hints).
class MazePlayback extends ChangeNotifier {
  MazePlayback(MazeLevel level) : robot = Offset(level.start.x.toDouble(), level.start.y.toDouble());

  Offset robot;
  double hop = 0;
  double shake = 0;
  double sink = 0;
  bool chestOpen = false;
  Mood mood = Mood.neutral;
  final Set<Cell> collected = {};
  final List<Cell> trail = [];
  Cell? crashCell;
  List<Cell> hintCells = const [];
  Cell? highlightCell;

  void reset(MazeLevel level) {
    robot = Offset(level.start.x.toDouble(), level.start.y.toDouble());
    hop = 0;
    shake = 0;
    sink = 0;
    chestOpen = false;
    mood = Mood.neutral;
    collected.clear();
    trail
      ..clear()
      ..add(level.start);
    crashCell = null;
    notifyListeners();
  }

  void update() => notifyListeners();
}

/// Draws the garden board, pickups and Robo.
class MazeBoardPainter extends CustomPainter {
  MazeBoardPainter({
    required this.level,
    required this.playback,
    required this.time,
    this.editorMode = false,
  }) : super(repaint: Listenable.merge([playback, time, SpriteCache.revision]));

  final MazeLevel level;
  final MazePlayback playback;
  final Animation<double> time;
  final bool editorMode;

  static const _grassA = Color(0xFFA4DE6F);
  static const _grassB = Color(0xFF93D460);
  static const _bushDark = Color(0xFF3E8F35);
  static const _bushLight = Color(0xFF5DB64C);
  static const _water = Color(0xFF4BC0EE);

  /// Board geometry for hit testing (editor) and layout.
  static ({Offset origin, double cell}) geometry(MazeLevel level, Size size) {
    const pad = 8.0;
    final cell = math.min((size.width - pad * 2) / level.width, (size.height - pad * 2) / level.height);
    final w = cell * level.width;
    final h = cell * level.height;
    return (origin: Offset((size.width - w) / 2, (size.height - h) / 2), cell: cell);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry(level, size);
    final cell = g.cell;
    final origin = g.origin;
    final boardRect = Rect.fromLTWH(origin.dx, origin.dy, cell * level.width, cell * level.height);
    final t = time.value;

    // 2.5D Garden stage surround + wooden courtyard frame (r50)
    final frame = RRect.fromRectAndRadius(boardRect.inflate(9), const Radius.circular(20));
    final ui.Image? stageSprite = SpriteCache.get('assets/images/garden_stage_r50.webp');
    if (stageSprite != null) {
      canvas.save();
      canvas.clipRRect(frame);
      paintImage(
        canvas: canvas,
        rect: frame.outerRect,
        image: stageSprite,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      );
      canvas.restore();
    }
    canvas.drawRRect(frame.shift(const Offset(0, 6)), Paint()..color = PQColors.ink.withValues(alpha: 0.28));
    if (stageSprite == null) {
      canvas.drawRRect(frame, Paint()..color = PQColors.wood);
    } else {
      canvas.drawRRect(frame, _stroke(5, const Color(0xFF8C6239)));
    }
    canvas.drawRRect(frame, _stroke(2.8));
    final inner = RRect.fromRectAndRadius(boardRect, const Radius.circular(14));
    canvas.save();
    canvas.clipRRect(inner);

    for (var y = 0; y < level.height; y++) {
      for (var x = 0; x < level.width; x++) {
        final r = Rect.fromLTWH(origin.dx + x * cell, origin.dy + y * cell, cell, cell);
        final tile = level.tiles[y][x];
        canvas.drawRect(r, Paint()..color = (x + y).isEven ? _grassA : _grassB);
        // 2.5D bevel on each courtyard tile
        canvas.drawLine(r.topLeft, r.topRight, Paint()..color = Colors.white.withValues(alpha: 0.26)..strokeWidth = 2);
        canvas.drawLine(r.topLeft, r.bottomLeft, Paint()..color = Colors.white.withValues(alpha: 0.18)..strokeWidth = 2);
        canvas.drawLine(r.bottomLeft, r.bottomRight, Paint()..color = const Color(0xFF4C8D32).withValues(alpha: 0.30)..strokeWidth = 2);
        canvas.drawLine(r.topRight, r.bottomRight, Paint()..color = const Color(0xFF4C8D32).withValues(alpha: 0.24)..strokeWidth = 2);
        if (tile == Tile.floor) _tuft(canvas, r, x * 7 + y * 13);
        if (tile == Tile.water) _waterTile(canvas, r, t, x, y);
      }
    }
    // Hint footprints and run trail
    for (final c in playback.trail) {
      final center = _center(origin, cell, c);
      canvas.drawCircle(center, cell * 0.09, Paint()..color = Colors.white.withValues(alpha: 0.55));
    }
    for (var i = 0; i < playback.hintCells.length; i++) {
      final c = playback.hintCells[i];
      final center = _center(origin, cell, c);
      final pulse = 0.75 + 0.25 * math.sin(t * math.pi * 2 * 6 + i);
      canvas.drawCircle(center, cell * 0.2 * pulse, Paint()..color = PQColors.sun.withValues(alpha: 0.85));
      canvas.drawCircle(center, cell * 0.2 * pulse, _stroke(2));
      _label(canvas, '${i + 1}', center, cell * 0.22);
    }
    if (playback.highlightCell != null) {
      final r = _cellRect(origin, cell, playback.highlightCell!).deflate(3);
      canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(cell * 0.18)), _stroke(3.4, PQColors.sun));
    }
    // Walls (2.5D isometric boxwood hedges from r50, row by row so tops overlap nicely)
    final ui.Image? hedgeSprite = SpriteCache.get('assets/images/hedge_token_r50.png');
    for (var y = 0; y < level.height; y++) {
      for (var x = 0; x < level.width; x++) {
        if (level.tiles[y][x] == Tile.wall) {
          final Rect cellRect = _cellRect(origin, cell, Cell(x, y));
          if (hedgeSprite != null) {
            canvas.drawOval(
              Rect.fromCenter(
                center: Offset(cellRect.center.dx, cellRect.bottom - cell * 0.08),
                width: cell * 0.90,
                height: cell * 0.24,
              ),
              Paint()..color = PQColors.ink.withValues(alpha: 0.22),
            );
            paintImage(
              canvas: canvas,
              rect: cellRect.inflate(cell * 0.06).shift(Offset(0, -cell * 0.04)),
              image: hedgeSprite,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
            );
          } else {
            _bush(canvas, cellRect, x + y * 3);
          }
        }
      }
    }
    if (playback.crashCell != null && level.inside(playback.crashCell!)) {
      final r = _cellRect(origin, cell, playback.crashCell!).deflate(2);
      canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(cell * 0.2)), _stroke(4, PQColors.danger));
    }
    // Start pad
    final startC = _center(origin, cell, level.start);
    canvas.drawOval(Rect.fromCenter(center: startC.translate(0, cell * 0.22), width: cell * 0.7, height: cell * 0.28),
        Paint()..color = const Color(0xFFE9E2CF));
    canvas.drawOval(Rect.fromCenter(center: startC.translate(0, cell * 0.22), width: cell * 0.7, height: cell * 0.28), _stroke(2));
    // Gems
    for (final gem in level.gems) {
      if (playback.collected.contains(gem)) continue;
      final c = _center(origin, cell, gem).translate(0, math.sin(t * math.pi * 2 * 4 + gem.x) * cell * 0.04);
      final s = cell * 0.5;
      canvas.save();
      canvas.translate(c.dx - s / 2, c.dy - s / 2);
      GameIconPainter(GameIconKind.gem).paint(canvas, Size.square(s));
      canvas.restore();
      final sparkle = (math.sin(t * math.pi * 2 * 5 + gem.y * 2) + 1) / 2;
      if (sparkle > 0.7) {
        final sp = c.translate(s * 0.35, -s * 0.35);
        final a = (sparkle - 0.7) / 0.3;
        canvas.drawPath(starPath(sp, s * 0.18 * a + 1, s * 0.05 * a + 0.5), Paint()..color = Colors.white);
      }
    }
    // Chest
    _chest(canvas, _cellRect(origin, cell, level.goal), playback.chestOpen, t);
    canvas.restore();

    // Robo (not clipped so the antenna can poke above the top row)
    final rc = Offset(origin.dx + (playback.robot.dx + 0.5) * cell, origin.dy + (playback.robot.dy + 0.5) * cell);
    final shakeX = playback.shake * math.sin(t * math.pi * 2 * 30) * cell * 0.08;
    final scale = 1 - playback.sink * 0.8;
    final roboSize = cell * 1.08 * scale;
    canvas.save();
    canvas.translate(
        rc.dx - roboSize / 2 + shakeX, rc.dy - roboSize * 0.62 - playback.hop * cell * 0.25 + playback.sink * cell * 0.3);
    RoboPainter(t: t, blink: 0, bob: 0, mood: playback.mood).paint(canvas, Size.square(roboSize));
    canvas.restore();
    if (playback.sink > 0) {
      final splash = Paint()
        ..color = Colors.white.withValues(alpha: (1 - playback.sink) * 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawOval(Rect.fromCenter(center: rc.translate(0, cell * 0.2), width: cell * (0.4 + playback.sink), height: cell * 0.25), splash);
    }
  }

  Offset _center(Offset origin, double cell, Cell c) => Offset(origin.dx + (c.x + 0.5) * cell, origin.dy + (c.y + 0.5) * cell);
  Rect _cellRect(Offset origin, double cell, Cell c) => Rect.fromLTWH(origin.dx + c.x * cell, origin.dy + c.y * cell, cell, cell);

  Paint _stroke(double w, [Color c = PQColors.ink]) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  void _tuft(Canvas canvas, Rect r, int seed) {
    final rnd = math.Random(seed);
    final p = _stroke(1.6, const Color(0xFF6DB743));
    for (var i = 0; i < 2; i++) {
      final x = r.left + r.width * (0.2 + rnd.nextDouble() * 0.6);
      final y = r.top + r.height * (0.25 + rnd.nextDouble() * 0.6);
      final h = r.height * 0.08;
      canvas.drawLine(Offset(x, y), Offset(x - h * 0.4, y - h), p);
      canvas.drawLine(Offset(x, y), Offset(x + h * 0.4, y - h), p);
    }
    if (rnd.nextDouble() < 0.25) {
      final c = Offset(r.left + r.width * (0.2 + rnd.nextDouble() * 0.6), r.top + r.height * (0.2 + rnd.nextDouble() * 0.6));
      for (var k = 0; k < 4; k++) {
        final a = k * math.pi / 2;
        canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r.width * 0.04, r.width * 0.035, Paint()..color = Colors.white);
      }
      canvas.drawCircle(c, r.width * 0.03, Paint()..color = PQColors.sun);
    }
  }

  void _waterTile(Canvas canvas, Rect r, double t, int x, int y) {
    canvas.drawRect(r, Paint()..color = _water);
    canvas.drawRect(r.deflate(r.width * 0.06), Paint()..color = const Color(0xFF6ED3F7).withValues(alpha: 0.5));
    final wave = _stroke(2, Colors.white.withValues(alpha: 0.75));
    for (var i = 0; i < 2; i++) {
      final yy = r.top + r.height * (0.35 + i * 0.3);
      final shift = math.sin(t * math.pi * 2 * 3 + x + y + i) * r.width * 0.08;
      final p = Path()
        ..moveTo(r.left + r.width * 0.2 + shift, yy)
        ..quadraticBezierTo(r.left + r.width * 0.35 + shift, yy - r.height * 0.07, r.left + r.width * 0.5 + shift, yy)
        ..quadraticBezierTo(r.left + r.width * 0.65 + shift, yy + r.height * 0.07, r.left + r.width * 0.8 + shift, yy);
      canvas.drawPath(p, wave);
    }
  }

  void _bush(Canvas canvas, Rect r, int seed) {
    final w = r.width;
    final blobs = [
      (Offset(r.left + w * 0.3, r.top + w * 0.6), w * 0.27),
      (Offset(r.left + w * 0.7, r.top + w * 0.6), w * 0.27),
      (Offset(r.left + w * 0.5, r.top + w * 0.38), w * 0.3),
      (Offset(r.left + w * 0.5, r.top + w * 0.68), w * 0.28),
    ];
    canvas.drawOval(Rect.fromCenter(center: Offset(r.center.dx, r.bottom - w * 0.1), width: w * 0.86, height: w * 0.22),
        Paint()..color = PQColors.ink.withValues(alpha: 0.18));
    final ink = Paint()..color = PQColors.ink;
    for (final (c, rad) in blobs) {
      canvas.drawCircle(c, rad + 2.2, ink);
    }
    for (final (c, rad) in blobs) {
      canvas.drawCircle(c, rad, Paint()..color = _bushDark);
    }
    for (final (c, rad) in blobs) {
      canvas.drawCircle(c.translate(-rad * 0.18, -rad * 0.2), rad * 0.62, Paint()..color = _bushLight);
    }
    final rnd = math.Random(seed);
    if (rnd.nextDouble() < 0.4) {
      canvas.drawCircle(Offset(r.left + w * (0.35 + rnd.nextDouble() * 0.3), r.top + w * 0.45), w * 0.05, Paint()..color = PQColors.berry);
    }
  }

  void _chest(Canvas canvas, Rect r, bool open, double t) {
    final w = r.width;
    final body = Rect.fromLTWH(r.left + w * 0.18, r.top + w * 0.45, w * 0.64, w * 0.38);
    if (open) {
      final glow = 0.6 + 0.4 * math.sin(t * math.pi * 2 * 6);
      canvas.drawCircle(body.center.translate(0, -w * 0.1), w * 0.42,
          Paint()..color = PQColors.sun.withValues(alpha: 0.35 * glow));
    }
    canvas.drawOval(Rect.fromCenter(center: Offset(r.center.dx, body.bottom), width: w * 0.75, height: w * 0.16),
        Paint()..color = PQColors.ink.withValues(alpha: 0.2));
    canvas.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(w * 0.06)), Paint()..color = PQColors.wood);
    canvas.drawRect(Rect.fromLTWH(body.left, body.top + body.height * 0.35, body.width, body.height * 0.14),
        Paint()..color = PQColors.woodDeep);
    canvas.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(w * 0.06)), _stroke(2.2));
    if (open) {
      final lid = Path()
        ..moveTo(body.left, body.top)
        ..lineTo(body.left + w * 0.06, body.top - w * 0.3)
        ..quadraticBezierTo(body.center.dx, body.top - w * 0.42, body.right - w * 0.06, body.top - w * 0.3)
        ..lineTo(body.right, body.top)
        ..close();
      canvas.drawPath(lid, Paint()..color = const Color(0xFFD08A4A));
      canvas.drawPath(lid, _stroke(2.2));
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(Offset(body.left + body.width * (0.3 + i * 0.2), body.top + w * 0.02), w * 0.07, Paint()..color = PQColors.sun);
        canvas.drawCircle(Offset(body.left + body.width * (0.3 + i * 0.2), body.top + w * 0.02), w * 0.07, _stroke(1.4));
      }
    } else {
      final lid = RRect.fromRectAndCorners(
        Rect.fromLTWH(body.left - w * 0.02, body.top - w * 0.18, body.width + w * 0.04, w * 0.22),
        topLeft: Radius.circular(w * 0.14),
        topRight: Radius.circular(w * 0.14),
      );
      canvas.drawRRect(lid, Paint()..color = const Color(0xFFD08A4A));
      canvas.drawRRect(lid, _stroke(2.2));
      final lock = Rect.fromCenter(center: Offset(body.center.dx, body.top + w * 0.02), width: w * 0.14, height: w * 0.16);
      canvas.drawRect(lock, Paint()..color = PQColors.sun);
      canvas.drawRect(lock, _stroke(1.6));
    }
  }

  void _label(Canvas canvas, String text, Offset c, double size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w800, fontSize: size, color: PQColors.ink)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(MazeBoardPainter old) => old.level != level || old.playback != playback || old.editorMode != editorMode;
}
