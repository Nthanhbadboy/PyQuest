// PQC-009 — regression cho route "bài học thật" xuất phát từ Activity Sheet.
//
// Vì sao file này tồn tại (PQD-002 revision 2 + review PQC-007): bảng feasibility
// cũ chỉ chứng minh tới mức `'lesson:mq1_03'` được pop khỏi sheet. Review chứng
// minh mức đó KHÔNG đủ, vì `openActivity(..., lessonId:)` (main_map_screen.dart:
// 252–267) chỉ dựng `MainQuestHomeScreen(openLessonId:)`, và screen đó chỉ cuộn +
// vẽ viền highlight card (main_quest_module.dart:87–111, 262–277) — nó KHÔNG tự
// push LessonScreen, KHÔNG tự trừ năng lượng, vẫn giữ `_unlocked` theo bài trước.
// Test ở đây đi hết chuỗi thật map → sheet → CTA → home → (tap card) →
// LessonScreen bằng chính mã nguồn app, với hai fixture người chơi khác nhau.
//
// Phạm vi: chỉ app/test/**. Không sửa app/lib, không asset mới, không emulator.
// PQC-008 (Semantics/focus + thiết bị) vẫn còn nguyên; nhóm "characterization"
// cuối file ghi đúng những gì code hiện có/thiếu, không suy ra hành vi thiết bị.
library;

// `avoid_dynamic_calls`: `SemanticsProperties` không được export từ material.dart của
// SDK mà CI dùng (run 38886724385 cháy analyze vì đoán tên type) → helper dưới đọc
// `properties` qua `dynamic`; mọi kết luận vẫn nằm trong expect.
// ignore_for_file: avoid_dynamic_calls

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/app/app_services.dart';
import 'package:pyquest/app/pyquest_app.dart';
import 'package:pyquest/core/events.dart';
import 'package:pyquest/modules/main_quest/lesson_screen.dart';
import 'package:pyquest/modules/main_quest/main_quest_module.dart';
import 'package:pyquest/shared/theme/palette.dart';
import 'package:pyquest/shared/widgets/chunky_button.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_helpers.dart';

/// 390×844 là khung mà render J đã ghi nhận CTA `sheet_go_lesson` nằm trong màn;
/// 360×640 tụt "Để sau" xuống dưới fold (EV-ID-013) nên không dùng cho route test.
const Size kRouteViewport = Size(390, 844);
const double kRouteDpr = 3.0;

/// Nạp services thật (DB in-memory qua sqflite_common_ffi) rồi dựng app.
///
/// Bài học được đánh dấu hoàn thành đúng bằng con đường production: phát
/// `EventTypes.lessonCompleted` cho hub — giống cách `lesson_complete_screen` làm
/// khi trẻ học xong — không INSERT tay, không fake `completedLessons()`.
///
/// Không dùng `pumpAndSettle` trên Main Map: `_ambient` là
/// `AnimationController..repeat()` (main_map_screen.dart:38) nên cây không bao giờ
/// "settle"; bơm số khung cố định như harness render.
Future<AppServices> boot(WidgetTester tester, {List<String> lessonsDone = const <String>[]}) async {
  final FakeClock clock = FakeClock(DateTime(2026, 10, 16, 9));
  final AppServices s = (await tester.runAsync(() => AppServices.create(
        bundle: rootBundle,
        databaseFactory: databaseFactoryFfiNoIsolate,
        databasePath: inMemoryDatabasePath,
        clock: clock,
        audioEnabled: false,
        startSessionTimer: false,
      )))!;
  await tester.runAsync(() async {
    await s.settings.setIntroSeen();
    for (final String id in lessonsDone) {
      await s.events.emit(StandardEvent(
        type: EventTypes.lessonCompleted,
        sourceId: 'main_quest',
        data: {'lesson_id': id, 'chapter_id': 'code_apprentice', 'skills': <String>[], 'score': 100},
      ));
    }
  });
  tester.view.devicePixelRatio = kRouteDpr;
  tester.view.physicalSize = Size(kRouteViewport.width * kRouteDpr, kRouteViewport.height * kRouteDpr);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(PyQuestApp(servicesFactory: (_) async => s, minSplash: Duration.zero));
  await pumpFor(tester, const Duration(seconds: 2));
  // Nạp nền đảo + thumbnail thật: landmark được đặt theo khung ảnh, nếu ảnh chưa
  // nạp thì hình học tap không còn giống trên thiết bị.
  await tester.runAsync(() async {
    final BuildContext context = tester.element(find.byType(Scaffold).first);
    for (final String asset in kMapAssets) {
      await precacheImage(AssetImage(asset), context);
    }
  });
  await pumpFor(tester, const Duration(milliseconds: 400));
  return s;
}

const List<String> kMapAssets = <String>[
  'assets/images/island_map.webp',
  'assets/images/thumb_maze.webp',
  'assets/images/thumb_tower.webp',
  'assets/images/thumb_volcano.webp',
  'assets/images/thumb_observatory.webp',
  'assets/images/thumb_workshop.webp',
  'assets/images/thumb_house.webp',
];

/// Dọn giống `finish()` của harness render: if không, `Future.delayed(900ms)` của
/// toast reward (main_map_screen.dart:268–271) hoặc ticker mini-game còn sống sẽ
/// làm đỏ test bằng "A Timer is still pending" không liên quan tới điều được kiểm.
Future<void> finishTest(WidgetTester tester, AppServices s) async {
  s.dispose();
  await pumpFor(tester, const Duration(seconds: 4));
  await tester.pumpWidget(const SizedBox.shrink());
  await pumpFor(tester, const Duration(milliseconds: 1100));
}

/// Những event hub đã phát SAU khi đăng ký — đủ để chứng minh "mở sheet không
/// nhân tiện mở activity". Không assert danh sách rỗng tuyệt đối vì services
/// cũng phát event của riêng nó lúc khởi tạo.
List<String> recordEvents(AppServices s) {
  final List<String> seen = <String>[];
  final StreamSubscription<StandardEvent> sub = s.events.stream.listen((StandardEvent e) => seen.add(e.type));
  addTearDown(sub.cancel);
  return seen;
}

/// Tap theo key, có ensureVisible cho phần trong sheet cuộn.
///
/// `warnIfMissed` mặc định true: tap hụt là fail, không im lặng đi tiếp. Nơi nào
/// thật sự cần tắt (card bị khóa nên không còn handler) ghi rõ tại chỗ gọi, và
/// nghiệm thu bằng trạng thái chứ không bằng hit-test.
Future<void> tapKey(WidgetTester tester, String key, {int ms = 1200, bool warnIfMissed = true}) async {
  final Finder f = find.byKey(ValueKey<String>(key));
  expect(f, findsOneWidget, reason: 'thiếu key $key — route/sheet đã đổi, không được bỏ qua im lặng');
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f, warnIfMissed: warnIfMissed);
  await pumpFor(tester, Duration(milliseconds: ms));
}

/// `Semantics.properties` của mọi node `Semantics` trong `subtree`.
///
/// Không nêu tên type `SemanticsProperties`: SDK của CI không export nó (đã trả giá
/// bằng một run đỏ), và `Semantics` mới là type test này cần để tìm đúng node.
List<dynamic> semanticsProps(WidgetTester tester, Finder subtree) => find
    .descendant(of: subtree, matching: find.byType(Semantics))
    .evaluate()
    .map((Element e) {
      final dynamic w = e.widget;
      return w.properties;
    })
    .toList();

/// Màu viền card bài học: `highlighted` (khớp `openLessonId`) vẽ viền berry, card
/// thường vẽ ink — bằng chứng trực tiếp rằng `openLessonId` đã tới screen.
Color cardBorderColor(WidgetTester tester, String lessonId) {
  final Container box = tester.widget<Container>(
    find.descendant(of: find.byKey(ValueKey<String>('lesson_card_$lessonId')), matching: find.byType(Container)).first,
  );
  final Border border = (box.decoration! as BoxDecoration).border! as Border;
  return border.top.color; // Color (không nullable ở SDK của CI — warning `!` đã bị ghi nhận)
}

bool cardShowsLockedHint(WidgetTester tester, String lessonId) {
  final Finder hint = find.descendant(
    of: find.byKey(ValueKey<String>('lesson_card_$lessonId')),
    matching: find.text('Hoàn thành bài trước để mở'),
  );
  return hint.evaluate().isNotEmpty;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUpAll(() async {
    await loadAppFonts();
  });

  group('route bài học từ Activity Sheet (PQC-009)', () {
    testWidgets('người mới: sheet khóa → CTA chỉ tới home Main Quest, highlight mq1_03, không auto-open, không tốn năng lượng',
        (WidgetTester tester) async {
      final AppServices s = await boot(tester);
      final List<String> events = recordEvents(s);
      final int energyBefore = s.energy.current;
      expect(energyBefore, greaterThan(0), reason: 'fixture phải còn năng lượng thì phép thử mới có nghĩa');

      await tapKey(tester, 'map_hit_bug_hunter');
      expect(find.byKey(const Key('sheet_go_lesson')), findsOneWidget,
          reason: 'Bug Hunter phải ở nhánh khóa và có CTA đi tới bài học');
      expect(find.byKey(const Key('sheet_open')), findsNothing);
      expect(s.energy.current, energyBefore, reason: 'chỉ mở sheet không được tiêu hao năng lượng');

      await tapKey(tester, 'sheet_go_lesson');

      // Tới đúng nơi sheet hứa: home của Main Quest, openLessonId = mq1_03.
      expect(find.byType(MainQuestHomeScreen), findsOneWidget);
      // ...và DỪNG Ở ĐÓ: nguồn chỉ cuộn/highlight, không tự vào bài.
      expect(find.byType(LessonScreen), findsNothing);
      expect(cardBorderColor(tester, 'mq1_03'), PQColors.berry,
          reason: 'openLessonId phải tới screen và highlight đúng card mq1_03');
      expect(cardBorderColor(tester, 'mq1_04'), isNot(PQColors.berry));
      final String targetTitle = s.mainQuest.lessons.firstWhere((l) => l.id == 'mq1_03').title;
      expect(
        find.descendant(of: find.byKey(const Key('lesson_card_mq1_03')), matching: find.text(targetTitle)),
        findsOneWidget,
        reason: 'card được highlight phải là card của mq1_03, không phải ô nào đó',
      );
      expect(events, contains(EventTypes.activityOpened), reason: 'openActivity phải phát sự kiện mở activity');
      expect(events, isNot(contains(EventTypes.lessonCompleted)));

      // Người mới thì mq1_03 vẫn khóa: bấm vào card cũng không vào bài, không trừ năng lượng.
      // Chờ toast reward (chèn lúc +900ms, sống 2.8s mỗi cái) đóng đã, nếu không
      // "không có gì xảy ra" chỉ là bằng chứng của một cú chạm bị che.
      expect(cardShowsLockedHint(tester, 'mq1_03'), isTrue);
      await pumpFor(tester, const Duration(seconds: 5));
      await tapKey(tester, 'lesson_card_mq1_03', warnIfMissed: false);
      expect(find.byType(LessonScreen), findsNothing);
      expect(s.energy.current, energyBefore);
      expect(await tester.runAsync(() => s.progress.completedLessons()), isNot(contains('mq1_03')));

      await finishTest(tester, s);
    });

    // Test 2 bị TÁCH LÀM BA để tên test tự chỉ chỗ gãy. Lý do thực dụng: báo cáo
    // check-run của CI cắt giữa log, chỉ đọc được DANH SÁCH test fail ở cuối chứ không
    // đọc được message — một test gộp là một điểm mù, ba test thì biết ngay là route,
    // khóa/mở, hay energy/lesson (run 38887445456 đỏ ở test gộp này, không rõ assertion nào).
    testWidgets('fixture mq1_01+mq1_02: route vẫn chỉ tới home, mq1_03 hết khóa, Bug Hunter còn khóa',
        (WidgetTester tester) async {
      final AppServices s = await boot(tester, lessonsDone: <String>['mq1_01', 'mq1_02']);
      final int energyBefore = s.energy.current;

      await tapKey(tester, 'map_hit_bug_hunter');
      expect(find.byKey(const Key('sheet_go_lesson')), findsOneWidget,
          reason: 'mq1_03 chưa xong thì Bug Hunter vẫn khóa và sheet vẫn mời đi tới bài học');
      await tapKey(tester, 'sheet_go_lesson');

      expect(find.byType(MainQuestHomeScreen), findsOneWidget);
      expect(find.byType(LessonScreen), findsNothing, reason: 'route không được tự mở lesson player');
      expect(s.energy.current, energyBefore, reason: 'chỉ đi tới home thì chưa được trừ năng lượng');
      expect(cardShowsLockedHint(tester, 'mq1_03'), isFalse, reason: 'mq1_02 xong rồi thì mq1_03 phải mở');

      await finishTest(tester, s);
    });

    testWidgets('card đã mở vẫn chạm được: toast reward phải tự tắt trước đó', (WidgetTester tester) async {
      final AppServices s = await boot(tester, lessonsDone: <String>['mq1_01', 'mq1_02']);
      await tapKey(tester, 'map_hit_bug_hunter');
      await tapKey(tester, 'sheet_go_lesson');
      // `openActivity` chèn toast reward vào root overlay sau 900 ms và mỗi toast
      // sống 2.8 s (main_map_screen.dart:268-271, reward_toast.dart:20-27). Chờ nó
      // đóng rồi mới kiểm khả năng chạm, để test đo đúng cái cần đo (route + khóa),
      // không ăn may theo thời điểm.
      await pumpFor(tester, const Duration(seconds: 5));
      expect(find.byKey(const Key('lesson_card_mq1_03')).hitTestable(), findsOneWidget,
          reason: 'card mq1_03 phải chạm được ở 390x844 sau khi toast đã tắt');
      await finishTest(tester, s);
    });

    testWidgets('tap card đã mở → LessonScreen đúng bài, energy trừ đúng cost app tính', (WidgetTester tester) async {
      final AppServices s = await boot(tester, lessonsDone: <String>['mq1_01', 'mq1_02']);
      await tapKey(tester, 'map_hit_bug_hunter');
      await tapKey(tester, 'sheet_go_lesson');
      await pumpFor(tester, const Duration(seconds: 5));

      final target = s.mainQuest.lessons.firstWhere((l) => l.id == 'mq1_03');
      // Lấy cost theo đúng rule của `_open` (main_quest_module.dart:103-111) thay vì
      // đoán tên key: mq1_03 hiện challenge=false, nhưng test không được cứng nhắc
      // hơn data mà design đã chốt ở §4 (cost ở CTA, lấy từ config/progression).
      final int expectedCost =
          target.isChallenge ? s.config.cost('chapter_challenge_first') : s.config.cost('main_quest_lesson_first');
      final int before = s.energy.current;
      expect(before, greaterThan(expectedCost), reason: 'fixture phải đủ năng lượng để phép thử có nghĩa');

      await tapKey(tester, 'lesson_card_mq1_03');
      expect(tester.takeException(), isNull, reason: 'LessonScreen nổ khi build thì phải thấy ngay đây');
      expect(find.byType(LessonScreen), findsOneWidget,
          reason: 'tap card đã mở khóa mới vào lesson player (route không auto-start)');
      expect(s.energy.current, before - expectedCost,
          reason: 'vào bài phải trả đúng cost mà app tính cho lesson này');

      await finishTest(tester, s);
    });

    testWidgets('"Để sau" đóng sheet, không đổi route, không phát activityOpened, không tốn năng lượng',
        (WidgetTester tester) async {
      final AppServices s = await boot(tester);
      final List<String> events = recordEvents(s);
      final int energyBefore = s.energy.current;

      await tapKey(tester, 'map_hit_bug_hunter');
      final Finder later = find.widgetWithText(ChunkyButton, 'Để sau');
      expect(later, findsOneWidget);
      await tester.ensureVisible(later);
      await tester.pump();
      await tester.tap(later);
      await pumpFor(tester, const Duration(milliseconds: 900));

      expect(find.byKey(const Key('sheet_go_lesson')), findsNothing, reason: 'sheet phải đã đóng');
      expect(find.byType(MainQuestHomeScreen), findsNothing);
      expect(find.byType(LessonScreen), findsNothing);
      expect(events, isNot(contains(EventTypes.activityOpened)),
          reason: 'hủy ở sheet không được mở activity');
      expect(s.energy.current, energyBefore);

      await finishTest(tester, s);
    });
  });

  group('characterization những gì code đang có/không có (chưa phải kết luận thiết bị)', () {
    testWidgets('characterization keyboard: Tab không đặt focus vào landmark nào (hành vi hiện có)',
        (WidgetTester tester) async {
      final AppServices s = await boot(tester);
      // Ghi lại **hành vi hiện tại** bằng API có thật, không đoán tên: sáu ô chạm là
      // GestureDetector trần (main_map_screen.dart:161-168), không Focus/Actions tường
      // minh nên Tab không có gì để nhảy tới. Đây là baseline cho PQC-008: khi ai đó làm
      // thật, assertion này ĐỔI và buộc tài liệu phải cập nhật — bản thân nó không tuyên
      // bố Android/TalkBack đạt hay không đạt, và không được dùng để đóng PQC-008.
      final FocusNode? before = FocusManager.instance.primaryFocus;
      for (var i = 0; i < 6; i++) {
        // `WidgetTester.sendKeyDownEvent` của SDK này nhận **physical int** vị trí,
        // không có named `logicalKey` (4 error analyze ở run 38889441962 là bằng chứng).
        await tester.sendKeyDownEvent(PhysicalKeyboardKey.tab.usbHidUsage);
        // Nếu engine không map physical 0x2B sang Tab thì phép thử này vô nghĩa —
        // kiểm thẳng vào HardwareKeyboard thay vì giả định.
        expect(HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.tab), isTrue,
            reason: 'sự kiện phải được hiểu là Tab, nếu không kết luận keyboard là rỗng');
        await tester.sendKeyUpEvent(PhysicalKeyboardKey.tab.usbHidUsage);
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      expect(FocusManager.instance.primaryFocus, same(before),
          reason: 'Tab 6 lần không đổi focus node — landmark chưa có target bàn phím');
      // Và bàn phím cũng không mở được sheet: không có route nào bật lên.
      expect(find.byKey(const Key('sheet_go_lesson')), findsNothing);

      await finishTest(tester, s);
    });

    testWidgets('CTA của sheet khai báo button semantics; landmark trên map thì không', (WidgetTester tester) async {
      final AppServices s = await boot(tester);
      await tapKey(tester, 'map_hit_bug_hunter');

      // ChunkyButton tự bọc Semantics(button:true, label:..., excludeSemantics:true)
      // → CTA trong sheet đã có role + tên. Ghi lại thành regression.
      expect(semanticsProps(tester, find.byKey(const Key('sheet_go_lesson'))).where((dynamic p) => p.button == true),
          isNotEmpty,
          reason: 'CTA chính phải còn khai báo là nút trong semantics');
      // Tên đọc được lấy từ chính nhãn nhìn thấy (Semantics của ChunkyButton dùng
      // lại widget.label), nên kiểm cả hai phía thay vì đoán API cây semantics.
      expect(
        find.descendant(of: find.byKey(const Key('sheet_go_lesson')), matching: find.text('Đi tới bài học')),
        findsOneWidget,
      );

      // `map_hit_*` là GestureDetector trần (main_map_screen.dart:161–168), không
      // khai báo Semantics nào. Đây là khoảng trống ở MỨC CODE — review PQC-007
      // nói đúng: chưa được suy thành "TalkBack không tới được", vì GestureDetector
      // không tự loại semantics và `_MapLabel` (map:347–400) còn chứa Text.
      // Cây semantics thật, duplicate node, Tab/Enter/Space và thiết bị vẫn là
      // việc của PQC-008 (runtime=no, chưa được authorize).
      for (final String id in <String>['bug_hunter', 'robot_maze', 'main_quest', 'catch_stars']) {
        final Finder hit = find.byKey(ValueKey<String>('map_hit_$id'));
        expect(hit, findsOneWidget, reason: 'landmark $id phải còn trên map');
        expect(semanticsProps(tester, hit).where((dynamic p) => p.button == true), isEmpty,
            reason: 'map_hit_$id bất ngờ khai báo button — PQC-008 đã được làm, phải cập nhật tài liệu');
        // Nhãn nổi trên map vẫn là Text thường (map:347–400) nên vẫn có khả năng
        // được đọc; đó là lý do KHÔNG được kết luận "TalkBack không tới được".
        expect(find.descendant(of: find.byKey(ValueKey<String>('map_label_$id')), matching: find.byType(Text)),
            findsWidgets, reason: 'landmark $id phải còn nhãn chữ để screen reader còn dữ liệu');
      }

      await finishTest(tester, s);
    });

    testWidgets('card bị khóa không có handler để bấm nhầm, và không có route dự phòng', (WidgetTester tester) async {
      final AppServices s = await boot(tester);
      final int energyBefore = s.energy.current;
      await tapKey(tester, 'map_hit_bug_hunter');
      await tapKey(tester, 'sheet_go_lesson');

      // Khóa là thật: `_unlocked = i == 0 || done.contains(lessons[i - 1].id)`, và
      // screen không có đường vòng nào (không auto-_open, không bỏ prerequisite).
      expect(cardShowsLockedHint(tester, 'mq1_03'), isTrue);
      expect(cardShowsLockedHint(tester, 'mq1_04'), isTrue);
      expect(find.byType(LessonScreen), findsNothing);
      expect(s.energy.current, energyBefore);

      await finishTest(tester, s);
    });
  });
}
