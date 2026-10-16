import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/core/config/game_config.dart';
import 'package:pyquest/modules/bug_hunter/bug_models.dart';
import 'package:pyquest/modules/main_quest/answer_check.dart';
import 'package:pyquest/modules/main_quest/quest_models.dart';
import 'package:pyquest/modules/robot_maze/maze_models.dart';
import 'package:pyquest/python_runtime/python_runtime.dart';
import 'package:pyquest/python_runtime/simulated_runtime.dart';

/// Content is data; these tests prove every level, lesson and puzzle that
/// ships is actually solvable with the in-app engines.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final runtime = SimulatedPythonRuntime();

  ({bool reached, ExecutionResult result}) runRobot(List<String> rows, String code) {
    final level = MazeLevel.fromRows(id: 't', title: 't', rows: rows, commandLimit: 99, allowLoops: true);
    final sim = MazeSimulation(level);
    final result = runtime.executeSync(code,
        context: ExecutionContext(hostFunctions: {
          for (final d in Dir.values)
            d.py: (args) {
              if (!sim.move(d)) throw HostHalt('stop');
              return null;
            },
          'at_chest': (args) => sim.position == level.goal,
        }));
    return (reached: sim.outcome == RunOutcome.win, result: result);
  }

  test('game config loads with sane values', () async {
    final config = await GameConfig.load(rootBundle);
    expect(config.energyMaxInitial, 20);
    expect(config.cost('mini_game_new_level'), 2);
    expect(config.cost('creator_mode'), 0);
    expect(config.pythonLimits.stepBudget, 100000);
  });

  test('every Robot Maze level is solvable with all gems inside its command limit', () async {
    final content = await RobotMazeContent.load(rootBundle);
    expect(content.levels, hasLength(10));
    for (final level in content.levels) {
      final steps = expandProgram(level.solution).map((s) => s.dir).toList();
      final run = MazeSimulation.runMoves(level, steps);
      final stars = MazeStars.evaluate(level, run, commandCount(level.solution));
      expect(stars.count, 3, reason: '${level.id} reference solution should earn 3 stars');
      if (level.index >= 5) expect(level.allowLoops, isTrue);
    }
  });

  test('maze engine reports crashes, water and short programs', () async {
    final level = MazeLevel.fromRows(id: 'x', title: 'x', rows: ['S.~', '#.C'], commandLimit: 3, allowLoops: false);
    expect(MazeSimulation.runMoves(level, [Dir.down]).outcome, RunOutcome.wall);
    expect(MazeSimulation.runMoves(level, [Dir.up]).outcome, RunOutcome.edge);
    expect(MazeSimulation.runMoves(level, [Dir.right, Dir.right]).outcome, RunOutcome.water);
    expect(MazeSimulation.runMoves(level, [Dir.right]).outcome, RunOutcome.notThere);
    expect(MazeSimulation.runMoves(level, [Dir.right, Dir.down, Dir.right]).won, isTrue);
    expect(programToPython([MoveBlock(Dir.right), RepeatBlock(3, [Dir.down])]), 'right()\nfor i in range(3):\n    down()');
  });

  test('every Main Quest exercise is solvable and matches the expected output', () async {
    final content = await MainQuestContent.load(rootBundle);
    expect(content.lessons, hasLength(12));
    for (final lesson in content.lessons) {
      for (final step in lesson.steps) {
        switch (step) {
          case ExampleStep e:
            final r = runtime.executeSync(e.code);
            // Lesson 6 intentionally shows a TypeError example.
            if (e.id != 'mq1_06_s3') expect(r.success, isTrue, reason: '${e.id}: ${r.errorMessage}');
          case FillStep f:
            final r = runtime.executeSync(f.build([for (final b in f.blanks) b.first]));
            expect(compareOutput(r.output, f.expectedOutput), OutputMatch.exact, reason: '${f.id}: ${r.output} ${r.errorMessage}');
          case OrderStep o:
            final r = runtime.executeSync(o.lines.join('\n'));
            expect(compareOutput(r.output, o.expectedOutput), OutputMatch.exact, reason: o.id);
          case WriteStep w:
            final r = runtime.executeSync(w.solution);
            expect(r.success, isTrue, reason: '${w.id}: ${r.errorMessage}');
            if (w.expectedOutput != null) {
              expect(compareOutput(r.output, w.expectedOutput!), OutputMatch.exact, reason: w.id);
            }
            expect(missingParts(w.solution, w.mustContain), isEmpty, reason: w.id);
          case RobotStep r:
            final run = runRobot(r.rows, r.solution);
            expect(run.reached, isTrue, reason: r.id);
          case ChoiceStep c:
            expect(c.answer, inInclusiveRange(0, c.options.length - 1));
          case StoryStep _:
            break;
        }
      }
    }
  });

  test('lenient comparison accepts missing diacritics but not wrong text', () {
    expect(compareOutput('Robo thong minh', 'Robo thông minh'), OutputMatch.loose);
    expect(compareOutput('Robo thông minh\n', 'Robo thông minh'), OutputMatch.exact);
    expect(compareOutput('Robo', 'Robo thông minh'), OutputMatch.wrong);
  });

  test('every Bug Hunter puzzle: buggy fails, correct fixes pass, wrong fixes fail', () async {
    final content = await BugHunterContent.load(rootBundle);
    expect(content.totalBugs, 20);
    for (final p in content.puzzles) {
      final buggy = runtime.executeSync(p.code.join('\n'));
      expect(buggy.success && compareOutput(buggy.output, p.expectedOutput) == OutputMatch.exact, isFalse, reason: p.id);
      final fixed = List.of(p.code);
      for (final b in p.bugs) {
        fixed[b.line - 1] = b.correct;
      }
      final good = runtime.executeSync(fixed.join('\n'));
      expect(compareOutput(good.output, p.expectedOutput), OutputMatch.exact, reason: '${p.id}: ${good.errorMessage}');
      for (final b in p.bugs) {
        for (final wrong in b.options.skip(1)) {
          final trial = List.of(fixed)..[b.line - 1] = wrong;
          final r = runtime.executeSync(trial.join('\n'));
          expect(r.success && compareOutput(r.output, p.expectedOutput) == OutputMatch.exact, isFalse,
              reason: '${p.id} wrong option "$wrong" must not pass');
        }
      }
    }
  });
}
