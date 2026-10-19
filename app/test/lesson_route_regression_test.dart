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
// PQC-008 (Semantics/focus + thiết bị) vẫn còn nguyên: nhóm cuối file từ PQC-020 r2
// kiểm hành vi bàn phím/semantics THẬT của hub R1-A ở mức cây widget, và ghi rõ ở tên
// test rằng thiết bị thật (TalkBack, thứ tự focus của ROM) chưa phải kết luận ở đây.
library;

// `avoid_dynamic_calls`: `SemanticsProperties` không được export từ material.dart của
// SDK mà CI dùng (run 38886724385 cháy analyze vì đoán tên type) → helper dưới đọc
// `properties` qua `dynamic`; mọi kết luận vẫn nằm trong expect.
// ignore_for_file: avoid_dynamic_calls

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/app/activity_registry.dart';
import 'package:pyquest/app/app_services.dart';
import 'package:pyquest/app/pyquest_app.dart';
import 'package:pyquest/core/events.dart';
import 'package:pyquest/l10n/generated/app_localizations.dart';
import 'package:pyquest/modules/main_map/activity_sheet.dart';
import 'package:pyquest/modules/main_map/main_map_scene.dart';
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
/// Hub R1-A lấy tên place từ `placeName(l10n, id)`, nên test nào so tên đọc được
/// trên marker phải biết app đang ở locale nào. Widget-test host báo `en-US`;
/// `systemLocalesReader` dưới đây pin `vi` để mọi case trong file này xác định,
/// cùng kiểu inject đã duyệt cho journey ở PQC-020 r1.
///
/// Không dùng `pumpAndSettle` trên Main Map: app còn các controller chạy vô hạn
/// (logo splash `pyquest_app.dart:169`, `characters.dart:96`) nên cây không bao giờ
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
  await tester.pumpWidget(PyQuestApp(
    servicesFactory: (_) async => s,
    systemLocalesReader: () => const <Locale>[Locale('vi')],
    minSplash: Duration.zero,
  ));
  await pumpFor(tester, const Duration(seconds: 2));
  // Nạp đúng nền hub mà R1-A đang hiển thị + thumbnail thật: landmark được đặt theo
  // khung ảnh, nếu ảnh chưa nạp thì hình học tap không còn giống trên thiết bị.
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
  'assets/images/village_r53.webp',
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

  group('bàn phím + semantics của hub R1-A (mức cây widget; thiết bị vẫn thuộc PQC-008)', () {
    testWidgets('keyboard: Tab/Shift+Tab đi qua sáu marker theo registry, Enter/Space mở đúng sheet, Back trả focus',
        (WidgetTester tester) async {
      final AppServices s = await boot(tester);
      final List<String> events = recordEvents(s);
      final int energyBefore = s.energy.current;
      expect(energyBefore, greaterThan(0), reason: 'fixture phải còn năng lượng thì phép thử mới có nghĩa');

      // FocusNode lấy từ CHÍNH nút map app đã tạo: `_placeFocus` của screen
      // (main_map_screen.dart:48-51) được đưa vào `_PlaceButton` và gán cho
      // TextButton của nó. Test không dựng node riêng và không tự bấm hộ.
      FocusNode placeNode(String id) {
        final Finder button = find.descendant(
          of: find.byKey(ValueKey<String>('map_label_$id')),
          matching: find.byType(TextButton),
        );
        return tester.widget<TextButton>(button).focusNode!;
      }

      final List<String> ids = activityRegistry.map((module) => module.def.id).toList();
      expect(ids, hasLength(6), reason: 'hub đi theo đúng thứ tự activityRegistry');
      final List<FocusNode> nodes = ids.map(placeNode).toList();
      expect(nodes.toSet(), hasLength(6), reason: 'sáu place là sáu focus node khác nhau');

      // CHỈ đặt focus khởi đầu MỘT lần; từ đây mọi bước dịch chuyển là phím thật.
      nodes.first.requestFocus();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, same(nodes.first), reason: 'khởi đầu phải ở ${ids.first}');

      // Tab là traversal, không phải activation: assert TỪNG bước một theo registry,
      // không chỉ so đầu/cuối vòng (bài học phương pháp rev 4 §V1 vẫn giữ nguyên).
      for (int i = 0; i + 1 < nodes.length; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, same(nodes[i + 1]),
            reason: 'Tab #${i + 1} phải sang ${ids[i + 1]}, không phải theo tọa độ ảnh trên map');
      }
      for (int i = nodes.length - 1; i > 0; i--) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, same(nodes[i - 1]),
            reason: 'Shift+Tab ở ${ids[i]} phải lùi về ${ids[i - 1]}');
      }
      // Không giả định "đủ sáu Tab là wrap": hub còn header controls, nên bước cuối
      // chỉ được kết luận là "tiến thêm đúng một node" — ở đây là robot_maze.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, same(nodes[1]), reason: 'Tab phải tiến thêm đúng một node: ${ids[1]}');

      // Enter trên node đang focus mở sheet của CHÍNH place đó.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await pumpFor(tester, const Duration(milliseconds: 700));
      expect(find.byType(ActivitySheet), findsOneWidget, reason: 'Enter kích hoạt place đang focus');
      expect(
        find.descendant(of: find.byType(ActivitySheet), matching: find.text(activityRegistry[1].def.name)),
        findsOneWidget,
        reason: 'sheet mở ra phải là sheet của ${ids[1]}, không phải một sheet bất kỳ',
      );

      // Back đóng sheet; hub phải trả focus về đúng nút đã mở nó.
      await tester.binding.handlePopRoute();
      await pumpFor(tester, const Duration(milliseconds: 700));
      expect(find.byType(ActivitySheet), findsNothing, reason: 'Back đóng activity sheet hiện hành');
      expect(FocusManager.instance.primaryFocus, same(nodes[1]), reason: 'đóng sheet phải trả focus về ${ids[1]}');

      // Space cùng hành vi. Mở rồi đóng sheet không được trừ năng lượng, không được
      // phát activityOpened (event đó chỉ thuộc `openActivity`).
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await pumpFor(tester, const Duration(milliseconds: 700));
      expect(find.byType(ActivitySheet), findsOneWidget, reason: 'Space kích hoạt place đang focus');
      expect(
        find.descendant(of: find.byType(ActivitySheet), matching: find.text(activityRegistry[1].def.name)),
        findsOneWidget,
        reason: 'Space cũng phải mở sheet của ${ids[1]}',
      );
      await tester.binding.handlePopRoute();
      await pumpFor(tester, const Duration(milliseconds: 700));
      expect(find.byType(ActivitySheet), findsNothing);
      expect(FocusManager.instance.primaryFocus, same(nodes[1]));
      expect(s.energy.current, energyBefore, reason: 'chỉ mở rồi đóng sheet thì năng lượng giữ nguyên');
      expect(events, isNot(contains(EventTypes.activityOpened)),
          reason: 'sheet không phải activityOpened; event đó chỉ do openActivity phát');
      expect(tester.takeException(), isNull);

      await finishTest(tester, s);
    });

    testWidgets('semantics: CTA của sheet và sáu marker hub đều có button + tên localized (đo hub sau khi đóng sheet)',
        (WidgetTester tester) async {
      final AppServices s = await boot(tester);
      await tapKey(tester, 'map_hit_bug_hunter');

      // ChunkyButton tự bọc Semantics(button:true, label:..., excludeSemantics:true)
      // → CTA trong sheet đã có role + tên. Ghi lại thành regression.
      expect(
        semanticsProps(tester, find.byKey(const Key('sheet_go_lesson'))).where((dynamic p) => p.button == true),
        isNotEmpty,
        reason: 'CTA chính phải còn khai báo là nút trong semantics',
      );
      // Tên đọc được lấy từ chính nhãn nhìn thấy (Semantics của ChunkyButton dùng
      // lại widget.label), nên kiểm cả hai phía thay vì đoán API cây semantics.
      expect(
        find.descendant(of: find.byKey(const Key('sheet_go_lesson')), matching: find.text('Đi tới bài học')),
        findsOneWidget,
      );

      // Đóng sheet TRƯỚC khi đo hub: nền bị modal che không phải những gì người dùng
      // đọc được trên map, nên đó không phải bằng chứng về semantics của hub.
      await tester.binding.handlePopRoute();
      await pumpFor(tester, const Duration(milliseconds: 700));
      expect(find.byType(ActivitySheet), findsNothing, reason: 'phải đo hub khi không còn sheet che');

      final AppLocalizations l10n =
          AppLocalizations.of(tester.element(find.byKey(const ValueKey<String>('map_label_main_quest'))))!;
      // `_PlaceButton` cố ý bỏ action khi còn loading (main_map_scene.dart:366-380),
      // nên đo ở pha đó sẽ cho "bằng chứng" sai; chờ hub thật sự có dữ liệu đã.
      expect(find.text(l10n.hubLoading), findsNothing, reason: 'sáu status phải về trước khi đo action');

      // Cây semantics THẬT của `map_label_*` (thay cho suy luận từ wrapper `map_hit_*`):
      // đúng một node button, mang tên localized mà R1-A đang hiển thị, có tap action,
      // và nhãn nhìn thấy trùng tên đó.
      for (final module in activityRegistry) {
        final String id = module.def.id;
        final Finder place = find.byKey(ValueKey<String>('map_label_$id'));
        expect(place, findsOneWidget, reason: 'place $id phải còn key map_label_* trên hub');
        final String name = placeName(l10n, id);
        final List<dynamic> buttons = semanticsProps(tester, place).where((dynamic p) => p.button == true).toList();
        expect(buttons, hasLength(1),
            reason: 'map_label_$id phải có đúng MỘT node button: không thiếu, không nhân đôi bởi wrapper');
        final dynamic marker = buttons.single;
        expect(marker.label, contains(name), reason: 'node button của $id phải đọc được tên localized của hub');
        expect(marker.onTap, isNotNull, reason: 'tap action phải gắn trên node semantics, không chỉ trên GestureDetector');
        expect(find.descendant(of: place, matching: find.text(name)), findsWidgets,
            reason: 'nhãn nhìn thấy và nhãn đọc được của $id phải cùng một tên');
      }
      expect(tester.takeException(), isNull);

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
