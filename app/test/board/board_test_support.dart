/// Hỗ trợ test cho `PQC-010`: nạp plan đã author, **ghép** copy VI/EN từ gói của design,
/// và dựng `DeterministicReference` từ **engine thật** của app.
///
/// Vì sao phải ghép: design giữ copy trong một fixture độc lập (`authored-copy.v1.json`,
/// byte-identical với gói `59f7023`) để dataset/progression không bị copy board làm trôi.
/// Plan ở đây chỉ mang phần hình thức (op/layer/scope/objectIds). Nếu test tự viết lại
/// caption thì nó đang test một bản sao khác của copy — không phải thứ trẻ sẽ thấy.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/modules/tutor/board/board_models.dart';
import 'package:pyquest/modules/tutor/board/board_plan_codec.dart';
import 'package:pyquest/modules/tutor/board/board_validator.dart';
import 'package:pyquest/python_runtime/python_runtime.dart';
import 'package:pyquest/python_runtime/simulated_runtime.dart';
import 'package:pyquest/shared/characters/cast.dart';

const String kBoardFixturePath = 'test/board/fixtures/board_plans.v1.json';
const String kCopyPackPath = 'test/fixtures/tutor_board/authored-copy.v1.json';

/// Hai bước `example` duy nhất mà slice này có nội dung đã chấp nhận, và code thật của chúng.
const Map<String, String> kExampleSteps = <String, String>{
  'mq1_01_s2': 'print("Xin chào!")',
  'mq1_03_s2': 'print(3 + 4)\nprint("3 + 4")',
};

Map<String, dynamic> _readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Map<String, dynamic> boardProvenance() =>
    _readJson(kBoardFixturePath)['provenance']! as Map<String, dynamic>;

/// Copy VI/EN đã duyệt của design, theo `beatId`, kèm `waitForLearner` gốc của gói.
Map<String, Map<String, dynamic>> copyPackByBeat() {
  final Map<String, dynamic> pack = _readJson(kCopyPackPath);
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
  final Map<String, dynamic> doc = _readJson(kBoardFixturePath);
  final Map<String, dynamic> plan =
      jsonDecode(jsonEncode((doc['plans']! as List<dynamic>)[index])) as Map<String, dynamic>;
  final Map<String, Map<String, dynamic>> pack = copyPackByBeat();
  final String stepId = plan['stepId']! as String;
  plan['characterId'] = CastRegistry.tutorForSkill(kExampleSteps[stepId]!).id.name;
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
  return jsonEncode(plan);
}

class _Removed {
  const _Removed();
}

/// Đánh dấu "xóa key/phần tử này" cho [mutatedSource].
Object removed() => const _Removed();

/// Reference **không** do plan khai: chạy từng câu qua engine thật của app, lấy output thật.
DeterministicReference referenceFor(Iterable<String> statements) {
  final PythonRuntime runtime = SimulatedPythonRuntime();
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

/// Reference cho một plan cụ thể: code của bước + mọi statement mà plan hoặc op nêu.
DeterministicReference referenceForPlan(int index) {
  final Map<String, dynamic> plan = composedPlan(index);
  final List<String> statements = <String>[
    kExampleSteps[plan['stepId']! as String]!,
    for (final dynamic raw in plan['beats']! as List<dynamic>)
      if ((raw as Map<String, dynamic>)['sourceStatement'] != null)
        (raw as Map<String, dynamic>)['sourceStatement']! as String,
    for (final dynamic raw in plan['beats']! as List<dynamic>)
      for (final dynamic opRaw in (raw as Map<String, dynamic>)['ops']! as List<dynamic>)
        if ((opRaw as Map<String, dynamic>)['statement'] != null)
          (opRaw as Map<String, dynamic>)['statement']! as String,
  ];
  return referenceFor(statements);
}

BoardValidation validateComposed(
  int index, {
  String locale = 'vi',
  String? lessonId,
  String? stepId,
  String? source,
}) {
  final Map<String, dynamic> plan = composedPlan(index);
  return validateBoardDocument(
    source ?? jsonEncode(plan),
    reference: referenceForPlan(index),
    locale: locale,
    expectedLessonId: lessonId ?? plan['lessonId']! as String,
    expectedStepId: stepId ?? plan['stepId']! as String,
    registeredObjects:
        (plan['registeredObjects']! as List<dynamic>).map((Object? e) => '$e').toList(),
    requiredLocales: const <String>['vi', 'en'],
  );
}

List<BoardIssueCode> codesOf(BoardValidation validation) =>
    validation.issues.map((BoardIssue e) => e.code).toList();

/// String có **ít nhất** `count` code point, mỗi code point là một emoji ngoài BMP
/// (1 code point = 2 UTF-16 unit) nên phép đếm theo code point khác hẳn theo `.length`.
String codePointsOfLength(int count) {
  final StringBuffer buffer = StringBuffer();
  while (buffer.runes.length < count) {
    buffer.write('😀');
  }
  String value = buffer.toString();
  while (value.runes.length - 2 >= count) {
    value = value.substring(0, value.length - 2);
  }
  return value;
}
