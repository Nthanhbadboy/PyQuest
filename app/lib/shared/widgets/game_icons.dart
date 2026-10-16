import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/palette.dart';

Paint _ink(double w) => Paint()
  ..color = PQColors.ink
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round;

Path starPath(Offset c, double outer, double inner, {double rotation = -math.pi / 2}) {
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final r = i.isEven ? outer : inner;
    final a = rotation + i * math.pi / 5;
    final pt = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
    if (i == 0) {
      p.moveTo(pt.dx, pt.dy);
    } else {
      p.lineTo(pt.dx, pt.dy);
    }
  }
  return p..close();
}

/// Gold star (filled) or an empty slot.
class StarIcon extends StatelessWidget {
  const StarIcon({super.key, this.filled = true, this.size = 28});
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _StarPainter(filled));
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.filled);
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.width * 0.47;
    final path = starPath(c, outer, outer * 0.5);
    if (filled) {
      canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE680), PQColors.sun, PQColors.sunDeep],
          ).createShader(Offset.zero & size),
      );
      final shine = starPath(c.translate(-outer * 0.08, -outer * 0.1), outer * 0.42, outer * 0.2);
      canvas.drawPath(shine, Paint()..color = Colors.white.withValues(alpha: 0.35));
    } else {
      canvas.drawPath(path, Paint()..color = PQColors.parchmentDeep);
    }
    canvas.drawPath(path, _ink(size.width * 0.075)..color = filled ? PQColors.ink : PQColors.inkFaint);
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.filled != filled;
}

class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.max = 3, this.size = 26, this.spacing = 2});
  final int stars;
  final int max;
  final double size;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing / 2),
            child: StarIcon(filled: i < stars, size: size),
          ),
      ],
    );
  }
}

enum GameIconKind { energy, coin, gem, heart, chest, stamp, lock, trophy }

/// Small painted pickups/resources used across the UI.
class GameIcon extends StatelessWidget {
  const GameIcon(this.kind, {super.key, this.size = 24, this.dimmed = false});
  final GameIconKind kind;
  final double size;
  final bool dimmed;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: GameIconPainter(kind, dimmed: dimmed));
}

class GameIconPainter extends CustomPainter {
  GameIconPainter(this.kind, {this.dimmed = false});
  final GameIconKind kind;
  final bool dimmed;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.save();
    canvas.scale(s);
    switch (kind) {
      case GameIconKind.energy:
        final bolt = Path()
          ..moveTo(13.5, 1.5)
          ..lineTo(4, 13.5)
          ..lineTo(10.5, 13.5)
          ..lineTo(9, 22.5)
          ..lineTo(20, 9.5)
          ..lineTo(13, 9.5)
          ..close();
        canvas.drawPath(bolt, Paint()..color = dimmed ? PQColors.disabled : PQColors.energy);
        canvas.drawPath(
            Path()
              ..moveTo(13.5, 1.5)
              ..lineTo(7, 10)
              ..lineTo(11, 10)
              ..close(),
            Paint()..color = Colors.white.withValues(alpha: 0.35));
        canvas.drawPath(bolt, _ink(1.8));
      case GameIconKind.coin:
        canvas.drawCircle(const Offset(12, 12), 10, Paint()..color = dimmed ? PQColors.disabled : PQColors.sunDeep);
        canvas.drawCircle(const Offset(12, 11), 8.6, Paint()..color = dimmed ? PQColors.disabled : PQColors.sun);
        canvas.drawCircle(const Offset(12, 12), 10, _ink(1.8));
        canvas.drawCircle(const Offset(12, 11.2), 5.4, _ink(1.4)..color = PQColors.sunDeep);
        canvas.drawLine(const Offset(9, 7.5), const Offset(8, 10), _ink(1.6)..color = Colors.white.withValues(alpha: 0.7));
      case GameIconKind.gem:
        final gem = Path()
          ..moveTo(6, 3)
          ..lineTo(18, 3)
          ..lineTo(22, 9)
          ..lineTo(12, 22)
          ..lineTo(2, 9)
          ..close();
        canvas.drawPath(
            gem,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dimmed ? [PQColors.disabled, PQColors.disabledDeep] : const [Color(0xFF9FF3FF), PQColors.sea, PQColors.seaDeep],
              ).createShader(const Rect.fromLTWH(0, 0, 24, 24)));
        canvas.drawPath(
            Path()
              ..moveTo(2, 9)
              ..lineTo(22, 9)
              ..moveTo(9, 3)
              ..lineTo(7.5, 9)
              ..lineTo(12, 22)
              ..lineTo(16.5, 9)
              ..lineTo(15, 3),
            _ink(1.1)..color = PQColors.ink.withValues(alpha: 0.55));
        canvas.drawPath(gem, _ink(1.8));
      case GameIconKind.heart:
        final heart = Path()
          ..moveTo(12, 21)
          ..cubicTo(3, 14.5, 1.5, 9.5, 3.5, 6)
          ..cubicTo(5.5, 2.5, 10, 2.8, 12, 6.5)
          ..cubicTo(14, 2.8, 18.5, 2.5, 20.5, 6)
          ..cubicTo(22.5, 9.5, 21, 14.5, 12, 21)
          ..close();
        canvas.drawPath(heart, Paint()..color = dimmed ? PQColors.disabled : PQColors.berry);
        canvas.drawOval(const Rect.fromLTWH(5.5, 6, 4.5, 3.4), Paint()..color = Colors.white.withValues(alpha: dimmed ? 0.2 : 0.55));
        canvas.drawPath(heart, _ink(1.8));
      case GameIconKind.chest:
        final body = RRect.fromRectAndRadius(const Rect.fromLTWH(2.5, 10, 19, 11), const Radius.circular(2));
        final lid = RRect.fromRectAndCorners(const Rect.fromLTWH(2.5, 4, 19, 7),
            topLeft: const Radius.circular(6), topRight: const Radius.circular(6));
        canvas.drawRRect(body, Paint()..color = PQColors.wood);
        canvas.drawRRect(lid, Paint()..color = const Color(0xFFD08A4A));
        canvas.drawRRect(body, _ink(1.6));
        canvas.drawRRect(lid, _ink(1.6));
        canvas.drawRect(const Rect.fromLTWH(10, 9, 4, 5), Paint()..color = PQColors.sun);
        canvas.drawRect(const Rect.fromLTWH(10, 9, 4, 5), _ink(1.2));
      case GameIconKind.stamp:
        canvas.drawCircle(const Offset(12, 12), 10, Paint()..color = dimmed ? PQColors.disabled : PQColors.berry);
        canvas.drawCircle(const Offset(12, 12), 7.4, _ink(1.2)..color = Colors.white.withValues(alpha: 0.85));
        canvas.drawPath(starPath(const Offset(12, 12), 5, 2.4), Paint()..color = Colors.white);
        canvas.drawCircle(const Offset(12, 12), 10, _ink(1.8));
      case GameIconKind.lock:
        final shackle = Path()
          ..moveTo(7.5, 11)
          ..lineTo(7.5, 7.5)
          ..arcToPoint(const Offset(16.5, 7.5), radius: const Radius.circular(4.5))
          ..lineTo(16.5, 11);
        canvas.drawPath(shackle, _ink(2.6));
        final body = RRect.fromRectAndRadius(const Rect.fromLTWH(4.5, 10, 15, 12), const Radius.circular(3));
        canvas.drawRRect(body, Paint()..color = PQColors.parchmentEdge);
        canvas.drawRRect(body, _ink(1.8));
        canvas.drawCircle(const Offset(12, 15.5), 1.8, Paint()..color = PQColors.ink);
      case GameIconKind.trophy:
        final cup = Path()
          ..moveTo(6, 3)
          ..lineTo(18, 3)
          ..lineTo(17, 10)
          ..quadraticBezierTo(16, 14, 12, 14.5)
          ..quadraticBezierTo(8, 14, 7, 10)
          ..close();
        canvas.drawPath(cup, Paint()..color = PQColors.sun);
        canvas.drawPath(cup, _ink(1.6));
        canvas.drawArc(const Rect.fromLTWH(2.5, 4, 6, 6), math.pi / 2, math.pi, false, _ink(1.6));
        canvas.drawArc(const Rect.fromLTWH(15.5, 4, 6, 6), -math.pi / 2, math.pi, false, _ink(1.6));
        canvas.drawRect(const Rect.fromLTWH(10.5, 14.5, 3, 4), Paint()..color = PQColors.sunDeep);
        final base = RRect.fromRectAndRadius(const Rect.fromLTWH(6.5, 18.5, 11, 3.5), const Radius.circular(1.5));
        canvas.drawRRect(base, Paint()..color = PQColors.wood);
        canvas.drawRRect(base, _ink(1.4));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(GameIconPainter old) => old.kind != kind || old.dimmed != dimmed;
}

/// Round medal used for badges in the Achievement House and result screens.
class BadgeMedal extends StatelessWidget {
  const BadgeMedal({super.key, required this.icon, required this.color, this.size = 72, this.locked = false, this.secret = false});
  final IconData icon;
  final Color color;
  final double size;
  final bool locked;
  final bool secret;

  @override
  Widget build(BuildContext context) {
    final face = locked ? PQColors.disabled : color;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MedalPainter(face, locked),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: size * 0.12),
            child: locked && secret
                ? Text('?', style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w800, fontSize: size * 0.4, color: Colors.white))
                : Icon(locked ? Icons.lock_rounded : icon, size: size * 0.38, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  _MedalPainter(this.face, this.locked);
  final Color face;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final ink = _ink(w * 0.04);
    // Ribbon tails
    final ribbonColor = locked ? PQColors.disabledDeep : PQColors.berry;
    for (final dir in [-1.0, 1.0]) {
      final p = Path()
        ..moveTo(w * 0.5 + dir * w * 0.08, w * 0.62)
        ..lineTo(w * 0.5 + dir * w * 0.3, w * 0.98)
        ..lineTo(w * 0.5 + dir * w * 0.17, w * 0.9)
        ..lineTo(w * 0.5 + dir * w * 0.06, w * 0.99)
        ..lineTo(w * 0.5 - dir * w * 0.06, w * 0.66)
        ..close();
      canvas.drawPath(p, Paint()..color = ribbonColor);
      canvas.drawPath(p, ink);
    }
    final c = Offset(w / 2, w * 0.44);
    final r = w * 0.4;
    // Scalloped rim
    final rim = Path();
    const bumps = 16;
    for (var i = 0; i <= bumps * 2; i++) {
      final a = i * math.pi / bumps;
      final rr = i.isEven ? r : r * 0.93;
      final pt = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
      if (i == 0) {
        rim.moveTo(pt.dx, pt.dy);
      } else {
        rim.lineTo(pt.dx, pt.dy);
      }
    }
    rim.close();
    canvas.drawPath(rim, Paint()..color = locked ? PQColors.disabledDeep : PQColors.sun);
    canvas.drawPath(rim, ink);
    canvas.drawCircle(
      c,
      r * 0.76,
      Paint()
        ..shader = RadialGradient(colors: [Color.lerp(face, Colors.white, 0.25)!, face])
            .createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(c, r * 0.76, ink);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.6), math.pi * 1.1, math.pi * 0.5, false,
        _ink(w * 0.035)..color = Colors.white.withValues(alpha: 0.45));
  }

  @override
  bool shouldRepaint(_MedalPainter old) => old.face != face || old.locked != locked;
}
