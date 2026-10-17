// Test-only, kiểm **nội dung do design giao** cho bảng giảng (PQD-003 rev 4: D4, D5, D8).
//
// Nguồn gốc file: `docs/design/tutor-board-prototype/authored-copy.v1.json` tại SHA design
// `59f702375551865efb3590fdc0e60d4dc1dc7408`. Asset runtime tại `app/assets/data/`
// là **byte-identical** (9359 bytes, sha256 `003a573b76e1363c…`), kiểm lại bằng:
//   git show 59f7023:docs/design/tutor-board-prototype/authored-copy.v1.json | sha256sum
//
// Vì sao file này hợp lệ mà **không** cần production API: nó chỉ kiểm dữ liệu — shape, ID ổn
// định, đủ hai ngôn ngữ, trần độ dài, và ranh giới "overlay không chứa dữ liệu chấm điểm".
// Không import type nào chưa tồn tại (đúng ràng buộc rev 4 mục E.2: "không tạo API production
// giả để test type chưa tồn tại" — bài học 6 vòng CI ở EV-ID-018).
//
// Giới hạn phải nói thẳng, đừng đọc vượt:
//  * Đây **không** phải bằng chứng TalkBack/semantics hay thứ tự đọc trên thiết bị; design ghi
//    rõ golden/semantics tests mới chứng minh phần đó (rev 4 §D4).
//  * `sourceDatasetSha256` chỉ được kiểm **định dạng** ở đây, vì `crypto` không phải dependency
//    của app. Việc hash **khớp** `app/assets/data/main_quest_ch1.json` được xác minh lúc nhập
//    và ghi ở `docs/implementation/coordination/EVIDENCE.md` (EV-ID-021).
//  * Test này không chứng minh `TeachingPlanV1` đã tồn tại hay đã được validate.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

const String kPackPath = 'assets/data/tutor_board_authored-copy.v1.json';
const List<String> kTopKeys = <String>[
  'contentVersion',
  'status',
  'sourceFixture',
  'sourceDatasetSha256',
  'languages',
  'plans',
];
const Set<String> kPlanKeys = <String>{'id', 'lessonId', 'sourceStep', 'beats'};
const Set<String> kBeatKeys = <String>{'beatId', 'sourceBeatIndex', 'waitForLearner', 'copy'};
const Set<String> kCopyFields = <String>{'title', 'say', 'caption', 'altText'};
const int kMaxCopyFieldLength = 600; // code point, theo rev 4 §D5
const int kMinAltTextLength = 30;

/// Overlay chỉ được chứa bản dịch. Chứa một trong các khóa này nghĩa là dataset chấm điểm
/// đã bị nhân bản sang file thứ hai và sẽ trôi đi (rev 4 §D8) → fail, không "bỏ qua".
const Set<String> kForbiddenKeys = <String>{
  'code',
  'expectedOutput',
  'expected_output',
  'answer',
  'answers',
  'solution',
  'rule',
  'rules',
  'prerequisite',
  'prerequisites',
  'score',
  'stars',
  'reward',
  'energy',
};

Map<String, dynamic> readPack() {
  final File file = File(kPackPath);
  expect(file.existsSync(), isTrue, reason: 'pack phải nằm cùng repo với test: $kPackPath');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

void collectKeys(Object? node, List<String> keys) {
  if (node is Map<String, dynamic>) {
    for (final MapEntry<String, dynamic> entry in node.entries) {
      keys.add(entry.key);
      collectKeys(entry.value, keys);
    }
  } else if (node is List<dynamic>) {
    for (final dynamic item in node) {
      collectKeys(item, keys);
    }
  }
}

List<Map<String, dynamic>> plansOf(Map<String, dynamic> pack) =>
    (pack['plans']! as List<dynamic>).cast<Map<String, dynamic>>();

List<Map<String, dynamic>> beatsOf(Map<String, dynamic> plan) =>
    (plan['beats']! as List<dynamic>).cast<Map<String, dynamic>>();

Map<String, dynamic> copyOf(Map<String, dynamic> beat) => beat['copy']! as Map<String, dynamic>;

Map<String, dynamic> fieldsFor(Map<String, dynamic> copy, String lang) =>
    copy[lang]! as Map<String, dynamic>;

int codePoints(String value) => value.runes.length;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('content pack của bảng giảng (authored-copy.v1.json)', () {
    test('tự khai là content handoff, không phải schema runtime', () {
      final Map<String, dynamic> pack = readPack();
      expect(pack.keys.toList(), kTopKeys, reason: 'thêm/bớt khóa ở gốc = đổi hợp đồng, phải qua design');
      expect(pack['contentVersion'], 1);
      expect(pack['status']! as String, contains('not a runtime'));
      expect(pack['languages'], <String>['vi', 'en'],
          reason: 'rev 4 §D7: registry supported là vi/en ở slice đầu, không giả hỗ trợ mọi locale');
      expect(pack['sourceFixture']! as String, isNotEmpty);
      expect(pack['sourceDatasetSha256']! as String, matches(RegExp(r'^[0-9a-f]{64}$')),
          reason: 'phải là sha256 hex thường để so được khi re-import; khớp nội dung là kiểm ở EV-ID-021');
      final int totalBeats = plansOf(pack)
          .map((Map<String, dynamic> p) => beatsOf(p).length)
          .fold(0, (int a, int b) => a + b);
      expect(totalBeats, 8, reason: 'rev 4 §D4 giao đúng tám beat của hai ví dụ');
    });

    test('shape chặt: plan 4 khóa, beat 4 khóa, copy đúng 4 trường cho cả hai ngôn ngữ', () {
      final Map<String, dynamic> pack = readPack();
      for (final Map<String, dynamic> plan in plansOf(pack)) {
        expect(plan.keys.toSet(), kPlanKeys, reason: 'plan ${plan['id']} có khóa ngoài hợp đồng');
        expect(beatsOf(plan), hasLength(4));
        for (final Map<String, dynamic> beat in beatsOf(plan)) {
          expect(beat.keys.toSet(), kBeatKeys, reason: 'beat ${beat['beatId']} có khóa ngoài hợp đồng');
          final Map<String, dynamic> copy = copyOf(beat);
          expect(copy.keys.toSet(), <String>{'vi', 'en'}, reason: 'beat phải có đủ vi + en, không ngôn ngữ khác');
          for (final String lang in <String>['vi', 'en']) {
            expect(fieldsFor(copy, lang).keys.toSet(), kCopyFields,
                reason: '$lang của ${beat['beatId']} phải có đúng title/say/caption/altText');
          }
        }
      }
    });

    test('ID ổn định: beatId suy ra từ sourceStep + vị trí, không do runtime đặt', () {
      final Map<String, dynamic> pack = readPack();
      for (final Map<String, dynamic> plan in plansOf(pack)) {
        final String step = plan['sourceStep']! as String;
        final List<Map<String, dynamic>> beats = beatsOf(plan);
        for (var i = 0; i < beats.length; i++) {
          final Map<String, dynamic> beat = beats[i];
          expect(beat['sourceBeatIndex'], i, reason: '$step: index phải là vị trí thật, không phải số đẹp');
          expect(beat['beatId'], '$step.b${i + 1}',
              reason: 'beatId là khóa bền cho highlight/annotation/ink; đặt lại tên là làm mất nét của trẻ');
        }
      }
    });

    test('mỗi plan có đúng một beat chờ người học, và beat đó là beat cuối (rev 4 §D3)', () {
      final Map<String, dynamic> pack = readPack();
      for (final Map<String, dynamic> plan in plansOf(pack)) {
        final List<Map<String, dynamic>> waiting = beatsOf(plan)
            .where((Map<String, dynamic> b) => b['waitForLearner'] == true)
            .toList();
        expect(waiting, hasLength(1), reason: '${plan['id']}: lượt thử phải là một điểm rõ ràng, không rải rác');
        expect(beatsOf(plan).last['waitForLearner'], isTrue,
            reason: 'trẻ được chờ ở cuối, không tự nhảy beat chỉ vì chưa tương tác');
        for (final Map<String, dynamic> beat in beatsOf(plan)) {
          expect(beat['waitForLearner'], isA<bool>(), reason: '${beat['beatId']}: waitForLearner phải là bool');
        }
      }
    });

    test('copy có thật: altText không rỗng, không nhãn chung, mọi field <= 600 code point', () {
      final Map<String, dynamic> pack = readPack();
      final RegExp genericLabel =
          RegExp(r'^(ảnh|hình|picture|image|illustration|graphic)(\s*(minh họa| minh hoa|illustration))?\.?$',
              caseSensitive: false);
      for (final Map<String, dynamic> plan in plansOf(pack)) {
        for (final Map<String, dynamic> beat in beatsOf(plan)) {
          final Map<String, dynamic> copy = copyOf(beat);
          for (final String lang in <String>['vi', 'en']) {
            final Map<String, dynamic> fields = fieldsFor(copy, lang);
            for (final String field in kCopyFields) {
              final String value = fields[field]! as String;
              expect(value.trim(), isNotEmpty, reason: '${beat['beatId']}.$field thiếu ở $lang');
              expect(codePoints(value), lessThanOrEqualTo(kMaxCopyFieldLength),
                  reason: '${beat['beatId']}.$field ($lang) vượt trần 600 code point của beat');
            }
            final String alt = fields['altText']! as String;
            expect(alt.trim(), isNot(matches(genericLabel)),
                reason: '${beat['beatId']}: altText là mô tả nội dung, không phải nhãn "ảnh minh họa" (rev 4 §D4)');
            expect(codePoints(alt.trim()), greaterThanOrEqualTo(kMinAltTextLength),
                reason: '${beat['beatId']}: altText quá ngắn để một mình hiểu được beat ở $lang');
          }
        }
      }
    });

    test('overlay không chứa dữ liệu chấm điểm/code (ranh giới D8)', () {
      final List<String> keys = <String>[];
      collectKeys(readPack(), keys);
      final Set<String> offenders = keys.toSet().intersection(kForbiddenKeys);
      expect(offenders, isEmpty,
          reason: 'overlay dịch mà chứa $offenders nghĩa là đã copy nguồn chấm điểm; '
              'hai bản sẽ trôi nhau. Loader phải ghép overlay với dataset duy nhất.');
    });

    test('lessonId/sourceStep khớp dataset thật — ánh xạ, không copy', () async {
      final Map<String, dynamic> dataset =
          jsonDecode(await rootBundle.loadString('assets/data/main_quest_ch1.json')) as Map<String, dynamic>;
      final Map<String, dynamic> byId = <String, dynamic>{
        for (final dynamic l in dataset['lessons']! as List<dynamic>)
          (l as Map<String, dynamic>)['id']! as String: l,
      };
      for (final Map<String, dynamic> plan in plansOf(readPack())) {
        final String lessonId = plan['lessonId']! as String;
        final String stepId = plan['sourceStep']! as String;
        expect(byId.containsKey(lessonId), isTrue, reason: 'pack tham chiếu bài không tồn tại: $lessonId');
        final Map<String, dynamic> lesson = byId[lessonId]! as Map<String, dynamic>;
        final List<dynamic> steps = lesson['steps']! as List<dynamic>;
        // Không dùng `firstOrNull`: đó là extension của package:collection, không phải
        // dependency của app — đoán API là cách 3 vòng CI trước đã đỏ (EV-ID-018).
        final List<Map<String, dynamic>> matched = steps
            .cast<Map<String, dynamic>>()
            .where((Map<String, dynamic> s) => s['id'] == stepId)
            .toList();
        expect(matched, hasLength(1), reason: '$lessonId phải có đúng một step $stepId mà beat bám vào');
        final Map<String, dynamic> step = matched.single;
        expect(step['code'], isA<String>(), reason: '$stepId phải là step có code (board minh họa code)');
        expect((step['code']! as String).trim(), isNotEmpty);
        expect(plan['id'], isNotEmpty);
      }
    });

    test('rev 4 §D5: beat minh họa output phải tự khai scope, beat ngoặc kép phải nói rõ', () {
      // `numbers`: `print(3 + 4)` in ra 7 và `print("3 + 4")` in nguyên chữ. Rev 4 yêu cầu
      // "scope statement/output-prefix rõ; không gán 7 là full output của cả hai lệnh".
      // Bản đầu của test này chỉ điểm SAI beat (đoán rằng ngoặc nằm ở b2) — CI đỏ và dữ liệu
      // của design đúng: b2 mang scope "dòng đầu", b3 mới là beat ngoặc kép. Sửa theo dữ liệu,
      // không nới assertion thành trivial.
      final Map<String, dynamic> pack = readPack();
      final Map<String, dynamic> numbers =
          plansOf(pack).firstWhere((Map<String, dynamic> p) => p['id'] == 'numbers');
      final List<Map<String, dynamic>> beats = beatsOf(numbers);
      expect(beats, hasLength(4));
      for (final String lang in <String>['vi', 'en']) {
        final Map<String, dynamic> b2 = fieldsFor(copyOf(beats[1]), lang);
        final String scope = '${b2['caption']} ${b2['altText']}'.toLowerCase();
        expect(scope, anyOf(contains('dòng đầu'), contains('first line')),
            reason: '$lang: beat 2 phải nói rõ nó chỉ minh họa dòng đầu, nếu không validator sẽ gán 7 cho cả hai dòng');

        final Map<String, dynamic> b3 = fieldsFor(copyOf(beats[2]), lang);
        final String quoted = '${b3['caption']} ${b3['altText']}'.toLowerCase();
        expect(quoted, anyOf(contains('ngoặc'), contains('quote')),
            reason: '$lang: beat 3 phải chỉ ra chữ có ngoặc kép in nguyên văn, đó là điểm dễ nhầm của bài');
      }
      // Beat chờ người học phải là lời mời thật, không phải nhãn kỹ thuật.
      for (final Map<String, dynamic> plan in plansOf(pack)) {
        for (final String lang in <String>['vi', 'en']) {
          final Map<String, dynamic> last = fieldsFor(copyOf(beatsOf(plan).last), lang);
          final String say = '${last['caption']} ${last['altText']}'.toLowerCase();
          expect(say, anyOf(contains('đến lượt'), contains('your turn')),
              reason: '${plan['id']}: beat cuối waitForLearner=true phải mời trẻ làm bằng lời');
        }
      }
    });
  });
}
