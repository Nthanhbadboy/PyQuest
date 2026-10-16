import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/activity.dart';
import '../../app/activity_registry.dart';
import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/settings_sheet.dart';
import '../../core/audio_service.dart';
import '../../core/events.dart';
import '../../shared/characters/characters.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/palette.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/game_icons.dart';
import '../../shared/widgets/reward_toast.dart';
import '../../shared/widgets/transitions.dart';
import '../daily_quests/daily_quests_sheet.dart';
import '../energy/energy_widgets.dart';
import '../main_quest/main_quest_module.dart';
import 'activity_sheet.dart';

const Size kMapImageSize = Size(1152, 2064);

/// The hub: a living island where every place opens its own activity.
/// It is not a game itself and has no global XP or level.
class MainMapScreen extends StatefulWidget {
  const MainMapScreen({super.key});

  @override
  State<MainMapScreen> createState() => _MainMapScreenState();
}

class _MainMapScreenState extends State<MainMapScreen> with TickerProviderStateMixin {
  late final AnimationController _ambient =
      AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
  Map<String, ActivityStatus> _status = {};
  bool _bubbleHidden = false;
  AppServices? _services;
  bool _introShown = false;
  Timer? _bubbleTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppScope.of(context);
    if (_services != s) {
      _services?.events.revision.removeListener(_refresh);
      _services?.session.removeListener(_onSession);
      _services = s;
      s.events.revision.addListener(_refresh);
      s.session.addListener(_onSession);
      _refresh();
      s.audio.music(MusicTrack.island);
      if (!s.settings.introSeen && !_introShown) {
        _introShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _showIntro());
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // The guide speaks for a while, then steps aside so the whole island is visible.
    _bubbleTimer = Timer(const Duration(seconds: 12), () {
      if (mounted) setState(() => _bubbleHidden = true);
    });
  }

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    _services?.events.revision.removeListener(_refresh);
    _services?.session.removeListener(_onSession);
    _ambient.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final s = _services;
    if (s == null) return;
    final result = <String, ActivityStatus>{};
    for (final m in activityRegistry) {
      result[m.def.id] = await m.status(s);
    }
    if (mounted) setState(() => _status = result);
  }

  void _onSession() {
    final s = _services;
    if (s == null || s.session.pendingReminder == null || !mounted) return;
    final minutes = s.session.pendingReminder!;
    s.session.consumeReminder();
    showBreakReminder(context, minutes);
  }

  Future<void> _showIntro() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: PQColors.ink.withValues(alpha: 0.55),
      builder: (ctx) => const _WelcomeDialog(),
    );
    await _services?.settings.setIntroSeen();
  }

  Future<void> _openSheet(ActivityModule module) async {
    final s = _services!;
    s.audio.play(Sfx.pop);
    final status = _status[module.def.id] ?? const ActivityStatus(progressLabel: '');
    final action = await showPQSheet<String>(context, builder: (ctx) => ActivitySheet(module: module, status: status));
    if (!mounted || action == null) return;
    if (action == 'open') {
      await openActivity(context, module);
    } else if (action.startsWith('lesson:')) {
      final main = activityById('main_quest');
      if (main is MainQuestModule) {
        await openActivity(context, main, lessonId: action.substring(7));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final calm = s.settings.calmMode;
    return Scaffold(
      backgroundColor: PQColors.sea,
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(builder: (context, constraints) {
              final dest = _coverRect(kMapImageSize, constraints.biggest);
              Offset toScreen(Offset n) => Offset(dest.left + n.dx * dest.width, dest.top + n.dy * dest.height);
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fromRect(
                    rect: dest,
                    child: const Image(
                      image: AssetImage('assets/images/island_map.webp'),
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.medium,
                      gaplessPlayback: true,
                    ),
                  ),
                  if (!calm)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _ambient,
                          builder: (context, _) => CustomPaint(painter: _CloudShadowPainter(_ambient.value)),
                        ),
                      ),
                    ),
                  for (final m in activityRegistry) ...[
                    Positioned.fromRect(
                      rect: Rect.fromPoints(toScreen(m.def.hitBox.topLeft), toScreen(m.def.hitBox.bottomRight)),
                      child: GestureDetector(
                        key: ValueKey('map_hit_${m.def.id}'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _openSheet(m),
                      ),
                    ),
                  ],
                  for (final m in activityRegistry)
                    _MapLabel(
                      key: ValueKey('map_label_${m.def.id}'),
                      anchor: toScreen(m.def.labelAnchor),
                      def: m.def,
                      status: _status[m.def.id],
                      ambient: _ambient,
                      calm: calm,
                      onTap: () => _openSheet(m),
                    ),
                ],
              );
            }),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  const Expanded(child: Align(alignment: Alignment.centerLeft, child: _IslandTitle())),
                  const SizedBox(width: 8),
                  EnergyPill(compact: MediaQuery.sizeOf(context).width < 380),
                  const SizedBox(width: 8),
                  ListenableBuilder(
                    listenable: s.quests,
                    builder: (context, _) => RoundIconButton(
                      key: const ValueKey('daily_quests_button'),
                      icon: Icons.assignment_turned_in_rounded,
                      tooltip: 'Nhiệm vụ hôm nay',
                      tone: PQTone.sun,
                      size: 44,
                      badge: s.quests.claimable,
                      onPressed: () => showDailyQuests(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  RoundIconButton(
                    key: const ValueKey('settings_button'),
                    icon: Icons.settings_rounded,
                    tooltip: 'Cài đặt',
                    size: 44,
                    onPressed: () => showSettingsSheet(context),
                  ),
                ],
              ),
            ),
            ),
          ),
          if (!_bubbleHidden)
            Positioned(
              left: 12,
              right: 12,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Dismissible(
                    key: const ValueKey('guide_bubble'),
                    direction: DismissDirection.down,
                    onDismissed: (_) => setState(() => _bubbleHidden = true),
                    child: GestureDetector(
                      onTap: () => setState(() => _bubbleHidden = true),
                      child: _GuideBubble(status: _status),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Opens an activity's home with the cloud transition and records the visit.
Future<void> openActivity(BuildContext context, ActivityModule module, {String? lessonId}) async {
  final s = AppScope.of(context);
  final outcome = await s.events.emit(StandardEvent(
    type: EventTypes.activityOpened,
    sourceId: 'main_map',
    data: {'activity_id': module.def.id},
  ));
  if (!context.mounted) return;
  s.audio.play(Sfx.whoosh);
  WidgetBuilder page = module.buildHome;
  if (lessonId != null && module is MainQuestModule) {
    final mq = module;
    page = (ctx) => mq.buildHome(ctx, openLessonId: lessonId);
  }
  final nav = Navigator.of(context);
  final future = nav.push(CloudRoute<void>(builder: page, calm: s.settings.calmMode));
  if (outcome.notices.isNotEmpty) {
    unawaited(Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (nav.mounted) showRewardToasts(nav.context, outcome.notices);
    }));
  }
  await future;
  if (context.mounted) s.audio.music(MusicTrack.island);
}

Rect _coverRect(Size image, Size box) {
  final scale = math.max(box.width / image.width, box.height / image.height);
  final w = image.width * scale;
  final h = image.height * scale;
  return Rect.fromLTWH((box.width - w) / 2, (box.height - h) / 2, w, h);
}

class _IslandTitle extends StatelessWidget {
  const _IslandTitle();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 14, 4),
      decoration: BoxDecoration(
        color: PQColors.cream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PQColors.ink, width: 2.4),
        boxShadow: [BoxShadow(color: PQColors.ink.withValues(alpha: 0.2), offset: const Offset(0, 3), blurRadius: 0)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: PQText.h3.copyWith(fontSize: 19, height: 1.0),
              children: const [
                TextSpan(text: 'Py', style: TextStyle(color: PQColors.pyBlue)),
                TextSpan(text: 'Quest', style: TextStyle(color: PQColors.sunDeep)),
              ],
            ),
          ),
          Text('Đảo Khởi Đầu', maxLines: 1, overflow: TextOverflow.ellipsis, style: PQText.small.copyWith(fontSize: 12, height: 1.1)),
        ],
      ),
    );
  }
}

class _MapLabel extends StatelessWidget {
  const _MapLabel({
    super.key,
    required this.anchor,
    required this.def,
    required this.status,
    required this.ambient,
    required this.calm,
    required this.onTap,
  });

  final Offset anchor;
  final ActivityDef def;
  final ActivityStatus? status;
  final Animation<double> ambient;
  final bool calm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const width = 150.0;
    final st = status;
    final locked = st?.locked ?? false;
    final recommended = st?.recommended ?? false;
    return Positioned(
      left: anchor.dx - width / 2,
      top: anchor.dy - 22,
      width: width,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: ambient,
          builder: (context, child) {
            final phase = ambient.value * 2 * math.pi * 10 + def.id.length;
            final dy = calm ? 0.0 : math.sin(phase) * (recommended ? 3.5 : 1.5);
            return Transform.translate(offset: Offset(0, dy), child: child);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (recommended && !locked)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(
                    color: PQColors.berry,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: PQColors.ink, width: 2),
                  ),
                  child: Text('Bắt đầu ở đây!',
                      style: PQText.small.copyWith(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 3, 10, 4),
                decoration: BoxDecoration(
                  color: locked ? const Color(0xFFE8DDCB) : PQColors.cream,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: PQColors.ink, width: 2.4),
                  boxShadow: [BoxShadow(color: def.tone.depth, offset: const Offset(0, 3), blurRadius: 0)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(def.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: PQText.h3.copyWith(fontSize: 15.5, height: 1.15)),
                    if (st != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (locked)
                            const Padding(padding: EdgeInsets.only(right: 3), child: GameIcon(GameIconKind.lock, size: 15))
                          else if (st.stars != null)
                            const Padding(padding: EdgeInsets.only(right: 2), child: StarIcon(size: 15)),
                          Flexible(
                            child: Text(
                              locked ? 'Chưa mở' : (st.stars != null ? '${st.stars} · ${st.progressLabel}' : st.progressLabel),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PQText.small.copyWith(fontSize: 12, height: 1.1),
                            ),
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

class _GuideBubble extends StatelessWidget {
  const _GuideBubble({required this.status});
  final Map<String, ActivityStatus> status;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final (character, text) = _pickMessage(status, s);
    final short = MediaQuery.sizeOf(context).height < 700;
    return SpeechBubble(character: character, text: text, portraitSize: short ? 58 : 76);
  }

  (CharacterId, String) _pickMessage(Map<String, ActivityStatus> st, AppServices s) {
    final mq = st['main_quest'];
    final maze = st['robot_maze'];
    final bug = st['bug_hunter'];
    if (mq != null && mq.progressLabel.startsWith('0/')) {
      return (CharacterId.py, 'Chào bạn nhỏ! Tớ đang đợi ở Tháp Python. Cùng viết dòng code đầu tiên nhé!');
    }
    if (maze != null && maze.progressLabel.startsWith('0/')) {
      return (CharacterId.robo, 'Robo bị lạc trong Mê Cung Bụi Cây rồi! Chạm vào khu vườn để giúp mình nhé.');
    }
    if (bug != null && bug.locked) {
      return (CharacterId.bitsy, 'Meo! Tớ cần một trợ lý biết chút Python. Học tới Bài 3 ở Tháp Python rồi ghé xưởng của tớ nhé!');
    }
    if (s.quests.claimable > 0) {
      return (CharacterId.robo, 'Bạn vừa hoàn thành nhiệm vụ hôm nay! Mở bảng nhiệm vụ để nhận tem nhé.');
    }
    const tips = [
      (CharacterId.pip, 'Pip đang sưu tầm xu ở Núi Lửa. Nhảy cùng Pip và mua mũ mới nào!'),
      (CharacterId.robo, 'Bạn có thể tự thiết kế mê cung trong Xưởng Mê Cung — không tốn năng lượng!'),
      (CharacterId.py, 'Mỗi lỗi sai là một bài học. Đọc kỹ lời nhắc rồi thử lại nhé!'),
      (CharacterId.bitsy, 'Trên Đài Thiên Văn có cả một bầu trời chòm sao chờ bạn thắp sáng.'),
    ];
    final i = DateTime.now().minute % tips.length;
    return tips[i];
  }
}

/// Soft cloud shadows drifting over the island.
class _CloudShadowPainter extends CustomPainter {
  _CloudShadowPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1C3A5A).withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    for (var i = 0; i < 3; i++) {
      final speed = 1 + i * 0.35;
      final x = ((t * speed + i * 0.37) % 1.0) * (size.width + 420) - 210;
      final y = size.height * (0.22 + i * 0.27);
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 230, height: 90), paint);
      canvas.drawOval(Rect.fromCenter(center: Offset(x + 70, y - 25), width: 150, height: 80), paint);
    }
  }

  @override
  bool shouldRepaint(_CloudShadowPainter old) => old.t != t;
}

class _WelcomeDialog extends StatefulWidget {
  const _WelcomeDialog();

  @override
  State<_WelcomeDialog> createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends State<_WelcomeDialog> {
  int _page = 0;

  static const _pages = [
    (CharacterId.robo, 'Chào mừng tới Đảo Khởi Đầu!',
        'Mình là Robo. Mỗi địa điểm trên đảo là một trò chơi hoặc một chặng phiêu lưu riêng. Chạm vào một nơi để khám phá nhé!'),
    (CharacterId.py, 'Học Python ở Tháp Python',
        'Tớ là thầy Py. Ở Tháp Python bạn sẽ học viết code thật từng bước. Nhiều trò chơi khác trên đảo không cần biết Python đâu!'),
    (CharacterId.pip, 'Năng lượng và nghỉ ngơi',
        'Chơi màn mới và học bài mới dùng một chút năng lượng. Năng lượng tự hồi theo thời gian. Không có quảng cáo, không có mua bán!'),
  ];

  @override
  Widget build(BuildContext context) {
    final (character, title, body) = _pages[_page];
    final last = _page == _pages.length - 1;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: PQPanel(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CharacterView(key: ValueKey(character), id: character, size: 130),
            const SizedBox(height: 6),
            Text(title, textAlign: TextAlign.center, style: PQText.h2),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center, style: PQText.body),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  Container(
                    width: i == _page ? 22 : 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _page ? PQColors.sun : PQColors.parchmentDeep,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: PQColors.ink, width: 1.6),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            ChunkyButton(
              key: const ValueKey('welcome_next'),
              label: last ? 'Bắt đầu khám phá!' : 'Tiếp tục',
              tone: last ? PQTone.grass : PQTone.sun,
              expand: true,
              onPressed: () {
                if (last) {
                  Navigator.of(context).pop();
                } else {
                  setState(() => _page++);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Gentle, non-blocking break reminder (30 / 45 / 60 minutes).
Future<void> showBreakReminder(BuildContext context, int minutes) {
  AppScope.of(context).audio.play(Sfx.pop);
  return showDialog<void>(
    context: context,
    barrierColor: PQColors.ink.withValues(alpha: 0.5),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: PQPanel(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CharacterView(id: CharacterId.robo, size: 110, mood: Mood.neutral),
            Text('Bạn đã chơi $minutes phút rồi!', textAlign: TextAlign.center, style: PQText.h2),
            const SizedBox(height: 8),
            Text(
              minutes >= 60
                  ? 'Đã đến lúc nghỉ dài hơn rồi. Đứng dậy vươn vai, uống nước và chơi ngoài trời một chút nhé!'
                  : 'Mình cùng đứng dậy vươn vai và nhìn ra xa một chút nhé. Tiến trình của bạn đã được lưu.',
              textAlign: TextAlign.center,
              style: PQText.body,
            ),
            const SizedBox(height: 16),
            ChunkyButton(
              label: 'Nghỉ mắt 20 giây',
              tone: PQTone.sea,
              expand: true,
              onPressed: () {
                Navigator.of(ctx).pop();
                showEyeBreak(context);
              },
            ),
            const SizedBox(height: 10),
            ChunkyButton(label: 'Chơi tiếp một chút', tone: PQTone.parchment, expand: true, onPressed: () => Navigator.of(ctx).pop()),
          ],
        ),
      ),
    ),
  );
}
