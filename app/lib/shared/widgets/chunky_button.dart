import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../core/audio_service.dart';
import '../theme/app_theme.dart';
import '../theme/palette.dart';

enum ChunkySize { large, medium, small }

/// Signature PyQuest button: thick ink outline, glossy face and a darker
/// "depth" edge that squashes when pressed.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = PQTone.sun,
    this.size = ChunkySize.large,
    this.trailing,
    this.expand = false,
    this.sfx = Sfx.tap,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PQTone tone;
  final ChunkySize size;
  final Widget? trailing;
  final bool expand;
  final Sfx? sfx;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _pressed = false;

  double get _height => switch (widget.size) {
        ChunkySize.large => 58,
        ChunkySize.medium => 50,
        ChunkySize.small => 44,
      };

  double get _depth => switch (widget.size) {
        ChunkySize.large => 6,
        ChunkySize.medium => 5,
        ChunkySize.small => 4,
      };

  double get _fontSize => switch (widget.size) {
        ChunkySize.large => 22,
        ChunkySize.medium => 19,
        ChunkySize.small => 17,
      };

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final tone = enabled ? widget.tone : PQTone.disabled;
    final pressed = _pressed && enabled;
    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: tone.text, size: _fontSize + 6),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: PQText.button.copyWith(fontSize: _fontSize, color: tone.text),
          ),
        ),
        if (widget.trailing != null) ...[const SizedBox(width: 10), widget.trailing!],
      ],
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: () => _setPressed(false),
        onTap: enabled
            ? () {
                final sfx = widget.sfx;
                if (sfx != null) AppScope.maybeOf(context)?.audio.play(sfx);
                HapticFeedback.selectionClick();
                widget.onPressed!();
              }
            : null,
        child: CustomPaint(
          painter: ChunkyPainter(tone: tone, pressed: pressed, depth: _depth, radius: 18),
          child: Padding(
            padding: EdgeInsets.only(top: pressed ? _depth : 0, bottom: pressed ? 0 : _depth),
            child: SizedBox(
              height: _height,
              width: widget.expand ? double.infinity : null,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: switch (widget.size) { ChunkySize.large => 22, ChunkySize.medium => 14, ChunkySize.small => 12 },
                ),
                child: Center(widthFactor: 1, child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round icon button (back, close, settings...).
class RoundIconButton extends StatefulWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tone = PQTone.parchment,
    this.size = 52,
    this.tooltip,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final PQTone tone;
  final double size;
  final String? tooltip;
  final int? badge;

  @override
  State<RoundIconButton> createState() => _RoundIconButtonState();
}

class _RoundIconButtonState extends State<RoundIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final tone = enabled ? widget.tone : PQTone.disabled;
    final depth = widget.size * 0.09;
    final pressed = _pressed && enabled;
    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTap: enabled
          ? () {
              AppScope.maybeOf(context)?.audio.play(Sfx.tap);
              HapticFeedback.selectionClick();
              widget.onPressed!();
            }
          : null,
      child: CustomPaint(
        painter: ChunkyPainter(tone: tone, pressed: pressed, depth: depth, radius: widget.size / 2),
        child: Padding(
          padding: EdgeInsets.only(top: pressed ? depth : 0, bottom: pressed ? 0 : depth),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Icon(widget.icon, color: tone.text, size: widget.size * 0.52),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      label: widget.tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          if ((widget.badge ?? 0) > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: PQColors.danger,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PQColors.ink, width: 2),
                ),
                alignment: Alignment.center,
                child: Text('${widget.badge}',
                    style: PQText.small.copyWith(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
              ),
            ),
        ],
      ),
    );
  }
}

class ChunkyPainter extends CustomPainter {
  ChunkyPainter({required this.tone, required this.pressed, required this.depth, required this.radius});

  final PQTone tone;
  final bool pressed;
  final double depth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 2.6;
    final h = size.height - depth;
    final r = Radius.circular(radius.clamp(0, h / 2).toDouble());
    final depthRect = RRect.fromRectAndRadius(Rect.fromLTWH(1.3, depth + 1.3, size.width - 2.6, h - 2.6), r);
    final faceTop = pressed ? depth : 0.0;
    final faceRect = RRect.fromRectAndRadius(Rect.fromLTWH(1.3, faceTop + 1.3, size.width - 2.6, h - 2.6), r);
    final outline = Paint()
      ..color = PQColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    if (!pressed) {
      canvas.drawRRect(depthRect, Paint()..color = tone.depth);
      canvas.drawRRect(depthRect, outline);
    }
    final faceRectBounds = faceRect.outerRect;
    canvas.drawRRect(
      faceRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(tone.face, Colors.white, 0.18)!, tone.face],
        ).createShader(faceRectBounds),
    );
    // Soft gloss stripe near the top.
    final gloss = RRect.fromRectAndRadius(
      Rect.fromLTWH(faceRectBounds.left + 8, faceRectBounds.top + 4, faceRectBounds.width - 16, (h - 2.6) * 0.28),
      Radius.circular(radius),
    );
    canvas.drawRRect(gloss, Paint()..color = Colors.white.withValues(alpha: 0.22));
    canvas.drawRRect(faceRect, outline);
  }

  @override
  bool shouldRepaint(ChunkyPainter old) =>
      old.tone != tone || old.pressed != pressed || old.depth != depth || old.radius != radius;
}

/// Round chunky button with arbitrary content (level nodes, big picks...).
class ChunkyCircleButton extends StatefulWidget {
  const ChunkyCircleButton({super.key, required this.child, required this.onPressed, this.tone = PQTone.sun, this.size = 72, this.semanticLabel});
  final Widget child;
  final VoidCallback? onPressed;
  final PQTone tone;
  final double size;
  final String? semanticLabel;

  @override
  State<ChunkyCircleButton> createState() => _ChunkyCircleButtonState();
}

class _ChunkyCircleButtonState extends State<ChunkyCircleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final depth = widget.size * 0.08;
    final pressed = _pressed && enabled;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: enabled
            ? () {
                AppScope.maybeOf(context)?.audio.play(Sfx.tap);
                HapticFeedback.selectionClick();
                widget.onPressed!();
              }
            : null,
        child: CustomPaint(
          painter: ChunkyPainter(tone: widget.tone, pressed: pressed, depth: depth, radius: widget.size / 2),
          child: Padding(
            padding: EdgeInsets.only(top: pressed ? depth : 0, bottom: pressed ? 0 : depth),
            child: SizedBox(width: widget.size, height: widget.size, child: Center(child: widget.child)),
          ),
        ),
      ),
    );
  }
}
