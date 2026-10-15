import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/palette.dart';
import 'characters.dart';

// The eight companions are drawn with the same pipeline as the original
// islanders: a 100x100 design space, a dark "ink" outline, a soft vertical
// gradient on the main body shape and eyes with a highlight dot. Keeping the
// outline weight, palette and eye treatment identical is what makes them look
// like one cast instead of eight unrelated pictures.

Paint _fillC(Color c) => Paint()..color = c;

Paint _lineC(double w, [Color c = PQColors.ink]) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

Shader _gradC(Rect r, Color top, Color bottom) => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [top, bottom],
    ).createShader(r);

void _shape(Canvas canvas, Path path, Color fill, double stroke, {Shader? shader}) {
  final paint = Paint()..color = fill;
  if (shader != null) paint.shader = shader;
  canvas.drawPath(path, paint);
  canvas.drawPath(path, _lineC(stroke));
}

Path _ovalPath(double cx, double cy, double w, double h) =>
    Path()..addOval(Rect.fromCenter(center: Offset(cx, cy), width: w, height: h));

Path _roundPath(double left, double top, double w, double h, double r) =>
    Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left, top, w, h), Radius.circular(r)));

/// Shared expression helpers so all eight faces react to a mood the same way.
abstract class CastPainter2 extends CastPainter {
  CastPainter2({required super.t, required super.blink, required super.bob, required super.mood});

  bool get celebrating => mood == Mood.celebrating;
  bool get confused => mood == Mood.confused;
  bool get sad => mood == Mood.sad;
  bool get thinking => mood == Mood.thinking;
  bool get happy => mood == Mood.happy || mood == Mood.celebrating;

  /// A smile / flat line / frown centred on [c], [w] wide.
  void mouth(Canvas canvas, Offset c, double w, {double curve = 3.2, double stroke = 2.2, Color? color}) {
    final paint = _lineC(stroke, color ?? PQColors.ink);
    final path = Path();
    if (sad) {
      path
        ..moveTo(c.dx - w / 2, c.dy + curve)
        ..quadraticBezierTo(c.dx, c.dy - curve * 0.8, c.dx + w / 2, c.dy + curve);
    } else if (thinking || confused) {
      path
        ..moveTo(c.dx - w / 2, c.dy)
        ..quadraticBezierTo(c.dx - w * 0.1, c.dy - curve, c.dx + w / 2, c.dy + curve * 0.5);
    } else {
      path
        ..moveTo(c.dx - w / 2, c.dy - curve * 0.4)
        ..quadraticBezierTo(c.dx, c.dy + curve, c.dx + w / 2, c.dy - curve * 0.4);
    }
    canvas.drawPath(path, paint);
  }

  /// Small "thinking bubbles" / sparkles that mark a reaction.
  void reactionMarks(Canvas canvas, {required List<Offset> sparks, Offset? drop}) {
    if (celebrating) {
      final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi * 4).abs();
      for (final s in sparks) {
        canvas.drawCircle(s, 1.4 + 1.8 * pulse, _fillC(PQColors.sun));
        canvas.drawCircle(s, 1.4 + 1.8 * pulse, _lineC(1.3));
      }
    }
    if (confused && drop != null) {
      final path = Path()
        ..moveTo(drop.dx, drop.dy)
        ..quadraticBezierTo(drop.dx - 2.4, drop.dy + 3, drop.dx, drop.dy + 4.4)
        ..quadraticBezierTo(drop.dx + 2.4, drop.dy + 3, drop.dx, drop.dy);
      canvas.drawPath(path, _fillC(PQColors.sky));
      canvas.drawPath(path, _lineC(1.6));
    }
  }

  /// Hand/cuff with a rounded outline, used by the human characters.
  void arm(Canvas canvas, Offset from, double angle, double length, double thickness, Color colour) {
    canvas.save();
    canvas.translate(from.dx, from.dy);
    canvas.rotate(angle);
    final p = _roundPath(-thickness / 2, 0, thickness, length, thickness / 2);
    _shape(canvas, p, colour, 2.4);
    canvas.drawCircle(Offset(0, length), thickness * 0.46, _fillC(PQColors.skinLight));
    canvas.drawCircle(Offset(0, length), thickness * 0.46, _lineC(2.2));
    canvas.restore();
  }
}

// --------------------------------------------------------------- 1. Nova

/// Nova — curious young inventor: ponytail, goggles pushed up, tool belt.
class NovaPainter extends CastPainter2 {
  NovaPainter({required super.t, required super.blink, required super.bob, required super.mood});

  static const _suit = PQColors.sea;
  static const _suitDeep = PQColors.seaDeep;
  static const _hair = Color(0xFF6B3B22);
  static const _hairLight = Color(0xFF9A5A33);

  @override
  void draw(Canvas canvas) {
    final swing = math.sin(t * 2 * math.pi) * 4;
    // Ponytail behind the head.
    final tail = Path()
      ..moveTo(64, 30)
      ..quadraticBezierTo(84 + swing, 30, 82 + swing * 0.6, 46)
      ..quadraticBezierTo(78 + swing, 40, 72, 34)
      ..close();
    _shape(canvas, tail, _hair, 2.6, shader: _gradC(const Rect.fromLTWH(60, 24, 30, 28), _hairLight, _hair));
    // Legs + boots.
    for (final x in [42.0, 56.0]) {
      final leg = _roundPath(x, 74, 10, 16, 4);
      _shape(canvas, leg, _suitDeep, 2.4);
      final boot = _roundPath(x - 2, 87, 14, 8, 4);
      _shape(canvas, boot, PQColors.woodDeep, 2.4);
    }
    // Arms.
    arm(canvas, const Offset(36, 62), -0.45 + (celebrating ? -0.7 : 0), 16, 9, _suit);
    arm(canvas, const Offset(64, 62), 0.45 - (celebrating ? 0.9 : 0), 16, 9, _suit);
    // Body.
    final body = _roundPath(34, 56, 32, 24, 10);
    _shape(canvas, body, _suit, 2.7, shader: _gradC(const Rect.fromLTWH(34, 56, 32, 24), const Color(0xFF6FE3EC), _suit));
    // Tool belt.
    canvas.drawRect(const Rect.fromLTWH(34, 72, 32, 6), _fillC(PQColors.wood));
    canvas.drawRect(const Rect.fromLTWH(34, 72, 32, 6), _lineC(2.2));
    final buckle = _roundPath(46, 70.5, 9, 8, 2);
    _shape(canvas, buckle, PQColors.sun, 2.1);
    // Collar.
    final collar = Path()
      ..moveTo(42, 57)
      ..lineTo(50, 63)
      ..lineTo(58, 57)
      ..close();
    _shape(canvas, collar, PQColors.cream, 2.2);
    // Head.
    final head = _ovalPath(50, 34, 42, 40);
    _shape(canvas, head, PQColors.skinLight, 2.8, shader: _gradC(const Rect.fromLTWH(29, 14, 42, 40), const Color(0xFFFFE3C4), PQColors.skin));
    // Hair cap + fringe.
    final hairCap = Path()
      ..moveTo(29, 32)
      ..quadraticBezierTo(30, 10, 50, 11)
      ..quadraticBezierTo(70, 10, 71, 32)
      ..quadraticBezierTo(66, 20, 50, 20)
      ..quadraticBezierTo(34, 20, 29, 32)
      ..close();
    _shape(canvas, hairCap, _hair, 2.6, shader: _gradC(const Rect.fromLTWH(29, 10, 42, 24), _hairLight, _hair));
    // Goggles resting on the forehead.
    canvas.drawRect(const Rect.fromLTWH(31, 22, 38, 4), _fillC(PQColors.woodDeep));
    canvas.drawRect(const Rect.fromLTWH(31, 22, 38, 4), _lineC(1.8));
    for (final x in [40.0, 60.0]) {
      canvas.drawCircle(Offset(x, 24), 6.4, _fillC(PQColors.sky.withValues(alpha: 0.45)));
      canvas.drawCircle(Offset(x, 24), 6.4, _lineC(2.4, PQColors.woodDeep));
      canvas.drawCircle(Offset(x - 2, 22), 1.6, _fillC(Colors.white.withValues(alpha: 0.9)));
    }
    // Face.
    eye(canvas, const Offset(41, 38), 5.6, 6.8, look: const Offset(0.9, 0.5), iris: const Color(0xFF2E6E8C));
    eye(canvas, const Offset(59, 38), 5.6, 6.8, look: const Offset(0.9, 0.5), iris: const Color(0xFF2E6E8C));
    mouth(canvas, const Offset(50, 47), 9);
    canvas.drawOval(Rect.fromCenter(center: const Offset(32, 44), width: 7, height: 4.4),
        _fillC(PQColors.coral.withValues(alpha: 0.35)));
    canvas.drawOval(Rect.fromCenter(center: const Offset(68, 44), width: 7, height: 4.4),
        _fillC(PQColors.coral.withValues(alpha: 0.35)));
    reactionMarks(canvas, sparks: const [Offset(24, 16), Offset(76, 14), Offset(50, 6)], drop: const Offset(74, 30));
  }
}

// ------------------------------------------------------- 2. Professor Ada

/// Professor Ada — wise mentor: silver bun, round spectacles, a heavy book.
class AdaPainter extends CastPainter2 {
  AdaPainter({required super.t, required super.blink, required super.bob, required super.mood});

  static const _cardigan = PQColors.grape;
  static const _cardiganDeep = PQColors.grapeDeep;
  static const _hair = Color(0xFFE8E6F5);
  static const _hairShade = Color(0xFFC6C2E0);

  @override
  void draw(Canvas canvas) {
    // Skirt / robe.
    final robe = Path()
      ..moveTo(36, 62)
      ..lineTo(64, 62)
      ..lineTo(70, 92)
      ..lineTo(30, 92)
      ..close();
    _shape(canvas, robe, _cardigan, 2.7, shader: _gradC(const Rect.fromLTWH(30, 62, 40, 30), const Color(0xFFA88AF6), _cardigan));
    // Book held in front.
    final book = _roundPath(38, 66, 24, 15, 2.5);
    _shape(canvas, book, PQColors.pyBlue, 2.4);
    canvas.drawRect(const Rect.fromLTWH(49, 66, 2, 15), _fillC(PQColors.cream));
    canvas.drawRect(const Rect.fromLTWH(49, 66, 2, 15), _lineC(1.4));
    final swirl = Path()
      ..moveTo(42, 76)
      ..quadraticBezierTo(44, 70, 47, 74);
    canvas.drawPath(swirl, _lineC(1.6, PQColors.pyYellow));
    canvas.drawLine(const Offset(53, 71), const Offset(60, 71), _lineC(1.6, PQColors.cream));
    canvas.drawLine(const Offset(53, 75), const Offset(60, 75), _lineC(1.6, PQColors.cream));
    // Arms cradling the book.
    arm(canvas, const Offset(38, 64), 0.6, 12, 8, _cardigan);
    arm(canvas, const Offset(62, 64), -0.6, 12, 8, _cardigan);
    // Shoulders.
    final torso = _roundPath(33, 54, 34, 16, 8);
    _shape(canvas, torso, _cardiganDeep, 2.6, shader: _gradC(const Rect.fromLTWH(33, 54, 34, 16), _cardigan, _cardiganDeep));
    // Head.
    final head = _ovalPath(50, 34, 38, 38);
    _shape(canvas, head, PQColors.skinLight, 2.8, shader: _gradC(const Rect.fromLTWH(31, 15, 38, 38), const Color(0xFFFFE3C4), PQColors.skin));
    // Hair: side sweep + bun.
    final cap = Path()
      ..moveTo(32, 30)
      ..quadraticBezierTo(34, 12, 50, 12)
      ..quadraticBezierTo(66, 12, 68, 30)
      ..quadraticBezierTo(60, 22, 46, 23)
      ..quadraticBezierTo(36, 24, 32, 30)
      ..close();
    _shape(canvas, cap, _hair, 2.5, shader: _gradC(const Rect.fromLTWH(32, 12, 36, 20), Colors.white, _hairShade));
    canvas.drawCircle(const Offset(68, 20), 8.5, _fillC(_hair));
    canvas.drawCircle(const Offset(68, 20), 8.5, _lineC(2.5));
    canvas.drawCircle(const Offset(66, 18), 2.6, _fillC(Colors.white.withValues(alpha: 0.7)));
    // Wire spectacles.
    for (final x in [41.0, 59.0]) {
      canvas.drawCircle(Offset(x, 38), 8.6, _fillC(PQColors.sky.withValues(alpha: 0.16)));
      canvas.drawCircle(Offset(x, 38), 8.6, _lineC(2.2, PQColors.woodDeep));
    }
    canvas.drawLine(const Offset(49.6, 37), const Offset(50.4, 37), _lineC(2, PQColors.woodDeep));
    eye(canvas, const Offset(41, 38), 5.2, 6.4, look: const Offset(0.7, 0.6), iris: const Color(0xFF4A4E86));
    eye(canvas, const Offset(59, 38), 5.2, 6.4, look: const Offset(0.7, 0.6), iris: const Color(0xFF4A4E86));
    mouth(canvas, const Offset(50, 47), 8, curve: 2.8);
    // A single eyebrow raises when she is unconvinced.
    if (confused || thinking) {
      canvas.drawLine(const Offset(35, 27), const Offset(45, 26), _lineC(2.2, _hairShade));
    }
    reactionMarks(canvas, sparks: const [Offset(24, 14), Offset(78, 30), Offset(50, 6)], drop: const Offset(28, 30));
  }
}

// ---------------------------------------------------------------- 3. Kai

/// Kai — playful programmer: spiky hair, hoodie with drawstrings, headphones.
class KaiPainter extends CastPainter2 {
  KaiPainter({required super.t, required super.blink, required super.bob, required super.mood});

  static const _hoodie = PQColors.grass;
  static const _hoodieDeep = PQColors.grassDeep;
  static const _hair = Color(0xFF3A2A1E);

  @override
  void draw(Canvas canvas) {
    final bounce = math.sin(t * 2 * math.pi * 2) * 1.6;
    // Shoes.
    for (final x in [41.0, 57.0]) {
      final shoe = _roundPath(x - 1, 86 + (celebrating ? -bounce : 0), 15, 8, 4);
      _shape(canvas, shoe, PQColors.coral, 2.4);
    }
    // Legs.
    for (final x in [43.0, 55.0]) {
      final leg = _roundPath(x, 74, 10, 14, 4);
      _shape(canvas, leg, const Color(0xFF3E5A86), 2.4);
    }
    // Hoodie body.
    final body = _roundPath(33, 56, 34, 24, 10);
    _shape(canvas, body, _hoodie, 2.7, shader: _gradC(const Rect.fromLTWH(33, 56, 34, 24), const Color(0xFFA5E06B), _hoodie));
    // Hood roll + drawstrings.
    final hood = Path()
      ..moveTo(37, 58)
      ..quadraticBezierTo(50, 66, 63, 58);
    canvas.drawPath(hood, _lineC(3.4, _hoodieDeep));
    canvas.drawLine(const Offset(45, 62), const Offset(44, 70), _lineC(1.8, PQColors.cream));
    canvas.drawLine(const Offset(55, 62), const Offset(56, 70), _lineC(1.8, PQColors.cream));
    // Front pocket.
    final pocket = _roundPath(42, 71, 16, 8, 3);
    _shape(canvas, pocket, _hoodieDeep, 2);
    // Arms: one raised when celebrating.
    arm(canvas, const Offset(35, 60), 0.55, 14, 8, _hoodie);
    arm(canvas, const Offset(65, 60), celebrating ? -2.2 : -0.55, 14, 8, _hoodie);
    // Headphones around the neck.
    final band = Path()
      ..moveTo(30, 46)
      ..quadraticBezierTo(50, 60, 70, 46);
    canvas.drawPath(band, _lineC(3, PQColors.night));
    for (final x in [30.0, 70.0]) {
      final cup = _roundPath(x - 4, 44, 9, 9, 4);
      _shape(canvas, cup, PQColors.night, 2.2);
    }
    // Head.
    final head = _ovalPath(50, 35, 40, 39);
    _shape(canvas, head, PQColors.skinLight, 2.8, shader: _gradC(const Rect.fromLTWH(30, 16, 40, 39), const Color(0xFFFFE3C4), PQColors.skin));
    // Spiky hair.
    final spikes = Path()
      ..moveTo(28, 33)
      ..lineTo(22, 18)
      ..lineTo(33, 24)
      ..lineTo(34, 10)
      ..lineTo(43, 21)
      ..lineTo(50, 7)
      ..lineTo(56, 21)
      ..lineTo(66, 11)
      ..lineTo(68, 24)
      ..lineTo(78, 19)
      ..lineTo(72, 34)
      ..quadraticBezierTo(60, 22, 50, 22)
      ..quadraticBezierTo(38, 22, 28, 33)
      ..close();
    _shape(canvas, spikes, _hair, 2.6, shader: _gradC(const Rect.fromLTWH(22, 7, 56, 28), const Color(0xFF5A422F), _hair));
    eye(canvas, const Offset(41, 39), 5.6, 6.6, look: const Offset(0.8, 0.6), iris: const Color(0xFF5C3A1E));
    eye(canvas, const Offset(59, 39), 5.6, 6.6, look: const Offset(0.8, 0.6), iris: const Color(0xFF5C3A1E));
    mouth(canvas, const Offset(50, 48), 10, curve: 3.6);
    if (sad) canvas.drawLine(const Offset(34, 29), const Offset(46, 31), _lineC(2.2));
    reactionMarks(canvas, sparks: const [Offset(20, 12), Offset(80, 12), Offset(50, 2)], drop: const Offset(26, 28));
  }
}

// --------------------------------------------------------------- 4. Byte

/// Byte — orange fox who investigates bugs: sitting quadruped with a lens.
class BytePainter extends CastPainter2 {
  BytePainter({required super.t, required super.blink, required super.bob, required super.mood});

  static const _fur = Color(0xFFF59029);
  static const _furDeep = Color(0xFFC96A12);
  static const _cream = Color(0xFFFFF0D8);

  @override
  void draw(Canvas canvas) {
    final swish = math.sin(t * 2 * math.pi) * 7;
    // Tail sweeping behind.
    final tail = Path()
      ..moveTo(66, 80)
      ..cubicTo(92, 82, 94 + swish * 0.3, 58, 80 + swish * 0.4, 56)
      ..cubicTo(74, 56, 74, 66, 72, 74)
      ..close();
    _shape(canvas, tail, _fur, 2.6, shader: _gradC(const Rect.fromLTWH(66, 52, 30, 32), _fur, _furDeep));
    final tip = Path()..addOval(Rect.fromCenter(center: Offset(79 + swish * 0.35, 58), width: 14, height: 12));
    _shape(canvas, tip, _cream, 2.4);
    // Back legs + front legs (sitting).
    for (final x in [36.0, 62.0]) {
      final paw = _roundPath(x, 84, 14, 9, 4);
      _shape(canvas, paw, _furDeep, 2.4);
    }
    _shape(canvas, _roundPath(38, 78, 13, 12, 4), _fur, 2.4);
    // Body.
    final body = _ovalPath(50, 73, 40, 30);
    _shape(canvas, body, _fur, 2.7, shader: _gradC(const Rect.fromLTWH(30, 58, 40, 30), const Color(0xFFFFA94E), _fur));
    final chest = _ovalPath(50, 78, 20, 17);
    _shape(canvas, chest, _cream, 2.2);
    // Ears with dark tips.
    for (final left in [true, false]) {
      final dir = left ? -1.0 : 1.0;
      final ear = Path()
        ..moveTo(50 + dir * 10, 24)
        ..lineTo(50 + dir * 22, 4)
        ..lineTo(50 + dir * 26, 28)
        ..close();
      _shape(canvas, ear, _fur, 2.6, shader: _gradC(const Rect.fromLTWH(28, 4, 44, 26), _fur, _furDeep));
      final inner = Path()
        ..moveTo(50 + dir * 15, 23)
        ..lineTo(50 + dir * 21, 10)
        ..lineTo(50 + dir * 23, 25)
        ..close();
      canvas.drawPath(inner, _fillC(PQColors.berry.withValues(alpha: 0.5)));
    }
    // Head with a longer snout than Bitsy's round cat head.
    final head = _ovalPath(50, 40, 46, 36);
    _shape(canvas, head, _fur, 2.8, shader: _gradC(const Rect.fromLTWH(27, 22, 46, 36), const Color(0xFFFFA94E), _fur));
    final snout = Path()
      ..moveTo(50, 52)
      ..quadraticBezierTo(66, 50, 70, 42)
      ..quadraticBezierTo(64, 56, 50, 56)
      ..close();
    _shape(canvas, snout, _cream, 2.4);
    final nose = Path()
      ..moveTo(68, 41)
      ..lineTo(73, 43)
      ..lineTo(68, 45)
      ..close();
    canvas.drawPath(nose, _fillC(PQColors.ink));
    mouth(canvas, const Offset(60, 50), 7, curve: 2.2);
    // Cheek fur tufts.
    for (final s in [-1.0, 1.0]) {
      final tuft = Path()
        ..moveTo(50 + s * 20, 40)
        ..lineTo(50 + s * 27, 36)
        ..lineTo(50 + s * 21, 45)
        ..close();
      _shape(canvas, tuft, _cream, 2);
    }
    eye(canvas, const Offset(40, 36), 5.4, 6.4, look: const Offset(1, 0.4), iris: const Color(0xFF7A3E10));
    eye(canvas, const Offset(58, 35), 5.4, 6.4, look: const Offset(1, 0.4), iris: const Color(0xFF7A3E10));
    // The detective's lens, held low in the front paw.
    canvas.save();
    canvas.translate(0, math.sin(t * 2 * math.pi * 2) * 0.9);
    canvas.drawCircle(const Offset(76, 70), 9, _fillC(PQColors.sky.withValues(alpha: 0.2)));
    canvas.drawCircle(const Offset(76, 70), 9, _lineC(3, PQColors.woodDeep));
    canvas.drawLine(const Offset(82, 77), const Offset(90, 88), _lineC(3.4, PQColors.wood));
    canvas.restore();
    // A tiny bug being investigated on the ground.
    final crawl = math.sin(t * 2 * math.pi * 1.5) * 2;
    canvas.drawCircle(Offset(20 + crawl, 90), 2.6, _fillC(PQColors.berry));
    canvas.drawCircle(Offset(20 + crawl, 90), 2.6, _lineC(1.4));
    reactionMarks(canvas, sparks: const [Offset(22, 18), Offset(80, 22), Offset(50, 4)], drop: const Offset(30, 26));
  }
}

// -------------------------------------------------------------- 5. Pixel

/// Pixel — small blue owl who explains logic, patterns and algorithms.
class PixelPainter extends CastPainter2 {
  PixelPainter({required super.t, required super.blink, required super.bob, required super.mood});

  static const _feather = PQColors.skyDeep;
  static const _featherLight = Color(0xFF7EC2F7);
  static const _face = Color(0xFFEAF6FF);

  @override
  void draw(Canvas canvas) {
    final wing = math.sin(t * 2 * math.pi) * 0.12;
    // Branch-perch feet.
    for (final x in [43.0, 57.0]) {
      canvas.drawLine(Offset(x, 88), Offset(x, 93), _lineC(2.8, PQColors.woodDeep));
      canvas.drawLine(Offset(x, 93), Offset(x - 4, 95), _lineC(2.4, PQColors.woodDeep));
    }
    // Body.
    final body = _ovalPath(50, 67, 44, 40);
    _shape(canvas, body, _feather, 2.8, shader: _gradC(const Rect.fromLTWH(28, 47, 44, 40), _featherLight, _feather));
    // Chest plates: a small checker pattern, Pixel's "logic" motif.
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 2; col++) {
        final x = 44.0 + col * 11;
        final y = 68.0 + row * 8;
        final plate = _roundPath(x, y, 9, 6.5, 2.4);
        final light = (row + col).isEven;
        _shape(canvas, plate, light ? _face : _featherLight, 1.8);
      }
    }
    // Wings.
    canvas.save();
    canvas.translate(28, 66);
    canvas.rotate(0.25 + wing);
    _shape(canvas, _roundPath(-5, 0, 11, 24, 5), _feather, 2.4);
    canvas.restore();
    canvas.save();
    canvas.translate(72, 66);
    canvas.rotate(-0.25 - wing - (celebrating ? 0.6 : 0));
    _shape(canvas, _roundPath(-6, 0, 11, 24, 5), _feather, 2.4);
    canvas.restore();
    // Head: wide, with ear tufts.
    final head = _ovalPath(50, 36, 54, 44);
    _shape(canvas, head, _feather, 2.8, shader: _gradC(const Rect.fromLTWH(23, 14, 54, 44), const Color(0xFF8FCBF9), _feather));
    for (final left in [true, false]) {
      final dir = left ? -1.0 : 1.0;
      final tuft = Path()
        ..moveTo(50 + dir * 12, 16)
        ..lineTo(50 + dir * 20, 2)
        ..lineTo(50 + dir * 26, 20)
        ..close();
      _shape(canvas, tuft, _feather, 2.4);
    }
    // Face discs.
    for (final x in [39.0, 61.0]) {
      canvas.drawCircle(Offset(x, 36), 14, _fillC(_face));
      canvas.drawCircle(Offset(x, 36), 14, _lineC(2.2));
    }
    eye(canvas, const Offset(39, 36), 8, 8.4, look: const Offset(0.5, 0.6), iris: const Color(0xFF1B3A57));
    eye(canvas, const Offset(61, 36), 8, 8.4, look: const Offset(0.5, 0.6), iris: const Color(0xFF1B3A57));
    // Beak.
    final beak = Path()
      ..moveTo(50, 44)
      ..lineTo(55, 50)
      ..lineTo(45, 50)
      ..close();
    _shape(canvas, beak, PQColors.sun, 2.2);
    if (thinking || confused) {
      canvas.drawLine(const Offset(24, 20), const Offset(34, 22), _lineC(2.2, PQColors.inkSoft));
    }
    reactionMarks(canvas, sparks: const [Offset(20, 10), Offset(80, 14), Offset(50, 0)], drop: const Offset(24, 24));
  }
}

// --------------------------------------------------------------- 6. Loop

/// Loop — green turtle with a spiral shell: repetition, patience, loops.
class LoopPainter extends CastPainter2 {
  LoopPainter({required super.t, required super.blink, required super.bob, required super.mood});

  static const _skin = PQColors.grass;
  static const _skinDeep = PQColors.grassDeep;
  static const _shell = Color(0xFFB8793C);
  static const _shellLight = Color(0xFFE0A263);

  @override
  void draw(Canvas canvas) {
    final slow = math.sin(t * 2 * math.pi) * 1.2;
    // Legs.
    for (final x in [36.0, 60.0]) {
      final leg = _roundPath(x, 84, 14, 10, 5);
      _shape(canvas, leg, _skin, 2.4);
      canvas.drawLine(Offset(x + 3, 91), Offset(x + 11, 91), _lineC(1.6, _skinDeep));
    }
    // Shell.
    final shell = _ovalPath(50, 70, 56, 42);
    _shape(canvas, shell, _shell, 2.8, shader: _gradC(const Rect.fromLTWH(22, 49, 56, 42), _shellLight, _shell));
    // Spiral: the whole reason Loop exists.
    final spiral = Path();
    for (var i = 0; i <= 120; i++) {
      final a = i / 120 * math.pi * 4.4;
      final r = 2 + (i / 120) * 16;
      final p = Offset(50 + math.cos(a) * r * 1.05, 70 + math.sin(a) * r * 0.78);
      if (i == 0) {
        spiral.moveTo(p.dx, p.dy);
      } else {
        spiral.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(spiral, _lineC(2.6, PQColors.woodDeep));
    // Shell plates at the rim.
    for (final a in [0.5, 1.5, 2.5, 3.5, 4.5, 5.5]) {
      final c = Offset(50 + math.cos(a) * 24, 70 + math.sin(a) * 18);
      canvas.drawCircle(c, 2.6, _fillC(_shellLight));
      canvas.drawCircle(c, 2.6, _lineC(1.6, PQColors.woodDeep));
    }
    // Neck + head, leaning up like a curious turtle.
    final neck = Path()
      ..moveTo(44, 60)
      ..quadraticBezierTo(36, 44, 42, 36)
      ..lineTo(56, 34)
      ..quadraticBezierTo(56, 46, 58, 58)
      ..close();
    _shape(canvas, neck, _skin, 2.5, shader: _gradC(const Rect.fromLTWH(36, 34, 22, 26), const Color(0xFF9BDD64), _skin));
    final head = _ovalPath(50, 32, 34, 28);
    _shape(canvas, head, _skin, 2.8, shader: _gradC(const Rect.fromLTWH(33, 18, 34, 28), const Color(0xFF9BDD64), _skin));
    // Cheek stripes.
    for (final s in [-1.0, 1.0]) {
      canvas.drawLine(Offset(50 + s * 12, 36), Offset(50 + s * 18, 34), _lineC(1.8, _skinDeep));
    }
    eye(canvas, const Offset(41, 29), 5.2, 6.2, look: const Offset(0.7, 0.5), iris: const Color(0xFF2F5D1C));
    eye(canvas, const Offset(59, 29), 5.2, 6.2, look: const Offset(0.7, 0.5), iris: const Color(0xFF2F5D1C));
    mouth(canvas, const Offset(50, 38), 9, curve: 2.6);
    // A leaf hat: gentle nod to the forest, and a distinct silhouette.
    final leaf = Path()
      ..moveTo(38, 20)
      ..quadraticBezierTo(50, 4, 66, 18)
      ..quadraticBezierTo(52, 18, 38, 20)
      ..close();
    _shape(canvas, leaf, PQColors.grassDeep, 2.3);
    canvas.drawLine(const Offset(42, 19), const Offset(58, 12), _lineC(1.4, PQColors.grass));
    // Tiny hourglass-ish mark on the shell rim to hint "when does it stop".
    canvas.save();
    canvas.translate(slow, 0);
    canvas.drawCircle(const Offset(24, 62), 3.2, _fillC(PQColors.sun));
    canvas.drawCircle(const Offset(24, 62), 3.2, _lineC(1.8));
    canvas.restore();
    reactionMarks(canvas, sparks: const [Offset(20, 14), Offset(80, 16), Offset(50, 4)], drop: const Offset(80, 34));
  }
}

// ---------------------------------------------------------------- 7. Bit

/// Bit — a compact robot that floats: single-screen face, chest value slot.
class BitPainter extends CastPainter2 {
  BitPainter({required super.t, required super.blink, required super.bob, required super.mood});

  static const _shellC = PQColors.pyYellow;
  static const _shellDeep = PQColors.sunDeep;
  static const _screen = Color(0xFF17203F);
  static const _glow = Color(0xFF7DF9FF);

  @override
  void draw(Canvas canvas) {
    final hover = math.sin(t * 2 * math.pi * 1.5);
    // Hover thrust instead of wheels: Bit floats.
    for (final x in [40.0, 60.0]) {
      final cone = Path()
        ..moveTo(x - 6, 84)
        ..lineTo(x + 6, 84)
        ..lineTo(x, 92 + hover * 1.5)
        ..close();
      canvas.drawPath(cone, _fillC(PQColors.sky.withValues(alpha: 0.55)));
      canvas.drawPath(cone, _lineC(1.8, PQColors.skyDeep));
    }
    // Arms.
    for (final (x, dir) in [(31.0, -1.0), (69.0, 1.0)]) {
      final angle = dir * (0.5 + (celebrating ? 1.1 : 0)) + math.sin(t * 2 * math.pi * 2) * 0.06 * dir;
      canvas.save();
      canvas.translate(x, 62);
      canvas.rotate(angle);
      _shape(canvas, _roundPath(-3.4, 0, 7, 14, 3.4), _shellDeep, 2.2);
      canvas.drawCircle(const Offset(0, 15), 3.6, _fillC(PQColors.cream));
      canvas.drawCircle(const Offset(0, 15), 3.6, _lineC(2));
      canvas.restore();
    }
    // Body with a value slot: the variable motif.
    final body = _roundPath(32, 56, 36, 28, 9);
    _shape(canvas, body, _shellC, 2.7, shader: _gradC(const Rect.fromLTWH(32, 56, 36, 28), const Color(0xFFFFE787), _shellC));
    final slot = _roundPath(40, 66, 20, 12, 4);
    _shape(canvas, slot, PQColors.night, 2.4);
    final blinkGlow = (t * 3).floor().isEven;
    final value = blinkGlow ? '5' : '7';
    final tp = TextPainter(
      text: TextSpan(
        text: value,
        style: const TextStyle(
            fontFamily: 'JetBrainsMono', fontSize: 11, fontWeight: FontWeight.w700, color: _glow),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(50 - tp.width / 2, 67));
    // Neck.
    canvas.drawRect(const Rect.fromLTWH(46, 52, 8, 6), _fillC(_shellDeep));
    canvas.drawRect(const Rect.fromLTWH(46, 52, 8, 6), _lineC(2));
    // Antenna with a spinning propeller.
    canvas.drawLine(const Offset(50, 20), const Offset(50, 12), _lineC(2.4));
    final spin = math.cos(t * 2 * math.pi * 6);
    canvas.drawLine(Offset(50 - 9 * spin.abs(), 10), Offset(50 + 9, 10), _lineC(3, PQColors.coral));
    canvas.drawCircle(const Offset(50, 10), 2.4, _fillC(PQColors.coral));
    // Cube head with a screen face (square, unlike Robo's rounded rectangle).
    final head = _roundPath(26, 20, 48, 34, 7);
    _shape(canvas, head, _shellC, 2.8, shader: _gradC(const Rect.fromLTWH(26, 20, 48, 34), const Color(0xFFFFEFAE), _shellC));
    final screen = _roundPath(31, 25, 38, 24, 6);
    _shape(canvas, screen, _screen, 2.4);
    final led = Paint()
      ..color = _glow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final open = 1 - blink;
    if (confused) {
      canvas.drawLine(const Offset(38, 34), const Offset(45, 36), led);
      canvas.drawLine(const Offset(55, 36), const Offset(62, 34), led);
      canvas.drawLine(const Offset(46, 42), const Offset(54, 41), led);
    } else {
      for (final x in [41.0, 59.0]) {
        if (open > 0.2) {
          canvas.drawCircle(Offset(x, 34), 3.4 * open + 0.6, Paint()..color = _glow);
        } else {
          canvas.drawLine(Offset(x - 3.4, 34), Offset(x + 3.4, 34), led);
        }
      }
      final smile = Path();
      if (sad) {
        smile
          ..moveTo(44, 44)
          ..quadraticBezierTo(50, 40, 56, 44);
      } else {
        smile
          ..moveTo(44, 41)
          ..quadraticBezierTo(50, 47, 56, 41);
      }
      canvas.drawPath(smile, led);
    }
    if (celebrating) {
      final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi * 4).abs();
      for (final c in const [Offset(20, 16), Offset(80, 18), Offset(50, 4)]) {
        canvas.drawCircle(c, 1.6 + 1.8 * pulse, _fillC(_glow));
        canvas.drawCircle(c, 1.6 + 1.8 * pulse, _lineC(1.3));
      }
    }
    reactionMarks(canvas, sparks: const [Offset(18, 20), Offset(82, 22)], drop: const Offset(24, 30));
  }
}

// --------------------------------------------------------------- 8. Lumi

/// Lumi — forest spirit who hands out quests and creative challenges.
class LumiPainter extends CastPainter2 {
  LumiPainter({required super.t, required super.blink, required super.bob, required super.mood});

  static const _body = Color(0xFFF3FFFB);
  static const _bodyShade = Color(0xFFB7E8DE);
  static const _glow = Color(0xFF4FE0C0);

  @override
  void draw(Canvas canvas) {
    final float = math.sin(t * 2 * math.pi) * 1.8;
    // Soft halo, always behind the body.
    canvas.drawCircle(const Offset(50, 52), 40, _fillC(_glow.withValues(alpha: 0.16)));
    canvas.drawCircle(const Offset(50, 52), 30, _fillC(_glow.withValues(alpha: 0.14)));
    // Legs: slender, elegant deer-like.
    for (final x in [43.0, 57.0]) {
      final leg = _roundPath(x, 76, 6.5, 16, 3.2);
      _shape(canvas, leg, _bodyShade, 2.2);
      final hoof = _roundPath(x - 1, 89, 8.5, 4.5, 2);
      _shape(canvas, hoof, PQColors.woodDeep, 2);
    }
    // Body.
    final body = _ovalPath(50, 68, 30, 28);
    _shape(canvas, body, _body, 2.7, shader: _gradC(const Rect.fromLTWH(35, 54, 30, 28), Colors.white, _bodyShade));
    // Flowing tail.
    final tail = Path()
      ..moveTo(64, 70)
      ..quadraticBezierTo(78, 66, 76, 52)
      ..quadraticBezierTo(70, 62, 63, 64)
      ..close();
    _shape(canvas, tail, _glow, 2.2);
    // Neck.
    final neck = Path()
      ..moveTo(45, 58)
      ..quadraticBezierTo(44, 46, 48, 40)
      ..lineTo(58, 42)
      ..quadraticBezierTo(54, 50, 55, 60)
      ..close();
    _shape(canvas, neck, _body, 2.5, shader: _gradC(const Rect.fromLTWH(44, 40, 14, 20), Colors.white, _bodyShade));
    // Head: narrow with a gentle muzzle.
    final head = _ovalPath(52, 32, 30, 26);
    _shape(canvas, head, _body, 2.7, shader: _gradC(const Rect.fromLTWH(37, 19, 30, 26), Colors.white, _bodyShade));
    final muzzle = _ovalPath(64, 36, 12, 9);
    _shape(canvas, muzzle, Colors.white, 2.1);
    final nose = Path()
      ..moveTo(69, 34)
      ..lineTo(72, 36)
      ..lineTo(69, 38)
      ..close();
    canvas.drawPath(nose, _fillC(PQColors.grapeDeep));
    mouth(canvas, const Offset(61, 40), 6, curve: 2, stroke: 1.8);
    // Antlers of light.
    for (final s in [-1.0, 1.0]) {
      final antler = Path()
        ..moveTo(52 + s * 7, 21)
        ..quadraticBezierTo(52 + s * 12, 10, 52 + s * 20, 6);
      canvas.drawPath(antler, _lineC(2.4, _glow));
      final branch = Path()
        ..moveTo(52 + s * 14, 12)
        ..lineTo(52 + s * 22, 12);
      canvas.drawPath(branch, _lineC(1.8, _glow));
    }
    // Leaf ears.
    for (final left in [true, false]) {
      final dir = left ? -1.0 : 1.0;
      final ear = Path()
        ..moveTo(52 + dir * 11, 22)
        ..quadraticBezierTo(52 + dir * 22, 16, 52 + dir * 26, 24)
        ..quadraticBezierTo(52 + dir * 18, 26, 52 + dir * 11, 22)
        ..close();
      _shape(canvas, ear, _bodyShade, 2.1);
      canvas.drawLine(Offset(52 + dir * 13, 22), Offset(52 + dir * 23, 21), _lineC(1.3, _glow));
    }
    eye(canvas, const Offset(46, 31), 4.6, 5.6, look: const Offset(0.8, 0.5), iris: const Color(0xFF1E7A66));
    eye(canvas, const Offset(58, 30), 4.6, 5.6, look: const Offset(0.8, 0.5), iris: const Color(0xFF1E7A66));
    // Floating motes that drift with the idle animation.
    for (var i = 0; i < 3; i++) {
      final a = t * 2 * math.pi + i * 2.1;
      final c = Offset(50 + math.cos(a) * 30, 50 + math.sin(a) * 14 + float);
      canvas.drawCircle(c, 2.6, _fillC(_glow.withValues(alpha: 0.85)));
      canvas.drawCircle(c, 4.6, _fillC(_glow.withValues(alpha: 0.25)));
    }
    if (thinking || confused) {
      canvas.drawCircle(const Offset(78, 22), 2.2, _fillC(_glow.withValues(alpha: 0.8)));
      canvas.drawCircle(const Offset(84, 15), 3.2, _fillC(_glow.withValues(alpha: 0.6)));
      canvas.drawCircle(const Offset(90, 8), 4.2, _fillC(_glow.withValues(alpha: 0.45)));
    }
    reactionMarks(canvas, sparks: const [Offset(14, 30), Offset(86, 34), Offset(50, 2)], drop: const Offset(30, 22));
  }
}
