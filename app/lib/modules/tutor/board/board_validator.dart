/// Validate **ngữ nghĩa** của một plan đã decode được.
///
/// Điểm mấu chốt của rev 4 §D5: output **không** tin lời plan. `output` chỉ được nhận khi
/// trùng với `DeterministicReference` dựng từ code ví dụ thật; và mọi lỗi đều là
/// **reject nguyên plan**, không cắt beat/connector rồi render nốt.
library;

import 'board_models.dart';
import 'board_plan_codec.dart';

/// Đường vào duy nhất mà host nên dùng: **decode rồi validate, một khối**.
///
/// Không tồn tại chế độ "bỏ beat lỗi rồi vẽ phần còn lại": mọi `BoardIssue` đều làm toàn bộ
/// tài liệu bị từ chối trước khi có bất kỳ pixel nào thay đổi.
BoardValidation validateBoardDocument(
  String source, {
  required DeterministicReference reference,
  required String locale,
  required String expectedLessonId,
  required String expectedStepId,
  required List<String> registeredObjects,
  required List<String> requiredLocales,
}) {
  final DecodedPlan decoded = decodePlan(
    source,
    registeredObjects: registeredObjects,
    requiredLocales: requiredLocales,
  );
  final TeachingPlan? plan = decoded.plan;
  if (plan == null || !decoded.clean) return BoardValidation.rejected(decoded.issues);
  return validatePlan(
    plan,
    reference: reference,
    expectedLessonId: expectedLessonId,
    expectedStepId: expectedStepId,
    locale: locale,
  );
}

/// Đường vào **đã có kiểm cấu trúc**: `plan` phải là kết quả của [decodePlan] (hoặc
/// [validateBoardDocument]). Đây là tầng ngữ nghĩa — đối chiếu output với reference, kiểm
/// scope/layer/limit — chứ không phải tầng an toàn JSON: nó giả định mọi field đã đúng kiểu
/// và đã qua trần độ dài, nên host **không** được tự dựng [TeachingPlan] bằng tay rồi gọi
/// thẳng vào đây để "vẽ nhanh". [validateBoardDocument] là đường duy nhất cho JSON bên ngoài.
BoardValidation validatePlan(
  TeachingPlan plan, {
  required DeterministicReference reference,
  required String expectedLessonId,
  required String expectedStepId,
  required String locale,
}) {
  final List<BoardIssue> issues = <BoardIssue>[];

  if (plan.lessonId != expectedLessonId || plan.stepId != expectedStepId) {
    issues.add(BoardIssue(
      BoardIssueCode.foreignKey,
      'plan cho ${plan.lessonId}/${plan.stepId}, host đang ở $expectedLessonId/$expectedStepId',
    ));
  }
  if (plan.beats.length < BoardLimits.minBeats) {
    issues.add(const BoardIssue(BoardIssueCode.emptyPlan, 'plan rỗng không phải thành công'));
  }
  if (plan.beats.length > BoardLimits.maxBeats) {
    issues.add(BoardIssue(
      BoardIssueCode.tooManyBeats,
      '${plan.beats.length} beats vượt ${BoardLimits.maxBeats}',
    ));
  }

  for (int b = 0; b < plan.beats.length; b++) {
    final BoardBeat beat = plan.beats[b];

    final BoardBeatCopy? copy = beat.copyFor(locale);
    if (copy == null) {
      issues.add(BoardIssue(BoardIssueCode.missingCopy, 'beat ${beat.beatId} không có copy cho $locale',
          beatIndex: b));
    } else if (copy.altText.trim().isEmpty) {
      issues.add(BoardIssue(BoardIssueCode.missingAltText, 'beat ${beat.beatId} thiếu altText', beatIndex: b));
    }
    if (beat.copy.length < 2) {
      issues.add(BoardIssue(BoardIssueCode.missingCopy, 'beat ${beat.beatId} phải có ít nhất 2 locale',
          beatIndex: b));
    }
    for (final String localeKey in beat.locales) {
      final BoardBeatCopy entry = beat.copy[localeKey]!;
      if (entry.caption.trim().isEmpty) {
        issues.add(BoardIssue(BoardIssueCode.missingCopy, 'caption rỗng ở $localeKey', beatIndex: b));
      }
      if (entry.altText.runes.length > BoardLimits.maxCopyField) {
        issues.add(BoardIssue(BoardIssueCode.copyTooLong, 'altText vượt trần ở $localeKey', beatIndex: b));
      }
    }

    final String? statement = beat.sourceStatement;
    if (statement != null && !reference.knows(statement)) {
      // Plan bịa một câu lệnh không có trong code ví dụ -> mọi output kèm theo vô nghĩa.
      issues.add(BoardIssue(BoardIssueCode.outputMismatch, 'reference không biết statement: $statement',
          beatIndex: b));
    }

    final int statementLines = statement == null ? 0 : _lineCount(statement);
    if (beat.outputScope == BoardOutputScope.singleStatement && statementLines > 1) {
      issues.add(BoardIssue(
        BoardIssueCode.outputScopeMismatch,
        'beat khai singleStatement nhưng statement có $statementLines dòng',
        beatIndex: b,
      ));
    }

    int outputs = 0;
    for (int i = 0; i < beat.ops.length; i++) {
      final BoardOp op = beat.ops[i];
      switch (op.kind) {
        case BoardOpKind.output:
          outputs++;
          _checkOutput(
            op: op,
            beat: beat,
            reference: reference,
            issues: issues,
            beatIndex: b,
            opIndex: i,
          );
        case BoardOpKind.highlightToken:
        case BoardOpKind.highlightLine:
          final String target = op.statement.trim().isEmpty ? (statement ?? '') : op.statement.trim();
          if (target.isEmpty) {
            issues.add(BoardIssue(BoardIssueCode.outputWithoutStatement,
                '${op.kind.wire} không nêu câu lệnh nào để tô', beatIndex: b, opIndex: i));
          } else if (!reference.knows(target) && !_containedInKnownLine(target, reference)) {
            issues.add(BoardIssue(BoardIssueCode.unknownObject,
                'bộ tô sáng trỏ tới đoạn không thuộc code ví dụ: $target', beatIndex: b, opIndex: i));
          }
        case BoardOpKind.text:
        case BoardOpKind.codeSnippet:
        case BoardOpKind.simpleShape:
        case BoardOpKind.connector:
        case BoardOpKind.tokenGroup:
        case BoardOpKind.clearTutorLayer:
        case BoardOpKind.unknown:
          break;
      }
      // Rev 7 §R7-A/§R7-C: altText của op bị kiểm **theo từng locale** — cả trần code point
      // lẫn "không rỗng" — vì renderer đọc đúng chuỗi này cho cả chữ nhìn thấy lẫn nhãn
      // accessibility. Chỉ kiểm rỗng là để lọt một khối 5.000 ký tự vào semantic label.
      if (op.altTexts.isEmpty) {
        issues.add(BoardIssue(BoardIssueCode.missingAltText, 'op ${op.kind.wire} thiếu altText',
            beatIndex: b, opIndex: i));
      }
      for (final MapEntry<String, String> e in op.altTexts.entries) {
        if (e.value.trim().isEmpty) {
          issues.add(BoardIssue(BoardIssueCode.missingAltText, 'op ${op.kind.wire} altText rỗng ở ${e.key}',
              beatIndex: b, opIndex: i));
        }
        if (e.value.runes.length > BoardLimits.maxCopyField) {
          issues.add(BoardIssue(BoardIssueCode.copyTooLong,
              'op ${op.kind.wire} altText ${e.value.runes.length} code point vượt ${BoardLimits.maxCopyField}',
              beatIndex: b, opIndex: i));
        }
      }
      for (final MapEntry<String, String> e in op.text.entries) {
        if (e.value.runes.length > BoardLimits.maxOpText) {
          issues.add(BoardIssue(BoardIssueCode.payloadTooLarge, 'text op quá dài ở ${e.key}',
              beatIndex: b, opIndex: i));
        }
      }
    }
    if (outputs > 1 && beat.outputScope == BoardOutputScope.singleStatement) {
      // Một beat không được tích hai ô kết quả rồi gọi đó là "dòng đầu".
      issues.add(BoardIssue(BoardIssueCode.outputScopeMismatch,
          '$outputs op output trong một beat singleStatement', beatIndex: b));
    }
  }

  if (issues.isNotEmpty) return BoardValidation.rejected(issues);
  return BoardValidation.accepted(plan);
}

void _checkOutput({
  required BoardOp op,
  required BoardBeat beat,
  required DeterministicReference reference,
  required List<BoardIssue> issues,
  required int beatIndex,
  required int opIndex,
}) {
  // Op phải tự nói nó mô tả câu nào; `beat.sourceStatement` chỉ là fallback. Cả hai trống thì
  // không có gì để đối chiếu => lỗi, vì một ô "kết quả" vô chủ chính là chỗ plan bịa số.
  String statement = op.statement.trim();
  if (statement.isEmpty) statement = (beat.sourceStatement ?? '').trim();
  if (statement.isEmpty) {
    issues.add(BoardIssue(BoardIssueCode.outputWithoutStatement,
        'op output cần statement của riêng nó hoặc beat.sourceStatement để đối chiếu',
        beatIndex: beatIndex, opIndex: opIndex));
    return;
  }
  final String expected;
  if (beat.outputScope == BoardOutputScope.singleStatement) {
    final String? single = reference.outputOf(statement.trim());
    if (single == null) {
      issues.add(BoardIssue(BoardIssueCode.outputMismatch, 'reference không có output cho: $statement',
          beatIndex: beatIndex, opIndex: opIndex));
      return;
    }
    expected = single;
  } else {
    final String? full = reference.runOutputOf(statement);
    if (full == null) {
      issues.add(BoardIssue(BoardIssueCode.outputMismatch, 'reference không chạy được toàn bộ statement này',
          beatIndex: beatIndex, opIndex: opIndex));
      return;
    }
    expected = full;
  }
  if (op.value != expected) {
    issues.add(BoardIssue(
      BoardIssueCode.outputMismatch,
      'plan khai "${op.value}" nhưng reference của code ví dụ là "$expected"',
      beatIndex: beatIndex,
      opIndex: opIndex,
    ));
  }
}

int _lineCount(String value) {
  int count = 0;
  for (final String line in value.split('\n')) {
    if (line.trim().isNotEmpty) count++;
  }
  return count == 0 ? 1 : count;
}

/// Cho phép tô một từ/đoạn nằm trong một dòng đã biết, mà không cần khai cả dòng.
bool _containedInKnownLine(String fragment, DeterministicReference reference) {
  for (final String line in reference.knownStatements) {
    if (line.contains(fragment)) return true;
  }
  return false;
}
