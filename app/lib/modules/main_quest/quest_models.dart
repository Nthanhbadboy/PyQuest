import 'dart:convert';

import 'package:flutter/services.dart';

import '../../shared/characters/characters.dart';

sealed class LessonStep {
  LessonStep(this.json) : id = json['id'] as String;
  final Map<String, dynamic> json;
  final String id;

  List<String> get skills => (json['skills'] as List?)?.cast<String>() ?? const [];

  /// Exercises are checked and counted; stories/examples are not.
  bool get isExercise => this is! StoryStep && this is! ExampleStep;

  static LessonStep fromJson(Map<String, dynamic> j) => switch (j['type']) {
        'story' => StoryStep(j),
        'example' => ExampleStep(j),
        'choice' => ChoiceStep(j),
        'fill' => FillStep(j),
        'order' => OrderStep(j),
        'write' => WriteStep(j),
        'robot' => RobotStep(j),
        _ => throw FormatException('Unknown step type ${j['type']}'),
      };
}

class StoryStep extends LessonStep {
  StoryStep(super.json);
  String get text => json['text'] as String;
  CharacterId get speaker => json['speaker'] == 'robo' ? CharacterId.robo : CharacterId.py;
  Mood get mood => json['mood'] == 'thinking' ? Mood.thinking : Mood.happy;
}

class ExampleStep extends LessonStep {
  ExampleStep(super.json);
  String get text => json['text'] as String;
  String get code => json['code'] as String;
}

class ChoiceStep extends LessonStep {
  ChoiceStep(super.json);
  String get question => json['question'] as String;
  String? get code => json['code'] as String?;
  List<String> get options => (json['options'] as List).cast<String>();
  int get answer => (json['answer'] as num).toInt();
  String get explain => json['explain'] as String? ?? '';
}

class FillStep extends LessonStep {
  FillStep(super.json);
  String get prompt => json['prompt'] as String;
  String get template => json['template'] as String;

  /// Options per blank; the first option is the intended answer (shuffled in UI).
  List<List<String>> get blanks => [for (final b in json['blanks'] as List) (b as List).cast<String>()];
  String get expectedOutput => json['expected_output'] as String;
  String get explain => json['explain'] as String? ?? '';

  String build(List<String?> picks) {
    var code = template;
    for (final p in picks) {
      code = code.replaceFirst('___', p ?? '___');
    }
    return code;
  }
}

class OrderStep extends LessonStep {
  OrderStep(super.json);
  String get prompt => json['prompt'] as String;

  /// Lines in the correct order (shuffled in UI).
  List<String> get lines => (json['lines'] as List).cast<String>();
  String get expectedOutput => json['expected_output'] as String;
}

class WriteStep extends LessonStep {
  WriteStep(super.json);
  String get prompt => json['prompt'] as String;
  String? get expectedOutput => json['expected_output'] as String?;
  String get solution => json['solution'] as String;
  String get hint => json['hint'] as String? ?? '';
  String get starter => json['starter'] as String? ?? '';
  List<String> get mustContain => (json['must_contain'] as List?)?.cast<String>() ?? const [];
  bool get lenient => json['lenient'] as bool? ?? false;
  bool get anyOutput => json['any_output'] as bool? ?? false;
}

class RobotStep extends LessonStep {
  RobotStep(super.json);
  String get prompt => json['prompt'] as String;
  List<String> get rows => (json['rows'] as List).cast<String>();
  String get starter => json['starter'] as String? ?? '';
  String get solution => json['solution'] as String;
  String get hint => json['hint'] as String? ?? '';
  List<String> get mustContain => (json['must_contain'] as List?)?.cast<String>() ?? const [];
}

class Lesson {
  Lesson(this.json, this.chapterId)
      : id = json['id'] as String,
        number = (json['number'] as num).toInt(),
        steps = [for (final s in json['steps'] as List) LessonStep.fromJson(s as Map<String, dynamic>)];

  final Map<String, dynamic> json;
  final String chapterId;
  final String id;
  final int number;
  final List<LessonStep> steps;

  String get title => json['title'] as String;
  String get skill => json['skill'] as String;
  String get summary => json['summary'] as String;
  String get pyLine => json['py_line'] as String;
  bool get isChallenge => json['challenge'] as bool? ?? false;
  int get exerciseCount => steps.where((s) => s.isExercise).length;

  /// Skill ids recorded when the lesson is completed.
  List<String> get skillIds => ['py:${skill.toLowerCase()}', ...{for (final s in steps) ...s.skills}];
}

class PlaygroundExample {
  const PlaygroundExample(this.title, this.code);
  final String title;
  final String code;
}

class MainQuestContent {
  MainQuestContent({
    required this.chapterId,
    required this.chapterNumber,
    required this.chapterTitle,
    required this.chapterSubtitle,
    required this.chapterDescription,
    required this.nextChapterTitle,
    required this.nextChapterDescription,
    required this.lessons,
    required this.examples,
  });

  final String chapterId;
  final int chapterNumber;
  final String chapterTitle;
  final String chapterSubtitle;
  final String chapterDescription;
  final String nextChapterTitle;
  final String nextChapterDescription;
  final List<Lesson> lessons;
  final List<PlaygroundExample> examples;

  static Future<MainQuestContent> load(AssetBundle bundle) async {
    final j = jsonDecode(await bundle.loadString('assets/data/main_quest_ch1.json')) as Map<String, dynamic>;
    return fromJson(j);
  }

  static MainQuestContent fromJson(Map<String, dynamic> j) {
    final chapter = j['chapter'] as Map<String, dynamic>;
    final next = j['next_chapter'] as Map<String, dynamic>;
    final id = chapter['id'] as String;
    return MainQuestContent(
      chapterId: id,
      chapterNumber: (chapter['number'] as num).toInt(),
      chapterTitle: chapter['title'] as String,
      chapterSubtitle: chapter['subtitle'] as String,
      chapterDescription: chapter['description'] as String,
      nextChapterTitle: next['title'] as String,
      nextChapterDescription: next['description'] as String,
      lessons: [for (final l in j['lessons'] as List) Lesson(l as Map<String, dynamic>, id)],
      examples: [
        for (final e in (j['playground_examples'] as List? ?? const []))
          PlaygroundExample((e as Map<String, dynamic>)['title'] as String, e['code'] as String),
      ],
    );
  }

  Lesson? byId(String id) {
    for (final l in lessons) {
      if (l.id == id) return l;
    }
    return null;
  }
}
