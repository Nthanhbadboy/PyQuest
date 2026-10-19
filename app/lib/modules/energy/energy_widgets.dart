import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/audio_service.dart';
import '../../shared/characters/characters.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/palette.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/game_icons.dart';

String formatCountdown(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

String formatLongDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h == 0) return '$m phút';
  if (m == 0) return '$h giờ';
  return '$h giờ $m phút';
}

/// Rebuilds once per second (for countdowns).
class SecondTicker extends StatefulWidget {
  const SecondTicker({super.key, required this.builder});
  final WidgetBuilder builder;

  @override
  State<SecondTicker> createState() => _SecondTickerState();
}

class _SecondTickerState extends State<SecondTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// HUD pill: ⚡ 12/20 and the time until the next unit.
class EnergyPill extends StatelessWidget {
  const EnergyPill({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final energy = AppScope.of(context).energy;
    return GestureDetector(
      key: const ValueKey('energy_pill'),
      onTap: () => showEnergySheet(context),
      child: ListenableBuilder(
        listenable: energy,
        builder: (context, _) => Container(
          padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
          decoration: BoxDecoration(
            color: PQColors.cream,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: PQColors.ink, width: 2.4),
            boxShadow: [BoxShadow(color: PQColors.ink.withValues(alpha: 0.2), offset: const Offset(0, 3), blurRadius: 0)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GameIcon(GameIconKind.energy, size: 30),
              const SizedBox(width: 4),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${energy.current}/${energy.max}', style: PQText.number.copyWith(fontSize: 19)),
                  if (!compact && !energy.isFull)
                    SecondTicker(
                      builder: (context) => Text(
                        '+1 sau ${formatCountdown(energy.timeToNext ?? Duration.zero)}',
                        style: PQText.small.copyWith(fontSize: 11.5, height: 1.0),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showEnergySheet(BuildContext context) {
  return showPQSheet<void>(context, builder: (ctx) => const _EnergySheet());
}

class _EnergySheet extends StatelessWidget {
  const _EnergySheet();

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final energy = services.energy;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: ListenableBuilder(
        listenable: energy,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              key: const ValueKey('energy_25d_scene'),
              height: 118,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF2D6E7E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: PQColors.ink, width: 2.4),
                boxShadow: [
                  BoxShadow(
                    color: PQTone.sea.depth,
                    offset: const Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/rest_nook_r38.webp',
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.48),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 4,
                    child: Image.asset(
                      'assets/images/robo_token_r50.png',
                      width: 68,
                      height: 68,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 84,
                    bottom: 8,
                    child: Text(
                      'Góc nghỉ ngơi 2.5D · Hồi phục năng lượng tự nhiên',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: PQText.small.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const GameIcon(GameIconKind.energy, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Năng lượng ${energy.current}/${energy.max}', style: PQText.h2),
                      SecondTicker(
                        builder: (context) => Text(
                          energy.isFull
                              ? 'Đầy rồi! Đi khám phá thôi.'
                              : 'Hồi 1 sau ${formatCountdown(energy.timeToNext ?? Duration.zero)} · đầy sau ${formatLongDuration(energy.timeToFull ?? Duration.zero)}',
                          style: PQText.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ChunkyProgress(value: energy.current / energy.max, color: PQColors.energy, height: 20),
            const SizedBox(height: 16),
            const _CostTable(),
            const SizedBox(height: 14),
            PQPanel(
              color: const Color(0xFFE9F8EC),
              child: Text(
                'Luôn miễn phí: bản đồ, ôn lại bài đã học, Nhà Thành Tích, Xưởng Mê Cung và Sân tập code. '
                'Năng lượng tự hồi kể cả khi bạn tắt ứng dụng. Không có quảng cáo hay mua bán.',
                style: PQText.body.copyWith(fontSize: 15.5),
              ),
            ),
            const SizedBox(height: 16),
            ChunkyButton(
              label: 'Nghỉ mắt 20 giây',
              icon: Icons.visibility_rounded,
              tone: PQTone.sea,
              expand: true,
              onPressed: () {
                Navigator.of(context).pop();
                showEyeBreak(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CostTable extends StatelessWidget {
  const _CostTable();

  @override
  Widget build(BuildContext context) {
    final config = AppScope.of(context).config;
    Widget row(String label, int cost) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(child: Text(label, style: PQText.bodyStrong.copyWith(fontSize: 15.5))),
              if (cost == 0)
                const PillTag(label: 'Miễn phí', color: PQColors.success)
              else ...[
                Text('$cost', style: PQText.number.copyWith(fontSize: 18)),
                const SizedBox(width: 2),
                const GameIcon(GameIconKind.energy, size: 20),
              ],
            ],
          ),
        );
    return PQPanel(
      child: Column(
        children: [
          row('Màn mới trong mini-game', config.cost('mini_game_new_level')),
          row('Một lượt Rồng Nhảy / Hái Sao', config.cost('arcade_run')),
          row('Bài học mới của Main Quest', config.cost('main_quest_lesson_first')),
          row('Thử thách cuối chặng (lần đầu)', config.cost('chapter_challenge_first')),
          row('Chơi lại màn đã thắng, ôn bài cũ', config.cost('main_quest_review')),
          row('Xưởng sáng tạo', config.cost('creator_mode')),
        ],
      ),
    );
  }
}

/// Tries to spend [cost] energy; explains kindly (no purchase prompts) when
/// there is not enough. Returns true when the activity may start.
Future<bool> spendEnergy(BuildContext context, int cost) async {
  if (cost <= 0) return true;
  final energy = AppScope.of(context).energy;
  if (await energy.spend(cost)) return true;
  if (context.mounted) await showOutOfEnergy(context, cost);
  return false;
}

Future<void> showOutOfEnergy(BuildContext context, int cost) {
  AppScope.of(context).audio.play(Sfx.pop);
  return showPQSheet<void>(context, builder: (ctx) => _OutOfEnergy(cost: cost));
}

class _OutOfEnergy extends StatelessWidget {
  const _OutOfEnergy({required this.cost});
  final int cost;

  @override
  Widget build(BuildContext context) {
    final energy = AppScope.of(context).energy;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SpeechBubble(
            character: CharacterId.robo,
            mood: Mood.neutral,
            text: 'Hoạt động này cần $cost năng lượng, bạn đang có ${energy.current}. '
                'Mình cùng nghỉ một chút nhé — năng lượng sẽ tự hồi!',
          ),
          const SizedBox(height: 12),
          SecondTicker(
            builder: (context) {
              final need = cost - energy.current;
              final next = energy.timeToNext ?? Duration.zero;
              final wait = need <= 1 ? next : next + energy.regenInterval * (need - 1);
              return PQPanel(
                child: Row(
                  children: [
                    const GameIcon(GameIconKind.energy, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Đủ năng lượng sau khoảng ${formatLongDuration(wait + const Duration(seconds: 59))}.',
                          style: PQText.bodyStrong),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text('Trong lúc chờ, bạn vẫn có thể:', style: PQText.h3),
          const SizedBox(height: 6),
          for (final idea in const [
            'Thiết kế mê cung trong Xưởng Mê Cung',
            'Ôn lại các bài đã học ở Tháp Python',
            'Viết code tự do ở Sân tập code',
            'Ngắm huy hiệu trong Nhà Thành Tích',
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: PQColors.success, size: 22),
                  const SizedBox(width: 8),
                  Expanded(child: Text(idea, style: PQText.body)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          ChunkyButton(
            label: 'Nghỉ mắt 20 giây',
            icon: Icons.visibility_rounded,
            tone: PQTone.sea,
            expand: true,
            onPressed: () {
              Navigator.of(context).pop();
              showEyeBreak(context);
            },
          ),
          const SizedBox(height: 10),
          ChunkyButton(
            label: 'Đã hiểu',
            tone: PQTone.parchment,
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// 20-20-20 eye break with Robo. Pure wellness: no rewards attached.
Future<void> showEyeBreak(BuildContext context) {
  final audio = AppScope.of(context).audio;
  audio.music(MusicTrack.calm);
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: PQColors.night.withValues(alpha: 0.75),
    builder: (ctx) => const _EyeBreakDialog(),
  ).whenComplete(() => audio.music(MusicTrack.island));
}

class _EyeBreakDialog extends StatefulWidget {
  const _EyeBreakDialog();

  @override
  State<_EyeBreakDialog> createState() => _EyeBreakDialogState();
}

class _EyeBreakDialogState extends State<_EyeBreakDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 20))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        AppScope.maybeOf(context)?.audio.play(Sfx.sparkle);
        setState(() {});
      }
    })
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: PQPanel(
        padding: const EdgeInsets.all(20),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final done = _c.isCompleted;
            final left = (20 - _c.value * 20).ceil();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(done ? 'Tuyệt vời!' : 'Nhìn ra xa nào!', style: PQText.h2),
                const SizedBox(height: 8),
                SizedBox(
                  width: 170,
                  height: 170,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CustomPaint(painter: _RingPainter(_c.value)),
                      ),
                      CharacterView(id: CharacterId.robo, size: 110, mood: done ? Mood.happy : Mood.neutral),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  done
                      ? 'Đôi mắt của bạn đã được nghỉ ngơi. Nhớ chớp mắt thường xuyên nhé!'
                      : 'Hãy nhìn một vật ở thật xa (cửa sổ, cái cây...) trong $left giây.',
                  textAlign: TextAlign.center,
                  style: PQText.bodyStrong,
                ),
                const SizedBox(height: 16),
                ChunkyButton(
                  label: done ? 'Xong rồi' : 'Dừng lại',
                  tone: done ? PQTone.grass : PQTone.parchment,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 8;
    canvas.drawCircle(c, r, Paint()
      ..color = PQColors.parchmentDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -1.5708,
      6.2832 * progress,
      false,
      Paint()
        ..color = PQColors.sea
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 12,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

/// Small "⚡ 2" chip shown on play buttons.
class EnergyCostChip extends StatelessWidget {
  const EnergyCostChip({super.key, required this.cost, this.light = true});
  final int cost;
  final bool light;

  @override
  Widget build(BuildContext context) {
    if (cost <= 0) {
      return Text('Miễn phí', style: PQText.small.copyWith(color: light ? Colors.white : PQColors.ink, fontWeight: FontWeight.w900));
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 2, 8, 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GameIcon(GameIconKind.energy, size: 20),
          Text('$cost', style: PQText.number.copyWith(fontSize: 17, color: light ? Colors.white : PQColors.ink)),
        ],
      ),
    );
  }
}
