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

  Color get accentColor => PQColors.sea;

  @override
  void drawOverlay(Canvas canvas) {
    final Rect ring = Rect.fromCenter(center: const Offset(50, 91), width: 62, height: 14);
    canvas.drawOval(
      ring.shift(const Offset(0, 3)),
      _fillC(PQColors.ink.withValues(alpha: 0.35)),
    );
    canvas.drawOval(
      ring,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            accentColor.withValues(alpha: 0.85),
            PQColors.woodDeep,
          ],
        ).createShader(ring),
    );
    canvas.drawOval(ring, _lineC(2.0, PQColors.ink));
  }

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

  @override
  String? get spriteAsset => 'assets/images/robo_token_r50.png';

  @override
  Color get accentColor => PQColors.sea;

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

  @override
  String? get spriteAsset => 'assets/images/py_token_r56.png';

  @override
  Color get accentColor => PQColors.grape;

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

/// Kai — readable young programmer silhouette: headphones, swept spikes and hoodie.
class KaiPainter extends CastPainter2 {
  KaiPainter({required super.t, required super.blink, required super.bob, required super.mood});

  @override
  String? get spriteAsset => 'assets/images/pip_token_r54.png';

  @override
  Color get accentColor => PQColors.grass;

  static const _hoodie = PQColors.grass;
  static const _hoodieDeep = PQColors.grassDeep;
  static const _hair = Color(0xFF3A2A1E);
  static const _skin = Color(0xFFFFDDBA);
  static const _shoe = PQColors.coral;

  @override
  void draw(Canvas canvas) {
    final bounce = math.sin(t * 2 * math.pi * 2) * 1.4;
    // Shoes and separated legs make the human silhouette clear at thumbnail size.
    for (final x in [41.0, 57.0]) {
      _shape(canvas, _roundPath(x - 5, 85 + (celebrating ? -bounce : 0), 13, 7, 3.5), _shoe, 2.2);
      _shape(canvas, _roundPath(x - 1, 74, 7, 13, 3), const Color(0xFF3E5A86), 2.2);
    }

    // Arms sit behind the hoodie; celebrating raises the right hand.
    arm(canvas, const Offset(34, 61), 0.72, 14, 8, _hoodie);
    arm(canvas, const Offset(66, 60), celebrating ? -2.25 : -0.68, 14, 8, _hoodie);

    // Hoodie with a distinct shoulder line and pocket.
    _shape(canvas, _roundPath(32, 53, 36, 28, 10), _hoodie, 2.7,
        shader: _gradC(const Rect.fromLTWH(32, 53, 36, 28), const Color(0xFFA9E86C), _hoodie));
    final hood = Path()
      ..moveTo(38, 56)
      ..quadraticBezierTo(50, 68, 62, 56);
    canvas.drawPath(hood, _lineC(3, _hoodieDeep));
    canvas.drawLine(const Offset(45, 61), const Offset(44, 69), _lineC(1.8, PQColors.cream));
    canvas.drawLine(const Offset(55, 61), const Offset(56, 69), _lineC(1.8, PQColors.cream));
    _shape(canvas, _roundPath(41, 70, 18, 8, 3), _hoodieDeep, 1.8);
    // Tiny pixel emblem on the chest.
    _shape(canvas, _roundPath(57, 59, 7, 7, 1.5), PQColors.cream, 1.4);
    for (final p in const [Offset(59, 61), Offset(62, 64), Offset(59, 64)]) {
      canvas.drawRect(Rect.fromLTWH(p.dx, p.dy, 1.5, 1.5), _fillC(_hoodieDeep));
    }

    // Neck and headphones now frame the head, rather than hanging like a necklace.
    _shape(canvas, _roundPath(45, 47, 10, 11, 3), _skin, 2.2);
    final band = Path()
      ..moveTo(29, 35)
      ..cubicTo(27, 7, 73, 7, 71, 35);
    canvas.drawPath(band, _lineC(5, PQColors.night));
    canvas.drawPath(band, _lineC(2, PQColors.sky));
    for (final x in [29.0, 71.0]) {
      _shape(canvas, _roundPath(x - 4, 29, 8, 13, 3), PQColors.night, 2.2);
      canvas.drawLine(Offset(x - 1, 33), Offset(x + 1, 38), _lineC(1.4, PQColors.sky));
    }

    // Head, ears and a more intentional hair silhouette.
    _shape(canvas, _ovalPath(50, 35, 39, 39), _skin, 2.7,
        shader: _gradC(const Rect.fromLTWH(30.5, 15.5, 39, 39), const Color(0xFFFFE8CF), PQColors.skin));
    for (final x in [31.0, 69.0]) {
      _shape(canvas, _ovalPath(x, 37, 7, 10), _skin, 2);
    }
    final spikes = Path()
      ..moveTo(29, 33)
      ..lineTo(23, 19)
      ..lineTo(34, 24)
      ..lineTo(35, 10)
      ..lineTo(44, 21)
      ..lineTo(51, 6)
      ..lineTo(57, 20)
      ..lineTo(67, 11)
      ..lineTo(68, 24)
      ..lineTo(78, 19)
      ..lineTo(72, 34)
      ..quadraticBezierTo(61, 24, 50, 24)
      ..quadraticBezierTo(39, 24, 29, 33)
      ..close();
    _shape(canvas, spikes, _hair, 2.6,
        shader: _gradC(const Rect.fromLTWH(23, 6, 55, 29), const Color(0xFF5B4230), _hair));

    // Brows, bright eyes and an open, friendly smile.
    canvas.drawLine(const Offset(35, 29), Offset(44, sad ? 31 : 28), _lineC(2.1, _hair));
    canvas.drawLine(const Offset(56, 28), Offset(65, sad ? 31 : 29), _lineC(2.1, _hair));
    eye(canvas, const Offset(41, 38), 5.3, 6.6, look: const Offset(0.5, 0.5), iris: const Color(0xFF5C3A1E));
    eye(canvas, const Offset(59, 38), 5.3, 6.6, look: const Offset(0.5, 0.5), iris: const Color(0xFF5C3A1E));
    mouth(canvas, const Offset(50, 47), 10, curve: 3.2);
    // Cheek warmth and a tiny headphone status light.
    canvas.drawCircle(const Offset(35, 45), 2.1, _fillC(const Color(0xFFE99A87).withValues(alpha: 0.72)));
    canvas.drawCircle(const Offset(65, 45), 2.1, _fillC(const Color(0xFFE99A87).withValues(alpha: 0.72)));
    canvas.drawCircle(const Offset(71, 39), 1.2, _fillC(PQColors.sun));
    reactionMarks(canvas, sparks: const [Offset(20, 12), Offset(80, 12), Offset(50, 2)], drop: const Offset(26, 28));
  }
}

// --------------------------------------------------------------- 4. Byte

/// Byte — orange fox who investigates bugs: sitting quadruped with a lens.
class BytePainter extends CastPainter2 {
  BytePainter({required super.t, required super.blink, required super.bob, required super.mood});

  @override
  String? get spriteAsset => 'assets/images/bitsy_token_r56.png';

  @override
  Color get accentColor => const Color(0xFFF59029);

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

  @override
  String? get spriteAsset => 'assets/images/py_token_r56.png';

  @override
  Color get accentColor => PQColors.skyDeep;

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

  @override
  String? get spriteAsset => 'assets/images/pip_token_r54.png';

  @override
  Color get accentColor => PQColors.grassDeep;

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

  @override
  String? get spriteAsset => 'assets/images/robo_token_r50.png';

  @override
  Color get accentColor => PQColors.pyYellow;

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

/// Lumi — a tiny forest quest-spirit with unmistakable leaf ears and a charm.
class LumiPainter extends CastPainter2 {
  LumiPainter({required super.t, required super.blink, required super.bob, required super.mood});

  @override
  String? get spriteAsset => 'assets/images/bitsy_token_r56.png';

  @override
  Color get accentColor => const Color(0xFF70DEC2);

  static const _mint = Color(0xFF70DEC2);
  static const _mintDeep = Color(0xFF279B88);
  static const _leaf = Color(0xFF78D96A);
  static const _leafDeep = Color(0xFF3B9D63);
  static const _cream = Color(0xFFEFFFF5);
  static const _gold = Color(0xFFFFD66D);

  @override
  void draw(Canvas canvas) {
    final float = math.sin(t * 2 * math.pi) * 1.8;
    canvas.save();
    canvas.translate(0, float);

    // Soft magical glow stays behind the clear silhouette.
    canvas.drawCircle(const Offset(50, 51), 38, _fillC(_mint.withValues(alpha: 0.13)));
    canvas.drawCircle(const Offset(50, 51), 29, _fillC(_mint.withValues(alpha: 0.12)));

    // Leaf ears: long, pointed, and large enough to identify Lumi at a glance.
    final leftEar = Path()
      ..moveTo(40, 25)
      ..quadraticBezierTo(17, 20, 13, 4)
      ..quadraticBezierTo(34, 5, 44, 20)
      ..close();
    _shape(canvas, leftEar, _leaf, 2.5,
        shader: _gradC(const Rect.fromLTWH(13, 4, 31, 21), const Color(0xFFA3F27D), _leaf));
    canvas.drawLine(const Offset(19, 8), const Offset(39, 21), _lineC(1.5, _leafDeep));
    final rightEar = Path()
      ..moveTo(60, 25)
      ..quadraticBezierTo(83, 20, 87, 4)
      ..quadraticBezierTo(66, 5, 56, 20)
      ..close();
    _shape(canvas, rightEar, _leaf, 2.5,
        shader: _gradC(const Rect.fromLTWH(56, 4, 31, 21), const Color(0xFFA3F27D), _leaf));
    canvas.drawLine(const Offset(81, 8), const Offset(61, 21), _lineC(1.5, _leafDeep));

    // Short petal cape gives Lumi a separate shoulder and outer contour.
    final cape = Path()
      ..moveTo(34, 52)
      ..quadraticBezierTo(21, 48, 20, 62)
      ..lineTo(25, 78)
      ..quadraticBezierTo(29, 82, 34, 75)
      ..lineTo(40, 63)
      ..close();
    _shape(canvas, cape, const Color(0xFFB6F0A2), 2.3);
    final capeRight = Path()
      ..moveTo(66, 52)
      ..quadraticBezierTo(79, 48, 80, 62)
      ..lineTo(75, 78)
      ..quadraticBezierTo(71, 82, 66, 75)
      ..lineTo(60, 63)
      ..close();
    _shape(canvas, capeRight, const Color(0xFFB6F0A2), 2.3);

    // Little feet and rounded body; the pale belly separates the torso from the head.
    for (final x in [41.0, 59.0]) {
      _shape(canvas, _roundPath(x - 4, 82, 9, 7, 3), _mintDeep, 2);
    }
    _shape(canvas, _ovalPath(50, 67, 36, 30), _mint, 2.7,
        shader: _gradC(const Rect.fromLTWH(32, 52, 36, 30), const Color(0xFF9BF0D8), _mintDeep));
    _shape(canvas, _ovalPath(50, 70, 20, 17), _cream, 1.8);

    // Scarf and quest medallion anchor the character's role in the game.
    final scarf = Path()
      ..moveTo(34, 49)
      ..quadraticBezierTo(50, 57, 66, 49)
      ..lineTo(63, 56)
      ..quadraticBezierTo(50, 62, 37, 56)
      ..close();
    _shape(canvas, scarf, _gold, 2.2);
    _shape(canvas, _roundPath(58, 57, 10, 12, 4), _gold, 2);
    canvas.drawLine(const Offset(63, 59), const Offset(63, 64), _lineC(1.5, PQColors.woodDeep));

    // Large friendly head with a subtle cheek shape, not an undifferentiated blob.
    _shape(canvas, _ovalPath(50, 34, 43, 37), _mint, 2.8,
        shader: _gradC(const Rect.fromLTWH(28.5, 15.5, 43, 37), const Color(0xFFB5F5E3), _mint));
    // Three-leaf crown.
    final crownLeaves = [
      Path()..moveTo(38, 20)..quadraticBezierTo(29, 7, 38, 2)..quadraticBezierTo(47, 8, 43, 21)..close(),
      Path()..moveTo(47, 19)..quadraticBezierTo(45, 3, 54, 0)..quadraticBezierTo(61, 10, 53, 21)..close(),
      Path()..moveTo(55, 21)..quadraticBezierTo(62, 8, 71, 10)..quadraticBezierTo(70, 20, 58, 24)..close(),
    ];
    for (final leaf in crownLeaves) {
      _shape(canvas, leaf, _leaf, 1.8);
    }

    // Expressive eyes and cheeks, consistent with the rest of the PyQuest cast.
    canvas.drawLine(const Offset(36, 28), const Offset(44, 27), _lineC(1.8, _mintDeep));
    canvas.drawLine(const Offset(56, 27), const Offset(64, 28), _lineC(1.8, _mintDeep));
    eye(canvas, const Offset(41, 35), 5.4, 6.7, look: const Offset(0.5, 0.4), iris: const Color(0xFF1E6E60));
    eye(canvas, const Offset(59, 35), 5.4, 6.7, look: const Offset(0.5, 0.4), iris: const Color(0xFF1E6E60));
    canvas.drawCircle(const Offset(32, 43), 2.7, _fillC(const Color(0xFFFFA99C).withValues(alpha: 0.78)));
    canvas.drawCircle(const Offset(68, 43), 2.7, _fillC(const Color(0xFFFFA99C).withValues(alpha: 0.78)));
    mouth(canvas, const Offset(50, 45), 8, curve: 2.8);

    // Floating golden quest-star, plus gentle idle motes.
    final starCenter = Offset(79, 54 + math.sin(t * 2 * math.pi * 1.5) * 2);
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? 5.3 : 2.5;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point = Offset(starCenter.dx + math.cos(angle) * radius, starCenter.dy + math.sin(angle) * radius);
      if (i == 0) {
        star.moveTo(point.dx, point.dy);
      } else {
        star.lineTo(point.dx, point.dy);
      }
    }
    star.close();
    _shape(canvas, star, _gold, 1.7);
    canvas.drawCircle(const Offset(17, 38), 1.8, _fillC(_gold));
    canvas.drawCircle(const Offset(83, 31), 1.6, _fillC(_gold));
    if (thinking || confused) {
      canvas.drawCircle(const Offset(82, 18), 2.2, _fillC(_mintDeep));
      canvas.drawCircle(const Offset(88, 12), 3.2, _fillC(_mint));
    }
    canvas.restore();
    reactionMarks(canvas, sparks: const [Offset(14, 30), Offset(86, 34), Offset(50, 2)], drop: const Offset(30, 22));
  }
}