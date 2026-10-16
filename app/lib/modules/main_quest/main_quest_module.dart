import 'package:flutter/material.dart';

import '../../app/activity.dart';
import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../shared/characters/characters.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/palette.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/game_icons.dart';
import '../../shared/widgets/transitions.dart';
import '../energy/energy_widgets.dart';
import 'adventure_recap_screen.dart';
import 'lesson_screen.dart';
import 'playground_screen.dart';
import 'quest_models.dart';

class MainQuestModule extends ActivityModule {
  @override
  final ActivityDef def = const ActivityDef(
    id: 'main_quest',
    name: 'Tháp Python',
    tagline: 'Main Quest · Học lập trình Python',
    description: 'Lên Tháp Python học viết code thật cùng thầy Py: từng bài ngắn, có ví dụ chạy được và bài tập vui.',
    host: CharacterId.py,
    hitBox: Rect.fromLTRB(0.39, 0.044, 0.64, 0.27),
    labelAnchor: Offset(0.514, 0.275),
    thumbnail: 'assets/images/thumb_tower.webp',
    tone: PQTone.py,
    needsPython: true,
  );

  @override
  Future<ActivityStatus> status(AppServices services) async {
    final done = await services.progress.completedLessons();
    final lessons = services.mainQuest.lessons;
    final count = lessons.where((l) => done.contains(l.id)).length;
    final next = lessons.where((l) => !done.contains(l.id)).firstOrNull;
    return ActivityStatus(
      progressLabel: '$count/${lessons.length} bài',
      recommended: count == 0,
      detailLines: [
        'Chặng ${services.mainQuest.chapterNumber}: ${services.mainQuest.chapterTitle}',
        if (next != null) 'Bài tiếp theo: ${next.title}' else 'Đã hoàn thành Chặng ${services.mainQuest.chapterNumber}!',
      ],
    );
  }

  @override
  Widget buildHome(BuildContext context, {String? openLessonId}) => MainQuestHomeScreen(openLessonId: openLessonId);
}

class MainQuestHomeScreen extends StatefulWidget {
  const MainQuestHomeScreen({super.key, this.openLessonId});
  final String? openLessonId;

  @override
  State<MainQuestHomeScreen> createState() => _MainQuestHomeScreenState();
}

class _MainQuestHomeScreenState extends State<MainQuestHomeScreen> {
  Set<String> _done = {};
  AppServices? _services;
  final ScrollController _scroll = ScrollController();
  bool _scrolledToTarget = false;

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
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final done = await _services!.progress.completedLessons();
    if (!mounted) return;
    setState(() => _done = done);
    if (!_scrolledToTarget && widget.openLessonId != null) {
      _scrolledToTarget = true;
      final i = _services!.mainQuest.lessons.indexWhere((l) => l.id == widget.openLessonId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients && i > 1) {
          _scroll.animateTo((i - 1) * 96.0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
        }
      });
    }
  }

  bool _unlocked(List<Lesson> lessons, int i) => i == 0 || _done.contains(lessons[i - 1].id);

  Future<void> _open(Lesson lesson) async {
    final s = AppScope.of(context);
    final cost = _done.contains(lesson.id)
        ? s.config.cost('main_quest_review')
        : (lesson.isChallenge ? s.config.cost('chapter_challenge_first') : s.config.cost('main_quest_lesson_first'));
    if (!await spendEnergy(context, cost)) return;
    if (!mounted) return;
    await Navigator.of(context).push(CloudRoute<void>(builder: (_) => LessonScreen(lesson: lesson), calm: s.settings.calmMode));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final content = s.mainQuest;
    final lessons = content.lessons;
    final count = lessons.where((l) => _done.contains(l.id)).length;
    final chapterDone = count == lessons.length;
    final firstOpen = List.generate(lessons.length, (i) => i)
        .firstWhere((i) => _unlocked(lessons, i) && !_done.contains(lessons[i].id), orElse: () => -1);
    return Scaffold(
      body: PQBackground(
        top: const Color(0xFFC7DEFF),
        bottom: PQColors.parchment,
        child: SafeArea(
          child: Column(
            children: [
              PQTopBar(
                title: 'Tháp Python',
                subtitle: 'Main Quest · $count/${lessons.length} bài',
                tone: PQTone.py,
                trailing: const [EnergyPill(compact: true)],
              ),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _ChapterHeader(content: content, done: count),
                    const SizedBox(height: 12),
                    for (var i = 0; i < lessons.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _LessonCard(
                          key: ValueKey('lesson_card_${lessons[i].id}'),
                          lesson: lessons[i],
                          done: _done.contains(lessons[i].id),
                          unlocked: _unlocked(lessons, i),
                          current: i == firstOpen,
                          highlighted: lessons[i].id == widget.openLessonId,
                          cost: _done.contains(lessons[i].id)
                              ? 0
                              : (lessons[i].isChallenge
                                  ? s.config.cost('chapter_challenge_first')
                                  : s.config.cost('main_quest_lesson_first')),
                          onTap: () => _open(lessons[i]),
                        ),
                      ),
                    const SizedBox(height: 6),
                    if (chapterDone)
                      ChunkyButton(
                        label: 'Xem lại hành trình Chặng ${content.chapterNumber}',
                        icon: Icons.auto_stories_rounded,
                        tone: PQTone.sun,
                        expand: true,
                        onPressed: () => Navigator.of(context).push(
                          CloudRoute<void>(builder: (_) => const AdventureRecapScreen(), calm: s.settings.calmMode),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _PlaygroundCard(
                      onOpen: () => Navigator.of(context).push(
                        CloudRoute<void>(builder: (_) => const PlaygroundScreen(), calm: s.settings.calmMode),
                      ),
                    ),
                    const SizedBox(height: 12),
                    PQPanel(
                      color: const Color(0xFFEDE7DA),
                      child: Row(
                        children: [
                          const GameIcon(GameIconKind.lock, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Chặng ${content.chapterNumber + 1}: ${content.nextChapterTitle}', style: PQText.h3),
                                Text(
                                  chapterDone
                                      ? 'Bạn đã sẵn sàng! ${content.nextChapterDescription}'
                                      : 'Mở khi hoàn thành Chặng ${content.chapterNumber}. ${content.nextChapterDescription}',
                                  style: PQText.body.copyWith(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ],
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

class _ChapterHeader extends StatelessWidget {
  const _ChapterHeader({required this.content, required this.done});
  final MainQuestContent content;
  final int done;

  @override
  Widget build(BuildContext context) {
    return PQPanel(
      color: const Color(0xFFE8F1FF),
      child: Row(
        children: [
          const CharacterView(id: CharacterId.py, size: 96),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CHẶNG ${content.chapterNumber}', style: PQText.small.copyWith(color: PQColors.pyBlue, fontWeight: FontWeight.w900)),
                Text(content.chapterTitle, style: PQText.h2),
                Text(content.chapterSubtitle, style: PQText.small),
                const SizedBox(height: 6),
                ChunkyProgress(value: done / content.lessons.length, color: PQColors.pyBlue),
                const SizedBox(height: 4),
                Text(content.chapterDescription, style: PQText.body.copyWith(fontSize: 14.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    super.key,
    required this.lesson,
    required this.done,
    required this.unlocked,
    required this.current,
    required this.highlighted,
    required this.cost,
    required this.onTap,
  });

  final Lesson lesson;
  final bool done;
  final bool unlocked;
  final bool current;
  final bool highlighted;
  final int cost;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = done ? PQTone.success : (unlocked ? (lesson.isChallenge ? PQTone.sun : PQTone.py) : PQTone.disabled);
    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: unlocked ? (current ? const Color(0xFFFFF4CC) : PQColors.cream) : const Color(0xFFEDE7DA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: highlighted ? PQColors.berry : PQColors.ink, width: highlighted || current ? 3.2 : 2.4),
          boxShadow: [BoxShadow(color: tone.depth.withValues(alpha: unlocked ? 1 : 0.4), offset: const Offset(0, 4), blurRadius: 0)],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: tone.face,
                shape: BoxShape.circle,
                border: Border.all(color: PQColors.ink, width: 2.4),
              ),
              alignment: Alignment.center,
              child: done
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 32)
                  : (unlocked
                      ? (lesson.isChallenge
                          ? const Icon(Icons.emoji_events_rounded, color: PQColors.ink, size: 30)
                          : Text('${lesson.number}', style: PQText.h2.copyWith(color: Colors.white)))
                      : const GameIcon(GameIconKind.lock, size: 28)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lesson.isChallenge ? 'Thử thách cuối chặng' : 'Bài ${lesson.number}',
                      style: PQText.small.copyWith(color: tone.depth, fontWeight: FontWeight.w900, fontSize: 13)),
                  Text(lesson.title, style: PQText.h3.copyWith(fontSize: 18, color: unlocked ? PQColors.ink : PQColors.inkFaint)),
                  Text(
                    unlocked ? '${lesson.skill} · ${lesson.steps.length} bước' : 'Hoàn thành bài trước để mở',
                    style: PQText.small.copyWith(fontSize: 13.5),
                  ),
                ],
              ),
            ),
            if (unlocked)
              done
                  ? const PillTag(label: 'Ôn tập', color: PQColors.success)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$cost', style: PQText.number.copyWith(fontSize: 18)),
                        const GameIcon(GameIconKind.energy, size: 22),
                      ],
                    ),
          ],
        ),
      ),
    );
  }
}

class _PlaygroundCard extends StatelessWidget {
  const _PlaygroundCard({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return PQPanel(
      color: const Color(0xFFE3F6EC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: PQColors.codeBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PQColors.ink, width: 2.4),
                ),
                child: const Icon(Icons.terminal_rounded, color: PQColors.codeNumber, size: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sân tập code', style: PQText.h2.copyWith(color: PQColors.successDeep)),
                    Text('Viết và chạy Python tự do, có sẵn ví dụ vui. Luôn miễn phí!', style: PQText.body.copyWith(fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ChunkyButton(
            key: const ValueKey('open_playground'),
            label: 'Mở Sân tập',
            icon: Icons.code_rounded,
            tone: PQTone.success,
            expand: true,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}
