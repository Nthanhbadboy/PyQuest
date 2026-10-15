import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/activity.dart';
import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../core/audio_service.dart';
import '../../core/events.dart';
import '../../data/repositories/progress_repository.dart';
import '../../python_runtime/python_runtime.dart';
import '../../shared/characters/characters.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/palette.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/code_widgets.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/game_icons.dart';
import '../../shared/widgets/result_screen.dart';
import '../../shared/widgets/transitions.dart';
import '../energy/energy_widgets.dart';
import '../main_quest/answer_check.dart';
import 'bug_models.dart';

class BugHunterModule extends ActivityModule {
  @override
  final ActivityDef def = const ActivityDef(
    id: BugHunterContent.gameId,
    name: 'Xưởng Bitsy',
    tagline: 'Mini-game · Săn bọ lỗi',
    description: 'Bitsy là thám tử săn bọ lỗi trong code. Đọc chương trình, chạy thử, tìm dòng có bọ rồi chọn cách sửa đúng!',
    host: CharacterId.bitsy,
    hitBox: Rect.fromLTRB(0.13, 0.465, 0.43, 0.61),
    labelAnchor: Offset(0.28, 0.63),
    thumbnail: 'assets/images/thumb_workshop.webp',
    tone: PQTone.grape,
    needsPython: true,
  );

  @override
  Future<ActivityStatus> status(AppServices services) async {
    final content = services.bugHunter;
    final lessons = await services.progress.completedLessons();
    if (!lessons.contains(content.unlockLessonId)) {
      final lesson = services.mainQuest.byId(content.unlockLessonId);
      return ActivityStatus(
        progressLabel: 'Chưa mở',
        locked: true,
        lockReason: 'Bitsy cần trợ lý biết print() và phép tính. Hãy hoàn thành Bài ${lesson?.number ?? 3}: '
            '${lesson?.title ?? ''} ở Tháp Python để mở Xưởng Bitsy.',
        unlockLessonId: content.unlockLessonId,
      );
    }
    final done = await services.progress.completedLevelCount(gameId: BugHunterContent.gameId);
    final bugs = await services.progress.countClaims('bug:');
    return ActivityStatus(
      progressLabel: '$done/${content.puzzles.length} câu đố',
      stars: await services.progress.totalStars(gameId: BugHunterContent.gameId),
      recommended: done == 0,
      detailLines: ['Đã sửa $bugs/${content.totalBugs} con bọ lỗi'],
    );
  }

  @override
  Widget buildHome(BuildContext context) => const BugHunterHomeScreen();
}

class BugHunterHomeScreen extends StatefulWidget {
  const BugHunterHomeScreen({super.key});

  @override
  State<BugHunterHomeScreen> createState() => _BugHunterHomeScreenState();
}

class _BugHunterHomeScreenState extends State<BugHunterHomeScreen> {
  Map<String, LevelRecord> _records = {};
  Set<String> _lessons = {};
  int _bugs = 0;
  AppServices? _s;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppScope.of(context);
    if (_s != s) {
      _s?.events.revision.removeListener(_load);
      _s = s;
      s.events.revision.addListener(_load);
      _load();
    }
  }

  @override
  void dispose() {
    _s?.events.revision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final s = _s!;
    final r = await s.progress.levelRecords(BugHunterContent.gameId);
    final l = await s.progress.completedLessons();
    final b = await s.progress.countClaims('bug:');
    if (mounted) {
      setState(() {
        _records = r;
        _lessons = l;
        _bugs = b;
      });
    }
  }

  bool _puzzleUnlocked(BugHunterContent c, BugPuzzle p) {
    final pack = c.packOf(p);
    if (!_lessons.contains(pack.requiresLesson)) return false;
    final i = c.puzzles.indexOf(p);
    if (i == 0) return true;
    final prev = c.puzzles[i - 1];
    return _records.containsKey(prev.id) || prev.pack != p.pack;
  }

  Future<void> _open(BugPuzzle p) async {
    final s = AppScope.of(context);
    final cost = _records.containsKey(p.id) ? s.config.cost('mini_game_replay_completed') : s.config.cost('mini_game_new_level');
    if (!await spendEnergy(context, cost)) return;
    if (!mounted) return;
    await Navigator.of(context).push(CloudRoute<void>(builder: (_) => BugPuzzleScreen(puzzle: p), calm: s.settings.calmMode));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.bugHunter;
    return Scaffold(
      body: PQBackground(
        top: const Color(0xFFE6DCFF),
        bottom: const Color(0xFFFFF3E2),
        child: SafeArea(
          child: Column(
            children: [
              PQTopBar(
                title: 'Xưởng Bitsy',
                subtitle: 'Đã sửa $_bugs/${c.totalBugs} con bọ',
                tone: PQTone.grape,
                trailing: const [EnergyPill(compact: true)],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    const SpeechBubble(
                      character: CharacterId.bitsy,
                      text: 'Meo! Mỗi câu đố là một chương trình có bọ lỗi. Bấm Chạy thử để xem chuyện gì xảy ra, chạm vào dòng có bọ rồi chọn cách sửa nhé!',
                      portraitSize: 74,
                    ),
                    const SizedBox(height: 10),
                    ChunkyProgress(value: _bugs / c.totalBugs, color: PQColors.grape, height: 18),
                    const SizedBox(height: 12),
                    for (final pack in c.packs) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text(pack.title, style: PQText.h3)),
                            if (!_lessons.contains(pack.requiresLesson))
                              PillTag(
                                label: 'Cần Bài ${s.mainQuest.byId(pack.requiresLesson)?.number ?? ''}',
                                color: PQColors.inkFaint,
                                icon: Icons.lock_rounded,
                              ),
                          ],
                        ),
                      ),
                      for (final p in c.puzzles.where((p) => p.pack == pack.number))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PuzzleCard(
                            key: ValueKey('puzzle_${p.id}'),
                            puzzle: p,
                            record: _records[p.id],
                            unlocked: _puzzleUnlocked(c, p),
                            onTap: () => _open(p),
                          ),
                        ),
                    ],
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

class _PuzzleCard extends StatelessWidget {
  const _PuzzleCard({super.key, required this.puzzle, required this.record, required this.unlocked, required this.onTap});
  final BugPuzzle puzzle;
  final LevelRecord? record;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = record != null;
    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: PQPanel(
        padding: const EdgeInsets.all(12),
        color: unlocked ? PQColors.cream : const Color(0xFFEDE7DA),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: done ? PQColors.success : (unlocked ? PQColors.grape : PQColors.disabled),
                shape: BoxShape.circle,
                border: Border.all(color: PQColors.ink, width: 2.4),
              ),
              alignment: Alignment.center,
              child: unlocked
                  ? (done
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 30)
                      : const Icon(Icons.bug_report_rounded, color: Colors.white, size: 28))
                  : const GameIcon(GameIconKind.lock, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Câu đố ${puzzle.index + 1}', style: PQText.small.copyWith(color: PQColors.grapeDeep, fontWeight: FontWeight.w900, fontSize: 13)),
                  Text(puzzle.title, style: PQText.h3.copyWith(fontSize: 18, color: unlocked ? PQColors.ink : PQColors.inkFaint)),
                  Text('${puzzle.bugs.length} con bọ · ${puzzle.code.length} dòng code', style: PQText.small.copyWith(fontSize: 13)),
                ],
              ),
            ),
            if (done) StarRow(stars: record!.stars, size: 18),
          ],
        ),
      ),
    );
  }
}

/// One debugging puzzle.
class BugPuzzleScreen extends StatefulWidget {
  const BugPuzzleScreen({super.key, required this.puzzle});
  final BugPuzzle puzzle;

  @override
  State<BugPuzzleScreen> createState() => _BugPuzzleScreenState();
}

class _BugPuzzleScreenState extends State<BugPuzzleScreen> {
  late final List<String> _lines = List.of(widget.puzzle.code);
  final Set<int> _fixed = {};
  int _mistakes = 0;
  ExecutionResult? _result;
  int? _flashWrong;
  String? _message;
  Mood _mood = Mood.happy;
  final Stopwatch _watch = Stopwatch()..start();
  Timer? _ticker;
  bool _done = false;
  final List<RewardNotice> _notices = [];

  BugPuzzle get p => widget.puzzle;

  @override
  void initState() {
    super.initState();
    _message = p.story;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_done) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _run({bool auto = false}) async {
    final s = AppScope.of(context);
    final r = await s.python.execute(_lines.join('\n'));
    if (!mounted) return;
    final ok = r.success && compareOutput(r.output, p.expectedOutput) == OutputMatch.exact;
    if (!auto) s.audio.play(ok ? Sfx.sparkle : Sfx.bonk);
    setState(() {
      _result = r;
      if (!auto) {
        _mood = Mood.thinking;
        _message = r.success
            ? (ok ? 'Chạy đúng rồi!' : 'Chương trình chạy được nhưng in ra khác điều tớ muốn. So sánh kỹ hai kết quả nhé!')
            : 'Có lỗi ở dòng ${r.errorLine ?? '?'}. Đọc lời nhắc rồi chạm vào dòng có bọ nhé!';
      }
    });
  }

  Future<void> _tapLine(int line) async {
    if (_done) return;
    final s = AppScope.of(context);
    final bug = p.bugAt(line);
    if (bug == null || _fixed.contains(line)) {
      s.audio.play(Sfx.bonk);
      setState(() {
        _mistakes += bug == null ? 1 : 0;
        _flashWrong = line;
        _mood = Mood.thinking;
        _message = _fixed.contains(line) ? 'Dòng này đã được sửa rồi!' : 'Dòng $line không có bọ đâu. Thử chạy chương trình để tìm manh mối nhé!';
      });
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _flashWrong = null);
      });
      return;
    }
    s.audio.play(Sfx.pop);
    final options = List.of(bug.options)..shuffle(math.Random(line * 7 + p.index));
    final pick = await showPQSheet<String>(
      context,
      builder: (ctx) => _FixPicker(line: line, current: _lines[line - 1], options: options),
    );
    if (pick == null || !mounted) return;
    if (pick == bug.correct) {
      s.audio.play(Sfx.bug);
      setState(() {
        _lines[line - 1] = pick;
        _fixed.add(line);
        _mood = Mood.happy;
        _message = 'Bắt được một con bọ! ${bug.explain}';
      });
      final outcome = await s.events.emit(StandardEvent(
        type: EventTypes.bugFixed,
        sourceId: BugHunterContent.gameId,
        data: {'puzzle_id': p.id, 'bug_index': p.bugs.indexOf(bug)},
      ));
      _notices.addAll(outcome.notices);
      if (_fixed.length == p.bugs.length) await _win();
    } else {
      s.audio.play(Sfx.fail);
      setState(() {
        _mistakes++;
        _mood = Mood.sad;
        _message = 'Cách sửa đó chưa đúng. Gợi ý: ${bug.explain}';
      });
    }
  }

  Future<void> _win() async {
    _done = true;
    _watch.stop();
    await _run(auto: true);
    if (!mounted) return;
    final s = AppScope.of(context);
    final seconds = _watch.elapsed.inSeconds;
    final limit = s.config.gameInt('bug_hunter', 'three_star_seconds', 60);
    final noMistakes = _mistakes == 0;
    final fast = seconds <= limit;
    final stars = 1 + (noMistakes ? 1 : 0) + (fast ? 1 : 0);
    final score = 40 + (noMistakes ? 30 : 0) + (fast ? 30 : 0);
    final content = s.bugHunter;
    final next = p.index + 1 < content.puzzles.length ? content.puzzles[p.index + 1] : null;
    if (p.aboutConditions) {
      final o = await s.events.emit(StandardEvent(
        type: EventTypes.exerciseSolved,
        sourceId: BugHunterContent.gameId,
        data: {'exercise_id': p.id, 'skills': const ['conditions']},
      ));
      _notices.addAll(o.notices);
    }
    final outcome = await s.events.emit(StandardEvent(
      type: EventTypes.levelCompleted,
      sourceId: BugHunterContent.gameId,
      data: {'level_id': p.id, 'stars': stars, 'score': score, if (next != null) 'next_level_id': next.id},
    ));
    _notices.addAll(outcome.notices);
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final lessons = await s.progress.completedLessons();
    final nextUnlocked = next != null && lessons.contains(content.packOf(next).requiresLesson);
    final nextDone = next != null && await s.progress.levelRecord(BugHunterContent.gameId, next.id) != null;
    final nextCost = nextDone ? s.config.cost('mini_game_replay_completed') : s.config.cost('mini_game_new_level');
    if (!mounted) return;
    final action = await showLevelResult(
      context,
      LevelResultData(
        gameName: 'Săn Bọ Lỗi',
        levelTitle: 'Câu đố ${p.index + 1}: ${p.title}',
        success: true,
        stars: stars,
        score: score,
        bestScore: outcome.bestScore,
        newBest: outcome.newHighScore,
        goals: [
          ResultGoal('Sửa hết ${p.bugs.length} con bọ', true),
          ResultGoal('Không chạm nhầm, không sửa sai', noMistakes),
          ResultGoal('Hoàn thành trong $limit giây (bạn: ${seconds}s)', fast),
        ],
        stats: [
          ResultStat('Bọ đã bắt', '${p.bugs.length}'),
          ResultStat('Lần nhầm', '$_mistakes'),
          ResultStat('Thời gian', '${seconds}s'),
        ],
        skill: 'Gỡ lỗi (debug): ${p.skill}.',
        host: CharacterId.bitsy,
        hostLine: noMistakes ? 'Mắt thám tử của bạn tinh thật đấy!' : 'Bắt bọ giỏi lắm! Lần sau thử chạy chương trình trước để tìm manh mối nhé.',
        notices: _notices,
        primaryLabel: nextUnlocked ? 'Câu đố tiếp theo' : null,
        primaryCost: nextCost,
        tone: PQTone.grape,
      ),
    );
    if (!mounted) return;
    switch (action) {
      case ResultAction.primary:
        if (next == null || !await spendEnergy(context, nextCost)) {
          if (mounted) Navigator.of(context).pop();
          return;
        }
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => BugPuzzleScreen(puzzle: next)));
      case ResultAction.replay:
      case ResultAction.back:
        Navigator.of(context).pop();
      case ResultAction.map:
        Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  Map<int, Color> _lineColors() {
    final colors = <int, Color>{for (final l in _fixed) l: PQColors.success.withValues(alpha: 0.35)};
    final wrong = _flashWrong;
    if (wrong != null) colors[wrong] = PQColors.danger.withValues(alpha: 0.45);
    return colors;
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _watch.elapsed.inSeconds;
    return Scaffold(
      body: PQBackground(
        top: const Color(0xFFE6DCFF),
        bottom: const Color(0xFFFFF3E2),
        child: SafeArea(
          child: Column(
            children: [
              PQTopBar(
                title: p.title,
                subtitle: 'Câu đố ${p.index + 1} · ${_fixed.length}/${p.bugs.length} bọ',
                tone: PQTone.grape,
                trailing: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: PQColors.cream,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: PQColors.ink, width: 2.2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_rounded, size: 18, color: PQColors.inkSoft),
                        Text(' ${seconds}s', style: PQText.number.copyWith(fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
                  children: [
                    SpeechBubble(character: CharacterId.bitsy, text: _message ?? '', mood: _mood, portraitSize: 66),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF6D9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: PQColors.sunDeep, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bitsy muốn máy in ra:', style: PQText.small.copyWith(color: PQColors.sunDeep, fontWeight: FontWeight.w900)),
                          Text(p.expectedOutput, style: PQText.code.copyWith(fontSize: 15, color: PQColors.ink)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Chạm vào dòng có bọ:', style: PQText.small),
                    const SizedBox(height: 4),
                    CodeView(
                      code: _lines.join('\n'),
                      fontSize: 15,
                      errorLine: _result?.success == false ? _result?.errorLine : null,
                      onLineTap: _tapLine,
                      lineColors: _lineColors(),
                    ),
                    const SizedBox(height: 10),
                    ChunkyButton(
                      key: const ValueKey('bug_run'),
                      label: 'Chạy thử',
                      icon: Icons.play_arrow_rounded,
                      tone: PQTone.grass,
                      size: ChunkySize.medium,
                      expand: true,
                      sfx: null,
                      onPressed: _done ? null : () => _run(),
                    ),
                    const SizedBox(height: 10),
                    OutputConsole(result: _result, helper: CharacterId.bitsy),
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

class _FixPicker extends StatelessWidget {
  const _FixPicker({required this.line, required this.current, required this.options});
  final int line;
  final String current;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sửa dòng $line thành:', style: PQText.h2),
          const SizedBox(height: 6),
          CodeView(code: current, fontSize: 14),
          const SizedBox(height: 12),
          for (var i = 0; i < options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                key: ValueKey('fix_option_$i'),
                onTap: () => Navigator.of(context).pop(options[i]),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PQColors.codeBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PQColors.ink, width: 2.4),
                    boxShadow: const [BoxShadow(color: PQColors.grapeDeep, offset: Offset(0, 4), blurRadius: 0)],
                  ),
                  child: Text.rich(
                    TextSpan(children: highlightPython(options[i], PQText.code.copyWith(fontSize: 15))),
                    style: PQText.code.copyWith(fontSize: 15),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
