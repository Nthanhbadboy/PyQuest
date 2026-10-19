import 'package:flutter/material.dart';

import '../../app/activity.dart';
import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../data/repositories/state_repositories.dart';
import '../../shared/characters/characters.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/palette.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/game_icons.dart';
import '../../shared/widgets/transitions.dart';
import '../catch_stars/catch_stars_module.dart';
import '../catch_stars/stars_game.dart';
import '../dragon_jump/dragon_jump_module.dart';
import '../main_quest/adventure_recap_screen.dart';
import '../robot_maze/maze_models.dart';
import '../robot_maze/maze_play_screen.dart';
import 'achievement_catalog.dart';

class AchievementHouseModule extends ActivityModule {
  @override
  final ActivityDef def = const ActivityDef(
    id: 'achievement_house',
    name: 'Nhà Thành Tích',
    tagline: 'Nơi cất giữ huy hiệu và kỷ niệm',
    description: 'Ngôi nhà ghi lại hành trình của bạn: tủ huy hiệu, tường chiến tích, bộ sưu tập và góc sáng tạo.',
    host: CharacterId.robo,
    hitBox: Rect.fromLTRB(0.404, 0.618, 0.664, 0.785),
    labelAnchor: Offset(0.534, 0.795),
    thumbnail: 'assets/images/thumb_house.webp',
    tone: PQTone.sun,
    needsPython: false,
  );

  @override
  Future<ActivityStatus> status(AppServices services) async {
    final unlocked = services.achievements.unlocked.length;
    return ActivityStatus(
      progressLabel: '$unlocked/${achievementCatalog.length} huy hiệu',
      detailLines: [
        if (services.achievements.unseenCount > 0) 'Có ${services.achievements.unseenCount} huy hiệu mới chưa xem!',
        'Huy hiệu bí mật: ${achievementCatalog.where((a) => a.secret).length} cái đang ẩn mình.',
      ],
    );
  }

  @override
  Widget buildHome(BuildContext context) => const AchievementHouseScreen();
}

class _HouseData {
  _HouseData({
    required this.snapshot,
    required this.levelsByGame,
    required this.lessons,
    required this.totalStars,
    required this.dragonOwned,
    required this.starsTotal,
    required this.stamps,
    required this.creations,
  });
  final ProgressSnapshot snapshot;
  final Map<String, int> levelsByGame;
  final int lessons;
  final int totalStars;
  final List<String> dragonOwned;
  final int starsTotal;
  final int stamps;
  final List<CustomLevel> creations;

  int get totalLevels => levelsByGame.values.fold(0, (a, b) => a + b);
}

class AchievementHouseScreen extends StatefulWidget {
  const AchievementHouseScreen({super.key});

  @override
  State<AchievementHouseScreen> createState() => _AchievementHouseScreenState();
}

class _AchievementHouseScreenState extends State<AchievementHouseScreen> {
  _HouseData? _data;
  int _room = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_data == null) _load();
  }

  Future<void> _load() async {
    final s = AppScope.of(context);
    final snap = await s.achievements.snapshot();
    final data = _HouseData(
      snapshot: snap,
      levelsByGame: snap.completedLevels,
      lessons: snap.completedLessons.length,
      totalStars: await s.progress.totalStars(),
      dragonOwned: await s.store.getList(kDragonGameId, 'owned'),
      starsTotal: await s.store.getInt(kStarsGameId, 'atlas_total'),
      stamps: s.quests.totalStamps,
      creations: (await s.customLevels.list(RobotMazeContent.gameId)).where((c) => c.verified).toList(),
    );
    await s.achievements.markAllSeen();
    if (mounted) setState(() => _data = data);
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final rooms = [
      ('Tủ huy hiệu', Icons.military_tech_rounded, true, ''),
      ('Tường chiến tích', Icons.emoji_events_rounded, true, ''),
      ('Bộ sưu tập', Icons.collections_rounded, true, ''),
      ('Góc sáng tạo', Icons.construction_rounded, true, ''),
    ];
    return Scaffold(
      body: PQBackground(
        top: const Color(0xFFFFE3B3),
        bottom: const Color(0xFFFFF6E6),
        child: SafeArea(
          child: Column(
            children: [
              PQTopBar(
                title: 'Nhà Thành Tích',
                subtitle:
                    '${AppScope.of(context).achievements.unlocked.length}/${achievementCatalog.length} huy hiệu',
                tone: PQTone.sun,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                child: Container(
                  key: const ValueKey('achievement_25d_scene'),
                  height: 184,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4298B5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF5C3D1E), width: 2.8),
                    boxShadow: [
                      BoxShadow(
                        color: PQTone.sun.depth,
                        offset: const Offset(0, 5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        switch (_room) {
                          0 => 'assets/images/achievement_cutaway_r35.webp',
                          1 => 'assets/images/achievement_room_r39.webp',
                          2 => 'assets/images/interior_room_r34.webp',
                          _ => 'assets/images/study_corner_r35.webp',
                        },
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.05),
                        gaplessPlayback: true,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.05),
                              Colors.black.withValues(alpha: 0.58),
                            ],
                          ),
                        ),
                      ),
                      // 3D Glowing Badge Orbs sitting on the pedestals in Room 0 (r39 style)
                      if (_room == 0) ...[
                        Positioned(
                          left: 112,
                          top: 86,
                          child: _PedestalOrb(
                            icon: Icons.directions_walk_rounded,
                            color: PQColors.grass,
                          ),
                        ),
                        Positioned(
                          left: 162,
                          top: 66,
                          child: _PedestalOrb(
                            icon: Icons.code_rounded,
                            color: PQColors.pyYellow,
                          ),
                        ),
                        Positioned(
                          left: 214,
                          top: 86,
                          child: _PedestalOrb(
                            icon: Icons.emoji_events_rounded,
                            color: PQColors.coral,
                          ),
                        ),
                      ],
                      Positioned(
                        left: 12,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xEBFFF8E7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF6B4C2B),
                              width: 1.6,
                            ),
                          ),
                          child: Text(
                            '🏛️ ${rooms[_room].$1} 2.5D',
                            style: PQText.small.copyWith(
                              color: const Color(0xFF4A3219),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 4,
                        child: Image.asset(
                          'assets/images/robo_token_r50.png',
                          width: 78,
                          height: 78,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 96,
                        bottom: 10,
                        child: Text(
                          'Chạm vào từng huy hiệu để xem câu chuyện và cách mở khóa nhé!',
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
              ),
              SizedBox(
                height: 54,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  children: [
                    for (var i = 0; i < rooms.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          key: ValueKey('room_$i'),
                          onTap: () => setState(() => _room = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: _room == i ? PQColors.sun : PQColors.cream,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: PQColors.ink,
                                width: _room == i ? 2.8 : 2,
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                children: [
                                  Icon(
                                    rooms[i].$3
                                        ? rooms[i].$2
                                        : Icons.lock_rounded,
                                    size: 20,
                                    color: PQColors.ink,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    rooms[i].$1,
                                    style: PQText.label.copyWith(fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: d == null
                    ? const Center(child: CharacterView(id: CharacterId.robo, size: 100))
                    : (!rooms[_room].$3
                        ? _LockedRoom(text: rooms[_room].$4)
                        : switch (_room) {
                            0 => _BadgeCabinet(snapshot: d.snapshot),
                            1 => _TrophyWall(data: d),
                            2 => _Collection(data: d),
                            _ => _CreatorCorner(creations: d.creations),
                          }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedRoom extends StatelessWidget {
  const _LockedRoom({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GameIcon(GameIconKind.lock, size: 72),
            const SizedBox(height: 10),
            Text(
              'Căn phòng này đang khoá',
              textAlign: TextAlign.center,
              style: PQText.h2,
            ),
            const SizedBox(height: 6),
            Text(text, textAlign: TextAlign.center, style: PQText.body),
          ],
        ),
      ),
    );
  }
}

class _BadgeCabinet extends StatelessWidget {
  const _BadgeCabinet({required this.snapshot});
  final ProgressSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final unlocked = AppScope.of(context).achievements.unlocked;
    final bigText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 520 ? 4 : (bigText ? 2 : 3);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: bigText ? 0.56 : 0.68,
          ),
          itemCount: achievementCatalog.length,
        itemBuilder: (context, i) {
          final a = achievementCatalog[i];
          final got = unlocked.containsKey(a.id);
          return GestureDetector(
            key: ValueKey('badge_${a.id}'),
            onTap: () => _showBadge(context, a, got),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: got
                      ? const [Color(0xFFFFFAEB), Color(0xFFFFE599)]
                      : const [Color(0xFFF3ECE0), Color(0xFFE3D8C4)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: got ? const Color(0xFF9A6B16) : const Color(0xFF7B6B53),
                  width: got ? 2.8 : 2.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: got ? const Color(0xFF8C5A14) : const Color(0xFF8A7960),
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: FittedBox(child: BadgeMedal(icon: a.icon, color: a.color, locked: !got, secret: a.secret, size: 80)),
                    ),
                  ),
                  Text(
                    got || !a.secret ? a.title : '???',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: PQText.small.copyWith(fontSize: 12.5, color: got ? PQColors.ink : PQColors.inkFaint),
                  ),
                  if (!got && a.goal != null && a.progress != null) ...[
                    const SizedBox(height: 4),
                    ChunkyProgress(value: a.progress!(snapshot) / a.goal!, color: a.color, height: 9),
                  ],
                ],
              ),
            ),
          );
        },
      );
    });
  }

  void _showBadge(BuildContext context, AchievementDef a, bool got) {
    final date = AppScope.of(context).achievements.unlocked[a.id];
    showPQSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BadgeMedal(icon: a.icon, color: a.color, locked: !got, secret: a.secret, size: 120),
            const SizedBox(height: 6),
            Text(got || !a.secret ? a.title : 'Huy hiệu bí mật', style: PQText.h2),
            const SizedBox(height: 6),
            Text(got ? a.description : a.howTo, textAlign: TextAlign.center, style: PQText.body),
            if (got && date != null) ...[
              const SizedBox(height: 6),
              Text('Nhận ngày ${date.day}/${date.month}/${date.year}', style: PQText.small),
            ],
            if (!got && a.goal != null && a.progress != null) ...[
              const SizedBox(height: 10),
              Text('Tiến độ: ${a.progress!(snapshot).clamp(0, a.goal!)}/${a.goal}', style: PQText.bodyStrong),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrophyWall extends StatelessWidget {
  const _TrophyWall({required this.data});
  final _HouseData data;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final snap = data.snapshot;
    final rows = <(String, String, Widget)>[
      ('Màn chơi đã vượt', '${data.totalLevels}', const GameIcon(GameIconKind.trophy, size: 30)),
      ('Tổng số sao', '${data.totalStars}', const StarIcon(size: 30)),
      ('Bài học Python', '${data.lessons}/${s.mainQuest.lessons.length}', const Icon(Icons.school_rounded, color: PQColors.pyBlue, size: 30)),
      ('Mê cung Robo', '${snap.levels('robot_maze')}/${s.robotMaze.levels.length}', const Icon(Icons.route_rounded, color: PQColors.teal, size: 30)),
      ('Bọ lỗi đã bắt', '${snap.claims('bug:')}/${s.bugHunter.totalBugs}', const Icon(Icons.bug_report_rounded, color: PQColors.grape, size: 30)),
      ('Kỷ lục Rồng Nhảy', '${snap.bestScores['dragon_jump/run'] ?? 0}', const GameIcon(GameIconKind.coin, size: 30)),
      ('Kỷ lục Hái Sao', '${snap.bestScores['catch_stars/run'] ?? 0}', const Icon(Icons.auto_awesome_rounded, color: PQColors.sunDeep, size: 30)),
      ('Tem nhiệm vụ', '${data.stamps}', const GameIcon(GameIconKind.stamp, size: 30)),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PQPanel(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  SizedBox(width: 36, child: Center(child: r.$3)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(r.$1, style: PQText.bodyStrong)),
                  Text(r.$2, style: PQText.number),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        ChunkyButton(
          label: 'Hành trình Tháp Python',
          icon: Icons.auto_stories_rounded,
          tone: PQTone.py,
          expand: true,
          onPressed: () => Navigator.of(context).push(CloudRoute<void>(builder: (_) => const AdventureRecapScreen())),
        ),
      ],
    );
  }
}

class _Collection extends StatelessWidget {
  const _Collection({required this.data});
  final _HouseData data;

  @override
  Widget build(BuildContext context) {
    final hats = dragonItems.where((i) => i.isHat).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text('Mũ của Pip', style: PQText.h3),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final h in hats)
              Container(
                width: 96,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: data.dragonOwned.contains(h.id) ? PQColors.cream : const Color(0xFFF1EADC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PQColors.ink, width: 2),
                ),
                child: Column(
                  children: [
                    Opacity(
                      opacity: data.dragonOwned.contains(h.id) ? 1 : 0.25,
                      child: CharacterView(id: CharacterId.pip, size: 70, hat: h.id, animate: false),
                    ),
                    Text(data.dragonOwned.contains(h.id) ? h.name : '???',
                        textAlign: TextAlign.center, style: PQText.small.copyWith(fontSize: 12.5)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Chòm sao đã thắp sáng', style: PQText.h3),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in constellations)
              Column(
                children: [
                  ConstellationCard(c: c, lit: data.starsTotal >= c.threshold, size: 96),
                  SizedBox(
                    width: 96,
                    child: Text(data.starsTotal >= c.threshold ? c.name : '???',
                        textAlign: TextAlign.center, style: PQText.small.copyWith(fontSize: 12.5)),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _CreatorCorner extends StatelessWidget {
  const _CreatorCorner({required this.creations});
  final List<CustomLevel> creations;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const SpeechBubble(
          character: CharacterId.robo,
          text: 'Đây là những mê cung chính bạn thiết kế và đã chứng minh là giải được. Thật tuyệt vời!',
          portraitSize: 64,
        ),
        const SizedBox(height: 10),
        for (final c in creations)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PQPanel(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 78,
                    height: 78,
                    child: _MiniMaze(rows: (c.data['rows'] as List).cast<String>()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: PQText.h3.copyWith(fontSize: 18)),
                        Text('Giới hạn 3 sao: ${c.data['command_limit']} lệnh', style: PQText.small),
                      ],
                    ),
                  ),
                  ChunkyButton(
                    label: 'Chơi',
                    size: ChunkySize.small,
                    tone: PQTone.grass,
                    onPressed: () => Navigator.of(context).push(CloudRoute<void>(
                      builder: (_) => MazePlayScreen(level: MazeLevel.fromCustomJson(c.id, c.data), customId: c.id),
                    )),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniMaze extends StatelessWidget {
  const _MiniMaze({required this.rows});
  final List<String> rows;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _MiniMazePainter(rows));
}

class _MiniMazePainter extends CustomPainter {
  _MiniMazePainter(this.rows);
  final List<String> rows;

  @override
  void paint(Canvas canvas, Size size) {
    final h = rows.length;
    final w = rows.first.length;
    final cell = size.width / (w > h ? w : h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final ch = rows[y][x];
        final color = switch (ch) {
          '#' => const Color(0xFF3E8F35),
          '~' => PQColors.sea,
          'S' => PQColors.teal,
          'C' => PQColors.wood,
          '*' => PQColors.sky,
          _ => const Color(0xFFA4DE6F),
        };
        canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), Paint()..color = color);
      }
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, w * cell, h * cell), Paint()
      ..color = PQColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_MiniMazePainter old) => old.rows != rows;
}

class _PedestalOrb extends StatelessWidget {
  const _PedestalOrb({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: PQColors.ink, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.65),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, size: 18, color: PQColors.ink),
    );
  }
}

