import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/palette.dart';

/// One-shot confetti burst that falls over its child.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.play = true, this.count = 70});
  final bool play;
  final int count;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(7);
    const colors = [PQColors.sun, PQColors.coral, PQColors.sea, PQColors.grass, PQColors.grape, PQColors.berry];
    _pieces = List.generate(widget.count, (i) {
      return _Piece(
        x: rnd.nextDouble(),
        delay: rnd.nextDouble() * 0.35,
        speed: 0.7 + rnd.nextDouble() * 0.6,
        drift: (rnd.nextDouble() - 0.5) * 0.25,
        spin: (rnd.nextDouble() - 0.5) * 12,
        size: 6 + rnd.nextDouble() * 7,
        color: colors[i % colors.length],
        round: rnd.nextBool(),
      );
    });
    if (widget.play) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(painter: _ConfettiPainter(_pieces, _c.value), size: Size.infinite),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.x,
    required this.delay,
    required this.speed,
    required this.drift,
    required this.spin,
    required this.size,
    required this.color,
    required this.round,
  });
  final double x;
  final double delay;
  final double speed;
  final double drift;
  final double spin;
  final double size;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    for (final p in pieces) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final y = -20 + local * p.speed * (size.height + 60);
      final x = (p.x + p.drift * local + math.sin(local * 9 + p.x * 6) * 0.02) * size.width;
      final fade = local > 0.8 ? (1 - local) / 0.2 : 1.0;
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(local * p.spin);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
