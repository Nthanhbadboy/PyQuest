/// Unit test cho `BoardController` (`PQC-010`): envelope token, atomic apply, `waitForLearner`,
/// cô lập lớp của trẻ, và hoán vị locale.
///
/// Không có `Timer` nào trong file này: board chờ tín hiệu thật, nên test cũng không cần
/// `pump()` thời gian — đó chính là điều rev 4 §D10 yêu cầu cho slice caption-only.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/modules/tutor/board/board_controller.dart';
import 'package:pyquest/modules/tutor/board/board_models.dart';

import 'board_test_support.dart';

const String kControllerPath = 'lib/modules/tutor/board/board_controller.dart';
const List<String> kForbiddenApiWords = <String>[
  'score',
  'quota',
  'energy',
  'reward',
  'lessoncompleted',
  'progression',
  'stars',
  'xp',
];

void main() {
  BoardController newController({String locale = 'vi', String session = 'lesson-session-1'}) =>
      BoardController(
        sessionId: session,
        locale: locale,
        lessonId: 'mq1_01',
        stepId: 'mq1_01_s2',
      );

  BoardValidation valid(int index, {String locale = 'vi'}) => validateComposed(index, locale: locale);

  group('envelope token', () {
    test('đúng session + revision + turn + locale thì nhận', () {
      final BoardController c = newController();
      final BoardValidation validation = valid(0);
      expect(c.applyPlan(c.currentToken, validation), BoardApplyOutcome.applied);
      expect(c.beatIndex, 0);
      expect(c.beatCount, 4);
      expect(c.currentCopy!.caption, isNotEmpty);
      expect(c.fallbackNotice, isNull);
      c.dispose();
    });

    test('revision cũ (code vừa đổi) bị chặn', () {
      final BoardController c = newController();
      final BoardPlanToken stale = c.currentToken;
      c.bumpContext();
      expect(c.applyPlan(stale, valid(0)), BoardApplyOutcome.tokenRejected);
      expect(c.hasPlan, isFalse, reason: 'reply muộn không được vẽ lên bảng');
      c.dispose();
    });

    test('revision TƯƠNG LAI cũng bị chặn — hợp đồng là khớp tuyệt đối', () {
      final BoardController c = newController();
      final BoardPlanToken future = BoardPlanToken(
        sessionId: c.sessionId,
        contextRevision: c.contextRevision + 1,
        turnId: c.turnId,
        locale: c.locale,
      );
      expect(c.applyPlan(future, valid(0)), BoardApplyOutcome.tokenRejected);
      expect(c.hasPlan, isFalse);
      c.dispose();
    });

    test('session khác bị chặn', () {
      final BoardController c = newController();
      final BoardPlanToken other = BoardPlanToken(
        sessionId: 'khac',
        contextRevision: c.contextRevision,
        turnId: c.turnId,
        locale: c.locale,
      );
      expect(c.applyPlan(other, valid(0)), BoardApplyOutcome.tokenRejected);
      c.dispose();
    });

    test('turn đã cancel bị chặn; turn mới thì nhận', () {
      final BoardController c = newController();
      final BoardPlanToken before = c.currentToken;
      c.cancelTurn();
      expect(c.applyPlan(before, valid(0)), BoardApplyOutcome.tokenRejected);
      expect(c.applyPlan(c.currentToken, valid(0)), BoardApplyOutcome.applied);
      c.dispose();
    });

    test('locale lệch với board bị chặn', () {
      final BoardController c = newController();
      final BoardPlanToken en = BoardPlanToken(
        sessionId: c.sessionId,
        contextRevision: c.contextRevision,
        turnId: c.turnId,
        locale: 'en',
      );
      expect(c.applyPlan(en, valid(0, locale: 'en')), BoardApplyOutcome.tokenRejected);
      c.dispose();
    });

    test('board đã dispose: không nhận, không notify', () {
      final BoardController c = newController();
      final BoardPlanToken token = c.currentToken;
      int notifications = 0;
      c.addListener(() => notifications++);
      c.dispose();
      expect(c.applyPlan(token, valid(0)), BoardApplyOutcome.disposed);
      expect(notifications, 0);
      expect(c.next(), isFalse);
      c.replay();
      expect(notifications, 0);
    });
  });

  group('tính atomic của reject', () {
    test('plan hỏng -> bảng cũ còn nguyên, có nhãn fallback, không beat nào bị cắt', () {
      final BoardController c = newController();
      expect(c.applyPlan(c.currentToken, valid(0)), BoardApplyOutcome.applied);
      final int beatBefore = c.beatIndex;
      final TeachingPlan planBefore = c.plan!;

      final BoardValidation broken = validateComposed(
        1,
        source: mutatedSource(1, <Object>['beats', 1, 'ops', 1, 'value'], '8'),
      );
      expect(broken.accepted, isFalse);
      expect(c.applyPlan(c.currentToken, broken), BoardApplyOutcome.rejectedPlan);
      expect(c.plan, same(planBefore), reason: 'phải giữ nguyên plan đang hiển thị');
      expect(c.beatIndex, beatBefore);
      expect(c.fallbackNotice, isNotNull);
      expect(c.fallbackNotice, contains('soạn sẵn'));
      expect(c.lastIssues, isNotEmpty);

      // Sửa nội dung -> cùng token vẫn nhận được, fallback biến mất.
      expect(c.applyPlan(c.currentToken, valid(1)), BoardApplyOutcome.applied);
      expect(c.fallbackNotice, isNull);
      c.dispose();
    });

    test('plan rỗng bị từ chối chứ không phải "thành công 0 beat"', () {
      final BoardController c = newController();
      final BoardValidation empty = validateComposed(0, source: mutatedSource(0, <Object>['beats'], <Object>[]));
      expect(c.applyPlan(c.currentToken, empty), BoardApplyOutcome.rejectedPlan);
      expect(c.hasPlan, isFalse);
      expect(c.currentBeat, isNull);
      c.dispose();
    });
  });

  group('beat + waitForLearner', () {
    test('next/previous không tự nhảy khi beat đang chờ trẻ', () {
      final BoardController c = newController();
      c.applyPlan(c.currentToken, valid(1));
      expect(c.isWaitingForLearner, isFalse);
      expect(c.next(), isTrue);
      expect(c.next(), isTrue);
      expect(c.next(), isTrue);
      expect(c.beatIndex, 3);
      expect(c.isWaitingForLearner, isTrue, reason: 'beat cuối của cả hai plan chờ trẻ thao tác');
      expect(c.next(), isFalse, reason: 'không được bỏ qua beat chờ');
      c.learnerActed();
      expect(c.isWaitingForLearner, isFalse);
      expect(c.next(), isFalse, reason: 'hết beat thì đứng lại');
      expect(c.previous(), isTrue);
      expect(c.beatIndex, 2);
      c.dispose();
    });

    test('plan không được tự ý đổi waitForLearner so với gói design', () {
      // Bản đồ beat là của design; nếu plan sửa một mình thì test ghép phải nổ trước khi
      // board kịp tin nó — tránh "beat chờ" trở thành chỗ giấu logic điều hướng mới.
      expect(() => mutatedSource(0, <Object>['beats', 0, 'waitForLearner'], true), throwsA(anything));
    });

    test('beat đầu đã chờ thì next bị chặn, trẻ tác tác rồi mới đi tiếp được', () {
      final BoardController c = newController();
      c.applyPlan(c.currentToken, valid(1));
      // beat 3 chờ; lùi về 2 rồi lên lại để kiểm tra chiều quay lại của trạng thái chờ.
      c.next();
      c.next();
      c.next();
      expect(c.isWaitingForLearner, isTrue);
      expect(c.previous(), isTrue);
      expect(c.isWaitingForLearner, isFalse);
      c.next();
      c.learnerActed();
      expect(c.isWaitingForLearner, isFalse);
      c.dispose();
    });

    test('replay quay về beat 0, giữ plan, không phát tín hiệu nào khác', () {
      final BoardController c = newController();
      c.applyPlan(c.currentToken, valid(0));
      c.next();
      c.next();
      int notifications = 0;
      c.addListener(() => notifications++);
      c.replay();
      expect(c.beatIndex, 0);
      expect(notifications, 1);
      expect(c.plan!.beats, hasLength(4));
      c.dispose();
    });

    test('cancel giữa beat chờ gỡ trạng thái chờ để không treo bảng', () {
      final BoardController c = newController();
      c.applyPlan(c.currentToken, valid(0));
      c.next();
      c.next();
      c.next();
      expect(c.isWaitingForLearner, isTrue);
      c.cancelTurn();
      expect(c.isWaitingForLearner, isFalse);
      c.dispose();
    });
  });

  group('cô lập lớp và locale', () {
    test('mọi op của plan đều không xóa được nét của trẻ', () {
      final BoardController c = newController();
      c.learner.addStroke('vòng-1');
      c.learner.setNote('tớ viết đây');
      // beat 2 của plan numbers mở đầu bằng clearTutorLayer.
      c.applyPlan(c.currentToken, valid(1));
      expect(c.learner.strokes, <String>['vòng-1']);
      expect(c.learner.note, 'tớ viết đây');
      c.learner.clearOwned();
      expect(c.learner.isEmpty, isTrue);
      c.dispose();
    });

    test('đổi locale: giữ nguyên plan/beat/ink, chỉ đổi copy; reply cũ bị chặn', () {
      final BoardController c = newController();
      c.applyPlan(c.currentToken, valid(0));
      c.next();
      final String viTitle = c.currentCopy!.title;
      c.learner.addStroke('nét-của-trẻ');
      final BoardPlanToken beforeSwap = c.currentToken;
      final int beatBefore = c.beatIndex;

      c.setLocale('en');
      expect(c.locale, 'en');
      expect(c.beatIndex, beatBefore, reason: 'đổi ngôn ngữ không được đưa trẻ về beat đầu');
      expect(c.plan!.beats, hasLength(4));
      expect(c.learner.strokes, <String>['nét-của-trẻ']);
      expect(c.currentCopy!.title, isNotEmpty);
      expect(c.currentCopy!.title, isNot(equals(viTitle)), reason: 'copy phải đổi thật, không chỉ đổi nhãn');
      expect(c.applyPlan(beforeSwap, valid(0, locale: 'en')), BoardApplyOutcome.tokenRejected,
          reason: 'reply đang bay của locale cũ phải bị chặn');
      c.dispose();
    });

    test('setLocale giống hệt thì không tăng revision', () {
      final BoardController c = newController();
      final int revision = c.contextRevision;
      c.setLocale('vi');
      expect(c.contextRevision, revision);
      c.dispose();
    });

    test('reduceMotion chỉ tắt chuyển động, không skip beat', () {
      final BoardController c = newController()..reduceMotion = true;
      c.applyPlan(c.currentToken, valid(0));
      expect(c.beatIndex, 0);
      expect(c.currentBeat!.beatId, 'mq1_01_s2.b1');
      c.next();
      expect(c.currentBeat!.beatId, 'mq1_01_s2.b2');
      expect(c.beatCount, 4);
      c.dispose();
    });
  });

  group('bề mặt API', () {
    test('controller không có kênh nào để ghi điểm/năng lượng/khóa bài', () {
      // Rev 4 §D5: renderer chỉ hiển thị. Nếu một ngày cần phát "đã học xong" thì đó là
      // việc của PQC-011 với contract riêng — không phải một callback "tiện tay" thêm ở đây.
      final List<String> offenders = <String>[];
      for (final String raw in File(kControllerPath).readAsLinesSync()) {
        final String line = raw.trim();
        if (line.isEmpty || line.startsWith('//') || line.startsWith('///')) continue;
        if (RegExp(r"^'[A-Za-z_]+',$").hasMatch(line)) continue;
        for (final String needle in kForbiddenApiWords) {
          if (line.toLowerCase().contains(needle)) {
            offenders.add('$needle -> $line');
            break;
          }
        }
      }
      expect(offenders, isEmpty);
    });

    test('không có timer hay độ trễ giả lập trong controller', () {
      final String source = File(kControllerPath).readAsStringSync();
      expect(source, isNot(contains('Timer')));
      expect(source, isNot(contains('Future.delayed')));
      expect(source, isNot(contains('await ')));
    });
  });
}
