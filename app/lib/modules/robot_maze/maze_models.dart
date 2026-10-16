import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

typedef Cell = math.Point<int>;

enum Dir { up, down, left, right }

extension DirInfo on Dir {
  int get dx => switch (this) { Dir.left => -1, Dir.right => 1, _ => 0 };
  int get dy => switch (this) { Dir.up => -1, Dir.down => 1, _ => 0 };
  String get py => name; // up(), down(), left(), right()
  String get label => switch (this) { Dir.up => 'Lên', Dir.down => 'Xuống', Dir.left => 'Trái', Dir.right => 'Phải' };
  String get letter => switch (this) { Dir.up => 'U', Dir.down => 'D', Dir.left => 'L', Dir.right => 'R' };
  IconData get icon => switch (this) {
        Dir.up => Icons.arrow_upward_rounded,
        Dir.down => Icons.arrow_downward_rounded,
        Dir.left => Icons.arrow_back_rounded,
        Dir.right => Icons.arrow_forward_rounded,
      };

  static Dir fromLetter(String l) => switch (l) {
        'U' => Dir.up,
        'D' => Dir.down,
        'L' => Dir.left,
        _ => Dir.right,
      };
}

enum Tile { floor, wall, water }

class MazeLevel {
  MazeLevel({
    required this.id,
    required this.title,
    required this.story,
    required this.tip,
    required this.skill,
    required this.width,
    required this.height,
    required this.tiles,
    required this.start,
    required this.goal,
    required this.gems,
    required this.commandLimit,
    required this.allowLoops,
    this.solution = const [],
    this.index = 0,
  });

  final String id;
  final String title;
  final String story;
  final String tip;
  final String skill;
  final int width;
  final int height;
  final List<List<Tile>> tiles; // [y][x]
  final Cell start;
  final Cell goal;
  final Set<Cell> gems;
  final int commandLimit;
  final bool allowLoops;

  /// Reference solution (blocks) used for hints and tests. Never shown in full.
  final List<Block> solution;
  final int index;

  bool inside(Cell c) => c.x >= 0 && c.y >= 0 && c.x < width && c.y < height;
  Tile tileAt(Cell c) => tiles[c.y][c.x];

  static MazeLevel fromRows({
    required String id,
    required String title,
    required List<String> rows,
    required int commandLimit,
    required bool allowLoops,
    String story = '',
    String tip = '',
    String skill = '',
    String solution = '',
    int index = 0,
  }) {
    final height = rows.length;
    final width = rows.first.length;
    Cell? start;
    Cell? goal;
    final gems = <Cell>{};
    final tiles = <List<Tile>>[];
    for (var y = 0; y < height; y++) {
      final row = <Tile>[];
      for (var x = 0; x < width; x++) {
        final ch = x < rows[y].length ? rows[y][x] : '#';
        switch (ch) {
          case '#':
            row.add(Tile.wall);
          case '~':
            row.add(Tile.water);
          default:
            row.add(Tile.floor);
            if (ch == 'S') start = Cell(x, y);
            if (ch == 'C') goal = Cell(x, y);
            if (ch == '*') gems.add(Cell(x, y));
        }
      }
      tiles.add(row);
    }
    return MazeLevel(
      id: id,
      title: title,
      story: story,
      tip: tip,
      skill: skill,
      width: width,
      height: height,
      tiles: tiles,
      start: start ?? const Cell(0, 0),
      goal: goal ?? Cell(width - 1, height - 1),
      gems: gems,
      commandLimit: commandLimit,
      allowLoops: allowLoops,
      solution: parseProgramNotation(solution),
      index: index,
    );
  }

  List<String> toRows() {
    return [
      for (var y = 0; y < height; y++)
        [
          for (var x = 0; x < width; x++)
            () {
              final c = Cell(x, y);
              if (c == start) return 'S';
              if (c == goal) return 'C';
              if (gems.contains(c)) return '*';
              return switch (tiles[y][x]) { Tile.wall => '#', Tile.water => '~', Tile.floor => '.' };
            }(),
        ].join(),
    ];
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'rows': toRows(),
        'command_limit': commandLimit,
        'allow_loops': allowLoops,
      };

  static MazeLevel fromCustomJson(int id, Map<String, dynamic> json) => MazeLevel.fromRows(
        id: 'custom_$id',
        title: json['title'] as String? ?? 'Mê cung của tôi',
        rows: (json['rows'] as List).cast<String>(),
        commandLimit: (json['command_limit'] as num?)?.toInt() ?? 10,
        allowLoops: json['allow_loops'] as bool? ?? true,
        story: 'Mê cung do chính bạn thiết kế. Hãy chứng minh nó giải được!',
        tip: 'Bạn là người tạo ra mê cung này — bạn biết đường mà!',
        skill: 'Thiết kế trò chơi và kiểm tra rằng nó chơi được.',
      );
}

// ----------------------------------------------------------------- program

sealed class Block {
  const Block();
  int get commandCount;
}

class MoveBlock extends Block {
  const MoveBlock(this.dir);
  final Dir dir;
  @override
  int get commandCount => 1;
}

class RepeatBlock extends Block {
  RepeatBlock(this.times, [List<Dir>? body]) : body = body ?? <Dir>[];
  int times;
  final List<Dir> body;
  @override
  int get commandCount => 1 + body.length;
}

/// One executed step and the block it came from (for highlighting).
class StepRef {
  const StepRef(this.dir, this.blockIndex, [this.innerIndex]);
  final Dir dir;
  final int blockIndex;
  final int? innerIndex;
}

int commandCount(List<Block> blocks) => blocks.fold(0, (a, b) => a + b.commandCount);

bool usesLoop(List<Block> blocks) => blocks.any((b) => b is RepeatBlock && b.body.isNotEmpty && b.times > 1);

List<StepRef> expandProgram(List<Block> blocks) {
  final out = <StepRef>[];
  for (var i = 0; i < blocks.length; i++) {
    final b = blocks[i];
    switch (b) {
      case MoveBlock m:
        out.add(StepRef(m.dir, i));
      case RepeatBlock r:
        for (var t = 0; t < r.times; t++) {
          for (var j = 0; j < r.body.length; j++) {
            out.add(StepRef(r.body[j], i, j));
          }
        }
    }
  }
  return out;
}

/// Translates blocks into the equivalent PyQuest Python program.
String programToPython(List<Block> blocks) {
  if (blocks.isEmpty) return '# Chưa có lệnh nào';
  final buf = StringBuffer();
  for (final b in blocks) {
    switch (b) {
      case MoveBlock m:
        buf.writeln('${m.dir.py}()');
      case RepeatBlock r:
        buf.writeln('for i in range(${r.times}):');
        if (r.body.isEmpty) {
          buf.writeln('    pass');
        } else {
          for (final d in r.body) {
            buf.writeln('    ${d.py}()');
          }
        }
    }
  }
  return buf.toString().trimRight();
}

/// Parses the compact notation used in level files: `R R 3[D L] U`.
List<Block> parseProgramNotation(String text) {
  final blocks = <Block>[];
  final re = RegExp(r'(\d+)\[([UDLR ]+)\]|([UDLR])');
  for (final m in re.allMatches(text)) {
    if (m.group(1) != null) {
      final body = m.group(2)!.trim().split(RegExp(r'\s+')).map(DirInfo.fromLetter).toList();
      blocks.add(RepeatBlock(int.parse(m.group(1)!), body));
    } else {
      blocks.add(MoveBlock(DirInfo.fromLetter(m.group(3)!)));
    }
  }
  return blocks;
}

// ------------------------------------------------------------------ engine

enum RunOutcome { win, wall, edge, water, notThere, tooLong }

class RunResult {
  RunResult({
    required this.outcome,
    required this.path,
    required this.gems,
    required this.failStep,
  });

  final RunOutcome outcome;

  /// Positions visited, starting with the start cell.
  final List<Cell> path;
  final Set<Cell> gems;

  /// Index of the step that failed (or -1).
  final int failStep;

  bool get won => outcome == RunOutcome.win;
}

/// Step-by-step simulation shared by blocks and Python code mode.
class MazeSimulation {
  MazeSimulation(this.level) : position = level.start, path = [level.start];

  final MazeLevel level;
  Cell position;
  final List<Cell> path;
  final List<Dir> moves = [];
  final Set<Cell> gems = {};
  RunOutcome? outcome;
  static const int maxMoves = 200;

  bool get finished => outcome != null;

  /// Performs one move. Returns false when the run ended (win or crash).
  bool move(Dir d) {
    if (finished) return false;
    if (moves.length >= maxMoves) {
      outcome = RunOutcome.tooLong;
      return false;
    }
    moves.add(d);
    final next = Cell(position.x + d.dx, position.y + d.dy);
    if (!level.inside(next)) {
      outcome = RunOutcome.edge;
      return false;
    }
    final tile = level.tileAt(next);
    if (tile == Tile.wall) {
      outcome = RunOutcome.wall;
      return false;
    }
    position = next;
    path.add(next);
    if (tile == Tile.water) {
      outcome = RunOutcome.water;
      return false;
    }
    if (level.gems.contains(next)) gems.add(next);
    if (next == level.goal) {
      outcome = RunOutcome.win;
      return false;
    }
    return true;
  }

  RunResult finish() {
    final o = outcome ?? RunOutcome.notThere;
    return RunResult(
      outcome: o,
      path: List.of(path),
      gems: Set.of(gems),
      failStep: o == RunOutcome.win ? -1 : moves.length - 1,
    );
  }

  static RunResult runMoves(MazeLevel level, List<Dir> dirs) {
    final sim = MazeSimulation(level);
    for (final d in dirs) {
      if (!sim.move(d)) break;
    }
    return sim.finish();
  }
}

/// Star rules for Robot Maze (each star is independent and visible up front):
/// ★ reach the chest · ★★ collect every gem · ★★★ use at most N commands.
class MazeStars {
  const MazeStars({required this.reached, required this.allGems, required this.withinLimit});
  final bool reached;
  final bool allGems;
  final bool withinLimit;

  int get count => reached ? 1 + (allGems ? 1 : 0) + (withinLimit ? 1 : 0) : 0;

  int score({int complete = 40, int gems = 30, int limit = 30}) =>
      reached ? complete + (allGems ? gems : 0) + (withinLimit ? limit : 0) : 0;

  static MazeStars evaluate(MazeLevel level, RunResult run, int commandsUsed) => MazeStars(
        reached: run.won,
        allGems: run.won && run.gems.length == level.gems.length,
        withinLimit: run.won && commandsUsed <= level.commandLimit,
      );
}

class RobotMazeContent {
  RobotMazeContent(this.levels);

  final List<MazeLevel> levels;
  static const String gameId = 'robot_maze';

  static Future<RobotMazeContent> load(AssetBundle bundle) async {
    final json = jsonDecode(await bundle.loadString('assets/data/robot_maze_levels.json')) as Map<String, dynamic>;
    final list = (json['levels'] as List).cast<Map<String, dynamic>>();
    return RobotMazeContent([
      for (var i = 0; i < list.length; i++)
        MazeLevel.fromRows(
          id: list[i]['id'] as String,
          title: list[i]['title'] as String,
          rows: (list[i]['rows'] as List).cast<String>(),
          commandLimit: (list[i]['command_limit'] as num).toInt(),
          allowLoops: list[i]['allow_loops'] as bool? ?? false,
          story: list[i]['story'] as String? ?? '',
          tip: list[i]['tip'] as String? ?? '',
          skill: list[i]['skill'] as String? ?? '',
          solution: list[i]['solution'] as String? ?? '',
          index: i,
        ),
    ]);
  }

  MazeLevel? byId(String id) {
    for (final l in levels) {
      if (l.id == id) return l;
    }
    return null;
  }
}
