import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../shared/characters/characters.dart';
import '../../shared/theme/palette.dart';
import '../../shared/widgets/game_icons.dart';

enum FallKind { star, golden, comet, rainbow, meteor }

class Faller {
  Faller(this.kind, this.x, this.y, this.vy, this.sway);
  final FallKind kind;
  double x; // 0..400 units
  double y; // units from top
  final double vy;
  final double sway;
  bool done = false;
}

class Spark {
  Spark(this.pos, this.vel, this.color, this.life);
  Offset pos;
  Offset vel;
  final Color color;
  double life;
}

class FloatText {
  FloatText(this.text, this.pos, this.color);
  final String text;
  Offset pos;
  final Color color;
  double life = 0.9;
}

/// Catch the Stars: move the star jar, catch what falls, dodge meteors.
class StarsGame extends ChangeNotifier {
  StarsGame({required this.roundSeconds, required this.maxHearts, int seed = 0})
      : hearts = maxHearts,
        _rnd = math.Random(seed == 0 ? DateTime.now().millisecondsSinceEpoch : seed);

  final double roundSeconds;
  final int maxHearts;
  final math.Random _rnd;

  Size size = Size.zero;
  double get k => size.width / 400;
  double get heightUnits => size.height / k;
  double get basketY => heightUnits * 0.84;

  bool started = false;
  bool over = false;
  double time = 0;
  double basketX = 200;
  double targetX = 200;
  int hearts;
  int score = 0;
  int caught = 0;
  int combo = 0;
  int bestCombo = 0;
  double rainbow = 0;
  double hurt = 0;
  double _spawn = 0.6;
  final List<Faller> fallers = [];
  final List<Spark> sparks = [];
  final List<FloatText> texts = [];
  final List<String> events = [];

  double get timeLeft => math.max(0, roundSeconds - time);
  int get multiplier => math.min(3, 1 + combo ~/ 5) * (rainbow > 0 ? 2 : 1);

  void moveTo(double screenX) {
    if (size == Size.zero) return;
    targetX = (screenX / k).clamp(45.0, 355.0);
    started = true;
  }

  void nudge(double screenDx) {
    if (size == Size.zero) return;
    targetX = (targetX + screenDx / k).clamp(45.0, 355.0);
    started = true;
  }

  void update(double dt) {
    if (size == Size.zero) return;
    dt = dt.clamp(0, 1 / 30);
    if (!started || over) {
      _updateFx(dt);
      notifyListeners();
      return;
    }
    time += dt;
    rainbow = math.max(0, rainbow - dt);
    hurt = math.max(0, hurt - dt * 2);
    basketX += (targetX - basketX) * math.min(1, dt * 14);

    final progress = (time / roundSeconds).clamp(0.0, 1.0);
    _spawn -= dt;
    if (_spawn <= 0) {
      _spawnOne(progress);
      _spawn = (0.85 - progress * 0.45) * (0.7 + _rnd.nextDouble() * 0.6);
    }
    for (final f in fallers) {
      f.y += f.vy * dt * (1 + progress * 0.35);
      f.x += math.sin(time * 2 + f.sway) * f.sway * dt * 20;
      if (!f.done && (f.y - basketY).abs() < 26 && (f.x - basketX).abs() < 52) {
        f.done = true;
        _catch(f);
      }
      if (!f.done && f.y > heightUnits + 30) {
        f.done = true;
        if (f.kind != FallKind.meteor && combo > 0) {
          combo = 0;
          events.add('miss');
        }
      }
    }
    fallers.removeWhere((f) => f.done);
    _updateFx(dt);
    if (time >= roundSeconds || hearts <= 0) {
      over = true;
      events.add('over');
    }
    notifyListeners();
  }

  void _spawnOne(double progress) {
    final r = _rnd.nextDouble();
    FallKind kind;
    if (r < 0.14 + progress * 0.12) {
      kind = FallKind.meteor;
    } else if (r < 0.22 + progress * 0.12) {
      kind = FallKind.comet;
    } else if (r < 0.28 + progress * 0.12) {
      kind = FallKind.golden;
    } else if (r < 0.30 + progress * 0.12) {
      kind = FallKind.rainbow;
    } else {
      kind = FallKind.star;
    }
    final speed = switch (kind) {
      FallKind.star => 150 + _rnd.nextDouble() * 70,
      FallKind.golden => 120 + _rnd.nextDouble() * 40,
      FallKind.comet => 330 + _rnd.nextDouble() * 80,
      FallKind.rainbow => 140.0,
      FallKind.meteor => 190 + _rnd.nextDouble() * 90,
    };
    fallers.add(Faller(kind, 40 + _rnd.nextDouble() * 320, -30, speed, kind == FallKind.comet ? 0 : _rnd.nextDouble() * 2));
  }

  void _catch(Faller f) {
    final at = Offset(f.x, basketY - 10);
    if (f.kind == FallKind.meteor) {
      hearts--;
      combo = 0;
      hurt = 1;
      events.add('hit');
      _burst(at, PQColors.coral, 14);
      texts.add(FloatText('Ối!', at, PQColors.coral));
      return;
    }
    caught++;
    combo++;
    bestCombo = math.max(bestCombo, combo);
    final base = switch (f.kind) {
      FallKind.star => 1,
      FallKind.golden => 5,
      FallKind.comet => 3,
      FallKind.rainbow => 2,
      FallKind.meteor => 0,
    };
    if (f.kind == FallKind.rainbow) {
      rainbow = 6;
      events.add('rainbow');
    }
    final gained = base * multiplier;
    score += gained;
    events.add(f.kind == FallKind.star ? 'catch' : 'bonus');
    _burst(at, f.kind == FallKind.comet ? PQColors.sky : PQColors.sun, f.kind == FallKind.star ? 6 : 12);
    texts.add(FloatText('+$gained', at, PQColors.sun));
  }

  void _burst(Offset at, Color c, int n) {
    for (var i = 0; i < n; i++) {
      final a = _rnd.nextDouble() * math.pi * 2;
      final v = 60 + _rnd.nextDouble() * 140;
      sparks.add(Spark(at, Offset(math.cos(a) * v, math.sin(a) * v - 60), c, 0.6));
    }
  }

  void _updateFx(double dt) {
    for (final s in sparks) {
      s.pos += s.vel * dt;
      s.vel = Offset(s.vel.dx * 0.95, s.vel.dy + 220 * dt);
      s.life -= dt;
    }
    sparks.removeWhere((s) => s.life <= 0);
    for (final t in texts) {
      t.pos = t.pos.translate(0, -50 * dt);
      t.life -= dt;
    }
    texts.removeWhere((t) => t.life <= 0);
  }
}

class StarsPainter extends CustomPainter {
  StarsPainter(this.game) : super(repaint: game);
  final StarsGame game;

  static final List<Offset> _bg = () {
    final r = math.Random(5);
    return List.generate(70, (_) => Offset(r.nextDouble(), r.nextDouble() * 0.8));
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final g = game;
    g.size = size;
    final k = g.k;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F1440), Color(0xFF2A2F7A), Color(0xFF5B4B9A)],
          stops: [0, 0.65, 1],
        ).createShader(rect),
    );
    if (g.rainbow > 0) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              PQColors.berry.withValues(alpha: 0.12),
              PQColors.sun.withValues(alpha: 0.12),
              PQColors.sea.withValues(alpha: 0.12),
            ],
          ).createShader(rect),
      );
    }
    for (var i = 0; i < _bg.length; i++) {
      final p = Offset(_bg[i].dx * size.width, _bg[i].dy * size.height);
      final tw = 0.4 + 0.6 * ((math.sin(g.time * 2 + i) + 1) / 2);
      canvas.drawCircle(p, (i % 3 == 0 ? 1.8 : 1.1) * k, Paint()..color = Colors.white.withValues(alpha: tw * 0.8));
    }
    // Moon
    final moon = Offset(size.width * 0.18, size.height * 0.12);
    canvas.drawCircle(moon, 34 * k, Paint()..color = const Color(0x33FFF6C8));
    canvas.drawCircle(moon, 24 * k, Paint()..color = const Color(0xFFFFF3BD));
    canvas.drawCircle(moon.translate(9 * k, -5 * k), 20 * k, Paint()..color = const Color(0xFF151A4C));
    // Hills + observatory silhouette
    final hill = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.84, size.width * 0.6, size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.95, size.width, size.height * 0.88)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hill, Paint()..color = const Color(0xFF1B1E4A));
    final ob = Offset(size.width * 0.82, size.height * 0.885);
    canvas.drawRect(Rect.fromLTWH(ob.dx - 18 * k, ob.dy - 22 * k, 36 * k, 22 * k), Paint()..color = const Color(0xFF14163A));
    canvas.drawArc(Rect.fromCenter(center: ob.translate(0, -22 * k), width: 40 * k, height: 36 * k), math.pi, math.pi, true,
        Paint()..color = const Color(0xFF14163A));
    canvas.drawLine(ob.translate(4 * k, -34 * k), ob.translate(22 * k, -50 * k), Paint()
      ..color = const Color(0xFF14163A)
      ..strokeWidth = 7 * k);

    // Fallers
    for (final f in g.fallers) {
      final c = Offset(f.x * k, f.y * k);
      switch (f.kind) {
        case FallKind.star:
          _star(canvas, c, 15 * k, PQColors.sun, g.time + f.sway);
        case FallKind.golden:
          canvas.drawCircle(c, 30 * k, Paint()..color = PQColors.sun.withValues(alpha: 0.25));
          _star(canvas, c, 24 * k, const Color(0xFFFFB627), g.time);
        case FallKind.comet:
          final tail = Path()
            ..moveTo(c.dx - 9 * k, c.dy)
            ..lineTo(c.dx, c.dy - 70 * k)
            ..lineTo(c.dx + 9 * k, c.dy)
            ..close();
          canvas.drawPath(tail, Paint()..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [PQColors.sky.withValues(alpha: 0.9), PQColors.sky.withValues(alpha: 0)],
          ).createShader(Rect.fromLTWH(c.dx - 9 * k, c.dy - 70 * k, 18 * k, 70 * k)));
          canvas.drawCircle(c, 11 * k, Paint()..color = const Color(0xFFD9F1FF));
          canvas.drawCircle(c, 11 * k, _ink(2));
        case FallKind.rainbow:
          for (var i = 0; i < 3; i++) {
            canvas.drawCircle(c, (26 - i * 6) * k, Paint()..color = [PQColors.berry, PQColors.sun, PQColors.sea][i].withValues(alpha: 0.6));
          }
          _star(canvas, c, 14 * k, Colors.white, g.time * 2);
        case FallKind.meteor:
          final tail = Path()
            ..moveTo(c.dx - 13 * k, c.dy)
            ..lineTo(c.dx, c.dy - 50 * k)
            ..lineTo(c.dx + 13 * k, c.dy)
            ..close();
          canvas.drawPath(tail, Paint()..color = PQColors.coral.withValues(alpha: 0.7));
          final rock = Path()
            ..moveTo(c.dx - 14 * k, c.dy)
            ..lineTo(c.dx - 6 * k, c.dy - 12 * k)
            ..lineTo(c.dx + 10 * k, c.dy - 10 * k)
            ..lineTo(c.dx + 15 * k, c.dy + 4 * k)
            ..lineTo(c.dx + 2 * k, c.dy + 14 * k)
            ..lineTo(c.dx - 10 * k, c.dy + 10 * k)
            ..close();
          canvas.drawPath(rock, Paint()..color = const Color(0xFF7A5C4F));
          canvas.drawPath(rock, _ink(2.2));
          canvas.drawCircle(c.translate(-3 * k, 1 * k), 3 * k, Paint()..color = const Color(0xFF5A3F35));
      }
    }

    // Jar on a little cloud
    final bx = g.basketX * k;
    final by = g.basketY * k;
    _cloud(canvas, Offset(bx, by + 26 * k), 60 * k);
    final jar = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(bx, by + 4 * k), width: 82 * k, height: 50 * k),
      bottomLeft: Radius.circular(18 * k),
      bottomRight: Radius.circular(18 * k),
      topLeft: Radius.circular(6 * k),
      topRight: Radius.circular(6 * k),
    );
    final glow = math.min(1.0, g.caught / 40);
    canvas.drawRRect(jar, Paint()..color = Color.lerp(const Color(0x66BFE3FF), const Color(0xCCFFE27A), glow)!);
    for (var i = 0; i < math.min(g.caught, 12); i++) {
      final sx = bx - 28 * k + (i % 6) * 11 * k;
      final sy = by + 18 * k - (i ~/ 6) * 11 * k;
      _star(canvas, Offset(sx, sy), 5 * k, PQColors.sun, 0);
    }
    canvas.drawRRect(jar, _ink(3));
    canvas.drawLine(Offset(bx - 30 * k, by - 12 * k), Offset(bx - 30 * k, by + 14 * k), _ink(2.4, Colors.white.withValues(alpha: 0.6)));
    final rim = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(bx, by - 21 * k), width: 92 * k, height: 12 * k), Radius.circular(6 * k));
    canvas.drawRRect(rim, Paint()..color = PQColors.wood);
    canvas.drawRRect(rim, _ink(2.4));
    // Robo peeks from behind the jar
    canvas.save();
    final roboSize = 52 * k;
    canvas.translate(bx + 30 * k, by - 50 * k);
    RoboPainter(t: g.time / 3, blink: 0, bob: 0, mood: g.hurt > 0 ? Mood.surprised : Mood.happy).paint(canvas, Size.square(roboSize));
    canvas.restore();
    if (g.hurt > 0) {
      canvas.drawRect(rect, Paint()..color = PQColors.danger.withValues(alpha: 0.18 * g.hurt));
    }

    for (final s in g.sparks) {
      canvas.drawCircle(s.pos.scale(k, k), 3.2 * k, Paint()..color = s.color.withValues(alpha: (s.life / 0.6).clamp(0.0, 1.0)));
    }
    for (final t in g.texts) {
      final tp = TextPainter(
        text: TextSpan(
          text: t.text,
          style: TextStyle(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w800,
            fontSize: 24 * k,
            color: t.color.withValues(alpha: (t.life / 0.9).clamp(0.0, 1.0)),
            shadows: const [Shadow(color: PQColors.ink, blurRadius: 0, offset: Offset(1.5, 1.5))],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, t.pos.scale(k, k) - Offset(tp.width / 2, tp.height));
    }
  }

  void _star(Canvas canvas, Offset c, double r, Color color, double spin) {
    final p = starPath(c, r, r * 0.48, rotation: -math.pi / 2 + math.sin(spin * 2) * 0.2);
    canvas.drawPath(p, Paint()..color = color);
    canvas.drawPath(p, _ink(math.max(1.4, r * 0.12)));
  }

  void _cloud(Canvas canvas, Offset c, double w) {
    final p = Paint()..color = const Color(0xFFE8ECFF);
    canvas.drawOval(Rect.fromCenter(center: c, width: w * 1.5, height: w * 0.45), p);
    canvas.drawCircle(c.translate(-w * 0.35, -w * 0.1), w * 0.25, p);
    canvas.drawCircle(c.translate(w * 0.3, -w * 0.08), w * 0.28, p);
  }

  Paint _ink(double w, [Color c = PQColors.ink]) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  @override
  bool shouldRepaint(StarsPainter old) => old.game != game;
}

/// A constellation in the Star Atlas collection.
class Constellation {
  const Constellation(this.id, this.name, this.threshold, this.points, this.lines, this.story);
  final String id;
  final String name;
  final int threshold;
  final List<Offset> points; // normalised 0..1
  final List<(int, int)> lines;
  final String story;
}

const List<Constellation> constellations = [
  Constellation('robo', 'Chòm Robo', 30,
      [Offset(0.3, 0.3), Offset(0.7, 0.3), Offset(0.7, 0.65), Offset(0.3, 0.65), Offset(0.5, 0.12), Offset(0.42, 0.45), Offset(0.58, 0.45)],
      [(0, 1), (1, 2), (2, 3), (3, 0), (4, 0), (4, 1)], 'Người ta kể rằng Robo đầu tiên được chế tạo dưới chòm sao này.'),
  Constellation('pip', 'Chòm Rồng Pip', 80,
      [Offset(0.15, 0.6), Offset(0.35, 0.45), Offset(0.55, 0.5), Offset(0.7, 0.3), Offset(0.85, 0.35), Offset(0.45, 0.25), Offset(0.6, 0.7)],
      [(0, 1), (1, 2), (2, 3), (3, 4), (1, 5), (5, 3), (2, 6)], 'Một chú rồng con đang dang cánh bay về phía mặt trăng.'),
  Constellation('bitsy', 'Chòm Mèo Bitsy', 150,
      [Offset(0.3, 0.2), Offset(0.4, 0.35), Offset(0.6, 0.35), Offset(0.7, 0.2), Offset(0.65, 0.6), Offset(0.35, 0.6), Offset(0.85, 0.75)],
      [(0, 1), (1, 2), (2, 3), (2, 4), (4, 5), (5, 1), (4, 6)], 'Đôi tai nhọn và chiếc đuôi dài — Bitsy luôn canh chừng những con bọ lỗi.'),
  Constellation('py', 'Chòm Rắn Py', 250,
      [Offset(0.15, 0.75), Offset(0.3, 0.6), Offset(0.5, 0.65), Offset(0.65, 0.5), Offset(0.55, 0.3), Offset(0.7, 0.18), Offset(0.85, 0.22)],
      [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6)], 'Uốn lượn như một dòng code dài, chòm sao của người thầy thông thái.'),
  Constellation('chest', 'Chòm Rương Báu', 400,
      [Offset(0.25, 0.45), Offset(0.75, 0.45), Offset(0.75, 0.75), Offset(0.25, 0.75), Offset(0.3, 0.3), Offset(0.7, 0.3), Offset(0.5, 0.55)],
      [(0, 1), (1, 2), (2, 3), (3, 0), (0, 4), (4, 5), (5, 1)], 'Ai tìm thấy chòm sao này sẽ gặp may mắn khi mở rương.'),
  Constellation('rocket', 'Chòm Tên Lửa', 600,
      [Offset(0.5, 0.1), Offset(0.62, 0.3), Offset(0.62, 0.65), Offset(0.38, 0.65), Offset(0.38, 0.3), Offset(0.75, 0.8), Offset(0.25, 0.8)],
      [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (2, 5), (3, 6)], 'Chỉ đường cho những nhà phát minh muốn bay tới các vì sao.'),
  Constellation('whale', 'Chòm Cá Voi', 850,
      [Offset(0.1, 0.55), Offset(0.3, 0.4), Offset(0.6, 0.38), Offset(0.85, 0.5), Offset(0.6, 0.65), Offset(0.3, 0.65), Offset(0.9, 0.3)],
      [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (3, 6)], 'Một chú cá voi hiền lành bơi giữa biển sao, phun ra những vì sao nhỏ.'),
  Constellation('snail', 'Chòm Ốc Sên', 1200,
      [Offset(0.2, 0.7), Offset(0.8, 0.7), Offset(0.55, 0.35), Offset(0.4, 0.45), Offset(0.48, 0.55), Offset(0.85, 0.5), Offset(0.9, 0.4)],
      [(0, 1), (1, 2), (2, 3), (3, 4), (1, 5), (5, 6)], 'Chậm mà chắc — chòm sao dành cho người kiên nhẫn nhất đảo.'),
];
