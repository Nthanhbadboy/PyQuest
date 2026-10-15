import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/palette.dart';

/// The island's original cast. All drawn in code so they can animate.
enum CharacterId { robo, pip, bitsy, py }

enum Mood { happy, neutral, sad, surprised, thinking }

extension CharacterInfo on CharacterId {
  String get displayName => switch (this) {
        CharacterId.robo => 'Robo',
        CharacterId.pip => 'Pip',
        CharacterId.bitsy => 'Bitsy',
        CharacterId.py => 'Thầy Py',
      };

  String get role => switch (this) {
        CharacterId.robo => 'Robot nhỏ thích phiêu lưu',
        CharacterId.pip => 'Chú rồng con mê sưu tầm xu',
        CharacterId.bitsy => 'Cô mèo thám tử săn lỗi',
        CharacterId.py => 'Người thầy ở Tháp Python',
      };

  Color get color => switch (this) {
        CharacterId.robo => PQColors.teal,
        CharacterId.pip => PQColors.coral,
        CharacterId.bitsy => PQColors.grape,
        CharacterId.py => PQColors.pyBlue,
      };
}

/// Animated character (idle bob + blink). [size] is the square box size.
class CharacterView extends StatefulWidget {
  const CharacterView({
    super.key,
    required this.id,
    this.size = 120,
    this.mood = Mood.happy,
    this.animate = true,
    this.hat,
  });

  final CharacterId id;
  final double size;
  final Mood mood;
  final bool animate;

  /// Optional cosmetic for Pip ('party', 'crown', 'wizard', 'scarf', 'goggles').
  final String? hat;

  @override
  State<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends State<CharacterView> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void didUpdateWidget(CharacterView old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) _c.repeat();
    if (!widget.animate && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            // Blink briefly once per loop.
            final blink = (t > 0.92 && t < 0.97) ? 1 - ((t - 0.945).abs() / 0.025).clamp(0.0, 1.0) : 0.0;
            final bob = math.sin(t * 2 * math.pi) * 0.025;
            return CustomPaint(painter: characterPainter(widget.id, t: t, blink: blink, bob: bob, mood: widget.mood, hat: widget.hat));
          },
        ),
      ),
    );
  }
}

CustomPainter characterPainter(CharacterId id,
    {double t = 0, double blink = 0, double bob = 0, Mood mood = Mood.happy, String? hat}) {
  return switch (id) {
    CharacterId.robo => RoboPainter(t: t, blink: blink, bob: bob, mood: mood),
    CharacterId.pip => PipPainter(t: t, blink: blink, bob: bob, mood: mood, hat: hat),
    CharacterId.bitsy => BitsyPainter(t: t, blink: blink, bob: bob, mood: mood),
    CharacterId.py => PyPainter(t: t, blink: blink, bob: bob, mood: mood),
  };
}

// --------------------------------------------------------------- helpers

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(double w, [Color c = PQColors.ink]) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

void _outlined(Canvas canvas, Path path, Color fill, double stroke, {Shader? shader}) {
  final p = Paint()..color = fill;
  if (shader != null) p.shader = shader;
  canvas.drawPath(path, p);
  canvas.drawPath(path, _stroke(stroke));
}

Shader _vertical(Rect r, Color top, Color bottom) =>
    LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]).createShader(r);

/// Base class: draws in a 100×100 design space scaled to the canvas.
abstract class CastPainter extends CustomPainter {
  CastPainter({required this.t, required this.blink, required this.bob, required this.mood});

  final double t;
  final double blink;
  final double bob;
  final Mood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 100;
    canvas.save();
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);
    // Ground shadow (does not bob).
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 95), width: 54 - bob * 120, height: 8),
        _fill(PQColors.ink.withValues(alpha: 0.16)));
    canvas.translate(0, bob * 100);
    draw(canvas);
    canvas.restore();
  }

  void draw(Canvas canvas);

  void eye(Canvas canvas, Offset c, double rx, double ry, {Offset look = Offset.zero, Color iris = PQColors.ink}) {
    final open = 1 - blink;
    if (open < 0.15) {
      canvas.drawLine(c.translate(-rx, 0), c.translate(rx, 0), _stroke(2.6));
      return;
    }
    final r = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2 * open);
    canvas.drawOval(r, _fill(Colors.white));
    canvas.drawOval(r, _stroke(2.2));
    final pr = rx * 0.62;
    final pc = c + look;
    canvas.save();
    canvas.clipPath(Path()..addOval(r));
    canvas.drawCircle(pc, pr, _fill(iris));
    canvas.drawCircle(pc.translate(-pr * 0.35, -pr * 0.4), pr * 0.36, _fill(Colors.white));
    canvas.restore();
  }

  @override
  bool shouldRepaint(CastPainter old) => old.t != t || old.blink != blink || old.bob != bob || old.mood != mood;
}

// ------------------------------------------------------------------ Robo

class RoboPainter extends CastPainter {
  RoboPainter({required super.t, required super.blink, required super.bob, required super.mood});

  static const _body = PQColors.teal;
  static const _bodyDark = PQColors.tealDeep;
  static const _screen = Color(0xFF1B2547);
  static const _led = Color(0xFF7DF9FF);

  @override
  void draw(Canvas canvas) {
    final wave = mood == Mood.happy ? math.sin(t * 2 * math.pi * 2) * 0.35 : 0.0;
    // Wheels
    for (final x in [34.0, 54.0]) {
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(x, 84, 12, 8), const Radius.circular(4));
      canvas.drawRRect(r, _fill(const Color(0xFF3B4466)));
      canvas.drawRRect(r, _stroke(2.2));
    }
    // Arms
    canvas.save();
    canvas.translate(30, 67);
    canvas.rotate(0.5 + wave);
    final armL = RRect.fromRectAndRadius(const Rect.fromLTWH(-4, 0, 8, 17), const Radius.circular(4));
    canvas.drawRRect(armL, _fill(_bodyDark));
    canvas.drawRRect(armL, _stroke(2.2));
    canvas.restore();
    canvas.save();
    canvas.translate(70, 67);
    canvas.rotate(-0.5 - (mood == Mood.happy ? 0.9 + wave : 0));
    final armR = RRect.fromRectAndRadius(const Rect.fromLTWH(-4, 0, 8, 17), const Radius.circular(4));
    canvas.drawRRect(armR, _fill(_bodyDark));
    canvas.drawRRect(armR, _stroke(2.2));
    canvas.restore();
    // Body
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(30, 60, 40, 28), const Radius.circular(10));
    canvas.drawRRect(body, Paint()..shader = _vertical(body.outerRect, Color.lerp(_body, Colors.white, 0.2)!, _body));
    canvas.drawRRect(body, _stroke(2.6));
    final glow = 0.55 + 0.45 * math.sin(t * 2 * math.pi * 3).abs();
    canvas.drawCircle(const Offset(50, 74), 7, _fill(PQColors.pyYellow.withValues(alpha: 0.35 * glow)));
    canvas.drawCircle(const Offset(50, 74), 4.2, _fill(PQColors.pyYellow));
    canvas.drawCircle(const Offset(50, 74), 4.2, _stroke(1.8));
    // Neck
    canvas.drawRect(const Rect.fromLTWH(45, 55, 10, 7), _fill(_bodyDark));
    canvas.drawRect(const Rect.fromLTWH(45, 55, 10, 7), _stroke(2));
    // Antenna
    canvas.drawLine(const Offset(50, 19), const Offset(50, 9), _stroke(2.6));
    final antGlow = 0.5 + 0.5 * math.sin(t * 2 * math.pi * 2);
    canvas.drawCircle(const Offset(50, 7), 8, _fill(PQColors.coral.withValues(alpha: 0.25 * antGlow)));
    canvas.drawCircle(const Offset(50, 7), 4.6, _fill(PQColors.coral));
    canvas.drawCircle(const Offset(50, 7), 4.6, _stroke(2));
    // Ear bolts
    for (final x in [16.0, 84.0]) {
      canvas.drawCircle(Offset(x, 39), 5.5, _fill(const Color(0xFFB8C2D6)));
      canvas.drawCircle(Offset(x, 39), 5.5, _stroke(2.2));
    }
    // Head
    final head = RRect.fromRectAndRadius(const Rect.fromLTWH(18, 18, 64, 40), const Radius.circular(16));
    canvas.drawRRect(head, Paint()..shader = _vertical(head.outerRect, Color.lerp(_body, Colors.white, 0.3)!, _body));
    canvas.drawRRect(head, _stroke(3));
    // Screen face
    final screen = RRect.fromRectAndRadius(const Rect.fromLTWH(25, 24, 50, 28), const Radius.circular(10));
    canvas.drawRRect(screen, _fill(_screen));
    canvas.drawRRect(screen, _stroke(2.2));
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(29, 26.5, 26, 4), const Radius.circular(2)),
      _fill(Colors.white.withValues(alpha: 0.12)),
    );
    _face(canvas);
  }

  void _face(Canvas canvas) {
    final led = Paint()
      ..color = _led
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final ledFill = _fill(_led);
    final open = 1 - blink;
    switch (mood) {
      case Mood.happy:
        for (final x in [40.0, 60.0]) {
          final p = Path()
            ..moveTo(x - 5, 39)
            ..quadraticBezierTo(x, 31, x + 5, 39);
          canvas.drawPath(p, led);
        }
        final m = Path()
          ..moveTo(43, 44)
          ..quadraticBezierTo(50, 50, 57, 44);
        canvas.drawPath(m, led);
        canvas.drawCircle(const Offset(33, 45), 2.4, _fill(PQColors.berry.withValues(alpha: 0.8)));
        canvas.drawCircle(const Offset(67, 45), 2.4, _fill(PQColors.berry.withValues(alpha: 0.8)));
      case Mood.sad:
        for (final x in [40.0, 60.0]) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, 38), width: 6, height: 7 * open + 1),
                  const Radius.circular(3)),
              ledFill);
        }
        canvas.drawLine(const Offset(35, 32), const Offset(43, 34), led);
        canvas.drawLine(const Offset(65, 32), const Offset(57, 34), led);
        final m = Path()
          ..moveTo(44, 48)
          ..quadraticBezierTo(50, 43, 56, 48);
        canvas.drawPath(m, led);
      case Mood.surprised:
        canvas.drawCircle(const Offset(40, 37), 4.6 * open + 0.6, ledFill);
        canvas.drawCircle(const Offset(60, 37), 4.6 * open + 0.6, ledFill);
        canvas.drawCircle(const Offset(50, 46.5), 3, led);
      case Mood.thinking:
        canvas.drawLine(const Offset(36, 38), const Offset(44, 38), led);
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(60, 37), width: 6, height: 8 * open + 1),
                const Radius.circular(3)),
            ledFill);
        canvas.drawLine(const Offset(46, 46), const Offset(55, 45), led);
      case Mood.neutral:
        for (final x in [40.0, 60.0]) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, 37), width: 6.5, height: 9 * open + 1),
                  const Radius.circular(3.2)),
              ledFill);
        }
        final m = Path()
          ..moveTo(45, 45)
          ..quadraticBezierTo(50, 48, 55, 45);
        canvas.drawPath(m, led);
    }
  }
}

// ------------------------------------------------------------------- Pip

class PipPainter extends CastPainter {
  PipPainter({required super.t, required super.blink, required super.bob, required super.mood, this.hat, this.run = 0, this.flap});

  final String? hat;

  /// 0..1 running cycle (legs). Idle when 0 and [flap] is null.
  final double run;

  /// Wing angle override (radians) used while jumping.
  final double? flap;

  static const _skin = PQColors.coral;
  static const _skinLight = Color(0xFFFFA184);
  static const _belly = Color(0xFFFFE2B0);
  static const _wing = Color(0xFFFFC2A6);

  @override
  void draw(Canvas canvas) {
    final legSwing = math.sin(run * 2 * math.pi) * 5;
    final wingAngle = flap ?? (math.sin(t * 2 * math.pi * 2) * 0.18 - 0.1);
    // Tail
    final tail = Path()
      ..moveTo(30, 66)
      ..quadraticBezierTo(14, 70, 10, 56)
      ..quadraticBezierTo(18, 62, 30, 58)
      ..close();
    _outlined(canvas, tail, _skin, 2.4);
    final tip = Path()
      ..moveTo(10, 56)
      ..lineTo(3, 50)
      ..lineTo(13, 49)
      ..close();
    _outlined(canvas, tip, _belly, 2.2);
    // Back leg
    _leg(canvas, Offset(40 - legSwing * 0.6, 80), legSwing < 0);
    // Wing (behind body)
    canvas.save();
    canvas.translate(42, 46);
    canvas.rotate(wingAngle);
    final wing = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-12, -24, -26, -22)
      ..quadraticBezierTo(-22, -16, -24, -10)
      ..quadraticBezierTo(-18, -8, -18, -2)
      ..quadraticBezierTo(-10, -2, 0, 6)
      ..close();
    _outlined(canvas, wing, _wing, 2.4);
    canvas.drawLine(const Offset(-2, 2), const Offset(-22, -18), _stroke(1.6, PQColors.coralDeep));
    canvas.drawLine(const Offset(-2, 3), const Offset(-19, -7), _stroke(1.6, PQColors.coralDeep));
    canvas.restore();
    // Body
    final body = Path()..addOval(Rect.fromCenter(center: const Offset(48, 64), width: 50, height: 42));
    _outlined(canvas, body, _skin, 2.8, shader: _vertical(const Rect.fromLTWH(23, 43, 50, 42), _skinLight, _skin));
    final belly = Path()..addOval(Rect.fromCenter(center: const Offset(56, 68), width: 26, height: 28));
    _outlined(canvas, belly, _belly, 2.2);
    for (final y in [62.0, 68.0, 74.0]) {
      canvas.drawLine(Offset(49, y), Offset(63, y), _stroke(1.4, const Color(0xFFE7B97E)));
    }
    // Back spikes
    for (final p in [const Offset(30, 50), const Offset(37, 45), const Offset(45, 43)]) {
      final spike = Path()
        ..moveTo(p.dx - 4, p.dy + 3)
        ..lineTo(p.dx, p.dy - 5)
        ..lineTo(p.dx + 4, p.dy + 2)
        ..close();
      _outlined(canvas, spike, _belly, 2);
    }
    // Front leg + arm
    _leg(canvas, Offset(56 + legSwing * 0.6, 81), legSwing > 0);
    final arm = Path()
      ..moveTo(60, 62)
      ..quadraticBezierTo(70, 64, 68, 70)
      ..quadraticBezierTo(64, 70, 59, 67)
      ..close();
    _outlined(canvas, arm, _skin, 2.2);
    // Head
    final head = Path()..addOval(Rect.fromCenter(center: const Offset(66, 38), width: 40, height: 38));
    _outlined(canvas, head, _skin, 2.8, shader: _vertical(const Rect.fromLTWH(46, 19, 40, 38), _skinLight, _skin));
    // Horns
    for (final h in [const Offset(56, 22), const Offset(66, 19)]) {
      final horn = Path()
        ..moveTo(h.dx - 4, h.dy + 4)
        ..quadraticBezierTo(h.dx - 1, h.dy - 6, h.dx + 2, h.dy - 8)
        ..quadraticBezierTo(h.dx + 3, h.dy, h.dx + 4, h.dy + 4)
        ..close();
      _outlined(canvas, horn, _belly, 2);
    }
    // Snout
    final snout = Path()..addOval(Rect.fromCenter(center: const Offset(81, 45), width: 22, height: 17));
    _outlined(canvas, snout, _skinLight, 2.4);
    canvas.drawCircle(const Offset(85, 42), 1.5, _fill(PQColors.ink));
    canvas.drawCircle(const Offset(79, 42), 1.3, _fill(PQColors.ink));
    // Mouth
    final mouth = Path();
    if (mood == Mood.sad) {
      mouth
        ..moveTo(74, 50)
        ..quadraticBezierTo(79, 47, 84, 50);
    } else if (mood == Mood.surprised) {
      mouth.addOval(Rect.fromCenter(center: const Offset(80, 50), width: 5, height: 4));
    } else {
      mouth
        ..moveTo(73, 48)
        ..quadraticBezierTo(79, 54, 86, 48);
    }
    canvas.drawPath(mouth, _stroke(2));
    // Cheek + eye
    canvas.drawOval(Rect.fromCenter(center: const Offset(70, 47), width: 8, height: 5), _fill(PQColors.berry.withValues(alpha: 0.45)));
    eye(canvas, const Offset(67, 34), 6.5, 8, look: const Offset(1.6, 0.4));
    if (mood == Mood.sad) {
      canvas.drawLine(const Offset(61, 24), const Offset(71, 27), _stroke(2));
    }
    _drawHat(canvas);
  }

  void _leg(Canvas canvas, Offset foot, bool lifted) {
    final y = lifted ? foot.dy - 3 : foot.dy;
    final leg = RRect.fromRectAndRadius(Rect.fromLTWH(foot.dx - 5, y - 8, 10, 13), const Radius.circular(5));
    canvas.drawRRect(leg, _fill(PQColors.coralDeep));
    canvas.drawRRect(leg, _stroke(2.2));
  }

  void _drawHat(Canvas canvas) {
    switch (hat) {
      case 'party':
        final cone = Path()
          ..moveTo(56, 22)
          ..lineTo(66, -2)
          ..lineTo(76, 20)
          ..close();
        _outlined(canvas, cone, PQColors.sky, 2.2);
        canvas.drawLine(const Offset(60, 13), const Offset(71, 9), _stroke(2.2, PQColors.pyYellow));
        canvas.drawCircle(const Offset(66, -3), 3.5, _fill(PQColors.berry));
        canvas.drawCircle(const Offset(66, -3), 3.5, _stroke(1.8));
      case 'crown':
        final crown = Path()
          ..moveTo(54, 22)
          ..lineTo(55, 8)
          ..lineTo(61, 15)
          ..lineTo(66, 5)
          ..lineTo(71, 15)
          ..lineTo(77, 8)
          ..lineTo(78, 22)
          ..close();
        _outlined(canvas, crown, PQColors.sun, 2.2);
        canvas.drawCircle(const Offset(66, 17), 2.4, _fill(PQColors.berry));
      case 'wizard':
        final hatPath = Path()
          ..moveTo(50, 24)
          ..quadraticBezierTo(66, 18, 82, 22)
          ..lineTo(70, 16)
          ..quadraticBezierTo(66, -2, 58, -6)
          ..quadraticBezierTo(62, 6, 58, 17)
          ..close();
        _outlined(canvas, hatPath, PQColors.grapeDeep, 2.2);
        canvas.drawCircle(const Offset(63, 8), 1.8, _fill(PQColors.pyYellow));
        canvas.drawCircle(const Offset(66, 13), 1.4, _fill(PQColors.pyYellow));
      case 'scarf':
        final scarf = Path()
          ..moveTo(52, 50)
          ..quadraticBezierTo(64, 58, 78, 52)
          ..lineTo(78, 57)
          ..quadraticBezierTo(64, 63, 52, 56)
          ..close();
        _outlined(canvas, scarf, PQColors.teal, 2);
        final tail = Path()
          ..moveTo(54, 54)
          ..lineTo(44, 66)
          ..lineTo(50, 67)
          ..lineTo(58, 56)
          ..close();
        _outlined(canvas, tail, PQColors.teal, 2);
      case 'goggles':
        final band = Path()
          ..moveTo(50, 28)
          ..quadraticBezierTo(66, 22, 84, 28);
        canvas.drawPath(band, _stroke(4, PQColors.woodDeep));
        canvas.drawCircle(const Offset(66, 25), 6, _fill(PQColors.sky.withValues(alpha: 0.85)));
        canvas.drawCircle(const Offset(66, 25), 6, _stroke(2.2));
        canvas.drawCircle(const Offset(77, 26), 5, _fill(PQColors.sky.withValues(alpha: 0.85)));
        canvas.drawCircle(const Offset(77, 26), 5, _stroke(2.2));
    }
  }

  @override
  bool shouldRepaint(CastPainter old) =>
      super.shouldRepaint(old) || (old is PipPainter && (old.run != run || old.flap != flap || old.hat != hat));
}

// ----------------------------------------------------------------- Bitsy

class BitsyPainter extends CastPainter {
  BitsyPainter({required super.t, required super.blink, required super.bob, required super.mood});

  static const _fur = Color(0xFFA98BF5);
  static const _furDark = PQColors.grapeDeep;
  static const _muzzle = Color(0xFFFFF6FF);

  @override
  void draw(Canvas canvas) {
    final tailSwing = math.sin(t * 2 * math.pi) * 6;
    // Tail
    final tail = Path()
      ..moveTo(66, 82)
      ..quadraticBezierTo(90, 84, 88 + tailSwing * 0.3, 64)
      ..quadraticBezierTo(87, 58, 82 + tailSwing * 0.2, 60);
    canvas.drawPath(tail, _stroke(9));
    canvas.drawPath(tail, _stroke(5.4, _fur));
    // Body
    final body = Path()..addOval(Rect.fromCenter(center: const Offset(50, 79), width: 38, height: 26));
    _outlined(canvas, body, _fur, 2.6);
    final bellyP = Path()..addOval(Rect.fromCenter(center: const Offset(50, 81), width: 20, height: 16));
    _outlined(canvas, bellyP, _muzzle, 2);
    for (final x in [41.0, 59.0]) {
      final paw = Path()..addOval(Rect.fromCenter(center: Offset(x, 90), width: 12, height: 8));
      _outlined(canvas, paw, _muzzle, 2.2);
    }
    // Ears
    for (final left in [true, false]) {
      final dir = left ? -1.0 : 1.0;
      final ear = Path()
        ..moveTo(50 + dir * 8, 22)
        ..lineTo(50 + dir * 24, 6)
        ..lineTo(50 + dir * 26, 30)
        ..close();
      _outlined(canvas, ear, _fur, 2.6);
      final inner = Path()
        ..moveTo(50 + dir * 13, 22)
        ..lineTo(50 + dir * 22, 12)
        ..lineTo(50 + dir * 23, 26)
        ..close();
      canvas.drawPath(inner, _fill(PQColors.berry.withValues(alpha: 0.55)));
    }
    // Head
    final head = Path()..addOval(Rect.fromCenter(center: const Offset(50, 42), width: 56, height: 48));
    _outlined(canvas, head, _fur, 2.8, shader: _vertical(const Rect.fromLTWH(22, 18, 56, 48), const Color(0xFFC3AEFA), _fur));
    // Forehead stripes
    for (final dx in [-5.0, 0.0, 5.0]) {
      canvas.drawLine(Offset(50 + dx, 20), Offset(50 + dx * 0.8, 26), _stroke(2, _furDark));
    }
    // Muzzle
    final muzzle = Path()..addOval(Rect.fromCenter(center: const Offset(50, 53), width: 26, height: 17));
    _outlined(canvas, muzzle, _muzzle, 2.2);
    final nose = Path()
      ..moveTo(47, 48)
      ..lineTo(53, 48)
      ..lineTo(50, 51.5)
      ..close();
    canvas.drawPath(nose, _fill(PQColors.berry));
    final mouth = Path()
      ..moveTo(44.5, 54)
      ..quadraticBezierTo(47, 57, 50, 53)
      ..quadraticBezierTo(53, 57, 55.5, 54);
    canvas.drawPath(mouth, _stroke(1.8));
    if (mood == Mood.happy) {
      canvas.drawOval(Rect.fromCenter(center: const Offset(33, 50), width: 8, height: 5), _fill(PQColors.berry.withValues(alpha: 0.4)));
    }
    // Whiskers
    for (final s in [-1.0, 1.0]) {
      canvas.drawLine(Offset(50 + s * 14, 51), Offset(50 + s * 26, 48), _stroke(1.4));
      canvas.drawLine(Offset(50 + s * 14, 54), Offset(50 + s * 26, 55), _stroke(1.4));
    }
    // Eyes
    eye(canvas, const Offset(40, 39), 6, 7.5, look: const Offset(0.8, 0.6), iris: const Color(0xFF2E7D5B));
    eye(canvas, const Offset(61, 39), 6, 7.5, look: const Offset(0.8, 0.6), iris: const Color(0xFF2E7D5B));
    if (mood == Mood.thinking || mood == Mood.sad) {
      canvas.drawLine(const Offset(34, 30), const Offset(45, 32), _stroke(2));
    }
    // Bow tie
    final bowL = Path()
      ..moveTo(50, 67)
      ..lineTo(41, 62)
      ..lineTo(41, 72)
      ..close();
    final bowR = Path()
      ..moveTo(50, 67)
      ..lineTo(59, 62)
      ..lineTo(59, 72)
      ..close();
    _outlined(canvas, bowL, PQColors.grass, 2);
    _outlined(canvas, bowR, PQColors.grass, 2);
    canvas.drawCircle(const Offset(50, 67), 2.6, _fill(PQColors.grassDeep));
    // Magnifying glass over the right eye
    canvas.save();
    canvas.translate(0, math.sin(t * 2 * math.pi * 2) * 0.8);
    canvas.drawLine(const Offset(70, 49), const Offset(82, 68), _stroke(7));
    canvas.drawLine(const Offset(70, 49), const Offset(82, 68), _stroke(4, PQColors.wood));
    canvas.drawCircle(const Offset(63, 40), 12.5, _fill(PQColors.sky.withValues(alpha: 0.18)));
    canvas.drawCircle(const Offset(63, 40), 12.5, _stroke(3.4, PQColors.ink));
    canvas.drawCircle(const Offset(63, 40), 12.5, _stroke(1.6, PQColors.sun));
    final shine = Path()
      ..addArc(Rect.fromCircle(center: const Offset(63, 40), radius: 8.5), math.pi * 1.1, math.pi * 0.45);
    canvas.drawPath(shine, _stroke(1.8, Colors.white.withValues(alpha: 0.85)));
    canvas.restore();
  }
}

// -------------------------------------------------------------------- Py

class PyPainter extends CastPainter {
  PyPainter({required super.t, required super.blink, required super.bob, required super.mood});

  static const _blue = PQColors.pyBlue;
  static const _blueLight = Color(0xFF6FA3E6);
  static const _yellow = PQColors.pyYellow;

  @override
  void draw(Canvas canvas) {
    // Coils (back to front)
    final coilBack = Path()..addOval(Rect.fromCenter(center: const Offset(50, 84), width: 64, height: 18));
    _outlined(canvas, coilBack, _blue, 2.6);
    final coilMid = Path()..addOval(Rect.fromCenter(center: const Offset(46, 76), width: 50, height: 16));
    _outlined(canvas, coilMid, _blueLight, 2.6);
    canvas.drawArc(Rect.fromCenter(center: const Offset(46, 77), width: 38, height: 9), 0.2, 2.6, false,
        _stroke(3, _yellow));
    // Tail tip
    final tail = Path()
      ..moveTo(80, 84)
      ..quadraticBezierTo(92, 82, 94, 74)
      ..quadraticBezierTo(90, 80, 80, 80)
      ..close();
    _outlined(canvas, tail, _blue, 2.2);
    // Neck rising from the coils
    final neck = Path()
      ..moveTo(36, 76)
      ..cubicTo(30, 60, 58, 60, 52, 44)
      ..lineTo(64, 44)
      ..cubicTo(70, 62, 46, 64, 50, 76)
      ..close();
    _outlined(canvas, neck, _blue, 2.6, shader: _vertical(const Rect.fromLTWH(30, 44, 40, 34), _blueLight, _blue));
    final belly = Path()
      ..moveTo(41, 74)
      ..cubicTo(37, 62, 62, 60, 57, 46);
    canvas.drawPath(belly, _stroke(4, _yellow));
    for (var i = 0; i < 4; i++) {
      final y = 50.0 + i * 6;
      canvas.drawLine(Offset(50 + (i.isEven ? 4 : -2), y), Offset(56 + (i.isEven ? 4 : -2), y + 1), _stroke(1.2, PQColors.sunDeep));
    }
    // Head
    final head = Path()..addOval(Rect.fromCenter(center: const Offset(56, 34), width: 46, height: 36));
    _outlined(canvas, head, _blue, 2.8, shader: _vertical(const Rect.fromLTWH(33, 16, 46, 36), _blueLight, _blue));
    final jaw = Path()..addOval(Rect.fromCenter(center: const Offset(57, 43), width: 30, height: 13));
    _outlined(canvas, jaw, _yellow, 2.2);
    // Smile + tongue
    final flick = math.sin(t * 2 * math.pi * 3);
    if (flick > 0.6 && mood != Mood.sad) {
      final tongue = Path()
        ..moveTo(57, 46)
        ..lineTo(57, 53)
        ..moveTo(57, 53)
        ..lineTo(54, 56)
        ..moveTo(57, 53)
        ..lineTo(60, 56);
      canvas.drawPath(tongue, _stroke(2, PQColors.berry));
    }
    final smile = Path();
    if (mood == Mood.sad) {
      smile
        ..moveTo(50, 45)
        ..quadraticBezierTo(57, 41, 64, 45);
    } else {
      smile
        ..moveTo(49, 42)
        ..quadraticBezierTo(57, 48, 65, 42);
    }
    canvas.drawPath(smile, _stroke(2));
    // Eyes + round glasses
    eye(canvas, const Offset(47, 31), 5.6, 6.6, look: const Offset(0.6, 0.5));
    eye(canvas, const Offset(65, 31), 5.6, 6.6, look: const Offset(0.6, 0.5));
    canvas.drawCircle(const Offset(47, 31), 9, _stroke(2.4));
    canvas.drawCircle(const Offset(65, 31), 9, _stroke(2.4));
    canvas.drawLine(const Offset(56, 30), const Offset(56, 30.5), _stroke(2.4));
    canvas.drawArc(Rect.fromCircle(center: const Offset(56, 31), radius: 3), math.pi, math.pi, false, _stroke(2.2));
    // Graduation cap
    final capTop = Path()
      ..moveTo(32, 16)
      ..lineTo(56, 7)
      ..lineTo(80, 16)
      ..lineTo(56, 24)
      ..close();
    _outlined(canvas, capTop, PQColors.night, 2.4);
    final capBase = RRect.fromRectAndRadius(const Rect.fromLTWH(45, 17, 22, 8), const Radius.circular(3));
    canvas.drawRRect(capBase, _fill(PQColors.night));
    canvas.drawRRect(capBase, _stroke(2.2));
    final swing = math.sin(t * 2 * math.pi) * 3;
    canvas.drawLine(const Offset(56, 15), Offset(74 + swing * 0.3, 18), _stroke(1.8, _yellow));
    canvas.drawLine(Offset(74 + swing * 0.3, 18), Offset(75 + swing, 28), _stroke(1.8, _yellow));
    canvas.drawCircle(Offset(75 + swing, 29), 2.4, _fill(_yellow));
  }
}
