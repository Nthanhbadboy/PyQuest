import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Page route where puffy clouds sweep in and part to reveal the new place.
class CloudRoute<T> extends PageRouteBuilder<T> {
  CloudRoute({required WidgetBuilder builder, super.settings, bool calm = false})
      : super(
          transitionDuration: Duration(milliseconds: calm ? 250 : 700),
          reverseTransitionDuration: Duration(milliseconds: calm ? 200 : 450),
          pageBuilder: (context, animation, secondary) => builder(context),
          transitionsBuilder: (context, animation, secondary, child) {
            if (calm) return FadeTransition(opacity: animation, child: child);
            return _CloudTransition(animation: animation, child: child);
          },
        );
}

class _CloudTransition extends StatelessWidget {
  const _CloudTransition({required this.animation, required this.child});
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reveal = CurvedAnimation(parent: animation, curve: const Interval(0.45, 1.0, curve: Curves.easeOut));
    return Stack(
      children: [
        FadeTransition(
          opacity: reveal,
          child: ScaleTransition(scale: Tween(begin: 1.06, end: 1.0).animate(reveal), child: child),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) => CustomPaint(painter: CloudSweepPainter(animation.value)),
            ),
          ),
        ),
      ],
    );
  }
}

class CloudSweepPainter extends CustomPainter {
  CloudSweepPainter(this.t);
  final double t;

  static const _clouds = [
    // (y fraction, size fraction, from-left?)
    (0.08, 0.55, true), (0.22, 0.7, false), (0.38, 0.65, true), (0.52, 0.75, false),
    (0.68, 0.6, true), (0.82, 0.72, false), (0.95, 0.6, true),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cover = math.sin(t * math.pi); // 0 → 1 → 0
    if (cover <= 0.001) return;
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.96 * cover.clamp(0.0, 1.0));
    final shade = Paint()..color = const Color(0xFFDDEFFF).withValues(alpha: 0.9 * cover.clamp(0.0, 1.0));
    for (final (yf, sf, fromLeft) in _clouds) {
      final w = size.width * sf;
      final startX = fromLeft ? -w * 0.9 : size.width + w * 0.9;
      final endX = fromLeft ? size.width * 0.32 : size.width * 0.68;
      final cx = startX + (endX - startX) * cover;
      final cy = size.height * yf;
      _puff(canvas, Offset(cx, cy + w * 0.06), w, shade);
      _puff(canvas, Offset(cx, cy), w, fill);
    }
  }

  void _puff(Canvas canvas, Offset c, double w, Paint p) {
    canvas.drawCircle(c, w * 0.28, p);
    canvas.drawCircle(c.translate(-w * 0.28, w * 0.06), w * 0.2, p);
    canvas.drawCircle(c.translate(w * 0.3, w * 0.05), w * 0.22, p);
    canvas.drawCircle(c.translate(-w * 0.1, -w * 0.12), w * 0.22, p);
    canvas.drawCircle(c.translate(w * 0.14, -w * 0.1), w * 0.2, p);
  }

  @override
  bool shouldRepaint(CloudSweepPainter old) => old.t != t;
}

/// Gentle pop-in used for result stars, badges and dialogs.
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child, this.delay = Duration.zero, this.duration = const Duration(milliseconds: 450)});
  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final total = delay + duration;
    final start = total.inMilliseconds == 0 ? 0.0 : delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      builder: (context, v, child) {
        final local = start >= 1 ? 1.0 : ((v - start) / (1 - start)).clamp(0.0, 1.0);
        final scale = Curves.elasticOut.transform(local);
        return Opacity(
          opacity: local.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.2 + 0.8 * scale, child: child),
        );
      },
      child: child,
    );
  }
}
