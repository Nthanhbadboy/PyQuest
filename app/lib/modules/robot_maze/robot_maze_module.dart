import 'package:flutter/material.dart';

import '../../app/activity.dart';
import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../data/repositories/progress_repository.dart';
import '../../shared/characters/characters.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/palette.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/game_icons.dart';
import '../../shared/widgets/transitions.dart';
import '../energy/energy_widgets.dart';
import 'maze_models.dart';
import 'maze_play_screen.dart';
import 'maze_workshop_screen.dart';

class RobotMazeModule extends ActivityModule {
  @override
  final ActivityDef def = const ActivityDef(
    id: 'robot_maze',
    name: 'Mê Cung Robo',
    tagline: 'Mini-game · Xếp lệnh dẫn đường',
    description: 'Robo bị lạc giữa khu vườn bụi cây! Xếp các mũi tên thành chương trình để đưa Robo tới rương báu.',
    host: CharacterId.robo,
    hitBox: Rect.fromLTRB(0.117, 0.276, 0.443, 0.42),
    labelAnchor: Offset(0.28, 0.43),
    thumbnail: 'assets/images/thumb_maze.webp',
    tone: PQTone.grass,
    needsPython: false,
    hasCreatorMode: true,
  );

  @override
  Future<ActivityStatus> status(AppServices services) async {
    final total = services.robotMaze.levels.length;
    final done = await services.progress.completedLevelCount(gameId: RobotMazeContent.gameId);
    final stars = await services.progress.totalStars(gameId: RobotMazeContent.gameId);
    final creations = await services.customLevels.list(RobotMazeContent.gameId);
    return ActivityStatus(
      progressLabel: '$done/$total màn',
      stars: stars,
      recommended: done == 0,
      detailLines: [
        'Sao: $stars/${total * 3}',
        if (creations.isNotEmpty) 'Mê cung tự tạo: ${creations.length}',
      ],
    );
  }

  @override
  Widget buildHome(BuildContext context) => const RobotMazeHomeScreen();
}

class RobotMazeHomeScreen extends StatefulWidget {
  const RobotMazeHomeScreen({super.key});

  @override
  State<RobotMazeHomeScreen> createState() => _RobotMazeHomeScreenState();
}

class _RobotMazeHomeScreenState extends State<RobotMazeHomeScreen> {
  Map<String, LevelRecord> _records = {};
  AppServices? _services;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppScope.of(context);
    if (s != _services) {
      _services?.events.revision.removeListener(_load);
      _services = s;
      s.events.revision.addListener(_load);
      _load();
    }
  }

  @override
  void dispose() {
    _services?.events.revision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final r = await _services!.progress.levelRecords(RobotMazeContent.gameId);
    if (mounted) setState(() => _records = r);
  }

  bool _unlocked(List<MazeLevel> levels, int i) => i == 0 || _records.containsKey(levels[i - 1].id);

  Future<void> _openLevel(MazeLevel level) async {
    final s = AppScope.of(context);
    final completed = _records.containsKey(level.id);
    final cost = completed ? s.config.cost('mini_game_replay_completed') : s.config.cost('mini_game_new_level');
    if (!await spendEnergy(context, cost)) return;
    if (!mounted) return;
    await Navigator.of(context).push(CloudRoute<void>(builder: (_) => MazePlayScreen(level: level), calm: s.settings.calmMode));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final levels = s.robotMaze.levels;
    final stars = _records.values.fold<int>(0, (a, r) => a + r.stars);
    final firstOpen = List.generate(levels.length, (i) => i).firstWhere(
          (i) => _unlocked(levels, i) && !_records.containsKey(levels[i].id),
          orElse: () => -1,
        );
    return Scaffold(
      body: PQBackground(
        top: const Color(0xFFBDEBAE),
        bottom: const Color(0xFFF4F0D8),
        child: SafeArea(
          child: Column(
            children: [
              PQTopBar(
                title: 'Mê Cung Robo',
                subtitle: '${_records.length}/${levels.length} màn · $stars sao',
                tone: PQTone.grass,
                trailing: const [EnergyPill(compact: true)],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Container(
                      key: const ValueKey('maze_25d_scene'),
                      height: 176,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E6E37),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF5C3D1E), width: 2.8),
                        boxShadow: [
                          BoxShadow(
                            color: PQTone.grass.depth,
                            offset: const Offset(0, 5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/practice_arena_r35.webp',
                            fit: BoxFit.cover,
                            alignment: const Alignment(0, -0.15),
                            gaplessPlayback: true,
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.15),
                                  Colors.black.withValues(alpha: 0.68),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            top: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: PQColors.pyYellow,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: PQColors.ink, width: 1.6),
                              ),
                              child: Text(
                                '🌿 KHU VƯỜN MÊ CUNG 2.5D · ${levels.length} MÀN',
                                style: PQText.small.copyWith(
                                  color: PQColors.ink,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            bottom: 4,
                            child: Image.asset(
                              'assets/images/robo_token_r50.png',
                              width: 96,
                              height: 96,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                            ),
                          ),
                          Positioned(
                            left: 12,
                            right: 106,
                            bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xF2FFF8E7),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF6B4C2B),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                'Robo: Mỗi mũi tên là một lệnh. Xếp đúng thứ tự để dẫn đường qua vườn mê cung nhé!',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: PQText.small.copyWith(
                                  color: PQColors.ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, c) => _LevelPath(
                        width: c.maxWidth,
                        levels: levels,
                        records: _records,
                        isUnlocked: (i) => _unlocked(levels, i),
                        current: firstOpen,
                        onTap: _openLevel,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _WorkshopCard(
                      onOpen: () => Navigator.of(context).push(
                        CloudRoute<void>(builder: (_) => const MazeWorkshopScreen(), calm: s.settings.calmMode),
                      ),
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

class _LevelPath extends StatelessWidget {
  const _LevelPath({
    required this.width,
    required this.levels,
    required this.records,
    required this.isUnlocked,
    required this.current,
    required this.onTap,
  });

  final double width;
  final List<MazeLevel> levels;
  final Map<String, LevelRecord> records;
  final bool Function(int) isUnlocked;
  final int current;
  final ValueChanged<MazeLevel> onTap;

  static const double _rowH = 118;

  Offset _pos(int i) {
    final x = i.isEven ? width * 0.27 : width * 0.73;
    return Offset(x, 58 + i * _rowH * 0.78);
  }

  @override
  Widget build(BuildContext context) {
    final height = _pos(levels.length - 1).dy + 98;
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF4B7F42),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: PQColors.ink, width: 2.8),
        boxShadow: [
          BoxShadow(
            color: PQTone.grass.depth,
            offset: const Offset(0, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/maze_trail_r45.webp',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              gaplessPlayback: true,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF284D23).withValues(alpha: 0.22),
                    const Color(0xFF1D3B19).withValues(alpha: 0.34),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _PathPainter([for (var i = 0; i < levels.length; i++) _pos(i)]),
            ),
          ),
          for (var i = 0; i < levels.length; i++)
            Positioned(
              left: _pos(i).dx - 70,
              top: _pos(i).dy - 44,
              width: 140,
              child: _LevelNode(
                key: ValueKey('maze_level_${i + 1}'),
                index: i,
                level: levels[i],
                record: records[levels[i].id],
                unlocked: isUnlocked(i),
                current: i == current,
                onTap: () => onTap(levels[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  _PathPainter(this.points);
  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final mid = (a.dy + b.dy) / 2;
      path.cubicTo(a.dx, mid, b.dx, mid, b.dx, b.dy);
    }
    // 2.5D isometric stepping stones along the garden path (instead of a solid flat road)
    for (final metric in path.computeMetrics()) {
      for (var d = 16.0; d < metric.length - 16; d += 26) {
        final pos = metric.getTangentForOffset(d)?.position;
        if (pos == null) continue;
        final Rect stone = Rect.fromCenter(center: pos, width: 22, height: 12);
        canvas.drawOval(
          stone.shift(const Offset(0, 3)),
          Paint()..color = PQColors.ink.withValues(alpha: 0.35),
        );
        canvas.drawOval(
          stone,
          Paint()..color = const Color(0xFFEBD9B4),
        );
        canvas.drawOval(
          stone,
          Paint()
            ..color = const Color(0xFF6B533B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
      }
    }
    // 3D isometric stone pedestal base under each level node
    for (final pt in points) {
      final Rect rim = Rect.fromCenter(center: pt.translate(0, 26), width: 92, height: 28);
      final Rect top = Rect.fromCenter(center: pt.translate(0, 22), width: 88, height: 24);
      canvas.drawOval(rim.shift(const Offset(0, 4)), Paint()..color = PQColors.ink.withValues(alpha: 0.38));
      canvas.drawOval(rim, Paint()..color = const Color(0xFF9C8460));
      canvas.drawOval(
        rim,
        Paint()
          ..color = PQColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
      canvas.drawOval(top, Paint()..color = const Color(0xFFEADAB6));
      canvas.drawOval(
        top,
        Paint()
          ..color = PQColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.points != points;
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    super.key,
    required this.index,
    required this.level,
    required this.record,
    required this.unlocked,
    required this.current,
    required this.onTap,
  });

  final int index;
  final MazeLevel level;
  final LevelRecord? record;
  final bool unlocked;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = record != null;
    final tone = !unlocked ? PQTone.disabled : (done ? PQTone.grass : (current ? PQTone.sun : PQTone.sky));
    final node = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChunkyCircleButton(
          tone: tone,
          size: 70,
          semanticLabel: 'Màn ${index + 1}',
          onPressed: unlocked ? onTap : null,
          child: unlocked
              ? Text('${index + 1}', style: PQText.h1.copyWith(color: tone.text, fontSize: 30))
              : const GameIcon(GameIconKind.lock, size: 30),
        ),
        const SizedBox(height: 2),
        if (done) StarRow(stars: record!.stars, size: 20) else const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: unlocked ? const Color(0xF2FFF8E7) : const Color(0xD8EDE4D7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: PQColors.ink, width: 1.6),
          ),
          child: Text(
            level.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: PQText.small.copyWith(fontSize: 12.5, color: unlocked ? PQColors.ink : PQColors.inkFaint),
          ),
        ),
      ],
    );
    return current ? _Bounce(child: node) : node;
  }
}

class _Bounce extends StatefulWidget {
  const _Bounce({required this.child});
  final Widget child;

  @override
  State<_Bounce> createState() => _BounceState();
}

class _BounceState extends State<_Bounce> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calm = AppScope.of(context).settings.calmMode;
    if (calm) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(offset: Offset(0, -5 * Curves.easeInOut.transform(_c.value)), child: child),
      child: widget.child,
    );
  }
}

class _WorkshopCard extends StatelessWidget {
  const _WorkshopCard({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return PQPanel(
      color: const Color(0xFFEFE8FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: const ValueKey('maze_workshop_25d_banner'),
            height: 112,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF5D468E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PQColors.ink, width: 2.2),
            ),
            child: Image.asset(
              'assets/images/maze_workbench_r46.webp',
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const CharacterView(
                id: CharacterId.robo,
                size: 70,
                mood: Mood.thinking,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xưởng Mê Cung',
                      style: PQText.h2.copyWith(color: PQColors.grapeDeep),
                    ),
                    Text(
                      'Chế độ sáng tạo: tự vẽ mê cung, đặt luật chơi, rồi điều khiển Robo bằng khối lệnh hoặc code Python.',
                      style: PQText.body.copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ChunkyButton(
            key: const ValueKey('open_workshop'),
            label: 'Vào xưởng',
            icon: Icons.construction_rounded,
            tone: PQTone.grape,
            expand: true,
            trailing: const EnergyCostChip(cost: 0),
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}
