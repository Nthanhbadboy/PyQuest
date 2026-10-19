import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/audio_service.dart';
import '../../core/events.dart';
import '../../modules/achievements/achievement_catalog.dart';
import '../../shared/characters/characters.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/palette.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/confetti.dart';
import '../../shared/widgets/game_icons.dart';
import '../../shared/widgets/transitions.dart';
import '../energy/energy_widgets.dart';
import 'adventure_recap_screen.dart';
import 'lesson_screen.dart';
import 'quest_models.dart';

/// "Màn tổng kết bài học": what was learned, Py's comment, next steps.
class LessonCompleteScreen extends StatefulWidget {
  const LessonCompleteScreen({
    super.key,
    required this.lesson,
    required this.firstTime,
    required this.exercises,
    required this.mistakes,
    required this.duration,
    required this.notices,
    required this.chapterCompleted,
  });

  final Lesson lesson;
  final bool firstTime;
  final int exercises;
  final int mistakes;
  final Duration duration;
  final List<RewardNotice> notices;
  final bool chapterCompleted;

  @override
  State<LessonCompleteScreen> createState() => _LessonCompleteScreenState();
}

class _LessonCompleteScreenState extends State<LessonCompleteScreen> {
  bool _started = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final audio = AppScope.of(context).audio;
    audio.play(Sfx.success);
    if (widget.notices.any((n) => n.kind == RewardKind.badge)) {
      _timer = Timer(const Duration(milliseconds: 1200), () => audio.play(Sfx.unlock));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _nextLesson(Lesson next) async {
    final s = AppScope.of(context);
    final completed = await s.progress.completedLessons();
    if (!mounted) return;
    final cost = completed.contains(next.id)
        ? s.config.cost('main_quest_review')
        : (next.isChallenge ? s.config.cost('chapter_challenge_first') : s.config.cost('main_quest_lesson_first'));
    if (!await spendEnergy(context, cost)) return;
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => LessonScreen(lesson: next)));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final lessons = s.mainQuest.lessons;
    final i = lessons.indexWhere((l) => l.id == widget.lesson.id);
    final next = i >= 0 && i + 1 < lessons.length ? lessons[i + 1] : null;
    final minutes = widget.duration.inMinutes;
    final seconds = widget.duration.inSeconds.remainder(60);
    final badges = widget.notices.where((n) => n.kind == RewardKind.badge).toList();
    final others = widget.notices.where((n) => n.kind != RewardKind.badge).toList();
    final calm = s.settings.calmMode;
    return Scaffold(
      body: PQBackground(
        top: const Color(0xFFCFE4FF),
        child: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      key: const ValueKey('lesson_complete_25d_scene'),
                      height: 108,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: const Color(0xFF355843),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: PQColors.ink, width: 2.4),
                        boxShadow: [
                          BoxShadow(
                            color: PQTone.py.depth,
                            offset: const Offset(0, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/journal_recap_r36.webp',
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('THÁP PYTHON · CHẶNG ${s.mainQuest.chapterNumber}',
                        textAlign: TextAlign.center,
                        style: PQText.small.copyWith(color: PQColors.pyBlue, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                    Text(widget.lesson.isChallenge ? 'Vượt qua thử thách!' : 'Hoàn thành Bài ${widget.lesson.number}!',
                        key: const ValueKey('lesson_complete_title'), textAlign: TextAlign.center, style: PQText.h1),
                    Text(widget.lesson.title, textAlign: TextAlign.center, style: PQText.h3.copyWith(color: PQColors.inkSoft)),
                    const SizedBox(height: 8),
                    const Center(child: PopIn(child: CharacterView(id: CharacterId.py, size: 150))),
                    const SizedBox(height: 8),
                    PQPanel(
                      color: const Color(0xFFE8F1FF),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_rounded, color: PQColors.sunDeep, size: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Bạn đã học: ${widget.lesson.skill}',
                                    style: PQText.small.copyWith(color: PQColors.pyBlue, fontWeight: FontWeight.w900)),
                                Text(widget.lesson.summary, style: PQText.bodyStrong.copyWith(fontSize: 16)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _Stat(label: 'Bài tập', value: '${widget.exercises}')),
                        const SizedBox(width: 8),
                        Expanded(child: _Stat(label: 'Lần thử lại', value: '${widget.mistakes}')),
                        const SizedBox(width: 8),
                        Expanded(child: _Stat(label: 'Thời gian', value: minutes > 0 ? '$minutes:${seconds.toString().padLeft(2, '0')}' : '${seconds}s')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final b in badges) _BadgeLine(notice: b),
                    for (final n in others)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PQPanel(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              GameIcon(n.kind == RewardKind.quest ? GameIconKind.stamp : GameIconKind.energy, size: 34),
                              const SizedBox(width: 10),
                              Expanded(child: Text('${n.title} ${n.description}', style: PQText.bodyStrong.copyWith(fontSize: 15.5))),
                            ],
                          ),
                        ),
                      ),
                    SpeechBubble(character: CharacterId.py, text: widget.lesson.pyLine),
                    const SizedBox(height: 18),
                    if (widget.chapterCompleted)
                      ChunkyButton(
                        key: const ValueKey('open_recap'),
                        label: 'Xem hành trình Chặng 1',
                        icon: Icons.auto_stories_rounded,
                        tone: PQTone.sun,
                        expand: true,
                        onPressed: () => Navigator.of(context).pushReplacement(
                          CloudRoute<void>(builder: (_) => const AdventureRecapScreen(), calm: calm),
                        ),
                      )
                    else if (next != null)
                      ChunkyButton(
                        key: const ValueKey('next_lesson'),
                        label: 'Bài tiếp theo',
                        icon: Icons.arrow_forward_rounded,
                        tone: PQTone.py,
                        expand: true,
                        onPressed: () => _nextLesson(next),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ChunkyButton(
                            key: const ValueKey('back_to_tower'),
                            label: 'Tháp Python',
                            icon: Icons.castle_rounded,
                            tone: PQTone.parchment,
                            size: ChunkySize.medium,
                            expand: true,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChunkyButton(
                            key: const ValueKey('lesson_to_map'),
                            label: 'Về bản đồ',
                            icon: Icons.map_rounded,
                            tone: PQTone.sea,
                            size: ChunkySize.medium,
                            expand: true,
                            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ),
            if (!calm) const Positioned.fill(child: ConfettiBurst(count: 50)),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return PQPanel(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        children: [
          Text(value, style: PQText.number),
          Text(label, textAlign: TextAlign.center, style: PQText.small.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}

class _BadgeLine extends StatelessWidget {
  const _BadgeLine({required this.notice});
  final RewardNotice notice;

  @override
  Widget build(BuildContext context) {
    final def = achievementById(notice.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PopIn(
        delay: const Duration(milliseconds: 900),
        child: PQPanel(
          color: const Color(0xFFFFF6D6),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (def != null) BadgeMedal(icon: def.icon, color: def.color, size: 60),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Huy hiệu mới!', style: PQText.small.copyWith(color: PQColors.berry, fontWeight: FontWeight.w900)),
                    Text(notice.title, style: PQText.h3),
                    Text(notice.description, style: PQText.small),
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
