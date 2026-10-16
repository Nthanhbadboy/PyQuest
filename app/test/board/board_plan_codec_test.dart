/// Unit test cho codec/validator của board (`PQC-010`).
///
/// Mỗi ca tiêu cực được gọi **tên mã lỗi**, không so chuỗi tự do, và phải chứng minh
/// tính atomic: một lỗi -> không có plan nào được trả về.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/modules/tutor/board/board_models.dart';
import 'package:pyquest/modules/tutor/board/board_plan_codec.dart';
import 'package:pyquest/modules/tutor/board/board_validator.dart';
import 'package:pyquest/shared/characters/characters.dart';

import 'board_test_support.dart';

void main() {
  group('nội dung đã author nhận được', () {
    test('hai plan authored decode + validate sạch với reference dựng từ engine', () {
      for (int index = 0; index < 2; index++) {
        final BoardValidation validation = validateComposed(index);
        expect(validation.issues, isEmpty, reason: validation.issues.toString());
        expect(validation.accepted, isTrue);
        expect(validation.plan!.beats, hasLength(4));
        expect(validation.plan!.source, BoardPlanSource.authored);
      }
    });

    test('reference là output THẬT của code ví dụ, không phải lời plan tự khai', () {
      expect(referenceForPlan(0).outputOf('print("Xin chào!")'), 'Xin chào!');
      expect(referenceForPlan(1).outputOf('print(3 + 4)'), '7');
      expect(referenceForPlan(1).outputOf('print("3 + 4")'), '3 + 4');
      expect(referenceForPlan(1).runOutputOf(kExampleSteps['mq1_03_s2']!), '7\n3 + 4');
    });

    test('copy lấy từ gói design: cùng beatId, đủ vi + en', () {
      final Map<String, Map<String, dynamic>> pack = copyPackByBeat();
      expect(pack.keys, hasLength(8));
      for (int index = 0; index < 2; index++) {
        final Map<String, dynamic> plan = composedPlan(index);
        for (final dynamic raw in plan['beats']! as List<dynamic>) {
          final Map<String, dynamic> beat = raw as Map<String, dynamic>;
          final Map<String, dynamic> copied =
              pack[beat['beatId']! as String]!['copy']! as Map<String, dynamic>;
          expect(copied.keys, containsAll(<String>['vi', 'en']));
          expect(beat['copy'], copied, reason: 'beat ${beat['beatId']} phải dùng nguyên văn copy design');
        }
      }
    });

    test('characterId là nhân vật có thật trong CastRegistry', () {
      for (int index = 0; index < 2; index++) {
        final String id = composedPlan(index)['characterId']! as String;
        expect(CharacterId.values.map((CharacterId c) => c.name), contains(id),
            reason: 'plan hardcode nhân vật ngoài registry: $id');
      }
    });

    test('provenance của fixture trỏ đúng gói design và pin dataset', () {
      final Map<String, dynamic> prov = boardProvenance();
      expect(prov['copySourceDesignCommit'], '59f702375551865efb3590fdc0e60d4dc1dc7408');
      expect(prov['copySourceSha256'], startsWith('003a573b76e1363c'));
      expect(prov['opsAuthoredUnderCommit'], '5c69046272154cad57d2b8c34a3b5805f1d9435a');
      expect(prov['datasetPinSha256'], startsWith('bead251d9f290db0'));
    });

    test('trần copy tính bằng code point, không bằng UTF-16 unit', () {
      final String fat = codePointsOfLength(450); // 900 unit UTF-16, vẫn dưới trần 600 code point
      expect(fat.length, greaterThan(BoardLimits.maxCopyField));
      expect(fat.runes.length, lessThanOrEqualTo(BoardLimits.maxCopyField));
      expect(validateComposed(0, source: mutatedSource(0, <Object>['beats', 0, 'copy', 'vi', 'caption'], fat))
          .accepted, isTrue);
    });
  });

  group('tiêu cực — một lỗi là reject nguyên plan', () {
    test('schemaVersion lạ', () => expectOnly(0, <Object>['schemaVersion'], 2, BoardIssueCode.schemaVersion));
    test('plan rỗng không phải thành công',
        () => expectOnly(0, <Object>['beats'], <Object>[], BoardIssueCode.emptyPlan));
    test('op ngoài allowlist', () =>
        expectOnly(0, <Object>['beats', 0, 'ops', 0, 'type'], 'animateSprite', BoardIssueCode.unknownOpKind));
    test('object chưa đăng ký', () =>
        expectOnly(0, <Object>['beats', 0, 'ops', 0, 'objectId'], 'ghost-box', BoardIssueCode.unknownObject));
    test('beat tham chiếu object lạ', () =>
        expectOnly(0, <Object>['beats', 0, 'objectIds'], <Object>['ghost-box'], BoardIssueCode.unknownObject));
    test('op tự chọn layer khác', () =>
        expectOnly(0, <Object>['beats', 0, 'ops', 0, 'layer'], 'learner', BoardIssueCode.layerViolation));
    test('thiếu altText', () =>
        expectOnly(0, <Object>['beats', 0, 'copy', 'vi', 'altText'], '', BoardIssueCode.missingAltText));
    test('altText chỉ là nhãn chung', () => expectOnly(
        0, <Object>['beats', 0, 'copy', 'vi', 'altText'], 'Ảnh minh họa', BoardIssueCode.genericAltText));
    test('thiếu copy cho locale', () =>
        expectOnly(0, <Object>['beats', 1, 'copy', 'en'], null, BoardIssueCode.missingCopy));
    test('caption quá trần code point', () => expectOnly(0, <Object>['beats', 0, 'copy', 'vi', 'caption'],
        codePointsOfLength(BoardLimits.maxCopyField + 1), BoardIssueCode.copyTooLong));
    test('geometry ngoài 0..1', () =>
        expectOnly(1, <Object>['beats', 3, 'ops', 1, 'x'], 1.5, BoardIssueCode.badGeometry));
    test('id không hợp lệ', () => expectOnly(0, <Object>['planId'], 'Bad ID!', BoardIssueCode.malformedId));
    test('output tự khai khác engine', () =>
        expectOnly(1, <Object>['beats', 1, 'ops', 1, 'value'], '8', BoardIssueCode.outputMismatch));
    test('output không còn gì để đối chiếu (mất cả statement của op lẫn của beat)', () => expectOnly(
        0,
        <Object>['beats', 2, 'ops', 1, 'statement'],
        '',
        BoardIssueCode.outputWithoutStatement,
        also: <Object?>[
          <Object>['beats', 2, 'sourceStatement'],
          null,
        ],
    ));
    test('beat khai objectIds nhưng không op nào vẽ object đó (rev 7 §R7-B)', () {
      // Bỏ đúng op `output` của b2: `out-box` không còn hộp nào trên bảng ở beat đó, dù altText
      // vẫn kể về nó. Trước rev 7 ca này sạch — tức là validator không thấy bảng trống.
      expectOnly(1, <Object>['beats', 1, 'ops', 2], removed(), BoardIssueCode.unanchoredObject);
    });
    test('sai outputScope (hai dòng mà khai one line)', () => expectOnly(
        1, <Object>['beats', 2, 'outputScope'], 'singleStatement', BoardIssueCode.outputScopeMismatch));
    test('khóa chấm điểm/answer lọt vào plan', () => expectOnly(
        0, <Object>['beats', 0, 'expectedOutput'], 'Xin chào!', BoardIssueCode.foreignKey));
    test('markup/JS lọt vào chuỗi display', () => expectOnly(
        0,
        <Object>['beats', 0, 'ops', 0, 'text'],
        <String, Object>{
          'vi': '<script>alert(1)</script>',
          'en': '<script>alert(1)</script>',
        },
        BoardIssueCode.markupInText));
    test('codeSnippet quá số dòng', () => expectOnly(
        0,
        <Object>['beats', 0, 'ops', 0, 'text'],
        <String, Object>{
          for (final String loc in <String>['vi', 'en'])
            loc: List<String>.filled(30, 'print(1)').join('\n'),
        },
        BoardIssueCode.tooManyCodeLines));

    test('ops vượt trần mỗi beat', () {
      final List<Object> ops = <Object>[
        for (int i = 0; i <= BoardLimits.maxOpsPerBeat; i++)
          <String, Object>{
            'type': 'text',
            'text': <String, Object>{'vi': 'dòng $i', 'en': 'line $i'},
            'altText': <String, Object>{'vi': 'chữ $i', 'en': 'text $i'},
          },
      ];
      final BoardValidation validation =
          validateComposed(0, source: mutatedSource(0, <Object>['beats', 0, 'ops'], ops));
      expect(validation.codes, contains(BoardIssueCode.tooManyOps));
      expect(validation.accepted, isFalse);
    });

    test('tokenGroup vượt trần token', () {
      final List<Object> tokens = <Object>[
        for (int i = 0; i < BoardLimits.maxTokensPerGroup + 1; i++) 'stone-${(i % 7) + 1}',
      ];
      final BoardValidation validation =
          validateComposed(1, source: mutatedSource(1, <Object>['beats', 0, 'ops', 1, 'tokenIds'], tokens));
      expect(validation.codes, contains(BoardIssueCode.tooManyTokens));
      expect(validation.accepted, isFalse);
    });

    test('số beat vượt trần', () {
      final Map<String, dynamic> plan = composedPlan(0);
      final List<dynamic> beats = plan['beats']! as List<dynamic>;
      final List<Object> many = <Object>[];
      for (int i = 0; i < BoardLimits.maxBeats + 1; i++) {
        final Map<String, dynamic> copy =
            jsonClone(beats[i % beats.length]) as Map<String, dynamic>;
        copy['beatId'] = 'mq1_01_s2.b${i + 1}x';
        many.add(copy);
      }
      final BoardValidation validation = validateComposed(0, source: mutatedSource(0, <Object>['beats'], many));
      expect(validation.codes, contains(BoardIssueCode.tooManyBeats));
      expect(validation.accepted, isFalse);
    });

    test('beatId trùng nhau', () {
      final Map<String, dynamic> plan = composedPlan(0);
      final List<dynamic> beats = plan['beats']! as List<dynamic>;
      final BoardValidation validation =
          validateComposed(0, source: mutatedSource(0, <Object>['beats', 1], jsonClone(beats[0])));
      expect(validation.codes, contains(BoardIssueCode.duplicateId));
      expect(validation.accepted, isFalse);
    });

    test('tài liệu quá trần từ chối TRƯỚC khi parse sâu', () {
      final BoardValidation validation = validateBoardDocument(
        'x' * (BoardLimits.maxDocumentChars + 1),
        reference: referenceForPlan(0),
        locale: 'vi',
        expectedLessonId: 'mq1_01',
        expectedStepId: 'mq1_01_s2',
        registeredObjects: const <String>['cmd-print'],
        requiredLocales: const <String>['vi', 'en'],
      );
      expect(validation.codes, equals(<BoardIssueCode>{BoardIssueCode.documentTooLarge}));
    });

    test('json hỏng chỉ ra invalidJson, không ném', () {
      final DecodedPlan decoded = decodePlan('{"beats":[',
          registeredObjects: const <String>[], requiredLocales: const <String>['vi', 'en']);
      expect(decoded.clean, isFalse);
      expect(decoded.issues.map((BoardIssue e) => e.code), contains(BoardIssueCode.invalidJson));
    });

    test('plan của bài khác bị chặn bằng foreignKey', () {
      final BoardValidation validation = validateComposed(0, lessonId: 'mq1_09');
      expect(validation.codes, contains(BoardIssueCode.foreignKey));
      expect(validation.accepted, isFalse);
    });
  });

  group('r7 §R7-A — sai kiểu là reject, không phải ném hay mặc định', () {
    // Mỗi ca dưới đây từng là lỗ hổng thật của codec rev 6: `as List<dynamic>?` ném type
    // error, `_num` đổi "oops" thành 0, `line` thiếu thành 1, altText của op không có trần.
    test('objectIds là chuỗi thay vì mảng -> wrongType, không nổ', () =>
        expectOnly(0, <Object>['beats', 0, 'objectIds'], 'not-a-list', BoardIssueCode.wrongType));
    test('objectIds là object -> wrongType', () =>
        expectOnly(0, <Object>['beats', 0, 'objectIds'], <String, Object>{'a': 1}, BoardIssueCode.wrongType));
    test('tokenIds là object rỗng -> wrongType', () =>
        expectOnly(1, <Object>['beats', 0, 'ops', 1, 'tokenIds'], <String, Object>{}, BoardIssueCode.wrongType));
    test('tokenIds là chuỗi -> wrongType', () =>
        expectOnly(1, <Object>['beats', 0, 'ops', 1, 'tokenIds'], 'stone-1', BoardIssueCode.wrongType));
    test('tokenIds rỗng bị từ chối: op không còn gì để vẽ', () =>
        expectOnly(1, <Object>['beats', 0, 'ops', 1, 'tokenIds'], <Object>[], BoardIssueCode.missingOpField));
    test('x là chuỗi -> wrongType, không được thành 0', () =>
        expectOnly(1, <Object>['beats', 3, 'ops', 1, 'x'], 'oops', BoardIssueCode.wrongType));
    test('width 0 -> badGeometry (hộp rỗng không vẽ được)', () =>
        expectOnly(1, <Object>['beats', 3, 'ops', 1, 'width'], 0, BoardIssueCode.badGeometry));
    test('thiếu x -> missingOpField, không âm thầm thành 0', () =>
        expectOnly(1, <Object>['beats', 3, 'ops', 1, 'x'], null, BoardIssueCode.missingOpField));
    test('shape lạ -> unknownShape, không rơi thành rectangle', () =>
        expectOnly(1, <Object>['beats', 3, 'ops', 1, 'shape'], 'banana', BoardIssueCode.unknownShape));
    test('simpleShape thiếu neo -> missingOpField', () =>
        expectOnly(1, <Object>['beats', 3, 'ops', 1, 'objectId'], null, BoardIssueCode.missingOpField));
    test('connector thiếu một đầu mút -> missingOpField', () =>
        expectOnly(0, <Object>['beats', 2, 'ops', 0, 'toId'], null, BoardIssueCode.missingOpField));
    test('connector hai đầu trùng nhau -> missingOpField', () =>
        expectOnly(0, <Object>['beats', 2, 'ops', 0, 'toId'], 'cmd-print', BoardIssueCode.missingOpField));
    test('connector trỏ object chưa đăng ký -> unknownObject', () =>
        expectOnly(0, <Object>['beats', 2, 'ops', 0, 'fromId'], 'ghost', BoardIssueCode.unknownObject));
    test('altText của op 601 code point -> copyTooLong', () => expectOnly(0,
        <Object>['beats', 0, 'ops', 0, 'altText', 'vi'], 'a' * 601, BoardIssueCode.copyTooLong));
    test('altText của op 600 code point vẫn nhận', () => expect(
        validateComposed(0,
                source: mutatedSource(0, <Object>['beats', 0, 'ops', 0, 'altText', 'vi'], 'a' * 600))
            .accepted,
        isTrue));
    test('altText của op chỉ là nhãn chung -> genericAltText', () => expectOnly(0,
        <Object>['beats', 0, 'ops', 0, 'altText', 'vi'], 'Ảnh minh họa', BoardIssueCode.genericAltText));
    test('altText của op phải là bản per-locale', () => expectOnly(
        0, <Object>['beats', 0, 'ops', 0, 'altText'], 'plain string', BoardIssueCode.wrongType));
    test('thiếu text cho op chữ -> missingOpField', () =>
        expectOnly(0, <Object>['beats', 0, 'ops', 0, 'text'], null, BoardIssueCode.missingOpField));
    test('locale lạ trong text của op -> wrongType', () => expectOnly(
        0, <Object>['beats', 0, 'ops', 0, 'text', 'fr'], 'bonjour', BoardIssueCode.wrongType));
    test('token không có trong code nguồn -> badHighlightRange', () => expectOnly(
        0, <Object>['beats', 0, 'ops', 1, 'token'], 'printf', BoardIssueCode.badHighlightRange));
    test('highlightToken không nêu token -> badHighlightRange', () => expectOnly(
        0, <Object>['beats', 0, 'ops', 1, 'token'], null, BoardIssueCode.badHighlightRange));
    test('tokenIds ít hơn số lần xuất hiện -> badHighlightRange', () => expectOnly(
        0, <Object>['beats', 1, 'ops', 0, 'tokenIds'], <Object>['quote-open'], BoardIssueCode.badHighlightRange));
    test('line ngoài số dòng của đoạn code -> badHighlightRange', () => expectOnly(
        1, <Object>['beats', 0, 'ops', 0, 'line'], 9, BoardIssueCode.badHighlightRange));
    test('line là chuỗi -> wrongType, không thành 1', () =>
        expectOnly(1, <Object>['beats', 0, 'ops', 0, 'line'], '1', BoardIssueCode.wrongType));
    test('line vượt số dòng của statement nhiều dòng -> badHighlightRange', () => expectOnly(
        1, <Object>['beats', 2, 'ops', 0, 'line'], 3, BoardIssueCode.badHighlightRange));
    test('waitForLearner không phải boolean -> wrongType', () => expectOnly(
        0, <Object>['beats', 0, 'waitForLearner'], 'yes', BoardIssueCode.wrongType));
    test('beats là object -> wrongType, không phải plan rỗng', () =>
        expectOnly(0, <Object>['beats'], <String, Object>{}, BoardIssueCode.wrongType));
    test('ops là object -> wrongType', () =>
        expectOnly(0, <Object>['beats', 0, 'ops'], <String, Object>{}, BoardIssueCode.wrongType));
    test('source là số -> wrongType', () =>
        expectOnly(0, <Object>['source'], 42, BoardIssueCode.wrongType));

    test('một beat không có ops vẫn là beat hợp lệ, không bị âm thầm xóa', () {
      final BoardValidation validation =
          validateComposed(0, source: mutatedSource(0, <Object>['beats', 0, 'ops'], <Object>[]));
      expect(validation.accepted, isTrue, reason: 'ops rỗng = beat chỉ có copy: ${validation.issues}');
      expect(validation.plan!.beats, hasLength(4), reason: 'không được mất beat');
      expect(validation.plan!.beats.first.ops, isEmpty);
    });

    test('JSON bệnh hoạn không ném exception lên host', () {
      const List<String> sick = <String>[
        '{"schemaVersion":1,"beats":"nope"}',
        '{"schemaVersion":1,"beats":[{"ops":true,"copy":[],"objectIds":3}]}',
        '{"schemaVersion":1,"beats":[{"copy":{"vi":{"altText":"x"},"en":{"altText":"x"}},"ops":[{"type":"simpleShape","shape":{"a":1},"x":[1,2]}]}]}',
        '["not","an","object"]',
        'null',
      ];
      for (final String source in sick) {
        expect(() => decodePlan(source,
                registeredObjects: const <String>[], requiredLocales: const <String>['vi', 'en']),
            returnsNormally,
            reason: 'codec phải trả issue chứ không nổ: $source');
        final DecodedPlan decoded = decodePlan(source,
            registeredObjects: const <String>[], requiredLocales: const <String>['vi', 'en']);
        expect(decoded.clean, isFalse, reason: 'phải reject: $source');
        expect(decoded.plan, isNull);
      }
    });

    test('validatePlan là tầng ngữ nghĩa, không phải đường vòng qua kiểm cấu trúc', () {
      // Đọc source của đường vào public: nếu ai đó gọi thẳng validatePlan với JSON chưa decode
      // thì phải thấy precondition trong doc comment, không phải một API "tiện tay".
      final String source =
          File('lib/modules/tutor/board/board_validator.dart').readAsStringSync();
      expect(source, contains('/// Đường vào **đã có kiểm cấu trúc**'));
      expect(source, contains('decodePlan] (hoặc'));
    });
  });
}

void expectOnly(int index, List<Object> path, Object? value, BoardIssueCode code,
    {List<Object?>? also}) {
  final String source = also == null
      ? mutatedSource(index, path, value)
      : mutatedSource2(index, path, value, also[0]! as List<Object>, also[1]);
  final BoardValidation validation = validateComposed(index, source: source);
  expect(validation.accepted, isFalse, reason: 'phải reject: $code');
  expect(validation.plan, isNull, reason: 'reject mà còn trả plan là rò một nửa plan');
  expect(validation.codes, equals(<BoardIssueCode>{code}),
      reason: 'cần đúng một lỗi được gọi tên, thực tế: ${validation.issues}');
    }

/// Sao chép cấu trúc JSON để sửa mà không đụng object gốc của fixture.
Object? jsonClone(Object? node) => node == null ? null : _clone(node);

Object? _clone(Object? node) {
  if (node is Map<String, dynamic>) {
    return <String, dynamic>{for (final MapEntry<String, dynamic> e in node.entries) e.key: _clone(e.value)};
  }
  if (node is List<dynamic>) {
    return <Object?>[for (final Object? child in node) _clone(child)];
  }
  return node;
}
