import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../characters/characters.dart';
import '../theme/app_theme.dart';
import '../theme/palette.dart';
import 'chunky_button.dart';

/// Parchment card with an ink outline and a flat "sticker" shadow.
class PQPanel extends StatelessWidget {
  const PQPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = PQColors.cream,
    this.radius = 22,
    this.borderColor = PQColors.ink,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final Color borderColor;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 2.6),
        boxShadow: shadow
            ? [BoxShadow(color: PQColors.ink.withValues(alpha: 0.2), offset: const Offset(0, 5), blurRadius: 0)]
            : null,
      ),
      child: child,
    );
  }
}

/// Small rounded tag, e.g. "Không cần biết Python".
class PillTag extends StatelessWidget {
  const PillTag({super.key, required this.label, this.color = PQColors.grass, this.icon, this.textColor = Colors.white});
  final String label;
  final Color color;
  final IconData? icon;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PQColors.ink, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: textColor), const SizedBox(width: 4)],
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PQText.small.copyWith(color: textColor, fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

/// Character portrait + speech bubble.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.character,
    required this.text,
    this.mood = Mood.happy,
    this.portraitSize = 84,
    this.bubbleColor = PQColors.cream,
    this.trailing,
    this.showPortrait = true,
  });

  final bool showPortrait;
  final CharacterId character;
  final String text;
  final Mood mood;
  final double portraitSize;
  final Color bubbleColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showPortrait) ...[
          CharacterView(id: character, size: portraitSize, mood: mood),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: CustomPaint(
            painter: _BubblePainter(bubbleColor),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(character.displayName,
                      style: PQText.small.copyWith(color: character.color, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(text, style: PQText.bodyStrong.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                  if (trailing != null) ...[const SizedBox(height: 8), trailing!],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const tail = 10.0;
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(tail, 0, size.width - tail - 1.3, size.height - 1.3),
        const Radius.circular(18));
    final path = Path()..addRRect(r);
    final t = Path()
      ..moveTo(tail + 2, size.height - 30)
      ..lineTo(0, size.height - 12)
      ..lineTo(tail + 14, size.height - 16)
      ..close();
    final shape = Path.combine(PathOperation.union, path, t);
    canvas.drawPath(shape.shift(const Offset(0, 4)), Paint()..color = PQColors.ink.withValues(alpha: 0.18));
    canvas.drawPath(shape, Paint()..color = color);
    canvas.drawPath(
        shape,
        Paint()
          ..color = PQColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.color != color;
}

/// Wooden sign used for screen titles.
class TitlePlate extends StatelessWidget {
  const TitlePlate({super.key, required this.title, this.subtitle, this.tone = PQTone.wood});
  final String title;
  final String? subtitle;
  final PQTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(tone.face, Colors.white, 0.15)!, tone.face],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PQColors.ink, width: 2.6),
        boxShadow: [BoxShadow(color: tone.depth, offset: const Offset(0, 4), blurRadius: 0)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PQText.h3.copyWith(color: tone.text, fontSize: 20, height: 1.1)),
          if (subtitle != null)
            Text(subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PQText.small.copyWith(color: tone.text.withValues(alpha: 0.9), fontSize: 13)),
        ],
      ),
    );
  }
}

/// Standard top bar: back button, title plate, optional trailing widgets.
class PQTopBar extends StatelessWidget {
  const PQTopBar({super.key, required this.title, this.subtitle, this.onBack, this.trailing = const [], this.tone = PQTone.wood});
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> trailing;
  final PQTone tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          RoundIconButton(
            key: const ValueKey('back_button'),
            icon: Icons.arrow_back_rounded,
            tooltip: 'Quay lại',
            size: 48,
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          Expanded(child: Align(alignment: Alignment.centerLeft, child: TitlePlate(title: title, subtitle: subtitle, tone: tone))),
          for (final w in trailing) ...[const SizedBox(width: 8), w],
        ],
      ),
    );
  }
}

/// Soft themed background with gentle dotted pattern and corner leaves.
class PQBackground extends StatelessWidget {
  const PQBackground({super.key, required this.child, this.top = const Color(0xFFBFEAF5), this.bottom = PQColors.parchment, this.pattern = true});
  final Widget child;
  final Color top;
  final Color bottom;
  final bool pattern;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]),
      ),
      child: pattern ? CustomPaint(painter: _DotsPainter(Color.lerp(top, PQColors.ink, 0.12)!), child: child) : child,
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.35);
    const step = 34.0;
    for (var y = 12.0; y < size.height; y += step) {
      final row = (y / step).floor();
      for (var x = (row.isEven ? 10.0 : 27.0); x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 2.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.color != color;
}

/// Chunky horizontal progress bar.
class ChunkyProgress extends StatelessWidget {
  const ChunkyProgress({super.key, required this.value, this.color = PQColors.grass, this.height = 16});
  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: PQColors.parchmentDeep,
        borderRadius: BorderRadius.circular(height),
        border: Border.all(color: PQColors.ink, width: 2.2),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final v = value.clamp(0.0, 1.0);
        return Align(
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            width: math.max(0, c.maxWidth * v),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(height),
            ),
          ),
        );
      }),
    );
  }
}

/// Bottom sheet frame with a title and a parchment body.
Future<T?> showPQSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: PQColors.ink.withValues(alpha: 0.45),
    builder: (ctx) {
      final media = MediaQuery.of(ctx);
      return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
          child: Container(
            decoration: BoxDecoration(
              color: PQColors.parchment,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: PQColors.ink, width: 2.6),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 54,
                    height: 6,
                    decoration: BoxDecoration(color: PQColors.parchmentEdge, borderRadius: BorderRadius.circular(3)),
                  ),
                  Flexible(child: builder(ctx)),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
