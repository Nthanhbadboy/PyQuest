import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../app/activity.dart';
import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../core/audio_service.dart';
import '../../core/events.dart';
import '../../shared/characters/characters.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/palette.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/game_icons.dart';
import '../../shared/widgets/result_screen.dart';
import '../../shared/widgets/transitions.dart';
import '../energy/energy_widgets.dart';
import 'stars_game.dart';

const String kStarsGameId = 'catch_stars';

class CatchStarsModule extends ActivityModule {
  @override
  final ActivityDef def = const ActivityDef(
    id: kStarsGameId,
    name: 'Đài Thiên Văn',
    tagline: 'Mini-game · Hái Sao',
    description: 'Đêm nay sao rơi đầy trời! Kéo chiếc bình sao để hứng thật nhiều sao, nhưng nhớ né thiên thạch nhé.',
    host: CharacterId.robo,
    hitBox: Rect.fromLTRB(0.625, 0.45, 0.86, 0.574),
    labelAnchor: Offset(0.735, 0.585),
    thumbnail: 'assets/images/thumb_observatory.webp',
    tone: PQTone.night,
    needsPython: false,
  );

  @override
  Future<ActivityStatus> status(AppServices services) async {
    final record = await services.progress.levelRecord(kStarsGameId, 'run');
    final total = await services.store.getInt(kStarsGameId, 'atlas_total');
    final lit = constellations.where((c) => total >= c.threshold).length;
    return ActivityStatus(
      progressLabel: record == null ? 'Chưa có sao' : 'Kỷ lục ${record.highScore}',
      stars: record?.stars,
      detailLines: ['Tổng số sao đã hái: $total', 'Chòm sao đã thắp sáng: $lit/${constellations.length}'],
    );
  }

  @override
  Widget buildHome(BuildContext context) => const CatchStarsHomeScreen();
}

class CatchStarsHomeScreen extends StatefulWidget {
  const CatchStarsHomeScreen({super.key});

  @override
  State<CatchStarsHomeScreen> createState() => _CatchStarsHomeScreenState();
}

class _CatchStarsHomeScreenState extends State<CatchStarsHomeScreen> {
  int _total = 0;
  int _best = 0;
  int _stars = 0;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) _load();
  }

  Future<void> _load() async {
    final s = AppScope.of(context);
    final total = await s.store.getInt(kStarsGameId, 'atlas_total');
    final r = await s.progress.levelRecord(kStarsGameId, 'run');
    if (!mounted) return;
    setState(() {
      _loaded = true;
      _total = total;
      _best = r?.highScore ?? 0;
      _stars = r?.stars ?? 0;
    });
  }

  Future<void> _play() async {
    final s = AppScope.of(context);
    if (!await spendEnergy(context, s.config.cost('arcade_run'))) return;
    if (!mounted) return;
    await Navigator.of(context).push(CloudRoute<void>(builder: (_) => const StarsPlayScreen(), calm: s.settings.calmMode));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final next = constellations.where((c) => _total < c.threshold).firstOrNull;
    final thresholds = s.config.gameIntList(kStarsGameId, 'star_scores', const [60, 150, 300]);
    return Scaffold(
      body: PQBackground(
        top: const Color(0xFF2A2F7A),
        bottom: const Color(0xFF5B4B9A),
        pattern: false,
        child: SafeArea(
          child: Column(
            children: [
              PQTopBar(title: 'Đài Thiên Văn', subtitle: 'Hái Sao', tone: PQTone.night, trailing: const [EnergyPill(compact: true)]),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Container(
                      key: const ValueKey('stars_25d_scene'),
                      height: 196,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: const Color(0xFF151A4C),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: PQColors.ink, width: 2.6),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF151A4C),
                            offset: Offset(0, 5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/observatory_sky_r55.webp',
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.06),
                                  Colors.black.withValues(alpha: 0.42),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 22,
                            top: 20,
                            child: Image.asset(
                              'assets/images/star_token_r55.png',
                              width: 54,
                              height: 54,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                            ),
                          ),
                          Positioned(
                            right: 22,
                            top: 18,
                            child: Image.asset(
                              'assets/images/meteor_token_r55.png',
                              width: 52,
                              height: 52,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                            ),
                          ),
                          Positioned(
                            right: 34,
                            bottom: 8,
                            child: Image.asset(
                              'assets/images/robo_token_r50.png',
                              width: 78,
                              height: 78,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                            ),
                          ),
                          Align(
                            alignment: const Alignment(-0.1, 0.25),
                            child: Image.asset(
                              'assets/images/jar_token_r55.png',
                              height: 140,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SpeechBubble(
                      character: CharacterId.robo,
                      text: 'Kéo chiếc bình sang trái, sang phải để hứng sao. Sao vàng to +5, sao chổi +3, sao cầu vồng nhân đôi điểm. Né thiên thạch nhé!',
                      portraitSize: 70,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _Tile(label: 'Kỷ lục', value: '$_best')),
                        const SizedBox(width: 8),
                        Expanded(child: _Tile(label: 'Sao đã hái', value: '$_total')),
                        const SizedBox(width: 8),
                        Expanded(child: _Tile(label: 'Hạng sao', value: '$_stars/3')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PQPanel(
                      color: const Color(0xFF232867),
                      borderColor: PQColors.ink,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Bản đồ chòm sao', style: PQText.h3.copyWith(color: Colors.white)),
                          Text(
                            next == null
                                ? 'Bạn đã thắp sáng mọi chòm sao!'
                                : 'Hái thêm ${next.threshold - _total} sao để thắp sáng ${next.name}.',
                            style: PQText.small.copyWith(color: const Color(0xFFD6D9FF)),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 92,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                for (final c in constellations)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ConstellationCard(c: c, lit: _total >= c.threshold, size: 86),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ChunkyButton(
                            key: const ValueKey('open_atlas'),
                            label: 'Xem bản đồ sao',
                            icon: Icons.auto_awesome_rounded,
                            tone: PQTone.grape,
                            size: ChunkySize.medium,
                            expand: true,
                            onPressed: () => Navigator.of(context).push(
                              CloudRoute<void>(builder: (_) => StarAtlasScreen(total: _total), calm: s.settings.calmMode),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    PQPanel(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      child: Column(
                        children: [
                          for (var i = 0; i < thresholds.length; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  StarRow(stars: i + 1, max: i + 1, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text('Đạt ${thresholds[i]} điểm trong một đêm', style: PQText.bodyStrong.copyWith(fontSize: 15.5))),
                                  Icon(_best >= thresholds[i] ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                      color: _best >= thresholds[i] ? PQColors.success : PQColors.inkFaint),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ChunkyButton(
                      key: const ValueKey('stars_play'),
                      label: 'Bắt đầu hái sao',
                      icon: Icons.play_arrow_rounded,
                      tone: PQTone.sun,
                      expand: true,
                      trailing: EnergyCostChip(cost: s.config.cost('arcade_run'), light: false),
                      onPressed: _play,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return PQPanel(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        children: [
          Text(value, textAlign: TextAlign.center, style: PQText.number),
          Text(
            label,
            textAlign: TextAlign.center,
            style: PQText.small.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class ConstellationCard extends StatelessWidget {
  const ConstellationCard({super.key, required this.c, required this.lit, this.size = 120});
  final Constellation c;
  final bool lit;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF151A4C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lit ? PQColors.sun : const Color(0xFF3B4180), width: 2.4),
      ),
      child: CustomPaint(painter: _ConstellationPainter(c, lit)),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  _ConstellationPainter(this.c, this.lit);
  final Constellation c;
  final bool lit;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = [for (final p in c.points) Offset(p.dx * size.width, p.dy * size.height)];
    final line = Paint()
      ..color = lit ? PQColors.sun.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.8;
    for (final (a, b) in c.lines) {
      canvas.drawLine(pts[a], pts[b], line);
    }
    for (final p in pts) {
      if (lit) canvas.drawCircle(p, size.width * 0.06, Paint()..color = PQColors.sun.withValues(alpha: 0.25));
      canvas.drawCircle(p, size.width * 0.028, Paint()..color = lit ? Colors.white : Colors.white.withValues(alpha: 0.3));
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter old) => old.lit != lit || old.c != c;
}

class StarAtlasScreen extends StatelessWidget {
  const StarAtlasScreen({super.key, required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PQBackground(
        top: const Color(0xFF151A4C),
        bottom: const Color(0xFF3A2F7A),
        pattern: false,
        child: SafeArea(
          child: Column(
            children: [
              PQTopBar(title: 'Bản đồ chòm sao', subtitle: '$total sao đã hái', tone: PQTone.night),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                  children: [
                    for (final c in constellations)
                      Column(
                        children: [
                          AspectRatio(aspectRatio: 1, child: ConstellationCard(c: c, lit: total >= c.threshold, size: double.infinity)),
                          const SizedBox(height: 6),
                          Text(c.name, style: PQText.h3.copyWith(color: total >= c.threshold ? PQColors.sun : Colors.white70, fontSize: 17)),
                          Text(
                            total >= c.threshold ? c.story : 'Cần ${c.threshold} sao (còn ${c.threshold - total})',
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: PQText.small.copyWith(color: const Color(0xFFD6D9FF), fontSize: 12.5),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StarsPlayScreen extends StatefulWidget {
  const StarsPlayScreen({super.key, this.seed = 0});
  final int seed;

  @override
  State<StarsPlayScreen> createState() => _StarsPlayScreenState();
}

class _StarsPlayScreenState extends State<StarsPlayScreen> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  StarsGame? _game;
  Duration _last = Duration.zero;
  bool _finished = false;
  bool _paused = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_game != null) return;
    final s = AppScope.of(context);
    _game = StarsGame(
      roundSeconds: s.config.gameDouble(kStarsGameId, 'round_seconds', 45),
      maxHearts: s.config.gameInt(kStarsGameId, 'hearts', 3),
      seed: widget.seed,
    );
    s.audio.music(MusicTrack.arcade);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _game?.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final g = _game!;
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (_paused || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
    g.update(dt);
    if (g.events.isNotEmpty) {
      final audio = AppScope.of(context).audio;
      for (final e in g.events) {
        switch (e) {
          case 'catch':
            audio.play(Sfx.sparkle, volume: 0.7);
          case 'bonus':
          case 'rainbow':
            audio.play(Sfx.star);
          case 'hit':
            audio.play(Sfx.hit);
            HapticFeedback.mediumImpact();
          case 'miss':
            break;
          case 'over':
            audio.play(Sfx.whoosh);
        }
      }
      g.events.clear();
    }
    if (g.over && !_finished) {
      _finished = true;
      Future<void>.delayed(const Duration(milliseconds: 900), _finish);
    }
  }

  Future<void> _finish() async {
    if (!mounted) return;
    final s = AppScope.of(context);
    final g = _game!;
    _ticker.stop();
    final thresholds = s.config.gameIntList(kStarsGameId, 'star_scores', const [60, 150, 300]);
    final stars = thresholds.where((t) => g.score >= t).length;
    final before = await s.store.getInt(kStarsGameId, 'atlas_total');
    final after = await s.store.addInt(kStarsGameId, 'atlas_total', g.caught);
    final bestCaught = await s.store.getInt(kStarsGameId, 'best_caught');
    if (g.caught > bestCaught) await s.store.setInt(kStarsGameId, 'best_caught', g.caught);
    final notices = <RewardNotice>[];
    for (final c in constellations) {
      if (before < c.threshold && after >= c.threshold) {
        final o = await s.events.emit(StandardEvent(type: EventTypes.itemCollected, sourceId: kStarsGameId, data: {'item_id': 'const:${c.id}'}));
        notices.add(RewardNotice(kind: RewardKind.item, id: c.id, title: 'Chòm sao mới: ${c.name}', description: c.story));
        notices.addAll(o.notices);
      }
    }
    var best = g.score;
    var newBest = false;
    if (stars > 0) {
      final outcome = await s.events.emit(StandardEvent(
        type: EventTypes.levelCompleted,
        sourceId: kStarsGameId,
        data: {'level_id': 'run', 'stars': stars, 'score': g.score, 'caught': g.caught},
      ));
      notices.addAll(outcome.notices);
      best = outcome.bestScore;
      newBest = outcome.newHighScore || outcome.firstCompletion;
    } else {
      final r = await s.progress.levelRecord(kStarsGameId, 'run');
      best = math.max(best, r?.highScore ?? 0);
    }
    if (!mounted) return;
    final cost = s.config.cost('arcade_run');
    final action = await showLevelResult(
      context,
      LevelResultData(
        gameName: 'Hái Sao',
        levelTitle: 'Đài Thiên Văn',
        success: stars > 0,
        stars: stars,
        score: g.score,
        bestScore: best,
        newBest: newBest && stars > 0,
        goals: [for (var i = 0; i < thresholds.length; i++) ResultGoal('Đạt ${thresholds[i]} điểm', g.score >= thresholds[i])],
        stats: [
          ResultStat('Sao đã hái', '${g.caught}'),
          ResultStat('Chuỗi dài nhất', '${g.bestCombo}'),
          ResultStat('Tổng sao', '$after'),
        ],
        skill: 'Vòng lặp trò chơi: mỗi khung hình, máy tính cập nhật vị trí, kiểm tra va chạm rồi vẽ lại.',
        host: CharacterId.robo,
        hostLine: stars > 0
            ? 'Đẹp quá! Những ngôi sao bạn hái được đã bay lên bản đồ chòm sao.'
            : 'Bầu trời hôm nay hơi khó! Thử đứng chờ ngay dưới ngôi sao rơi nhé.',
        notices: notices,
        primaryLabel: 'Chơi lại',
        primaryCost: cost,
        tone: PQTone.night,
      ),
    );
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    switch (action) {
      case ResultAction.primary:
        if (!await spendEnergy(context, cost)) {
          if (mounted) Navigator.of(context).pop();
          return;
        }
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const StarsPlayScreen()));
      case ResultAction.replay:
      case ResultAction.back:
        Navigator.of(context).pop();
      case ResultAction.map:
        Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = _game!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (g.started && !g.over) {
          setState(() => _paused = !_paused);
        } else if (!g.started) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                key: const ValueKey('stars_area'),
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (d) => g.nudge(d.delta.dx),
                onTapDown: (d) => g.moveTo(d.localPosition.dx),
                child: CustomPaint(painter: StarsPainter(g)),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: AnimatedBuilder(
                  animation: g,
                  builder: (context, _) => Column(
                    children: [
                      Row(
                        children: [
                          for (var i = 0; i < g.maxHearts; i++)
                            Padding(padding: const EdgeInsets.only(right: 2), child: GameIcon(GameIconKind.heart, size: 28, dimmed: i >= g.hearts)),
                          const Spacer(),
                          _Pill(child: Text('${g.score}', key: const ValueKey('stars_score'), style: PQText.number)),
                          const SizedBox(width: 6),
                          _Pill(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_rounded, size: 20, color: PQColors.ink),
                                const SizedBox(width: 2),
                                Text('${g.timeLeft.ceil()}', style: PQText.number.copyWith(fontSize: 19)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          RoundIconButton(
                            icon: _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                            size: 42,
                            tooltip: 'Tạm dừng',
                            onPressed: g.started && !g.over ? () => setState(() => _paused = !_paused) : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ChunkyProgress(value: g.timeLeft / g.roundSeconds, color: PQColors.sun, height: 12),
                      if (g.multiplier > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: PillTag(label: 'Nhân ×${g.multiplier}', color: g.rainbow > 0 ? PQColors.berry : PQColors.grape),
                        ),
                    ],
                  ),
                ),
              ),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
              animation: g,
              builder: (context, _) => !g.started
                  ? IgnorePointer(
                      child: Align(
                        alignment: const Alignment(0, -0.2),
                        child: PQPanel(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Chạm hoặc kéo để bắt đầu!', style: PQText.h3),
                              Text('Đưa bình sao tới chỗ ngôi sao rơi', style: PQText.small),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            ),
            if (!_paused)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SafeArea(
                  top: false,
                  child: AnimatedBuilder(
                    animation: g,
                    builder: (context, _) => g.over
                        ? const SizedBox.shrink()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              RoundIconButton(
                                key: const ValueKey('stars_move_left'),
                                icon: Icons.chevron_left_rounded,
                                size: 48,
                                tooltip: 'Sang trái',
                                onPressed: () => g.nudge(-44),
                              ),
                              RoundIconButton(
                                key: const ValueKey('stars_move_right'),
                                icon: Icons.chevron_right_rounded,
                                size: 48,
                                tooltip: 'Sang phải',
                                onPressed: () => g.nudge(44),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            if (_paused)
              Positioned.fill(
                child: ColoredBox(
                  color: PQColors.ink.withValues(alpha: 0.5),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: PQPanel(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Tạm dừng', style: PQText.h2),
                            const SizedBox(height: 12),
                            ChunkyButton(label: 'Chơi tiếp', tone: PQTone.sun, expand: true, onPressed: () => setState(() => _paused = false)),
                            const SizedBox(height: 10),
                            ChunkyButton(
                              label: 'Kết thúc đêm nay',
                              tone: PQTone.parchment,
                              expand: true,
                              onPressed: () => setState(() {
                                _paused = false;
                                g.time = g.roundSeconds;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: PQColors.cream, borderRadius: BorderRadius.circular(18), border: Border.all(color: PQColors.ink, width: 2.4)),
      child: child,
    );
  }
}
