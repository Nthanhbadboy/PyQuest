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
import '../../shared/widgets/reward_toast.dart';
import '../../shared/widgets/transitions.dart';
import '../energy/energy_widgets.dart';
import 'dragon_game.dart';

const String kDragonGameId = 'dragon_jump';

class DragonItem {
  const DragonItem(this.id, this.name, this.description, this.price, {this.isHat = false, this.icon});
  final String id;
  final String name;
  final String description;
  final int price;
  final bool isHat;
  final IconData? icon;
}

const List<DragonItem> dragonItems = [
  DragonItem('heart', 'Trái tim thứ tư', 'Bắt đầu mỗi lượt với 4 trái tim.', 120, icon: Icons.favorite_rounded),
  DragonItem('magnet', 'Nam châm vàng', 'Hút những đồng xu ở gần về phía Pip.', 150, icon: Icons.attractions_rounded),
  DragonItem('wings', 'Đôi cánh lớn', 'Pip nhảy được 3 lần liên tiếp trên không.', 200, icon: Icons.air_rounded),
  DragonItem('party', 'Mũ tiệc', 'Một chiếc mũ vui nhộn cho Pip.', 60, isHat: true),
  DragonItem('scarf', 'Khăn quàng', 'Khăn bay phấp phới khi chạy.', 80, isHat: true),
  DragonItem('goggles', 'Kính phi công', 'Sẵn sàng cho những cú bay cao.', 100, isHat: true),
  DragonItem('wizard', 'Mũ phù thuỷ', 'Rồng phép thuật của đảo.', 150, isHat: true),
  DragonItem('crown', 'Vương miện', 'Dành cho nhà vô địch Núi Lửa.', 250, isHat: true),
];

class DragonLoadout {
  const DragonLoadout({required this.coins, required this.owned, required this.hat});
  final int coins;
  final List<String> owned;
  final String? hat;

  static Future<DragonLoadout> load(AppServices s) async {
    final hat = await s.store.getString(kDragonGameId, 'hat');
    return DragonLoadout(
      coins: await s.store.getInt(kDragonGameId, 'coins'),
      owned: await s.store.getList(kDragonGameId, 'owned'),
      hat: (hat == null || hat.isEmpty) ? null : hat,
    );
  }
}

class DragonJumpModule extends ActivityModule {
  @override
  final ActivityDef def = const ActivityDef(
    id: kDragonGameId,
    name: 'Núi Lửa Pip',
    tagline: 'Mini-game · Rồng Nhảy',
    description: 'Pip mê sưu tầm xu vàng! Chạm để nhảy qua đá và bụi gai, chạm thêm lần nữa để bay cao hơn.',
    host: CharacterId.pip,
    hitBox: Rect.fromLTRB(0.61, 0.24, 0.925, 0.407),
    labelAnchor: Offset(0.768, 0.41),
    thumbnail: 'assets/images/thumb_volcano.webp',
    tone: PQTone.coral,
    needsPython: false,
  );

  @override
  Future<ActivityStatus> status(AppServices services) async {
    final record = await services.progress.levelRecord(kDragonGameId, 'run');
    final coins = await services.store.getInt(kDragonGameId, 'coins');
    final runs = await services.store.getInt(kDragonGameId, 'runs');
    return ActivityStatus(
      progressLabel: record == null ? (runs == 0 ? 'Chưa chơi' : 'Chưa có sao') : 'Kỷ lục ${record.highScore}',
      stars: record?.stars,
      recommended: false,
      detailLines: ['Xu của Pip: $coins', 'Số lượt đã chơi: $runs'],
    );
  }

  @override
  Widget buildHome(BuildContext context) => const DragonHomeScreen();
}

class DragonHomeScreen extends StatefulWidget {
  const DragonHomeScreen({super.key});

  @override
  State<DragonHomeScreen> createState() => _DragonHomeScreenState();
}

class _DragonHomeScreenState extends State<DragonHomeScreen> {
  DragonLoadout? _loadout;
  int _best = 0;
  int _stars = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadout == null) _load();
  }

  Future<void> _load() async {
    final s = AppScope.of(context);
    final l = await DragonLoadout.load(s);
    final r = await s.progress.levelRecord(kDragonGameId, 'run');
    if (!mounted) return;
    setState(() {
      _loadout = l;
      _best = r?.highScore ?? 0;
      _stars = r?.stars ?? 0;
    });
  }

  Future<void> _play() async {
    final s = AppScope.of(context);
    if (!await spendEnergy(context, s.config.cost('arcade_run'))) return;
    if (!mounted) return;
    await Navigator.of(context).push(CloudRoute<void>(
      builder: (_) => DragonPlayScreen(loadout: _loadout!),
      calm: s.settings.calmMode,
    ));
    if (mounted) await _load();
  }

  Future<void> _openShop() async {
    await showPQSheet<void>(context, builder: (ctx) => DragonShop(onChanged: _load));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final l = _loadout;
    final thresholds = s.config.gameIntList(kDragonGameId, 'star_scores', const [150, 300, 500]);
    return Scaffold(
      body: PQBackground(
        top: const Color(0xFFFFD2B8),
        bottom: const Color(0xFFFFF1DE),
        child: SafeArea(
          child: Column(
            children: [
              PQTopBar(title: 'Núi Lửa Pip', subtitle: 'Rồng Nhảy', tone: PQTone.coral, trailing: const [EnergyPill(compact: true)]),
              Expanded(
                child: l == null
                    ? const SizedBox()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          Container(
                            key: const ValueKey('dragon_25d_scene'),
                            height: 206,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: const Color(0xFF47332D),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: PQColors.ink,
                                width: 2.6,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: PQTone.coral.depth,
                                  offset: const Offset(0, 5),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  'assets/images/volcano_trail_r54.webp',
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
                                  left: 16,
                                  bottom: 14,
                                  child: Image.asset(
                                    'assets/images/basalt_token_r54.png',
                                    width: 68,
                                    height: 60,
                                    fit: BoxFit.contain,
                                    gaplessPlayback: true,
                                  ),
                                ),
                                Positioned(
                                  right: 18,
                                  top: 22,
                                  child: Image.asset(
                                    'assets/images/beetle_token_r54.png',
                                    width: 64,
                                    height: 46,
                                    fit: BoxFit.contain,
                                    gaplessPlayback: true,
                                  ),
                                ),
                                Align(
                                  alignment: const Alignment(0, 0.25),
                                  child: l.hat != null
                                      ? CharacterView(
                                          id: CharacterId.pip,
                                          size: 164,
                                          hat: l.hat,
                                        )
                                      : Image.asset(
                                          'assets/images/pip_token_r54.png',
                                          height: 156,
                                          fit: BoxFit.contain,
                                          gaplessPlayback: true,
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const SpeechBubble(
                            character: CharacterId.pip,
                            text: 'Chạm màn hình để nhảy, chạm thêm lần nữa khi đang bay để vỗ cánh! Né đá, bụi gai và bọ cánh cứng nhé.',
                            showPortrait: false,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _InfoTile(icon: const GameIcon(GameIconKind.trophy, size: 30), label: 'Kỷ lục', value: '$_best')),
                              const SizedBox(width: 8),
                              Expanded(child: _InfoTile(icon: const GameIcon(GameIconKind.coin, size: 30), label: 'Xu của Pip', value: '${l.coins}')),
                              const SizedBox(width: 8),
                              Expanded(child: _InfoTile(icon: const StarIcon(size: 28), label: 'Sao', value: '$_stars/3')),
                            ],
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
                                        Expanded(child: Text('Đạt ${thresholds[i]} điểm trong một lượt', style: PQText.bodyStrong.copyWith(fontSize: 15.5))),
                                        Icon(_best >= thresholds[i] ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                            color: _best >= thresholds[i] ? PQColors.success : PQColors.inkFaint),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text('Điểm = quãng đường (m) + 3 × số xu', style: PQText.small.copyWith(fontSize: 13)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ChunkyButton(
                            key: const ValueKey('dragon_play'),
                            label: 'Bay thôi!',
                            icon: Icons.play_arrow_rounded,
                            tone: PQTone.coral,
                            expand: true,
                            trailing: EnergyCostChip(cost: s.config.cost('arcade_run')),
                            onPressed: _play,
                          ),
                          const SizedBox(height: 10),
                          ChunkyButton(
                            key: const ValueKey('dragon_shop'),
                            label: 'Tổ Rồng (cửa hàng xu)',
                            icon: Icons.storefront_rounded,
                            tone: PQTone.sun,
                            expand: true,
                            onPressed: _openShop,
                          ),
                          const SizedBox(height: 8),
                          Text('Xu chỉ kiếm được bằng cách chơi và chỉ dùng trong Núi Lửa Pip. Không có mua bằng tiền thật.',
                              textAlign: TextAlign.center, style: PQText.small.copyWith(fontSize: 13)),
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});
  final Widget icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return PQPanel(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        children: [
          icon,
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

/// Pip's nest: spend coins earned in Dragon Jump on upgrades and hats.
class DragonShop extends StatefulWidget {
  const DragonShop({super.key, required this.onChanged});
  final VoidCallback onChanged;

  @override
  State<DragonShop> createState() => _DragonShopState();
}

class _DragonShopState extends State<DragonShop> {
  DragonLoadout? _l;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_l == null) _reload();
  }

  Future<void> _reload() async {
    final l = await DragonLoadout.load(AppScope.of(context));
    if (mounted) setState(() => _l = l);
  }

  Future<void> _buy(DragonItem item) async {
    final s = AppScope.of(context);
    final l = _l!;
    if (l.coins < item.price) {
      s.audio.play(Sfx.bonk);
      return;
    }
    await s.store.addInt(kDragonGameId, 'coins', -item.price);
    await s.store.setList(kDragonGameId, 'owned', [...l.owned, item.id]);
    if (item.isHat) await s.store.setString(kDragonGameId, 'hat', item.id);
    final outcome = await s.events.emit(StandardEvent(type: EventTypes.itemCollected, sourceId: kDragonGameId, data: {'item_id': item.id}));
    s.audio.play(Sfx.coin);
    await _reload();
    widget.onChanged();
    if (mounted && outcome.notices.isNotEmpty) showRewardToasts(context, outcome.notices);
  }

  Future<void> _equip(DragonItem item) async {
    final s = AppScope.of(context);
    final current = _l!.hat;
    await s.store.setString(kDragonGameId, 'hat', current == item.id ? '' : item.id);
    s.audio.play(Sfx.pop);
    await _reload();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l = _l;
    if (l == null) return const SizedBox(height: 200);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Tổ Rồng', style: PQText.h2)),
              const GameIcon(GameIconKind.coin, size: 28),
              const SizedBox(width: 4),
              Text('${l.coins}', key: const ValueKey('shop_coins'), style: PQText.number),
            ],
          ),
          Text('Nâng cấp giúp Pip bay xa hơn, mũ giúp Pip thật phong cách!', style: PQText.body.copyWith(fontSize: 15)),
          const SizedBox(height: 12),
          for (final item in dragonItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PQPanel(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: item.isHat
                          ? CharacterView(id: CharacterId.pip, size: 64, hat: item.id, animate: false)
                          : Container(
                              decoration: BoxDecoration(
                                color: PQColors.coral,
                                shape: BoxShape.circle,
                                border: Border.all(color: PQColors.ink, width: 2.4),
                              ),
                              child: Icon(item.icon, color: Colors.white, size: 32),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: PQText.bodyStrong),
                          Text(item.description, style: PQText.small.copyWith(fontSize: 13.5)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (!l.owned.contains(item.id))
                      ChunkyButton(
                        key: ValueKey('buy_${item.id}'),
                        label: '${item.price}',
                        size: ChunkySize.small,
                        tone: l.coins >= item.price ? PQTone.sun : PQTone.disabled,
                        trailing: const GameIcon(GameIconKind.coin, size: 18),
                        onPressed: l.coins >= item.price ? () => _buy(item) : null,
                      )
                    else if (item.isHat)
                      ChunkyButton(
                        key: ValueKey('equip_${item.id}'),
                        label: l.hat == item.id ? 'Đang đội' : 'Đội',
                        size: ChunkySize.small,
                        tone: l.hat == item.id ? PQTone.success : PQTone.parchment,
                        onPressed: () => _equip(item),
                      )
                    else
                      const PillTag(label: 'Đã có', color: PQColors.success),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The running game.
class DragonPlayScreen extends StatefulWidget {
  const DragonPlayScreen({super.key, required this.loadout, this.seed = 0});
  final DragonLoadout loadout;
  final int seed;

  @override
  State<DragonPlayScreen> createState() => _DragonPlayScreenState();
}

class _DragonPlayScreenState extends State<DragonPlayScreen> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  DragonGame? _game;
  Duration _last = Duration.zero;
  bool _paused = false;
  bool _finished = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_game != null) return;
    final s = AppScope.of(context);
    final c = s.config;
    final owned = widget.loadout.owned;
    _game = DragonGame(
      startSpeed: c.gameDouble(kDragonGameId, 'start_speed', 250),
      maxSpeed: c.gameDouble(kDragonGameId, 'max_speed', 540),
      speedGain: c.gameDouble(kDragonGameId, 'speed_gain_per_sec', 5),
      maxHearts: c.gameInt(kDragonGameId, 'hearts', 3) + (owned.contains('heart') ? 1 : 0),
      maxJumps: owned.contains('wings') ? 3 : 2,
      magnet: owned.contains('magnet'),
      hat: widget.loadout.hat,
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
    // Auto-pause while a dialog (e.g. a break reminder) covers the game.
    if (_paused || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
    g.update(dt);
    if (g.events.isNotEmpty) {
      final audio = AppScope.of(context).audio;
      for (final e in g.events) {
        switch (e) {
          case 'jump':
            audio.play(Sfx.jump, volume: 0.8);
          case 'flap':
            audio.play(Sfx.whoosh, volume: 0.6);
          case 'coin':
            audio.play(Sfx.coin, volume: 0.7);
          case 'gem':
            audio.play(Sfx.sparkle);
          case 'hit':
            audio.play(Sfx.hit);
            HapticFeedback.mediumImpact();
          case 'over':
            audio.play(Sfx.fail);
        }
      }
      g.events.clear();
    }
    if (g.phase == DragonPhase.over && g.overT > 1.3 && !_finished) {
      _finished = true;
      _finish();
    }
  }

  Future<void> _finish() async {
    final s = AppScope.of(context);
    final g = _game!;
    _ticker.stop();
    final thresholds = s.config.gameIntList(kDragonGameId, 'star_scores', const [150, 300, 500]);
    final score = g.score;
    final stars = thresholds.where((t) => score >= t).length;
    await s.store.addInt(kDragonGameId, 'coins', g.coins);
    await s.store.addInt(kDragonGameId, 'runs', 1);
    final notices = <RewardNotice>[];
    var best = score;
    var newBest = false;
    if (stars > 0) {
      final outcome = await s.events.emit(StandardEvent(
        type: EventTypes.levelCompleted,
        sourceId: kDragonGameId,
        data: {'level_id': 'run', 'stars': stars, 'score': score},
      ));
      notices.addAll(outcome.notices);
      best = outcome.bestScore;
      newBest = outcome.newHighScore || outcome.firstCompletion;
    } else {
      final r = await s.progress.levelRecord(kDragonGameId, 'run');
      best = r?.highScore ?? score;
    }
    if (!mounted) return;
    final cost = s.config.cost('arcade_run');
    final action = await showLevelResult(
      context,
      LevelResultData(
        gameName: 'Rồng Nhảy',
        levelTitle: 'Núi Lửa Pip',
        success: stars > 0,
        stars: stars,
        score: score,
        bestScore: best,
        newBest: newBest && stars > 0,
        goals: [for (var i = 0; i < thresholds.length; i++) ResultGoal('Đạt ${thresholds[i]} điểm', score >= thresholds[i])],
        stats: [
          ResultStat('Quãng đường', '${g.distanceMeters} m'),
          ResultStat('Xu nhặt được', '${g.coins}', icon: GameIconKind.coin),
          if (g.gems > 0) ResultStat('Đá quý', '${g.gems}', icon: GameIconKind.gem),
        ],
        skill: 'Sự kiện và trạng thái: mỗi lần chạm là một sự kiện làm thay đổi trạng thái của Pip.',
        host: CharacterId.pip,
        hostLine: stars >= 3
            ? 'Woa! Bạn bay như một nhà vô địch! Xu đã được cất vào Tổ Rồng.'
            : (stars > 0
                ? 'Bay hay lắm! Xu đã được cất vào Tổ Rồng — ghé xem cửa hàng nhé.'
                : 'Lần này chưa có sao, nhưng xu vẫn được giữ lại! Thử nhảy sớm hơn một chút nhé.'),
        notices: notices,
        primaryLabel: 'Chơi lại',
        primaryCost: cost,
        tone: PQTone.coral,
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
        final loadout = await DragonLoadout.load(s);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => DragonPlayScreen(loadout: loadout)));
      case ResultAction.replay:
      case ResultAction.back:
        Navigator.of(context).pop();
      case ResultAction.map:
        Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    final audio = AppScope.of(context).audio;
    audio.music(_paused ? MusicTrack.calm : MusicTrack.arcade);
  }

  @override
  Widget build(BuildContext context) {
    final g = _game!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_paused && g.phase == DragonPhase.running) _togglePause();
        if (!didPop && (g.phase != DragonPhase.running)) Navigator.of(context).pop();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                key: const ValueKey('dragon_tap_area'),
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) {
                  if (!_paused) g.jump();
                },
                child: CustomPaint(painter: DragonPainter(g)),
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
                  builder: (context, _) => Row(
                    children: [
                      for (var i = 0; i < g.maxHearts; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: GameIcon(GameIconKind.heart, size: 30, dimmed: i >= g.hearts),
                        ),
                      const Spacer(),
                      _HudPill(child: Text('${g.score}', key: const ValueKey('dragon_score'), style: PQText.number)),
                      const SizedBox(width: 6),
                      _HudPill(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const GameIcon(GameIconKind.coin, size: 22),
                            const SizedBox(width: 4),
                            Text('${g.coins}', style: PQText.number.copyWith(fontSize: 19)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      RoundIconButton(
                        key: const ValueKey('dragon_pause'),
                        icon: _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        size: 44,
                        tooltip: 'Tạm dừng',
                        onPressed: g.phase == DragonPhase.running ? _togglePause : null,
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
              builder: (context, _) => g.phase == DragonPhase.ready
                  ? IgnorePointer(
                      child: Align(
                        alignment: const Alignment(0, -0.35),
                        child: PQPanel(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Chạm để nhảy!', style: PQText.h2),
                              Text('Chạm thêm khi đang bay để vỗ cánh', style: PQText.small),
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
                right: 16,
                bottom: 16,
                child: SafeArea(
                  top: false,
                  child: AnimatedBuilder(
                    animation: g,
                    builder: (context, _) => g.phase == DragonPhase.over
                        ? const SizedBox.shrink()
                        : ChunkyButton(
                            key: const ValueKey('dragon_jump_btn'),
                            label: g.onGround ? 'Nhảy' : 'Vỗ cánh',
                            icon: Icons.keyboard_double_arrow_up_rounded,
                            tone: PQTone.coral,
                            size: ChunkySize.medium,
                            onPressed: g.jump,
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
                            const CharacterView(id: CharacterId.pip, size: 110, mood: Mood.neutral),
                            Text('Tạm dừng', style: PQText.h2),
                            const SizedBox(height: 12),
                            ChunkyButton(label: 'Bay tiếp', icon: Icons.play_arrow_rounded, tone: PQTone.coral, expand: true, onPressed: _togglePause),
                            const SizedBox(height: 10),
                            ChunkyButton(
                              label: 'Thoát lượt chơi',
                              tone: PQTone.parchment,
                              expand: true,
                              onPressed: () {
                                setState(() => _paused = false);
                                g.hearts = 0;
                                g.phase = DragonPhase.over;
                                g.overT = 1.3;
                              },
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

class _HudPill extends StatelessWidget {
  const _HudPill({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: PQColors.cream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PQColors.ink, width: 2.4),
      ),
      child: child,
    );
  }
}
