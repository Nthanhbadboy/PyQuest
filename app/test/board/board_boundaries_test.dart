/// Test biên **nguồn** cho `PQC-010` (rev 4 §D5 + §D8 + PQC-010 §1).
///
/// Board chỉ là máy chiếu của lesson: nó không được cầm bút vào kinh tế, điểm, audio,
/// provider, session, và cũng không được tự tạo kênh điều khiển bằng timer. Những ràng buộc
/// đó nằm ngoài tầm với của widget test thông thường, nên soi trực tiếp trên nguồn —
/// chi phí rẻ, không phụ thuộc thiết bị, và hỏng là chỉ đúng dòng.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/modules/tutor/board/board_models.dart';

const List<String> kBoardLibFiles = <String>[
  'lib/modules/tutor/board/board_models.dart',
  'lib/modules/tutor/board/board_plan_codec.dart',
  'lib/modules/tutor/board/board_validator.dart',
  'lib/modules/tutor/board/board_controller.dart',
  'lib/modules/tutor/board/board_layout.dart',
  'lib/modules/tutor/board/board_view.dart',
];

/// Từ cấm trong **code** (không tính chú thích). Board không có lý do chính đáng nào để chạm chúng.
const List<String> kForbiddenWords = <String>[
  'score',
  'quota',
  'energy',
  'reward',
  'lessoncompleted',
  'progression',
  'achievement',
  'SharedPreferences',
  'sessionservice',
  'tutorpanel',
  'lessonscreen',
  'gemini',
  'voice',
  'audio',
  'provider',
  'http',
  'web_socket',
];

final RegExp _literalElement = RegExp(r"^'[A-Za-z_]+',$");

List<String> _codeLines(String path) {
  final List<String> out = <String>[];
  bool inBlock = false;
  for (final String raw in File(path).readAsLinesSync()) {
    String line = raw.trim();
    if (inBlock) {
      if (line.contains('*/')) {
        inBlock = false;
        line = line.substring(line.indexOf('*/') + 2).trim();
      } else {
        continue;
      }
    }
    final int blockStart = line.indexOf('/*');
    if (line.startsWith('///') || line.startsWith('//')) continue;
    if (line.startsWith('*')) continue;
    if (blockStart >= 0) {
      final int end = line.indexOf('*/', blockStart);
      if (end < 0) {
        inBlock = true;
        line = line.substring(0, blockStart).trim();
      } else {
        line = (line.substring(0, blockStart) + line.substring(end + 2)).trim();
      }
    }
    final int slash = line.indexOf('//');
    if (slash >= 0) line = line.substring(0, slash).trim();
    if (line.isEmpty) continue;
    out.add(line);
  }
  return out;
}

void main() {
  test('sáu file board tồn tại và có doc comment đầu file', () {
    for (final String path in kBoardLibFiles) {
      final File file = File(path);
      expect(file.existsSync(), isTrue, reason: 'thiếu $path');
      final String head = file.readAsLinesSync().take(14).join('\n');
      expect(head, contains('library;'), reason: '$path thiếu `library;`');
      expect(head.trimLeft().startsWith('///'), isTrue, reason: '$path thiếu doc comment tiếng Việt');
    }
  });

  test('board không chạm kinh tế/điểm/audio/provider/lesson', () {
    final List<String> offenders = <String>[];
    for (final String path in kBoardLibFiles) {
      for (final String line in _codeLines(path)) {
        // Phần tử của denylist trong codec ('score', 'energy', …) là **chốt chặn**, không phải
        // kênh ghi: bỏ qua dòng chỉ chứa một chuỗi ngắn dạng `'xxx',`.
        if (_literalElement.hasMatch(line)) continue;
        final String lower = line.toLowerCase();
        for (final String word in kForbiddenWords) {
          if (lower.contains(word)) offenders.add('$path: [$word] $line');
        }
      }
    }
    expect(offenders, isEmpty, reason: 'board chỉ được hiển thị: ${offenders.join('\n')}');
  });

  test('board không có timer/độ trễ/tự chạy — caption-only theo rev 4 §D10', () {
    final List<String> offenders = <String>[];
    for (final String path in kBoardLibFiles) {
      for (final String line in _codeLines(path)) {
        for (final String needle in <String>[
          'Timer',
          'Future.delayed',
          'StreamController',
          'await ',
          'async ',
        ]) {
          if (line.contains(needle)) offenders.add('$path: [$needle] $line');
        }
      }
    }
    expect(offenders, isEmpty, reason: 'board không được tự điều phối thời gian: ${offenders.join('\n')}');
  });

  test('import của board chỉ là flutter chuẩn + nội bộ board + dart:convert', () {
    final RegExp allowed = RegExp(
      r"^import '(dart:convert|package:flutter/(material|foundation|widgets)\.dart|"
      r"package:pyquest/modules/tutor/board/[a-z_]+\.dart|[a-z_]+\.dart)'",
    );
    final List<String> offenders = <String>[];
    for (final String path in kBoardLibFiles) {
      for (final String line in _codeLines(path)) {
        if (!line.startsWith('import ')) continue;
        if (!allowed.hasMatch(line)) offenders.add('$path: $line');
      }
    }
    expect(offenders, isEmpty, reason: 'board đang tự mở rộng quyền qua import: ${offenders.join('\n')}');
  });

  test('op không có trường layer: mọi op chỉ vào được lớp Tutor', () {
    final String models = File('lib/modules/tutor/board/board_models.dart').readAsStringSync();
    expect(models, isNot(contains('final BoardLayerKind layer')));
    expect(models, isNot(contains('this.layer')));
    // `BoardLayerKind` vẫn tồn tại để host vẽ scaffold/learner, nhưng plan không chọn được.
    expect(BoardLayerKind.values.map((BoardLayerKind k) => k.name),
        containsAll(<String>['scaffold', 'tutor', 'learner']));
  });

  test('view không tự diễn giải markup và không có animation nội suy', () {
    final List<String> lines = _codeLines('lib/modules/tutor/board/board_view.dart');
    for (final String needle in <String>[
      'Html',
      'flutter_svg',
      'Uri.parse',
      'dart:mirrors',
      'Process.run',
      'dart:developer',
      'GestureDetector(onTap',
      'Tween',
      'CurvedAnimation',
      'AnimationController',
      'duration:',
    ]) {
      expect(lines.any((String l) => l.contains(needle)), isFalse, reason: 'view chứa $needle');
    }
    // rev 7 §R7-B: `Text.rich`/`TextSpan` không còn bị cấm — tô đúng token cần span. Cái bị
    // cấm là diễn giải nội dung của trẻ thành markup/URL hoặc chạy nó.
    expect(lines.any((String l) => l.contains('RichText')), isTrue,
        reason: 'highlight phải là span thật trên code, không phải chuỗi mô tả');
    // `AnimatedBuilder` chỉ là wrapper rebuild theo Listenable — không nội suy gì.
    final Iterable<String> animat = lines.where((String l) => l.contains('Animat'));
    for (final String line in animat) {
      expect(line, contains('AnimatedBuilder'), reason: 'ngoài AnimatedBuilder không được có gì: $line');
    }
  });

  test('trần hợp đồng khớp bảng giới hạn rev 4', () {
    expect(BoardLimits.minBeats, 1);
    expect(BoardLimits.maxBeats, 12);
    expect(BoardLimits.maxOpsPerBeat, 8);
    expect(BoardLimits.maxCopyField, 600);
    expect(BoardLimits.maxTokensPerGroup, 12);
    expect(BoardLimits.maxTokenGroups, 4);
    expect(BoardLimits.maxShapes, 8);
    expect(BoardLimits.maxConnectors, 8);
    expect(TeachingPlan.currentSchemaVersion, 1);
    expect(BoardOpKind.values.where((BoardOpKind k) => k != BoardOpKind.unknown), hasLength(9));
    expect(BoardOpKind.fromWire('animateSprite'), isNull);
    expect(BoardOpKind.fromWire('output')!.wire, 'output');
  });
}
