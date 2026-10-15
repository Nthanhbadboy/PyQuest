import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
import '../../shared/widgets/game_icons.dart';
import '../../shared/widgets/result_screen.dart';
import '../energy/energy_widgets.dart';
import 'maze_board.dart';
import 'maze_models.dart';

enum _Phase { editing, running, won, failed }

/// Plays one maze with command blocks (and, in Creator Mode, with Python).
class MazePlayScreen extends StatefulWidget {
  const MazePlayScreen({super.key, required this.level, this.customId, this.startInCode = false});

  final MazeLevel level;

  /// Set when playing a self-made maze from the workshop (Creator Mode).
  final int? customId;
  final bool startInCode;

  bool get isCustom => customId != null;

  @override
  State<MazePlayScreen> createState() => _MazePlayScreenState();
}

class _MazePlayScreenState extends State<MazePlayScreen> with TickerProviderStateMixin {
  late final MazePlayback _pb = MazePlayback(widget.level)..reset(widget.level);
  late final AnimationController _time = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final AnimationController _run = AnimationController(vsync: this);
  final ScrollController _stripScroll = ScrollController();

  List<Block> _program = [];
  RepeatBlock? _openLoop;
  final List<List<Block>> _history = [];
  _Phase _phase = _Phase.editing;
  int _fails = 0;
  int _attempts = 0;
  String? _message;
  Mood _messageMood = Mood.neutral;
  bool _showPython = false;

  // Code mode (Creator Mode only)
  late bool _codeMode = widget.startInCode && widget.isCustom;
  final PythonCodeController _code = PythonCodeController(text: '# Điều khiển Robo bằng Python\nright()\n');
  ExecutionResult? _codeResult;
  bool _hadLimitError = false;

  // Run state
  List<_AnimStep> _anim = [];
  int _processed = 0;
  RunResult? _result;
  int _commandsUsed = 0;
  bool _usedLoop = false;

  MazeLevel get level => widget.level;

  @override
  void initState() {
    super.initState();
    _run.addListener(_onRunTick);
    _run.addStatusListener((s) {
      if (s == AnimationStatus.completed) _finishRun();
    });
    _message = level.story.isEmpty ? null : level.story;
    _messageMood = Mood.happy;
  }

  @override
  void dispose() {
    _run.dispose();
    _time.dispose();
    _pb.dispose();
    _stripScroll.dispose();
    _code.dispose();
    super.dispose();
  }

  int get _stepMs => AppScope.of(context).config.gameInt('robot_maze', 'step_ms', 380);

  // ------------------------------------------------------------ editing

  List<Block> _clone(List<Block> p) => [
        for (final b in p) b is RepeatBlock ? RepeatBlock(b.times, List.of(b.body)) : b,
      ];

  void _remember() {
    _history.add(_clone(_program));
    if (_history.length > 40) _history.removeAt(0);
  }

  void _resetBoardIfNeeded() {
    if (_phase == _Phase.won || _phase == _Phase.failed) {
      _phase = _Phase.editing;
      _pb.reset(level);
    }
  }

  void _addMove(Dir d) {
    if (_phase == _Phase.running) return;
    AppScope.of(context).audio.play(Sfx.pop);
    setState(() {
      _resetBoardIfNeeded();
      _remember();
      if (_openLoop != null) {
        if (_openLoop!.body.length < 6) _openLoop!.body.add(d);
      } else if (commandCount(_program) < 30) {
        _program.add(MoveBlock(d));
      }
    });
    _scrollStripToEnd();
  }

  void _addLoop() {
    if (_phase == _Phase.running || _openLoop != null) return;
    AppScope.of(context).audio.play(Sfx.pop);
    setState(() {
      _resetBoardIfNeeded();
      _remember();
      final loop = RepeatBlock(2);
      _program.add(loop);
      _openLoop = loop;
    });
    _scrollStripToEnd();
  }

  void _closeLoop() {
    setState(() {
      if (_openLoop != null && _openLoop!.body.isEmpty) {
        _program.remove(_openLoop);
      }
      _openLoop = null;
    });
  }

  void _removeAt(int index) {
    if (_phase == _Phase.running) return;
    AppScope.of(context).audio.play(Sfx.tap);
    setState(() {
      _resetBoardIfNeeded();
      _remember();
      final removed = _program.removeAt(index);
      if (identical(removed, _openLoop)) _openLoop = null;
    });
  }

  void _removeInner(RepeatBlock loop, int index) {
    if (_phase == _Phase.running) return;
    setState(() {
      _resetBoardIfNeeded();
      _remember();
      loop.body.removeAt(index);
    });
  }

  void _cycleTimes(RepeatBlock loop) {
    if (_phase == _Phase.running) return;
    AppScope.of(context).audio.play(Sfx.tap);
    setState(() {
      _resetBoardIfNeeded();
      _remember();
      loop.times = loop.times >= 9 ? 2 : loop.times + 1;
    });
  }

  void _undo() {
    if (_phase == _Phase.running || _history.isEmpty) return;
    setState(() {
      _resetBoardIfNeeded();
      _program = _history.removeLast();
      _openLoop = null;
    });
  }

  void _clear() {
    if (_phase == _Phase.running || _program.isEmpty) return;
    setState(() {
      _resetBoardIfNeeded();
      _remember();
      _program = [];
      _openLoop = null;
    });
  }

  void _scrollStripToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_stripScroll.hasClients) {
        _stripScroll.animateTo(_stripScroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  // -------------------------------------------------------------- running

  Future<void> _runProgram() async {
    if (_phase == _Phase.running) return;
    final services = AppScope.of(context);
    List<Dir> moves;
    List<StepRef?> refs;
    if (_codeMode) {
      FocusScope.of(context).unfocus();
      final sim = MazeSimulation(level);
      final result = await services.python.execute(_code.text,
          context: ExecutionContext(hostFunctions: {
            for (final d in Dir.values)
              d.py: (args) {
                if (!sim.move(d)) throw HostHalt(sim.outcome == RunOutcome.win ? 'win' : 'stop');
                return null;
              },
            'at_chest': (args) => sim.position == level.goal,
            'gems_left': (args) => level.gems.length - sim.gems.length,
          }));
      if (!mounted) return;
      final codeOk = result.success || (result.errorKind == ExecutionErrorKind.halted);
      final recovered = codeOk && _hadLimitError;
      if (result.hitLimit) _hadLimitError = true;
      if (recovered) _hadLimitError = false;
      final outcome = await services.events.emit(StandardEvent(
        type: EventTypes.codeRun,
        sourceId: 'robot_maze',
        data: {'success': codeOk && sim.outcome == RunOutcome.win, 'context': 'robot', 'recovered_from_limit': recovered},
      ));
      if (!mounted) return;
      _pendingNotices.addAll(outcome.notices);
      setState(() => _codeResult = (result.errorKind == ExecutionErrorKind.halted) ? null : result);
      if (!codeOk) {
        services.audio.play(Sfx.fail);
        setState(() {
          _message = 'Code có lỗi nên Robo chưa chạy được. Đọc lời nhắc bên dưới nhé!';
          _messageMood = Mood.thinking;
        });
        return;
      }
      moves = List.of(sim.moves);
      refs = List.filled(moves.length, null);
      _commandsUsed = _countCodeCommands(_code.text);
      _usedLoop = RegExp(r'^\s*(for|while)\b', multiLine: true).hasMatch(_code.text);
    } else {
      if (_openLoop != null) _closeLoop();
      if (_program.isEmpty) {
        services.audio.play(Sfx.bonk);
        setState(() {
          _message = 'Chưa có lệnh nào! Bấm các mũi tên để xếp đường đi cho Robo.';
          _messageMood = Mood.thinking;
        });
        return;
      }
      final steps = expandProgram(_program);
      moves = [for (final s in steps) s.dir];
      refs = steps;
      _commandsUsed = commandCount(_program);
      _usedLoop = usesLoop(_program);
    }
    _attempts++;
    _result = MazeSimulation.runMoves(level, moves);
    _buildAnimation(moves, refs, _result!);
    _pb.reset(level);
    _pb.hintCells = const [];
    _pb.highlightCell = null;
    _pb.mood = Mood.happy;
    setState(() {
      _phase = _Phase.running;
      _message = null;
    });
    _processed = 0;
    _run.duration = Duration(milliseconds: _stepMs * _anim.length + 500);
    await _run.forward(from: 0);
  }

  final List<RewardNotice> _pendingNotices = [];

  int _countCodeCommands(String code) {
    return code
        .split('\n')
        .where((l) => l.trim().isNotEmpty && !l.trim().startsWith('#'))
        .length;
  }

  void _buildAnimation(List<Dir> moves, List<StepRef?> refs, RunResult result) {
    _anim = [];
    var pos = level.start;
    final executed = result.won || result.outcome == RunOutcome.notThere ? result.path.length - 1 : result.failStep + 1;
    for (var i = 0; i < executed && i < moves.length; i++) {
      final d = moves[i];
      final next = Cell(pos.x + d.dx, pos.y + d.dy);
      final isLast = i == executed - 1;
      _AnimKind kind = _AnimKind.move;
      if (isLast) {
        switch (result.outcome) {
          case RunOutcome.wall:
          case RunOutcome.edge:
            kind = _AnimKind.bonk;
          case RunOutcome.water:
            kind = _AnimKind.sink;
          case RunOutcome.win:
            kind = _AnimKind.win;
          case RunOutcome.notThere:
          case RunOutcome.tooLong:
            kind = _AnimKind.move;
        }
      }
      _anim.add(_AnimStep(pos, next, kind, i < refs.length ? refs[i] : null));
      if (kind != _AnimKind.bonk) pos = next;
    }
  }

  void _onRunTick() {
    if (_anim.isEmpty) return;
    final elapsed = _run.value * (_run.duration?.inMilliseconds ?? 1);
    final idx = (elapsed / _stepMs).floor();
    final t = ((elapsed % _stepMs) / _stepMs).clamp(0.0, 1.0);
    final audio = AppScope.of(context).audio;
    // Fire effects for steps that just finished.
    while (_processed < _anim.length && _processed < idx) {
      final s = _anim[_processed];
      if (s.kind != _AnimKind.bonk) {
        _pb.trail.add(s.to);
        if (level.gems.contains(s.to) && !_pb.collected.contains(s.to)) {
          _pb.collected.add(s.to);
          audio.play(Sfx.sparkle);
        } else if (s.kind == _AnimKind.move) {
          audio.play(Sfx.step, volume: 0.6);
        }
      }
      if (s.kind == _AnimKind.win) {
        _pb.chestOpen = true;
        _pb.mood = Mood.happy;
        audio.play(Sfx.coin);
      }
      _processed++;
    }
    if (idx >= _anim.length) {
      final last = _anim.last;
      if (last.kind == _AnimKind.sink) {
        _pb.robot = Offset(last.to.x.toDouble(), last.to.y.toDouble());
        _pb.sink = 1;
      } else if (last.kind == _AnimKind.win) {
        _pb.hop = (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
      }
      _pb.update();
      return;
    }
    final s = _anim[idx];
    final from = Offset(s.from.x.toDouble(), s.from.y.toDouble());
    final to = Offset(s.to.x.toDouble(), s.to.y.toDouble());
    switch (s.kind) {
      case _AnimKind.move:
      case _AnimKind.win:
        final e = Curves.easeInOut.transform(t);
        _pb.robot = Offset.lerp(from, to, e)!;
        _pb.hop = (1 - (t * 2 - 1).abs()) * 0.6;
        _pb.shake = 0;
      case _AnimKind.bonk:
        final out = t < 0.4 ? t / 0.4 : 1 - (t - 0.4) / 0.6;
        _pb.robot = Offset.lerp(from, to, 0.32 * Curves.easeOut.transform(out.clamp(0.0, 1.0)))!;
        _pb.shake = t > 0.35 ? 1 : 0;
        _pb.hop = 0;
        if (t > 0.38 && _pb.mood != Mood.sad) {
          _pb.mood = Mood.sad;
          _pb.crashCell = s.to;
          audio.play(Sfx.bonk);
          HapticFeedback.mediumImpact();
        }
      case _AnimKind.sink:
        if (t < 0.6) {
          _pb.robot = Offset.lerp(from, to, Curves.easeInOut.transform(t / 0.6))!;
        } else {
          _pb.robot = to;
          if (_pb.sink == 0) audio.play(Sfx.splash);
          _pb.sink = ((t - 0.6) / 0.4).clamp(0.0, 1.0);
          _pb.mood = Mood.surprised;
        }
    }
    final ref = s.ref;
    if (ref != null && ref.blockIndex != _activeBlock) {
      setState(() => _activeBlock = ref.blockIndex);
    }
    _pb.update();
  }

  int? _activeBlock;

  Future<void> _finishRun() async {
    final result = _result;
    if (result == null || !mounted) return;
    _pb.shake = 0;
    setState(() => _activeBlock = null);
    if (result.won) {
      setState(() => _phase = _Phase.won);
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (mounted) await _onWin(result);
    } else {
      _fails++;
      final audio = AppScope.of(context).audio;
      audio.play(Sfx.fail);
      final cfg = AppScope.of(context).config;
      String msg = switch (result.outcome) {
        RunOutcome.wall => 'Ối! Robo đụng phải bụi cây rồi. Xem ô được tô đỏ nhé!',
        RunOutcome.edge => 'Ối! Robo suýt đi ra khỏi khu vườn. Kiểm tra lại hướng đi nhé!',
        RunOutcome.water => 'Ùm! Robo rơi xuống nước. Robo không biết bơi đâu!',
        RunOutcome.tooLong => 'Robo đi nhiều bước quá rồi (tối đa ${MazeSimulation.maxMoves} bước).',
        _ => 'Robo đã đi hết các lệnh nhưng chưa tới rương báu. Thêm vài bước nữa nhé!',
      };
      var mood = Mood.sad;
      if (_fails >= cfg.suggestPracticeAfterFails && level.index > 0 && !widget.isCustom) {
        msg += ' Nếu thấy khó, bạn có thể chơi lại màn trước để luyện thêm nhé.';
        _showStrongHint();
      } else if (_fails >= cfg.strongHintAfterFails) {
        msg += ' Gợi ý: các chấm vàng là vài bước đầu tiên.';
        _showStrongHint();
      } else if (_fails >= cfg.lightHintAfterFails && level.tip.isNotEmpty) {
        msg += ' Mẹo: ${level.tip}';
        mood = Mood.thinking;
      }
      setState(() {
        _phase = _Phase.failed;
        _message = msg;
        _messageMood = mood;
      });
    }
  }

  void _showStrongHint() {
    if (level.solution.isEmpty) return;
    final steps = expandProgram(level.solution).map((s) => s.dir).toList();
    final sim = MazeSimulation(level);
    final cells = <Cell>[];
    for (final d in steps.take(3)) {
      sim.move(d);
      cells.add(sim.position);
    }
    _pb.hintCells = cells;
  }

  void _showTip() {
    AppScope.of(context).audio.play(Sfx.pop);
    setState(() {
      _message = level.tip.isEmpty ? 'Hãy đếm số ô trước khi xếp lệnh nhé!' : level.tip;
      _messageMood = Mood.thinking;
    });
  }

  void _tryAgain() {
    setState(() {
      _phase = _Phase.editing;
      _pb.reset(level);
      _message = null;
    });
  }

  Future<void> _onWin(RunResult result) async {
    final services = AppScope.of(context);
    final stars = MazeStars.evaluate(level, result, _commandsUsed);
    final cfg = services.config;
    final score = stars.score(
      complete: cfg.gameInt('robot_maze', 'score_complete', 40),
      gems: cfg.gameInt('robot_maze', 'score_all_gems', 30),
      limit: cfg.gameInt('robot_maze', 'score_command_limit', 30),
    );
    final notices = <RewardNotice>[..._pendingNotices];
    _pendingNotices.clear();

    if (widget.isCustom) {
      final outcome = await services.events.emit(StandardEvent(
        type: EventTypes.creatorTestRun,
        sourceId: 'robot_maze',
        data: {'success': true},
      ));
      notices.addAll(outcome.notices);
      if (!mounted) return;
      Navigator.of(context).pop(_CustomRunReport(won: true, notices: notices, stars: stars.count));
      return;
    }

    // Different-path secret: compare the visited cells with the previous win.
    final signature = result.path.map((c) => '${c.x},${c.y}').join(';');
    final key = 'path:${level.id}';
    final previous = await services.store.getString('robot_maze', key);
    await services.store.setString('robot_maze', key, signature);
    final content = services.robotMaze;
    final next = level.index + 1 < content.levels.length ? content.levels[level.index + 1] : null;
    if (_usedLoop) {
      final o = await services.events.emit(StandardEvent(
        type: EventTypes.loopUsed,
        sourceId: 'robot_maze',
        data: {'key': 'robot_maze:${level.id}'},
      ));
      notices.addAll(o.notices);
    }
    final outcome = await services.events.emit(StandardEvent(
      type: EventTypes.levelCompleted,
      sourceId: 'robot_maze',
      data: {
        'level_id': level.id,
        'stars': stars.count,
        'score': score,
        if (next != null) 'next_level_id': next.id,
        'commands': _commandsUsed,
        'different_path': previous != null && previous != signature,
      },
    ));
    notices.addAll(outcome.notices);
    if (!mounted) return;
    final nextRecord = next == null ? null : await services.progress.levelRecord('robot_maze', next.id);
    if (!mounted) return;
    final nextCost = next == null
        ? 0
        : (nextRecord == null ? cfg.cost('mini_game_new_level') : cfg.cost('mini_game_replay_completed'));
    final gemsLabel = level.gems.isEmpty ? 'Không có đá quý ở màn này' : 'Nhặt đủ ${level.gems.length} đá quý';
    final action = await showLevelResult(
      context,
      LevelResultData(
        gameName: 'Mê Cung Robo',
        levelTitle: 'Màn ${level.index + 1}: ${level.title}',
        success: true,
        stars: stars.count,
        score: score,
        bestScore: outcome.bestScore,
        newBest: outcome.newHighScore,
        goals: [
          const ResultGoal('Đưa Robo tới rương báu', true),
          ResultGoal(gemsLabel, stars.allGems),
          ResultGoal('Dùng tối đa ${level.commandLimit} lệnh (bạn dùng $_commandsUsed)', stars.withinLimit),
        ],
        stats: [
          ResultStat('Số lệnh', '$_commandsUsed'),
          ResultStat('Đá quý', '${result.gems.length}/${level.gems.length}', icon: GameIconKind.gem),
          ResultStat('Lần chạy', '$_attempts'),
        ],
        skill: level.skill,
        host: CharacterId.robo,
        hostLine: _hostLine(stars),
        notices: notices,
        primaryLabel: next != null ? 'Màn tiếp theo' : null,
        primaryCost: nextCost,
        tone: PQTone.grass,
      ),
    );
    if (!mounted) return;
    switch (action) {
      case ResultAction.primary:
        if (next == null) {
          Navigator.of(context).pop();
          return;
        }
        if (!await spendEnergy(context, nextCost)) {
          if (mounted) Navigator.of(context).pop();
          return;
        }
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => MazePlayScreen(level: next)),
        );
      case ResultAction.replay:
        _tryAgain();
      case ResultAction.back:
        Navigator.of(context).pop();
      case ResultAction.map:
        Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  String _hostLine(MazeStars s) {
    if (s.count == 3) return 'Tuyệt vời! Chương trình của bạn vừa đúng vừa gọn gàng!';
    if (!s.allGems) return 'Mình tới rương rồi! Lần sau thử nhặt hết đá quý trên đường nhé.';
    if (!s.withinLimit) {
      return level.allowLoops
          ? 'Hay lắm! Thử dùng khối Lặp lại để chương trình ngắn hơn nhé.'
          : 'Hay lắm! Có con đường nào cần ít lệnh hơn không nhỉ?';
    }
    return 'Cảm ơn bạn đã giúp mình!';
  }

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    final title = widget.isCustom ? level.title : 'Màn ${level.index + 1}: ${level.title}';
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: PQBackground(
        top: const Color(0xFFCFF2C2),
        bottom: const Color(0xFFF6F0DA),
        child: SafeArea(
          child: Column(
            children: [
              PQTopBar(
                title: title,
                subtitle: widget.isCustom ? 'Xưởng Mê Cung · chạy thử' : 'Mê Cung Robo',
                tone: PQTone.grass,
                trailing: [
                  RoundIconButton(
                    key: const ValueKey('maze_hint'),
                    icon: Icons.lightbulb_rounded,
                    tooltip: 'Gợi ý',
                    tone: PQTone.sun,
                    size: 46,
                    onPressed: _showTip,
                  ),
                ],
              ),
              _GoalsRow(level: level, commands: _codeMode ? null : commandCount(_program), pb: _pb),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: CustomPaint(painter: MazeBoardPainter(level: level, playback: _pb, time: _time)),
                      ),
                    ),
                    if (_message != null)
                      Positioned(
                        left: 10,
                        right: 10,
                        top: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _message = null),
                          child: SpeechBubble(
                            key: const ValueKey('maze_message'),
                            character: CharacterId.robo,
                            text: _message!,
                            mood: _messageMood,
                            portraitSize: 58,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.isCustom) _modeSwitch(),
              if (_codeMode) _codePanel() else _blocksPanel(),
              _runRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeSwitch() {
    Widget seg(String label, bool code) {
      final active = _codeMode == code;
      return Expanded(
        child: GestureDetector(
          onTap: _phase == _Phase.running
              ? null
              : () {
                  setState(() {
                    if (code && !_codeMode && _program.isNotEmpty) {
                      _code.text = '${programToPython(_program)}\n';
                    }
                    _codeMode = code;
                  });
                  _tryAgain();
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: active ? PQColors.grape : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(label, style: PQText.label.copyWith(color: active ? Colors.white : PQColors.inkSoft, fontSize: 16)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: PQColors.cream,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: PQColors.ink, width: 2.2),
        ),
        child: Row(children: [seg('Khối lệnh', false), seg('Code Python', true)]),
      ),
    );
  }

  Widget _codePanel() {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.36),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CodeEditor(
              controller: _code,
              minLines: 4,
              errorLine: _codeResult?.errorLine,
              extraKeys: const [
                CodeKey('right()', 'right()'),
                CodeKey('left()', 'left()'),
                CodeKey('up()', 'up()'),
                CodeKey('down()', 'down()'),
                CodeKey('at_chest()', 'at_chest()'),
              ],
            ),
            if (_codeResult != null && !_codeResult!.success) ...[
              const SizedBox(height: 8),
              ErrorCard(result: _codeResult!, helper: CharacterId.robo),
            ],
          ],
        ),
      ),
    );
  }

  Widget _blocksPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _programStrip(),
          if (_showPython) ...[
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 130),
              child: SingleChildScrollView(child: CodeView(code: programToPython(_program), fontSize: 14)),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              for (final d in const [Dir.left, Dir.up, Dir.down, Dir.right]) ...[
                Expanded(
                  child: _PaletteButton(
                    key: ValueKey('palette_${d.name}'),
                    icon: d.icon,
                    label: d.label,
                    tone: PQTone.sky,
                    onTap: () => _addMove(d),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (level.allowLoops)
                Expanded(
                  child: _PaletteButton(
                    key: const ValueKey('palette_loop'),
                    icon: _openLoop == null ? Icons.repeat_rounded : Icons.check_rounded,
                    label: _openLoop == null ? 'Lặp lại' : 'Xong lặp',
                    tone: PQTone.grape,
                    onTap: _openLoop == null ? _addLoop : _closeLoop,
                  ),
                )
              else
                const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _programStrip() {
    final chips = <Widget>[];
    for (var i = 0; i < _program.length; i++) {
      final b = _program[i];
      final active = _activeBlock == i;
      switch (b) {
        case MoveBlock m:
          chips.add(_MoveChip(
            key: ValueKey('prog_$i'),
            dir: m.dir,
            active: active,
            onTap: () => _removeAt(i),
          ));
        case RepeatBlock r:
          chips.add(_LoopChip(
            key: ValueKey('prog_$i'),
            loop: r,
            open: identical(r, _openLoop),
            active: active,
            onTimes: () => _cycleTimes(r),
            onRemove: () => _removeAt(i),
            onRemoveInner: (j) => _removeInner(r, j),
          ));
      }
    }
    return Container(
      height: 72,
      padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
      decoration: BoxDecoration(
        color: PQColors.cream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PQColors.ink, width: 2.4),
      ),
      child: Row(
        children: [
          Expanded(
            child: _program.isEmpty
                ? Center(
                    child: Text('Chạm mũi tên bên dưới để xếp lệnh',
                        style: PQText.small.copyWith(color: PQColors.inkFaint), textAlign: TextAlign.center),
                  )
                : ListView(
                    controller: _stripScroll,
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final c in chips) Padding(padding: const EdgeInsets.only(right: 6), child: c),
                    ],
                  ),
          ),
          const SizedBox(width: 4),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniIcon(icon: Icons.undo_rounded, onTap: _undo, tooltip: 'Hoàn tác'),
              _MiniIcon(icon: Icons.delete_sweep_rounded, onTap: _clear, tooltip: 'Xoá hết'),
            ],
          ),
          const SizedBox(width: 2),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniIcon(
                icon: Icons.code_rounded,
                onTap: () => setState(() => _showPython = !_showPython),
                tooltip: 'Xem code Python',
                active: _showPython,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _runRow() {
    final running = _phase == _Phase.running;
    final failed = _phase == _Phase.failed;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: [
          if (failed) ...[
            Expanded(
              child: ChunkyButton(
                key: const ValueKey('maze_reset'),
                label: 'Về chỗ cũ',
                icon: Icons.replay_rounded,
                tone: PQTone.parchment,
                size: ChunkySize.medium,
                expand: true,
                onPressed: _tryAgain,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 2,
            child: ChunkyButton(
              key: const ValueKey('maze_run'),
              label: running ? 'Robo đang đi...' : (failed ? 'Chạy lại' : 'Chạy'),
              icon: Icons.play_arrow_rounded,
              tone: PQTone.grass,
              size: ChunkySize.medium,
              expand: true,
              sfx: null,
              onPressed: running || _phase == _Phase.won ? null : () => _runProgram(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Report returned to the workshop after a custom test run.
class _CustomRunReport {
  const _CustomRunReport({required this.won, required this.notices, required this.stars});
  final bool won;
  final List<RewardNotice> notices;
  final int stars;
}

/// Public view of the custom-run report.
typedef CustomRunReport = ({bool won, List<RewardNotice> notices});

CustomRunReport? readCustomRunReport(Object? value) {
  if (value is _CustomRunReport) return (won: value.won, notices: value.notices);
  return null;
}

enum _AnimKind { move, bonk, sink, win }

class _AnimStep {
  const _AnimStep(this.from, this.to, this.kind, this.ref);
  final Cell from;
  final Cell to;
  final _AnimKind kind;
  final StepRef? ref;
}

class _GoalsRow extends StatelessWidget {
  const _GoalsRow({required this.level, required this.commands, required this.pb});
  final MazeLevel level;
  final int? commands;
  final MazePlayback pb;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: pb,
      builder: (context, _) {
        final gemsDone = pb.collected.length;
        final c = commands;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
          child: Row(
            children: [
              _goal(const GameIcon(GameIconKind.chest, size: 20), 'Tới rương', pb.chestOpen),
              const SizedBox(width: 6),
              _goal(const GameIcon(GameIconKind.gem, size: 20),
                  level.gems.isEmpty ? 'Không có' : '$gemsDone/${level.gems.length}', level.gems.isEmpty || gemsDone == level.gems.length),
              const SizedBox(width: 6),
              Expanded(
                child: _goal(
                  const Icon(Icons.format_list_numbered_rounded, size: 20, color: PQColors.inkSoft),
                  c == null ? '≤ ${level.commandLimit} dòng' : '$c/${level.commandLimit} lệnh',
                  c != null && c > 0 && c <= level.commandLimit,
                  warn: c != null && c > level.commandLimit,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _goal(Widget icon, String label, bool done, {bool warn = false}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 10, 3),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFDDF5D2) : (warn ? const Color(0xFFFFE3D9) : PQColors.cream),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PQColors.ink, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StarIcon(filled: done, size: 18),
          const SizedBox(width: 3),
          icon,
          const SizedBox(width: 4),
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: PQText.small.copyWith(fontSize: 13.5))),
        ],
      ),
    );
  }
}

class _PaletteButton extends StatefulWidget {
  const _PaletteButton({super.key, required this.icon, required this.label, required this.tone, required this.onTap});
  final IconData icon;
  final String label;
  final PQTone tone;
  final VoidCallback onTap;

  @override
  State<_PaletteButton> createState() => _PaletteButtonState();
}

class _PaletteButtonState extends State<_PaletteButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: CustomPaint(
          painter: ChunkyPainter(tone: widget.tone, pressed: _down, depth: 5, radius: 16),
          child: Padding(
            padding: EdgeInsets.only(top: _down ? 5 : 0, bottom: _down ? 0 : 5),
            child: SizedBox(
              height: 58,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, color: Colors.white, size: 28),
                  Text(widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PQText.small.copyWith(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w900, height: 1.0)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoveChip extends StatelessWidget {
  const _MoveChip({super.key, required this.dir, required this.active, required this.onTap});
  final Dir dir;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 50,
        height: 56,
        decoration: BoxDecoration(
          color: active ? PQColors.sun : PQColors.sky,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PQColors.ink, width: active ? 3 : 2.2),
          boxShadow: [BoxShadow(color: active ? PQColors.sunDeep : PQColors.skyDeep, offset: const Offset(0, 3), blurRadius: 0)],
        ),
        child: Icon(dir.icon, color: active ? PQColors.ink : Colors.white, size: 30),
      ),
    );
  }
}

class _LoopChip extends StatelessWidget {
  const _LoopChip({
    super.key,
    required this.loop,
    required this.open,
    required this.active,
    required this.onTimes,
    required this.onRemove,
    required this.onRemoveInner,
  });

  final RepeatBlock loop;
  final bool open;
  final bool active;
  final VoidCallback onTimes;
  final VoidCallback onRemove;
  final ValueChanged<int> onRemoveInner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 3, 4, 3),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFFE89A) : const Color(0xFFE6DEFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: open ? PQColors.grapeDeep : PQColors.ink, width: open ? 3.4 : 2.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTimes,
            onLongPress: onRemove,
            child: Container(
              width: 46,
              decoration: BoxDecoration(
                color: PQColors.grape,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PQColors.ink, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.repeat_rounded, color: Colors.white, size: 20),
                  Text('×${loop.times}', style: PQText.number.copyWith(color: Colors.white, fontSize: 17)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          if (loop.body.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(open ? 'Thêm\nmũi tên' : 'Trống', style: PQText.small.copyWith(fontSize: 12, height: 1.1)),
            ),
          for (var j = 0; j < loop.body.length; j++)
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: GestureDetector(
                onTap: () => onRemoveInner(j),
                child: Container(
                  width: 38,
                  height: 44,
                  decoration: BoxDecoration(
                    color: PQColors.sky,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: PQColors.ink, width: 2),
                  ),
                  child: Icon(loop.body[j].icon, color: Colors.white, size: 24),
                ),
              ),
            ),
          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close_rounded, size: 18, color: PQColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  const _MiniIcon({required this.icon, required this.onTap, required this.tooltip, this.active = false});
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 26,
          decoration: BoxDecoration(
            color: active ? PQColors.pyBlue : PQColors.parchmentDeep,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: PQColors.ink, width: 1.8),
          ),
          child: Icon(icon, size: 18, color: active ? Colors.white : PQColors.ink),
        ),
      ),
    );
  }
}
