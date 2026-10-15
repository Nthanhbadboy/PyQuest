import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../shared/characters/characters.dart';
import '../../shared/theme/palette.dart';
import '../../shared/widgets/game_icons.dart';

enum DragonPhase { ready, running, over }

enum ObstacleKind { rock, bush, pillar, beetle }

class Obstacle {
  Obstacle(this.kind, this.x, this.w, this.h, this.lift);
  final ObstacleKind kind;
  double x;
  final double w;
  final double h;

  /// Height of the obstacle's bottom above the ground (flying beetles).
  final double lift;
  bool passed = false;
}

class Pickup {
  Pickup(this.x, this.y, {this.gem = false});
  double x;
  double y; // height above ground (centre)
  final bool gem;
  bool taken = false;
  double takenT = 0;
}

class Particle {
  Particle(this.pos, this.vel, this.color, this.life, this.size);
  Offset pos;
  Offset vel;
  final Color color;
  double life;
  final double size;
}

/// Dragon Jump simulation. Units scale with screen width (k = width / 400)
/// so the game feels the same on every phone.
class DragonGame extends ChangeNotifier {
  DragonGame({
    required this.startSpeed,
    required this.maxSpeed,
    required this.speedGain,
    required this.maxHearts,
    required this.maxJumps,
    required this.magnet,
    this.hat,
    int seed = 0,
  })  : hearts = maxHearts,
        _rnd = math.Random(seed == 0 ? DateTime.now().millisecondsSinceEpoch : seed);

  final double startSpeed;
  final double maxSpeed;
  final double speedGain;
  final int maxHearts;
  final int maxJumps;
  final bool magnet;
  final String? hat;
  final math.Random _rnd;

  Size size = Size.zero;
  double get k => size.width / 400;
  double get groundY => size.height * 0.76;
  double get pipX => size.width * 0.24;

  DragonPhase phase = DragonPhase.ready;
  double time = 0;
  double distance = 0; // in units
  double speed = 0;
  double pipY = 0; // height above ground (units of k)
  double vy = 0;
  int jumpsUsed = 0;
  int hearts;
  double invulnerable = 0;
  double shake = 0;
  int coins = 0;
  int gems = 0;
  double runCycle = 0;
  double flapT = 0;
  double _nextSpawn = 0;
  double overT = 0;

  final List<Obstacle> obstacles = [];
  final List<Pickup> pickups = [];
  final List<Particle> particles = [];

  /// Events the screen turns into sounds.
  final List<String> events = [];

  int get distanceMeters => (distance / 50).floor();
  int get score => distanceMeters + coins * 3;
  bool get onGround => pipY <= 0.001 && vy <= 0;

  void start() {
    phase = DragonPhase.running;
    speed = startSpeed;
    _nextSpawn = 380;
    notifyListeners();
  }

  void jump() {
    if (phase == DragonPhase.ready) start();
    if (phase != DragonPhase.running) return;
    if (onGround) {
      jumpsUsed = 0;
    }
    if (jumpsUsed >= maxJumps) return;
    vy = jumpsUsed == 0 ? 900 : 800;
    jumpsUsed++;
    flapT = 1;
    events.add(jumpsUsed == 1 ? 'jump' : 'flap');
    _dust(jumpsUsed == 1 ? 6 : 10, jumpsUsed > 1);
  }

  void update(double dt) {
    if (size == Size.zero) return;
    dt = dt.clamp(0, 1 / 30);
    time += dt;
    if (phase == DragonPhase.ready) {
      runCycle += dt * 1.5;
      notifyListeners();
      return;
    }
    if (phase == DragonPhase.over) {
      overT += dt;
      vy -= 2700 * dt;
      pipY = math.max(0, pipY + vy * dt);
      _updateParticles(dt);
      shake = math.max(0, shake - dt * 3);
      notifyListeners();
      return;
    }
    speed = math.min(maxSpeed, speed + speedGain * dt);
    final dx = speed * dt;
    distance += dx;
    runCycle += dt * (speed / 120);
    flapT = math.max(0, flapT - dt * 3);
    invulnerable = math.max(0, invulnerable - dt);
    shake = math.max(0, shake - dt * 3);

    // Pip physics
    vy -= 2700 * dt;
    pipY += vy * dt;
    if (pipY <= 0) {
      if (vy < -600) _dust(4, false);
      pipY = 0;
      vy = 0;
      jumpsUsed = 0;
    }

    // World scroll (units → pixels via k)
    for (final o in obstacles) {
      o.x -= dx;
    }
    for (final p in pickups) {
      p.x -= dx;
    }
    obstacles.removeWhere((o) => o.x + o.w < -140);
    pickups.removeWhere((p) => p.x < -140 || (p.taken && p.takenT > 0.4));

    _nextSpawn -= dx;
    if (_nextSpawn <= 0) _spawnPattern();

    _collide(dt);
    _updateParticles(dt);
    notifyListeners();
  }

  // ---------------------------------------------------------- spawning

  double get _spawnX => 400 + 60.0;

  void _spawnPattern() {
    final difficulty = ((speed - startSpeed) / (maxSpeed - startSpeed)).clamp(0.0, 1.0);
    final roll = _rnd.nextDouble();
    final x = _spawnX;
    if (roll < 0.28) {
      _obstacle(ObstacleKind.rock, x);
      _coinArc(x - 30, 7, 150);
    } else if (roll < 0.46) {
      _obstacle(ObstacleKind.bush, x);
      _coinLine(x + 110, 4, 0);
    } else if (roll < 0.6 && difficulty > 0.15) {
      _obstacle(ObstacleKind.pillar, x);
      _coinArc(x - 40, 5, 230);
    } else if (roll < 0.76) {
      _obstacle(ObstacleKind.beetle, x, lift: 70 + _rnd.nextDouble() * 30);
      _coinLine(x - 30, 4, 18);
    } else if (roll < 0.88 && difficulty > 0.3) {
      _obstacle(ObstacleKind.rock, x);
      _obstacle(ObstacleKind.rock, x + 210 + 60 * (1 - difficulty));
    } else {
      _coinArc(x, 8, 120);
      if (_rnd.nextDouble() < 0.25) pickups.add(Pickup(x + 120, 210, gem: true));
    }
    final gap = 330 + _rnd.nextDouble() * 220 - difficulty * 120;
    _nextSpawn = gap * (speed / startSpeed).clamp(1.0, 1.6);
  }

  void _obstacle(ObstacleKind kind, double x, {double lift = 0}) {
    final (w, h) = switch (kind) {
      ObstacleKind.rock => (48.0, 44.0),
      ObstacleKind.bush => (74.0, 38.0),
      ObstacleKind.pillar => (36.0, 84.0),
      ObstacleKind.beetle => (46.0, 32.0),
    };
    obstacles.add(Obstacle(kind, x, w, h, lift));
  }

  void _coinLine(double x, int n, double height) {
    for (var i = 0; i < n; i++) {
      pickups.add(Pickup(x + i * 34, 22 + height));
    }
  }

  void _coinArc(double x, int n, double peak) {
    for (var i = 0; i < n; i++) {
      final t = n == 1 ? 0.5 : i / (n - 1);
      final h = 40 + math.sin(t * math.pi) * (peak - 40);
      pickups.add(Pickup(x + i * 30, h));
    }
  }

  // --------------------------------------------------------- collisions

  void _collide(double dt) {
    final center = Offset(0, pipY + 30);
    for (final p in pickups) {
      if (p.taken) {
        p.takenT += dt;
        continue;
      }
      if (magnet) {
        final pos = Offset(p.x, p.y);
        final d = (pos - center).distance;
        if (d < 130 && d > 1 && p.x > -20) {
          final step = math.min(d, 420 * dt);
          final dir = (center - pos) / d;
          p.x += dir.dx * step;
          p.y += dir.dy * step;
        }
      }
      if ((Offset(p.x, p.y) - center).distance < 34) {
        p.taken = true;
        if (p.gem) {
          gems++;
          coins += 5;
          events.add('gem');
        } else {
          coins += 1;
          events.add('coin');
        }
        _sparkle(Offset(p.x, p.y), p.gem ? PQColors.sea : PQColors.sun);
      }
    }
    if (invulnerable > 0) return;
    for (final o in obstacles) {
      final left = o.x + o.w * 0.12;
      final right = o.x + o.w * 0.88;
      final bottom = o.lift + o.h * 0.04;
      final top = o.lift + o.h * 0.86;
      final overlapX = right > -20 && left < 20;
      final overlapY = top > pipY + 8 && bottom < pipY + 52;
      if (overlapX && overlapY) {
        _hit();
        return;
      }
    }
  }

  void _hit() {
    hearts--;
    shake = 1;
    events.add('hit');
    _sparkle(Offset(0, pipY + 30), PQColors.danger, count: 14);
    if (hearts <= 0) {
      phase = DragonPhase.over;
      vy = 700;
      events.add('over');
    } else {
      invulnerable = 1.5;
      vy = math.max(vy, 450);
    }
  }

  // ---------------------------------------------------------- particles

  void _dust(int n, bool air) {
    for (var i = 0; i < n; i++) {
      particles.add(Particle(
        Offset(-10 + _rnd.nextDouble() * 20, pipY + (air ? 20 : 2)),
        Offset(-80 - _rnd.nextDouble() * 120, 30 + _rnd.nextDouble() * 80),
        air ? Colors.white : const Color(0xFFE8D3A2),
        0.5,
        5 + _rnd.nextDouble() * 5,
      ));
    }
  }

  void _sparkle(Offset at, Color c, {int count = 8}) {
    for (var i = 0; i < count; i++) {
      final a = _rnd.nextDouble() * math.pi * 2;
      final v = 80 + _rnd.nextDouble() * 120;
      particles.add(Particle(at, Offset(math.cos(a) * v, math.sin(a) * v), c, 0.45, 4 + _rnd.nextDouble() * 4));
    }
  }

  void _updateParticles(double dt) {
    for (final p in particles) {
      p.pos += p.vel * dt;
      p.vel = Offset(p.vel.dx * 0.96, p.vel.dy - 300 * dt);
      p.life -= dt;
    }
    particles.removeWhere((p) => p.life <= 0);
  }
}

/// Draws the parallax world, pickups, obstacles and Pip.
class DragonPainter extends CustomPainter {
  DragonPainter(this.game) : super(repaint: game);
  final DragonGame game;

  static final Path _mountains = _ridge(seed: 3, peaks: 6, base: 1.0);
  static final Path _hills = _ridge(seed: 11, peaks: 9, base: 1.0);

  static Path _ridge({required int seed, required int peaks, required double base}) {
    final rnd = math.Random(seed);
    final p = Path()..moveTo(0, base);
    for (var i = 0; i <= peaks; i++) {
      final x = i / peaks;
      final y = 0.25 + rnd.nextDouble() * 0.5;
      p.quadraticBezierTo(x - 0.5 / peaks, y - 0.2, x, y);
    }
    p
      ..lineTo(1, base)
      ..close();
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final g = game;
    g.size = size;
    final k = g.k;
    final ground = g.groundY;
    final shakeOffset = g.shake > 0 ? Offset(math.sin(g.time * 70) * 6 * g.shake, 0) : Offset.zero;
    canvas.save();
    canvas.translate(shakeOffset.dx, shakeOffset.dy);

    // Sky
    final sky = Rect.fromLTWH(-10, 0, size.width + 20, ground);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7CC8F8), Color(0xFFBDE6FF), Color(0xFFFFE5C2)],
          stops: [0, 0.6, 1],
        ).createShader(sky),
    );
    // Sun
    final sunC = Offset(size.width * 0.78, ground * 0.22);
    canvas.drawCircle(sunC, 60 * k, Paint()..color = const Color(0x55FFF3B0));
    canvas.drawCircle(sunC, 38 * k, Paint()..color = const Color(0xFFFFE27A));
    // Clouds
    for (var i = 0; i < 4; i++) {
      final speed = 0.08 + i * 0.03;
      final span = size.width + 200 * k;
      final x = (size.width + 100 * k) - ((g.distance * k * speed + i * span / 4) % span);
      final y = ground * (0.12 + (i % 3) * 0.12);
      _cloud(canvas, Offset(x, y), (40 + (i % 2) * 18) * k);
    }
    // Far mountains with the island volcano
    _layer(canvas, _mountains, size, ground, 0.55, const Color(0xFFA9C7E8), g.distance * k * 0.06);
    final vx = size.width * 1.2 - ((g.distance * k * 0.06) % (size.width * 1.6));
    _volcano(canvas, Offset(vx, ground - ground * 0.3), 150 * k, g.time);
    _layer(canvas, _hills, size, ground, 0.32, const Color(0xFF8ED46B), g.distance * k * 0.22);

    // Ground
    final groundRect = Rect.fromLTWH(-10, ground, size.width + 20, size.height - ground);
    canvas.drawRect(groundRect, Paint()..color = const Color(0xFFC98E52));
    canvas.drawRect(Rect.fromLTWH(-10, ground, size.width + 20, 16 * k), Paint()..color = const Color(0xFF6CC04A));
    canvas.drawLine(Offset(-10, ground), Offset(size.width + 10, ground), _ink(3));
    canvas.drawLine(Offset(-10, ground + 16 * k), Offset(size.width + 10, ground + 16 * k), _ink(2, const Color(0xFF4E9A2B)));
    final stripe = 46 * k;
    final off = (g.distance * k) % stripe;
    for (var x = -off; x < size.width + stripe; x += stripe) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, ground + 30 * k, 22 * k, 7 * k), Radius.circular(4 * k)),
        Paint()..color = const Color(0xFFB57A42),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x + 18 * k, ground + 58 * k, 14 * k, 6 * k), Radius.circular(3 * k)),
        Paint()..color = const Color(0xFFB57A42),
      );
    }

    Offset world(double ux, double uy) => Offset(g.pipX + ux * k, ground - uy * k);

    // Pickups
    for (final p in g.pickups) {
      final pos = world(p.x, p.y);
      if (pos.dx < -40 || pos.dx > size.width + 40) continue;
      final s = (p.gem ? 34 : 28) * k;
      final scale = p.taken ? (1 + p.takenT * 2) : 1.0;
      final alpha = p.taken ? (1 - p.takenT / 0.4).clamp(0.0, 1.0) : 1.0;
      if (alpha <= 0) continue;
      canvas.save();
      canvas.translate(pos.dx, pos.dy - (p.taken ? p.takenT * 60 * k : 0));
      canvas.scale(scale);
      final spin = p.gem ? 1.0 : (0.55 + 0.45 * math.cos(g.time * 6 + p.x * 0.05)).abs();
      canvas.scale(spin, 1);
      canvas.translate(-s / 2, -s / 2);
      final painter = GameIconPainter(p.gem ? GameIconKind.gem : GameIconKind.coin);
      if (alpha < 1) {
        canvas.saveLayer(Rect.fromLTWH(0, 0, s, s), Paint()..color = Colors.white.withValues(alpha: alpha));
        painter.paint(canvas, Size.square(s));
        canvas.restore();
      } else {
        painter.paint(canvas, Size.square(s));
      }
      canvas.restore();
    }

    // Obstacles
    for (final o in g.obstacles) {
      final left = g.pipX + o.x * k;
      if (left > size.width + 60 || left + o.w * k < -60) continue;
      final r = Rect.fromLTWH(left, ground - (o.lift + o.h) * k, o.w * k, o.h * k);
      switch (o.kind) {
        case ObstacleKind.rock:
          _rock(canvas, r);
        case ObstacleKind.bush:
          _thorns(canvas, r);
        case ObstacleKind.pillar:
          _pillar(canvas, r);
        case ObstacleKind.beetle:
          _beetle(canvas, r.shift(Offset(0, math.sin(g.time * 5 + o.x * 0.02) * 6 * k)), g.time);
      }
    }

    // Particles
    for (final p in g.particles) {
      final pos = world(p.pos.dx, p.pos.dy);
      canvas.drawCircle(pos, p.size * k * (p.life / 0.5).clamp(0.2, 1.0), Paint()..color = p.color.withValues(alpha: (p.life / 0.5).clamp(0.0, 1.0)));
    }

    // Pip
    final pipSize = 92 * k;
    final blink = g.invulnerable > 0 && (g.time * 12).floor().isEven;
    if (!blink) {
      final pos = world(0, g.pipY);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(g.pipX, ground + 2), width: (54 - math.min(40, g.pipY * 0.15)) * k, height: 9 * k),
        Paint()..color = PQColors.ink.withValues(alpha: 0.18),
      );
      canvas.save();
      canvas.translate(pos.dx - pipSize * 0.5, pos.dy - pipSize * 0.93);
      if (g.phase == DragonPhase.over) {
        canvas.translate(pipSize / 2, pipSize / 2);
        canvas.rotate(math.min(1.2, g.overT * 3));
        canvas.translate(-pipSize / 2, -pipSize / 2);
      }
      final airborne = !g.onGround;
      PipPainter(
        t: g.time / 3,
        blink: 0,
        bob: 0,
        mood: g.phase == DragonPhase.over ? Mood.sad : (airborne ? Mood.surprised : Mood.happy),
        hat: g.hat,
        run: airborne ? 0.25 : g.runCycle % 1,
        flap: airborne ? -0.9 + math.sin(g.time * 30) * 0.5 * g.flapT : null,
      ).paint(canvas, Size.square(pipSize));
      canvas.restore();
    }
    canvas.restore();
  }

  void _layer(Canvas canvas, Path ridge, Size size, double ground, double heightFrac, Color color, double scroll) {
    final h = ground * heightFrac;
    final w = size.width * 1.4;
    final x0 = -(scroll % w);
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(x0 + i * w, ground - h);
      canvas.scale(w, h);
      canvas.drawPath(ridge, Paint()..color = color);
      canvas.restore();
    }
  }

  void _volcano(Canvas canvas, Offset base, double w, double t) {
    final p = Path()
      ..moveTo(base.dx - w * 0.6, base.dy + w * 0.6)
      ..lineTo(base.dx - w * 0.14, base.dy - w * 0.15)
      ..quadraticBezierTo(base.dx, base.dy - w * 0.22, base.dx + w * 0.14, base.dy - w * 0.15)
      ..lineTo(base.dx + w * 0.6, base.dy + w * 0.6)
      ..close();
    canvas.drawPath(p, Paint()..color = const Color(0xFF9F8AA8));
    final lava = Path()
      ..moveTo(base.dx - w * 0.14, base.dy - w * 0.15)
      ..quadraticBezierTo(base.dx, base.dy - w * 0.05, base.dx + w * 0.14, base.dy - w * 0.15)
      ..quadraticBezierTo(base.dx, base.dy - w * 0.22, base.dx - w * 0.14, base.dy - w * 0.15);
    canvas.drawPath(lava, Paint()..color = const Color(0xFFFF9D5C));
    for (var i = 0; i < 3; i++) {
      final phase = (t * 0.25 + i / 3) % 1;
      canvas.drawCircle(
        Offset(base.dx + math.sin(phase * 6 + i) * w * 0.05, base.dy - w * 0.25 - phase * w * 0.5),
        w * (0.05 + phase * 0.08),
        Paint()..color = Colors.white.withValues(alpha: 0.55 * (1 - phase)),
      );
    }
  }

  void _cloud(Canvas canvas, Offset c, double r) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.92);
    canvas.drawCircle(c, r * 0.6, p);
    canvas.drawCircle(c.translate(-r * 0.55, r * 0.15), r * 0.42, p);
    canvas.drawCircle(c.translate(r * 0.6, r * 0.12), r * 0.45, p);
  }

  Paint _ink(double w, [Color c = PQColors.ink]) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  void _rock(Canvas canvas, Rect r) {
    final p = Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left + r.width * 0.18, r.top + r.height * 0.35)
      ..lineTo(r.left + r.width * 0.42, r.top)
      ..lineTo(r.left + r.width * 0.62, r.top + r.height * 0.3)
      ..lineTo(r.left + r.width * 0.82, r.top + r.height * 0.2)
      ..lineTo(r.right, r.bottom)
      ..close();
    canvas.drawPath(p, Paint()..color = const Color(0xFF8C93A8));
    canvas.drawPath(
        Path()
          ..moveTo(r.left + r.width * 0.42, r.top)
          ..lineTo(r.left + r.width * 0.5, r.bottom)
          ..lineTo(r.left + r.width * 0.18, r.top + r.height * 0.35)
          ..close(),
        Paint()..color = const Color(0xFFB0B7C9));
    canvas.drawPath(p, _ink(2.4));
  }

  void _thorns(Canvas canvas, Rect r) {
    final base = Paint()..color = const Color(0xFF6B4BA8);
    final p = Path()..moveTo(r.left, r.bottom);
    const spikes = 5;
    for (var i = 0; i < spikes; i++) {
      final x0 = r.left + r.width * i / spikes;
      final x1 = r.left + r.width * (i + 0.5) / spikes;
      final x2 = r.left + r.width * (i + 1) / spikes;
      p
        ..lineTo(x0, r.top + r.height * 0.45)
        ..lineTo(x1, r.top + (i.isEven ? 0 : r.height * 0.15))
        ..lineTo(x2, r.top + r.height * 0.45);
    }
    p
      ..lineTo(r.right, r.bottom)
      ..close();
    canvas.drawPath(p, base);
    canvas.drawPath(p, _ink(2.4));
    canvas.drawCircle(Offset(r.left + r.width * 0.3, r.top + r.height * 0.65), r.width * 0.05, Paint()..color = PQColors.berry);
    canvas.drawCircle(Offset(r.left + r.width * 0.7, r.top + r.height * 0.7), r.width * 0.05, Paint()..color = PQColors.berry);
  }

  void _pillar(Canvas canvas, Rect r) {
    final rr = RRect.fromRectAndCorners(r, topLeft: Radius.circular(r.width * 0.4), topRight: Radius.circular(r.width * 0.4));
    canvas.drawRRect(rr, Paint()..color = const Color(0xFFE09856));
    for (var i = 1; i < 4; i++) {
      final y = r.top + r.height * i / 4;
      canvas.drawLine(Offset(r.left + 3, y), Offset(r.right - 3, y), _ink(1.6, const Color(0xFFB06A30)));
    }
    canvas.drawRRect(rr, _ink(2.4));
  }

  void _beetle(Canvas canvas, Rect r, double t) {
    final wing = math.sin(t * 40) * 0.5 + 0.5;
    final wingPaint = Paint()..color = Colors.white.withValues(alpha: 0.75);
    canvas.drawOval(Rect.fromCenter(center: Offset(r.center.dx - r.width * 0.15, r.top), width: r.width * 0.5, height: r.height * (0.4 + wing * 0.5)), wingPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(r.center.dx + r.width * 0.15, r.top), width: r.width * 0.5, height: r.height * (0.4 + wing * 0.5)), wingPaint);
    final body = Rect.fromLTWH(r.left, r.top + r.height * 0.2, r.width, r.height * 0.8);
    canvas.drawOval(body, Paint()..color = const Color(0xFF3FAF7E));
    canvas.drawLine(Offset(body.center.dx, body.top), Offset(body.center.dx, body.bottom), _ink(1.8));
    canvas.drawOval(body, _ink(2.4));
    final head = Offset(r.left - r.width * 0.06, body.center.dy);
    canvas.drawCircle(head, r.height * 0.28, Paint()..color = const Color(0xFF2B6E50));
    canvas.drawCircle(head, r.height * 0.28, _ink(2));
    canvas.drawCircle(head.translate(-r.height * 0.08, -r.height * 0.06), r.height * 0.08, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(DragonPainter old) => old.game != game;
}
