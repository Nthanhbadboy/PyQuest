import 'dart:convert';

import 'package:flutter/services.dart';

class BugFix {
  BugFix(Map<String, dynamic> j)
      : line = (j['line'] as num).toInt(),
        options = (j['options'] as List).cast<String>(),
        explain = j['explain'] as String;

  /// 1-based line number of the buggy line.
  final int line;

  /// Replacement lines; the first one is correct (shuffled in the UI).
  final List<String> options;
  final String explain;
  String get correct => options.first;
}

class BugPuzzle {
  BugPuzzle(Map<String, dynamic> j, this.index)
      : id = j['id'] as String,
        pack = (j['pack'] as num).toInt(),
        title = j['title'] as String,
        story = j['story'] as String,
        code = (j['code'] as List).cast<String>(),
        bugs = [for (final b in j['bugs'] as List) BugFix(b as Map<String, dynamic>)],
        expectedOutput = j['expected_output'] as String,
        skill = j['skill'] as String;

  final String id;
  final int pack;
  final String title;
  final String story;
  final List<String> code;
  final List<BugFix> bugs;
  final String expectedOutput;
  final String skill;
  final int index;

  BugFix? bugAt(int line) {
    for (final b in bugs) {
      if (b.line == line) return b;
    }
    return null;
  }

  /// Uses conditions → counts toward "Bậc Thầy Điều Kiện".
  bool get aboutConditions => pack == 3;
}

class BugPack {
  BugPack(Map<String, dynamic> j)
      : number = (j['number'] as num).toInt(),
        title = j['title'] as String,
        requiresLesson = j['requires_lesson'] as String;
  final int number;
  final String title;
  final String requiresLesson;
}

class BugHunterContent {
  BugHunterContent(this.packs, this.puzzles);

  final List<BugPack> packs;
  final List<BugPuzzle> puzzles;
  static const String gameId = 'bug_hunter';

  /// Bug Hunter opens once the player knows print() and numbers.
  String get unlockLessonId => packs.first.requiresLesson;

  int get totalBugs => puzzles.fold(0, (a, p) => a + p.bugs.length);

  static Future<BugHunterContent> load(AssetBundle bundle) async {
    final j = jsonDecode(await bundle.loadString('assets/data/bug_hunter_puzzles.json')) as Map<String, dynamic>;
    final puzzles = j['puzzles'] as List;
    return BugHunterContent(
      [for (final p in j['packs'] as List) BugPack(p as Map<String, dynamic>)],
      [for (var i = 0; i < puzzles.length; i++) BugPuzzle(puzzles[i] as Map<String, dynamic>, i)],
    );
  }

  BugPack packOf(BugPuzzle p) => packs.firstWhere((k) => k.number == p.pack);
}
