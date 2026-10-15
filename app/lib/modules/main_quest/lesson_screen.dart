import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/audio_service.dart';
import '../../core/events.dart';
import '../../python_runtime/python_runtime.dart';
import '../../shared/characters/characters.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/palette.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/code_widgets.dart';
import '../../shared/widgets/common.dart';
import '../robot_maze/maze_board.dart';
import '../robot_maze/maze_models.dart';
import 'answer_check.dart';
import 'lesson_complete_screen.dart';
import 'quest_models.dart';

/// Plays one Main Quest lesson step by step.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.lesson});
  final Lesson lesson;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

enum _Feedback { none, correct, wrong }

class _LessonScreenState extends State<LessonScreen> {
  int _index = 0;
  _Feedback _feedback = _Feedback.none;
  String _feedbackText = '';
  bool _canContinue = false;
  int _mistakes = 0;
  int _stepFails = 0;
  int _solved = 0;
  final Stopwatch _clock = Stopwatch()..start();
  final List<RewardNotice> _notices = [];
  bool _hadLimitError = false;

  // Per-step state, reset when the step changes.
  int? _choice;
  List<String?> _picks = [];
  List<String> _fillOptions = [];
  List<int> _orderPicked = [];
  List<String> _orderPool = [];
  PythonCodeController? _code;
  ExecutionResult? _run;
  bool _running = false;
  final GlobalKey<_RobotRunnerState> _robotKey = GlobalKey();

  LessonStep get _step => widget.lesson.steps[_index];

  @override
  void initState() {
    super.initState();
    _prepareStep();
  }

  @override
  void dispose() {
    _code?.dispose();
    super.dispose();
  }

  void _prepareStep() {
    final s = _step;
    _feedback = _Feedback.none;
    _feedbackText = '';
    _stepFails = 0;
    _choice = null;
    _run = null;
    _code?.dispose();
    _code = null;
    _canContinue = s is StoryStep;
    final rnd = math.Random(_index * 31 + widget.lesson.number);
    switch (s) {
      case FillStep f:
        _picks = List.filled(f.blanks.length, null);
        _fillOptions = [for (final b in f.blanks) ...b]..shuffle(rnd);
      case OrderStep o:
        _orderPicked = [];
        _orderPool = List.of(o.lines);
        do {
          _orderPool.shuffle(rnd);
        } while (_orderPool.length > 1 && _listEquals(_orderPool, o.lines));
      case WriteStep w:
        _code = PythonCodeController(text: w.starter);
      case RobotStep r:
        _code = PythonCodeController(text: r.starter);
      default:
        break;
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _next() async {
    if (_index < widget.lesson.steps.length - 1) {
      AppScope.of(context).audio.play(Sfx.whoosh, volume: 0.5);
      setState(() {
        _index++;
        _prepareStep();
      });
    } else {
      await _complete();
    }
  }

  Future<void> _complete() async {
    final s = AppScope.of(context);
    _clock.stop();
    final lesson = widget.lesson;
    final score = math.max(50, 100 - _mistakes * 5);
    final outcome = await s.events.emit(StandardEvent(
      type: EventTypes.lessonCompleted,
      sourceId: 'main_quest',
      data: {'lesson_id': lesson.id, 'chapter_id': lesson.chapterId, 'skills': lesson.skillIds, 'score': score},
    ));
    _notices.addAll(outcome.notices);
    var chapterDone = false;
    final completed = await s.progress.completedLessons();
    final content = s.mainQuest;
    if (content.lessons.every((l) => completed.contains(l.id))) {
      final firstTime = !await s.progress.isClaimed('chapter:${content.chapterId}');
      if (firstTime) {
        final o = await s.events.emit(StandardEvent(
          type: EventTypes.chapterCompleted,
          sourceId: 'main_quest',
          data: {'chapter_id': content.chapterId},
        ));
        _notices.addAll(o.notices);
        chapterDone = true;
      }
    }
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => LessonCompleteScreen(
        lesson: lesson,
        firstTime: outcome.firstCompletion,
        exercises: lesson.exerciseCount,
        mistakes: _mistakes,
        duration: _clock.elapsed,
        notices: List.of(_notices),
        chapterCompleted: chapterDone,
      ),
    ));
  }

  Future<void> _markSolved({String? extra}) async {
    final s = AppScope.of(context);
    s.audio.play(Sfx.success);
    _solved++;
    setState(() {
      _feedback = _Feedback.correct;
      _feedbackText = extra ?? _praise();
      _canContinue = true;
    });
    final outcome = await s.events.emit(StandardEvent(
      type: EventTypes.exerciseSolved,
      sourceId: 'main_quest',
      data: {'exercise_id': _step.id, 'skills': _step.skills},
    ));
    _notices.addAll(outcome.notices);
  }

  String _praise() {
    const lines = ['Chính xác!', 'Giỏi quá!', 'Tuyệt vời!', 'Đúng rồi!', 'Xuất sắc!'];
    return lines[(_index + _solved) % lines.length];
  }

  void _markWrong(String message) {
    AppScope.of(context).audio.play(Sfx.fail);
    _mistakes++;
    _stepFails++;
    setState(() {
      _feedback = _Feedback.wrong;
      _feedbackText = message;
    });
  }

  String? _hintFor(LessonStep s) => switch (s) {
        WriteStep w => w.hint,
        RobotStep r => r.hint,
        FillStep f => f.explain,
        ChoiceStep c => c.explain,
        _ => null,
      };

  Future<ExecutionResult> _execute(String code, {ExecutionContext? execContext}) async {
    final s = AppScope.of(context);
    setState(() => _running = true);
    final r = await s.python.execute(code, context: execContext);
    final recovered = r.success && _hadLimitError;
    if (r.hitLimit) _hadLimitError = true;
    if (recovered) _hadLimitError = false;
    final outcome = await s.events.emit(StandardEvent(
      type: EventTypes.codeRun,
      sourceId: 'main_quest',
      data: {'success': r.success, 'context': 'lesson', 'recovered_from_limit': recovered},
    ));
    _notices.addAll(outcome.notices);
    if (mounted) setState(() => _running = false);
    return r;
  }

  // ------------------------------------------------------------- checks

  Future<void> _check() async {
    final s = _step;
    switch (s) {
      case ChoiceStep c:
        if (_choice == null) return;
        if (_choice == c.answer) {
          await _markSolved(extra: '${_praise()} ${c.explain}');
        } else {
          _markWrong(_stepFails >= 1 ? c.explain : 'Chưa đúng rồi. Đọc lại câu hỏi và thử lần nữa nhé!');
        }
      case FillStep f:
        if (_picks.any((p) => p == null)) return;
        final r = await _execute(f.build(_picks));
        setState(() => _run = r);
        if (r.success && compareOutput(r.output, f.expectedOutput) == OutputMatch.exact) {
          await _markSolved(extra: '${_praise()} ${f.explain}');
        } else {
          _markWrong(r.success ? 'Chương trình chạy được nhưng in ra chưa đúng. Thử mảnh ghép khác nhé!' : 'Mảnh ghép này làm code bị lỗi. Thử lại nhé!');
        }
      case OrderStep o:
        if (_orderPicked.length != _orderPool.length) return;
        final code = [for (final i in _orderPicked) _orderPool[i]].join('\n');
        final r = await _execute(code);
        setState(() => _run = r);
        if (r.success && compareOutput(r.output, o.expectedOutput) == OutputMatch.exact) {
          await _markSolved();
        } else {
          _markWrong('Thứ tự chưa đúng. Chạm vào dòng đã chọn để trả nó về và thử lại!');
        }
      case WriteStep w:
        await _checkWrite(w);
      case RobotStep r:
        await _robotKey.currentState?.run();
      case StoryStep _:
      case ExampleStep _:
        break;
    }
  }

  Future<void> _checkWrite(WriteStep w) async {
    final code = _code!.text;
    final r = await _execute(code);
    setState(() => _run = r);
    if (!r.success) {
      _markWrong('Code có lỗi. Đọc lời nhắc của thầy Py bên dưới rồi sửa lại nhé!');
      return;
    }
    final missing = missingParts(code, w.mustContain);
    if (missing.isNotEmpty) {
      _markWrong('Chương trình chạy rồi, nhưng bài này cần dùng: ${missing.join(', ')}');
      return;
    }
    if (w.anyOutput || w.expectedOutput == null) {
      if (r.output.trim().isNotEmpty) {
        await _markSolved();
      } else {
        _markWrong('Chương trình chưa in ra gì cả. Đừng quên print()!');
      }
      return;
    }
    final match = compareOutput(r.output, w.expectedOutput!);
    if (match == OutputMatch.exact) {
      await _markSolved();
    } else if (match == OutputMatch.loose && w.lenient) {
      await _markSolved(extra: 'Đúng rồi! (Mẹo nhỏ: máy tính in ra chính xác từng chữ, từng dấu bạn viết.)');
    } else {
      _markWrong('Gần được rồi! Máy in ra:\n${normalizeOutput(r.output)}\nnhưng đề bài cần:\n${w.expectedOutput}');
    }
  }

  Future<void> _onRobotFinished(bool reached, String code, ExecutionResult? result) async {
    final step = _step;
    if (step is! RobotStep) return;
    setState(() => _run = (result != null && !result.success && result.errorKind != ExecutionErrorKind.halted) ? result : null);
    if (!reached) {
      _markWrong(result != null && !result.success && result.errorKind != ExecutionErrorKind.halted
          ? 'Code có lỗi nên Robo chưa đi được. Xem lời nhắc bên dưới nhé!'
          : 'Robo chưa tới rương. Kiểm tra lại các bước nhé!');
      return;
    }
    final missing = missingParts(code, step.mustContain);
    if (missing.isNotEmpty) {
      _markWrong('Robo tới nơi rồi! Nhưng bài này yêu cầu dùng: ${missing.join(', ')}');
      return;
    }
    await _markSolved();
  }

  // ------------------------------------------------------------------ UI

  Future<bool> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PQColors.parchment,
        title: Text('Tạm dừng bài học?', style: PQText.h2),
        content: Text('Bạn có thể học lại bài này bất cứ lúc nào. Tiến trình của bài đang học sẽ không được lưu.',
            style: PQText.body),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Học tiếp', style: PQText.label)),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Thoát', style: PQText.label.copyWith(color: PQColors.coralDeep)),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final step = _step;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmExit() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        body: PQBackground(
          top: const Color(0xFFCFE4FF),
          bottom: PQColors.parchment,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    children: [
                      RoundIconButton(
                        key: const ValueKey('lesson_close'),
                        icon: Icons.close_rounded,
                        size: 44,
                        tooltip: 'Thoát',
                        onPressed: () async {
                          if (await _confirmExit() && context.mounted) Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bài ${lesson.number}: ${lesson.title}',
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: PQText.h3.copyWith(fontSize: 18)),
                            const SizedBox(height: 4),
                            ChunkyProgress(value: (_index + (_canContinue ? 1 : 0)) / lesson.steps.length, color: PQColors.pyBlue, height: 14),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${_index + 1}/${lesson.steps.length}', style: PQText.number.copyWith(fontSize: 18)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    key: ValueKey('step_scroll_$_index'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: KeyedSubtree(key: ValueKey(step.id), child: _stepBody(step)),
                    ),
                  ),
                ),
                _bottomBar(step),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepBody(LessonStep step) {
    switch (step) {
      case StoryStep s:
        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            children: [
              CharacterView(id: s.speaker, size: 150, mood: s.mood),
              const SizedBox(height: 10),
              PQPanel(child: Text(s.text, key: const ValueKey('story_text'), style: PQText.bodyStrong.copyWith(fontSize: 18))),
            ],
          ),
        );
      case ExampleStep e:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SpeechBubble(character: CharacterId.py, text: e.text, portraitSize: 70),
            const SizedBox(height: 12),
            CodeView(code: e.code, errorLine: _run?.errorLine),
            const SizedBox(height: 10),
            ChunkyButton(
              key: const ValueKey('example_run'),
              label: _run == null ? 'Chạy thử' : 'Chạy lại',
              icon: Icons.play_arrow_rounded,
              tone: PQTone.grass,
              size: ChunkySize.medium,
              onPressed: _running
                  ? null
                  : () async {
                      final r = await _execute(e.code);
                      if (!mounted) return;
                      AppScope.of(context).audio.play(r.success ? Sfx.sparkle : Sfx.bonk);
                      setState(() {
                        _run = r;
                        _canContinue = true;
                      });
                    },
            ),
            const SizedBox(height: 10),
            if (_run != null) OutputConsole(result: _run),
          ],
        );
      case ChoiceStep c:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(c.question, style: PQText.h3),
            if (c.code != null) ...[const SizedBox(height: 10), CodeView(code: c.code!)],
            const SizedBox(height: 12),
            for (var i = 0; i < c.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OptionCard(
                  key: ValueKey('choice_$i'),
                  text: c.options[i],
                  code: c.options[i].contains('(') || c.options[i].contains('"') || c.options[i].contains('\n'),
                  selected: _choice == i,
                  state: _feedback == _Feedback.correct && i == c.answer
                      ? _OptionState.correct
                      : (_feedback == _Feedback.wrong && _choice == i ? _OptionState.wrong : _OptionState.idle),
                  onTap: _feedback == _Feedback.correct
                      ? null
                      : () => setState(() {
                            _choice = i;
                            _feedback = _Feedback.none;
                          }),
                ),
              ),
          ],
        );
      case FillStep f:
        final code = f.build(_picks);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(f.prompt, style: PQText.h3),
            const SizedBox(height: 4),
            _ExpectedBox(expected: f.expectedOutput),
            const SizedBox(height: 10),
            CodeView(code: code.replaceAll('___', '▢▢▢'), errorLine: _run?.errorLine),
            const SizedBox(height: 12),
            Text('Chạm mảnh ghép để đặt vào chỗ trống:', style: PQText.small),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _fillOptions.length; i++)
                  _TokenChip(
                    key: ValueKey('fill_option_$i'),
                    text: _fillOptions[i],
                    used: _picks.contains(_fillOptions[i]),
                    onTap: _feedback == _Feedback.correct ? null : () => _pickToken(_fillOptions[i]),
                  ),
              ],
            ),
            if (_picks.any((p) => p != null) && _feedback != _Feedback.correct)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _picks = List.filled(_picks.length, null);
                    _feedback = _Feedback.none;
                  }),
                  icon: const Icon(Icons.undo_rounded, color: PQColors.inkSoft),
                  label: Text('Bỏ chọn', style: PQText.small),
                ),
              ),
            if (_run != null) ...[const SizedBox(height: 8), OutputConsole(result: _run)],
          ],
        );
      case OrderStep o:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(o.prompt, style: PQText.h3),
            const SizedBox(height: 4),
            _ExpectedBox(expected: o.expectedOutput),
            const SizedBox(height: 10),
            Text('Chương trình của bạn:', style: PQText.small),
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(minHeight: 60),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: PQColors.codeBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PQColors.ink, width: 2.4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_orderPicked.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('Chạm các dòng bên dưới theo thứ tự...', style: PQText.code.copyWith(color: PQColors.codeComment, fontSize: 14)),
                    ),
                  for (var k = 0; k < _orderPicked.length; k++)
                    GestureDetector(
                      key: ValueKey('order_placed_$k'),
                      onTap: _feedback == _Feedback.correct
                          ? null
                          : () => setState(() {
                                _orderPicked.removeAt(k);
                                _feedback = _Feedback.none;
                              }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 26,
                              child: Text('${k + 1}', style: PQText.code.copyWith(color: PQColors.codeLine, fontSize: 14)),
                            ),
                            Expanded(
                              child: Text.rich(
                                TextSpan(children: highlightPython(_orderPool[_orderPicked[k]], PQText.code.copyWith(fontSize: 15))),
                                style: PQText.code.copyWith(fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _orderPool.length; i++)
              if (!_orderPicked.contains(i))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _OptionCard(
                    key: ValueKey('order_line_$i'),
                    text: _orderPool[i],
                    code: true,
                    selected: false,
                    state: _OptionState.idle,
                    onTap: () => setState(() {
                      _orderPicked.add(i);
                      _feedback = _Feedback.none;
                      AppScope.of(context).audio.play(Sfx.pop);
                    }),
                  ),
                ),
            if (_run != null) ...[const SizedBox(height: 8), OutputConsole(result: _run)],
          ],
        );
      case WriteStep w:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SpeechBubble(character: CharacterId.py, text: w.prompt, portraitSize: 64),
            const SizedBox(height: 10),
            if (w.expectedOutput != null) ...[_ExpectedBox(expected: w.expectedOutput!), const SizedBox(height: 10)],
            CodeEditor(controller: _code!, errorLine: _run?.errorLine, minLines: 4),
            if (_stepFails >= 2 && w.hint.isNotEmpty) ...[
              const SizedBox(height: 10),
              _HintBox(text: w.hint),
            ],
            const SizedBox(height: 10),
            OutputConsole(result: _run),
          ],
        );
      case RobotStep r:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SpeechBubble(character: CharacterId.robo, text: r.prompt, portraitSize: 64),
            const SizedBox(height: 8),
            SizedBox(height: 170, child: _RobotRunner(key: _robotKey, rows: r.rows, code: _code!, onFinished: _onRobotFinished, execute: _execute)),
            const SizedBox(height: 8),
            CodeEditor(
              controller: _code!,
              errorLine: _run?.errorLine,
              minLines: 3,
              extraKeys: const [
                CodeKey('right()', 'right()'),
                CodeKey('down()', 'down()'),
                CodeKey('left()', 'left()'),
                CodeKey('up()', 'up()'),
              ],
            ),
            if (_stepFails >= 2 && r.hint.isNotEmpty) ...[const SizedBox(height: 10), _HintBox(text: r.hint)],
            if (_run != null && !_run!.success) ...[const SizedBox(height: 8), ErrorCard(result: _run!, helper: CharacterId.robo)],
          ],
        );
    }
  }

  void _pickToken(String token) {
    final used = _picks.indexOf(token);
    setState(() {
      _feedback = _Feedback.none;
      if (used >= 0) {
        _picks[used] = null;
      } else {
        final empty = _picks.indexOf(null);
        if (empty >= 0) _picks[empty] = token;
      }
    });
    AppScope.of(context).audio.play(Sfx.pop);
  }

  Widget _bottomBar(LessonStep step) {
    final isExercise = step.isExercise;
    final ready = switch (step) {
      ChoiceStep _ => _choice != null,
      FillStep _ => !_picks.contains(null),
      OrderStep _ => _orderPicked.length == _orderPool.length,
      WriteStep _ => (_code?.text.trim().isNotEmpty ?? false),
      RobotStep _ => true,
      _ => true,
    };
    final showFeedback = _feedback != _Feedback.none;
    final hint = _feedback == _Feedback.wrong && _stepFails >= 3 ? _hintFor(step) : null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: !showFeedback ? Colors.transparent : (_feedback == _Feedback.correct ? const Color(0xFFDDF5D2) : const Color(0xFFFFE6DC)),
        border: showFeedback ? const Border(top: BorderSide(color: PQColors.ink, width: 2.4)) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showFeedback) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_feedback == _Feedback.correct ? Icons.check_circle_rounded : Icons.error_rounded,
                    color: _feedback == _Feedback.correct ? PQColors.success : PQColors.coralDeep, size: 30),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _feedbackText,
                    key: const ValueKey('feedback_text'),
                    style: PQText.bodyStrong.copyWith(
                      fontSize: 16,
                      color: _feedback == _Feedback.correct ? PQColors.successDeep : PQColors.coralDeep,
                    ),
                  ),
                ),
              ],
            ),
            if (hint != null && hint.isNotEmpty) ...[const SizedBox(height: 6), Text('Gợi ý: $hint', style: PQText.body.copyWith(fontSize: 15))],
            const SizedBox(height: 10),
          ],
          if (_canContinue || !isExercise)
            ChunkyButton(
              key: const ValueKey('lesson_continue'),
              label: _index == widget.lesson.steps.length - 1 ? 'Hoàn thành bài học' : 'Tiếp tục',
              icon: Icons.arrow_forward_rounded,
              tone: PQTone.grass,
              expand: true,
              onPressed: (_canContinue || step is StoryStep) ? _next : null,
            )
          else
            ChunkyButton(
              key: const ValueKey('lesson_check'),
              label: step is WriteStep || step is RobotStep ? 'Chạy và kiểm tra' : 'Kiểm tra',
              icon: step is WriteStep || step is RobotStep ? Icons.play_arrow_rounded : Icons.check_rounded,
              tone: PQTone.py,
              expand: true,
              sfx: null,
              onPressed: ready && !_running ? _check : null,
            ),
        ],
      ),
    );
  }
}

enum _OptionState { idle, correct, wrong }

class _OptionCard extends StatelessWidget {
  const _OptionCard({super.key, required this.text, required this.code, required this.selected, required this.state, required this.onTap});
  final String text;
  final bool code;
  final bool selected;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _OptionState.correct => const Color(0xFFDDF5D2),
      _OptionState.wrong => const Color(0xFFFFE0D6),
      _OptionState.idle => selected ? const Color(0xFFFFF1C2) : PQColors.cream,
    };
    final border = switch (state) {
      _OptionState.correct => PQColors.success,
      _OptionState.wrong => PQColors.coralDeep,
      _OptionState.idle => selected ? PQColors.sunDeep : PQColors.ink,
    };
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: selected || state != _OptionState.idle ? 3 : 2.2),
          boxShadow: [BoxShadow(color: PQColors.ink.withValues(alpha: 0.15), offset: const Offset(0, 3), blurRadius: 0)],
        ),
        child: code
            ? Text.rich(TextSpan(children: highlightPython(text, PQText.code.copyWith(fontSize: 16, color: PQColors.ink))),
                style: PQText.code.copyWith(fontSize: 16, color: PQColors.ink))
            : Text(text, style: PQText.bodyStrong),
      ),
    );
  }
}

class _TokenChip extends StatelessWidget {
  const _TokenChip({super.key, required this.text, required this.used, required this.onTap});
  final String text;
  final bool used;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: used ? 0.35 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: PQColors.codeBgSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PQColors.ink, width: 2.2),
            boxShadow: const [BoxShadow(color: PQColors.ink, offset: Offset(0, 3), blurRadius: 0)],
          ),
          child: Text(text, style: PQText.code.copyWith(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _ExpectedBox extends StatelessWidget {
  const _ExpectedBox({required this.expected});
  final String expected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6D9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PQColors.sunDeep, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.flag_rounded, color: PQColors.sunDeep),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kết quả cần in ra:', style: PQText.small.copyWith(color: PQColors.sunDeep, fontWeight: FontWeight.w900)),
                Text(expected, style: PQText.code.copyWith(fontSize: 15, color: PQColors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HintBox extends StatelessWidget {
  const _HintBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return PQPanel(
      color: const Color(0xFFE8F1FF),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, color: PQColors.sunDeep),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: PQText.body.copyWith(fontSize: 15.5))),
        ],
      ),
    );
  }
}

/// Small maze + robot driven by the child's Python code (lessons 11–12).
class _RobotRunner extends StatefulWidget {
  const _RobotRunner({super.key, required this.rows, required this.code, required this.onFinished, required this.execute});
  final List<String> rows;
  final PythonCodeController code;
  final Future<void> Function(bool reached, String code, ExecutionResult? result) onFinished;
  final Future<ExecutionResult> Function(String code, {ExecutionContext? execContext}) execute;

  @override
  State<_RobotRunner> createState() => _RobotRunnerState();
}

class _RobotRunnerState extends State<_RobotRunner> with TickerProviderStateMixin {
  late final MazeLevel _level =
      MazeLevel.fromRows(id: 'lesson', title: '', rows: widget.rows, commandLimit: 99, allowLoops: true);
  late final MazePlayback _pb = MazePlayback(_level)..reset(_level);
  late final AnimationController _time = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  bool _busy = false;

  @override
  void dispose() {
    _time.dispose();
    _pb.dispose();
    super.dispose();
  }

  Future<void> run() async {
    if (_busy) return;
    _busy = true;
    FocusScope.of(context).unfocus();
    _pb.reset(_level);
    final sim = MazeSimulation(_level);
    final code = widget.code.text;
    final result = await widget.execute(code,
        execContext: ExecutionContext(hostFunctions: {
          for (final d in Dir.values)
            d.py: (args) {
              if (!sim.move(d)) throw HostHalt('stop');
              return null;
            },
          'at_chest': (args) => sim.position == _level.goal,
        }));
    final ok = result.success || result.errorKind == ExecutionErrorKind.halted;
    if (!mounted) return;
    if (ok) {
      final audio = AppScope.of(context).audio;
      var pos = _level.start;
      for (final d in sim.moves) {
        if (!mounted) return;
        final next = Cell(pos.x + d.dx, pos.y + d.dy);
        final blocked = !_level.inside(next) || _level.tileAt(next) == Tile.wall;
        const frames = 8;
        for (var f = 1; f <= frames; f++) {
          await Future<void>.delayed(const Duration(milliseconds: 34));
          final t = f / frames;
          final target = Offset(next.x.toDouble(), next.y.toDouble());
          final from = Offset(pos.x.toDouble(), pos.y.toDouble());
          _pb.robot = blocked ? Offset.lerp(from, target, 0.3 * (1 - (t - 0.5).abs() * 2))! : Offset.lerp(from, target, t)!;
          _pb.hop = blocked ? 0 : (1 - (t * 2 - 1).abs()) * 0.5;
          _pb.update();
        }
        if (blocked) {
          _pb.crashCell = next;
          _pb.mood = Mood.sad;
          audio.play(Sfx.bonk);
          break;
        }
        pos = next;
        _pb.trail.add(pos);
        if (_level.tileAt(pos) == Tile.water) {
          _pb.sink = 1;
          audio.play(Sfx.splash);
          break;
        }
        audio.play(Sfx.step, volume: 0.6);
      }
      if (sim.outcome == RunOutcome.win) {
        _pb.chestOpen = true;
        _pb.mood = Mood.happy;
        _pb.update();
      }
    }
    _busy = false;
    await widget.onFinished(sim.outcome == RunOutcome.win, code, result);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: MazeBoardPainter(level: _level, playback: _pb, time: _time), size: Size.infinite);
  }
}
