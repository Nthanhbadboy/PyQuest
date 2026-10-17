/// Hỗ trợ test cho `PQC-010`: nạp plan đã author, **ghép** copy VI/EN từ gói của design,
/// và dựng `DeterministicReference` từ **engine thật** của app.
///
/// Vì sao phải ghép: design giữ copy trong một asset copy độc lập (`tutor_board_authored-copy.v1.json`,
/// byte-identical với gói `59f7023`) để dataset/progression không bị copy board làm trôi.
/// Plan ở đây chỉ mang phần hình thức (op/layer/scope/objectIds). Nếu test tự viết lại
/// caption thì nó đang test một bản sao khác của copy — không phải thứ trẻ sẽ thấy.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/modules/main_quest/quest_models.dart';
import 'package:pyquest/modules/tutor/board/board_models.dart';
import 'package:pyquest/modules/tutor/board/board_plan_codec.dart';
import 'package:pyquest/modules/tutor/board/board_validator.dart';
import 'package:pyquest/python_runtime/python_runtime.dart';
import 'package:pyquest/python_runtime/simulated_runtime.dart';
import 'package:pyquest/shared/characters/cast.dart';

const String kBoardAssetPath = 'assets/data/tutor_board_plans.v1.json';
const String kCopyAssetPath = 'assets/data/tutor_board_authored-copy.v1.json';
const List<String> kSupportedExampleStepIds = <String>['mq1_01_s2', 'mq1_03_s2'];
const Map<String, List<String>> _hostRegisteredObjectsByStep = <String, List<String>>{
  'mq1_01_s2': <String>['cmd-print', 'quote-open', 'quote-close', 'out-box'],
  'mq1_03_s2': <String>[
    'expr-add',
    'lit-text',
    'out-box',
    'stone-1',
    'stone-2',
    'stone-3',
    'stone-4',
    'stone-5',
    'stone-6',
    'stone-7',
  ],
};

Map<String, dynamic> _readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

MainQuestContent _mainQuestContent() =>
    MainQuestContent.fromJson(_readJson('assets/data/main_quest_ch1.json'));

Lesson _lessonForStep(String stepId) {
  for (final Lesson lesson in _mainQuestContent().lessons) {
    if (lesson.steps.any((LessonStep step) => step.id == stepId)) return lesson;
  }
  throw StateError('No authored lesson step $stepId');
}

String exampleCodeForStep(String stepId) {
  final Lesson lesson = _lessonForStep(stepId);
  for (final LessonStep step in lesson.steps) {
    if (step.id == stepId && step is ExampleStep) return step.code;
  }
  throw StateError('Step $stepId is not an authored example');
}

Map<String, dynamic> boardProvenance() =>
    _readJson(kBoardAssetPath)['provenance']! as Map<String, dynamic>;

/// Copy VI/EN đã duyệt của design, theo `beatId`, kèm `waitForLearner` gốc của gói.
Map<String, Map<String, dynamic>> copyPackByBeat() {
  final Map<String, dynamic> pack = _readJson(kCopyAssetPath);
  final Map<String, Map<String, dynamic>> out = <String, Map<String, dynamic>>{};
  for (final dynamic rawPlan in pack['plans']! as List<dynamic>) {
    final Map<String, dynamic> plan = rawPlan as Map<String, dynamic>;
    for (final dynamic raw in plan['beats']! as List<dynamic>) {
      final Map<String, dynamic> beat = raw as Map<String, dynamic>;
      out[beat['beatId']! as String] = <String, dynamic>{
        'copy': beat['copy'],
        'waitForLearner': beat['waitForLearner'],
      };
    }
  }
  return out;
}

/// Plan thứ `index` với copy đã ghép và `characterId` lấy từ registry thật của app.
Map<String, dynamic> composedPlan(int index) {
  final Map<String, dynamic> doc = _readJson(kBoardAssetPath);
  final Map<String, dynamic> plan =
      jsonDecode(jsonEncode((doc['plans']! as List<dynamic>)[index])) as Map<String, dynamic>;
  final Map<String, Map<String, dynamic>> pack = copyPackByBeat();
  final String hostStepId = kSupportedExampleStepIds[index];
  plan['characterId'] = CastRegistry.tutorForSkill(_lessonForStep(hostStepId).skill).id.name;
  for (final dynamic raw in plan['beats']! as List<dynamic>) {
    final Map<String, dynamic> beat = raw as Map<String, dynamic>;
    final Map<String, dynamic>? entry = pack[beat['beatId']! as String];
    // Ghép thất bại phải nổ ngay tại đây, không âm thầm vẽ beat thiếu copy.
    expect(entry, isNotNull, reason: 'gói copy design không có beat ${beat['beatId']}');
    beat['copy'] = entry!['copy'];
    expect(beat['waitForLearner'], entry['waitForLearner'],
        reason: 'waitForLearner của plan phải khớp gói design đã duyệt');
  }
  return plan;
}

String composedPlanSource(int index) => jsonEncode(composedPlan(index));

/// Sửa sâu một giá trị trong **plan đã ghép** để tạo ca tiêu cực; file fixture không đổi.
String mutatedSource(int index, List<Object> path, Object? value) {
  final Map<String, dynamic> plan = composedPlan(index);
  _applyAt(plan, path, value);
  return jsonEncode(plan);
}

/// Hai phép sửa cùng lúc, cho ca tiêu cực mà một mình nó chưa đủ (vd. xóa cả statement của op
/// lẫn của beat để không còn gì để đối chiếu).
String mutatedSource2(
  int index,
  List<Object> p1,
  Object? v1,
  List<Object> p2,
  Object? v2,
) {
  final Map<String, dynamic> plan = composedPlan(index);
  _applyAt(plan, p1, v1);
  _applyAt(plan, p2, v2);
  return jsonEncode(plan);
}

void _applyAt(Map<String, dynamic> plan, List<Object> path, Object? value) {
  Object? node = plan;
  for (int i = 0; i < path.length - 1; i++) {
    final Object key = path[i];
    node = key is int ? (node! as List<dynamic>)[key] : (node! as Map<String, dynamic>)[key];
  }
  final Object last = path.last;
  if (value is _Removed) {
    if (last is int) {
      (node! as List<dynamic>).removeAt(last);
    } else {
      (node! as Map<String, dynamic>).remove(last as String);
    }
  } else if (last is int) {
    (node! as List<dynamic>)[last] = value;
  } else {
    (node! as Map<String, dynamic>)[last as String] = value;
  }
}

class _Removed {
  const _Removed();
}

/// Đánh dấu "xóa key/phần tử này" cho [mutatedSource].
Object removed() => const _Removed();

/// Reference **không** do plan khai: chạy từng câu qua engine thật của app, lấy output thật.
DeterministicReference referenceFor(Iterable<String> statements) {
  final SimulatedPythonRuntime runtime = SimulatedPythonRuntime();
  final Map<String, String> out = <String, String>{};
  for (final String statement in statements.toSet()) {
    final ExecutionResult whole = runtime.executeSync(statement);
    if (whole.success) out[statement] = whole.output.trimRight();
    for (final String line in const LineSplitter().convert(statement)) {
      final String trimmed = line.trim();
      if (trimmed.isEmpty || out.containsKey(trimmed)) continue;
      final ExecutionResult single = runtime.executeSync(trimmed);
      if (single.success) out[trimmed] = single.output.trimRight();
    }
  }
  return DeterministicReference(out);
}

/// Reference cho plan chỉ từ ExampleStep.code bất biến của lesson thật. Không đưa statement,
/// value hay code từ plan vào engine để dựng oracle; chúng chỉ là dữ liệu cần được đối chiếu.
DeterministicReference referenceForPlan(int index) =>
    referenceFor(<String>[exampleCodeForStep(kSupportedExampleStepIds[index])]);

BoardValidation validateComposed(
  int index, {
  String locale = 'vi',
  String? lessonId,
  String? stepId,
  String? source,
}) {
  final Map<String, dynamic> plan = composedPlan(index);
  final String hostStepId = kSupportedExampleStepIds[index];
  final String hostLessonId = _lessonForStep(hostStepId).id;
  return validateBoardDocument(
    source ?? jsonEncode(plan),
    reference: referenceForPlan(index),
    locale: locale,
    expectedLessonId: lessonId ?? hostLessonId,
    expectedStepId: stepId ?? hostStepId,
    registeredObjects: List<String>.unmodifiable(_hostRegisteredObjectsByStep[hostStepId]!),
    requiredLocales: const <String>['vi', 'en'],
  );
}

List<BoardIssueCode> codesOf(BoardValidation validation) =>
    validation.issues.map((BoardIssue e) => e.code).toList();

/// String có **ít nhất** `count` code point, mỗi code point là một emoji ngoài BMP
/// (1 code point = 2 UTF-16 unit) nên phép đếm theo code point khác hẳn theo `.length`.
String codePointsOfLength(int count) => '😀' * count;
