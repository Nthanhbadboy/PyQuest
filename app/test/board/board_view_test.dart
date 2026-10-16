/// Widget test cho `BoardView` (`PQC-010`): hai ví dụ đã duyệt × {360×640, 390×844} ×
/// textScale {1.0, 2.0}, control ≥ 48 logical px, semantics/keyboard, và ảnh PNG do CI chụp.
///
/// Host ở đây là `MaterialApp` trần, **không** đi qua `PyQuestApp` — nên không thể mượn cái
/// clamp `textScaler` 1.2 của app để làm giả việc "font 2.0 vẫn không tràn" (rev 4 §D7).
/// Test tự đọc `MediaQuery` trong cây để chứng minh scale 2.0 được áp thật.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/modules/tutor/board/board_controller.dart';
import 'package:pyquest/modules/tutor/board/board_models.dart';
import 'package:pyquest/modules/tutor/board/board_view.dart';

import 'board_test_support.dart';

const List<Size> kViewportSizes = <Size>[Size(360, 640), Size(390, 844)];
const List<double> kTextScales = <double>[1.0, 2.0];
const List<String> kBoardControlKeys = <String>['board_previous', 'board_replay', 'board_next'];
const List<String> kBoardLocales = <String>['vi', 'en'];

Widget boardHost(
  Widget child, {
  required double textScale,
  Size surface = const Size(360, 640),
}) {
  return MediaQuery(
    data: MediaQueryData(size: surface, textScaler: TextScaler.linear(textScale)),
    child: MaterialApp(home: Scaffold(body: SafeArea(child: child))),
  );
}

void setSurface(WidgetTester tester, Size surface) {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Key của control đang nhận focus — đi ngược từ node focus tới widget mang `ValueKey`.
/// Phép chiếu này nằm **trong vòng lặp** Tab, nên một vòng lặp đi lạc node sẽ nổ ngay tại
/// bước đó thay vì chỉ so tổng số ở cuối.
String? focusedBoardControlKey() {
  final BuildContext? context = FocusManager.instance.primaryFocus?.context;
  if (context is! Element) return null;
  String? found;
  context.visitAncestorElements((Element ancestor) {
    final Key? key = ancestor.widget.key;
    if (key is ValueKey<String> && kBoardControlKeys.contains(key.value)) {
      found = key.value;
      return false;
    }
    return true;
  });
  return found;
}

Future<BoardController> pumpBoard(
  WidgetTester tester, {
  required int planIndex,
  Size surface = const Size(360, 640),
  double textScale = 1.0,
  String locale = 'vi',
  bool reduceMotion = false,
}) async {
  final Map<String, dynamic> plan = composedPlan(planIndex);
  final BoardController controller = BoardController(
    sessionId: 'widget-session',
    locale: locale,
    lessonId: plan['lessonId']! as String,
    stepId: plan['stepId']! as String,
    reduceMotion: reduceMotion,
  );
  final BoardApplyOutcome outcome =
      controller.applyPlan(controller.currentToken, validateComposed(planIndex, locale: locale));
  expect(outcome, BoardApplyOutcome.applied, reason: 'host test phải nhận được plan đã duyệt');
  addTearDown(controller.dispose);
  setSurface(tester, surface);
  await tester.pumpWidget(boardHost(BoardView(controller: controller),
      textScale: textScale, surface: surface));
  return controller;
}

void main() {
  testWidgets('MediaQuery trong host đúng là scale 2.0, không bị clamp', (WidgetTester tester) async {
    double? sampled;
    await tester.pumpWidget(boardHost(
      Builder(builder: (BuildContext context) {
        sampled = MediaQuery.of(context).textScaler.scale(100);
        return const SizedBox.shrink();
      }),
      textScale: 2.0,
    ));
    expect(sampled, 200.0, reason: 'host test không được dùng clamp 1.2 của app để lách font 2');
  });

  for (final Size surface in kViewportSizes) {
    final String sizeName = '${surface.width.round()}x${surface.height.round()}';
    for (final double scale in kTextScales) {
      for (int planIndex = 0; planIndex < 2; planIndex++) {
        final String step = planIndex == 0 ? 'mq1_01_s2' : 'mq1_03_s2';
        testWidgets('$step @ $sizeName font ${scale.toStringAsFixed(1)}: không tràn, không exception',
            (WidgetTester tester) async {
          final BoardController controller = await pumpBoard(
            tester,
            planIndex: planIndex,
            surface: surface,
            textScale: scale,
          );
          expect(tester.takeException(), isNull);
          for (final String key in kBoardControlKeys) {
            final Finder finder = find.byKey(ValueKey<String>(key));
            expect(finder, findsOneWidget, reason: 'thiếu control $key');
            final Rect rect = tester.getRect(finder);
            expect(rect.width, greaterThanOrEqualTo(48), reason: '$key chỉ rộng ${rect.width} px');
            expect(rect.height, greaterThanOrEqualTo(48), reason: '$key chỉ cao ${rect.height} px');
          }
          expect(find.byKey(const ValueKey<String>('board_scaffold')), findsOneWidget);
          expect(find.byKey(const ValueKey<String>('board_caption')), findsOneWidget);
          expect(find.byKey(const ValueKey<String>('board_ink')), findsOneWidget);
          expect(controller.beatCount, 4);

          // Bảng cuộn được là yêu cầu của rev 4 (360×640 + font 2); nếu nội dung vừa khít
          // thì Scrollable không cần cuộn — chỉ kiểm tra nó tồn tại và không lỗi.
          expect(find.byType(Scrollable), findsOneWidget);
          await tester.drag(find.byType(Scrollable), const Offset(0, -40));
          await tester.pump();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('ba lớp tách quyền: clearTutorLayer không đụng nét của trẻ; chính trẻ xóa được',
      (WidgetTester tester) async {
    final BoardController controller =
        await pumpBoard(tester, planIndex: 1, surface: const Size(390, 844));
    controller.learner.addStroke('net-a');
    controller.learner.addStroke('net-b');
    await tester.pump();
    expect(tester.takeException(), isNull);

    controller.next(); // beat 1 của plan numbers mở đầu bằng clearTutorLayer
    await tester.pump();
    expect(controller.learner.strokes, hasLength(2), reason: 'plan không được xóa lớp của trẻ');
    expect(find.byKey(const ValueKey<String>('board_ink')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('board_ink_clear')));
    await tester.pump();
    expect(controller.learner.strokes, isEmpty, reason: 'nút của trẻ vẫn xóa được nét của trẻ');
    expect(tester.takeException(), isNull);
  });

  testWidgets('bấm Tiếp/Trước/Xem lại là điều khiển thật', (WidgetTester tester) async {
    final BoardController controller = await pumpBoard(tester, planIndex: 0);
    final String first = controller.currentBeat!.beatId;
    await tester.tap(find.byKey(const ValueKey<String>('board_next')));
    await tester.pump();
    expect(controller.currentBeat!.beatId, isNot(equals(first)));
    await tester.tap(find.byKey(const ValueKey<String>('board_previous')));
    await tester.pump();
    expect(controller.currentBeat!.beatId, first);
    await tester.tap(find.byKey(const ValueKey<String>('board_replay')));
    await tester.pump();
    expect(controller.beatIndex, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard: mỗi lần Tab tới một control board MỚI, đủ ba control',
      (WidgetTester tester) async {
    await pumpBoard(tester, planIndex: 0);
    final Set<String> visited = <String>{};
    for (int i = 0; i < kBoardControlKeys.length; i++) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
      expect(HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.tab), isTrue,
          reason: 'Tab ${i + 1}: sự kiện không được ghi nhận là Tab -> kết luận focus vô nghĩa');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final String? key = focusedBoardControlKey();
      expect(key, isNotNull, reason: 'Tab ${i + 1} không rơi vào control board nào');
      expect(visited, isNot(contains(key)), reason: 'Tab ${i + 1} quay lại $key — traversal lặp');
      visited.add(key!);
      expect(visited.length, i + 1, reason: 'phải có đúng ${i + 1} control khác nhau sau ${i + 1} Tab');
    }
    expect(visited, containsAll(kBoardControlKeys));
  });

  testWidgets('semantics: altText của beat tới reader; Enter kích hoạt nút đang focus',
      (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    addTearDown(handle.dispose);
    final BoardController controller = await pumpBoard(tester, planIndex: 0);
    final Map<String, dynamic> pack = copyPackByBeat()['mq1_01_s2.b1']!;
    final Map<String, dynamic> vi =
        (pack['copy']! as Map<String, dynamic>)['vi']! as Map<String, dynamic>;
    final String alt = vi['altText']! as String;
    expect(alt, contains('chưa có kết quả'), reason: 'gói design đổi thì test này phải nói cho ta biết');
    expect(find.bySemanticsLabel(RegExp('Tên lệnh print được tô nổi bật')), findsWidgets);
    expect(tester.getSemantics(find.byKey(const ValueKey<String>('board_scaffold'))).toString(),
        contains('1/4'));

    // Enter được đo trên chính nút `board_next`: ở beat 0 thì `previous`/`replay` là no-op
    // hợp lệ, nên chỉ có `next` mới cho bằng chứng "activation thật bằng bàn phím".
    final int beatBefore = controller.beatIndex;
    String? focused;
    for (int i = 0; i < 6 && focused != 'board_next'; i++) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      focused = focusedBoardControlKey();
    }
    expect(focused, 'board_next', reason: 'không tab tới được nút Tiếp sau 6 lần');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(controller.beatIndex, beatBefore + 1,
        reason: 'nút được focus phải điều khiển được bằng bàn phím, không chỉ bằng chạm');
    expect(tester.takeException(), isNull);
  });

  testWidgets('đổi locale tại chỗ: cùng beat, copy khác, ink và code giữ nguyên',
      (WidgetTester tester) async {
    final BoardController controller = await pumpBoard(tester, planIndex: 0, locale: 'vi');
    controller.learner.addStroke('net-cua-tre');
    controller.next();
    await tester.pump();
    final String viCaption = controller.currentCopy!.caption;
    final int beatIndex = controller.beatIndex;

    controller.setLocale('en');
    await tester.pump();
    expect(controller.beatIndex, beatIndex, reason: 'đổi ngôn ngữ không được đưa trẻ về đầu');
    expect(controller.currentCopy!.caption, isNot(equals(viCaption)));
    expect(controller.learner.strokes, <String>['net-cua-tre']);
    expect(find.byKey(const ValueKey<String>('board_caption')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('plan bị reject: bảng hiện fallback có nhãn, không trắng, không crash',
      (WidgetTester tester) async {
    final Map<String, dynamic> plan = composedPlan(0);
    final BoardController controller = BoardController(
      sessionId: 'fallback-session',
      locale: 'vi',
      lessonId: plan['lessonId']! as String,
      stepId: plan['stepId']! as String,
    );
    expect(controller.applyPlan(controller.currentToken, validateComposed(0)), BoardApplyOutcome.applied);
    final BoardValidation broken = validateComposed(
      0,
      source: mutatedSource(0, <Object>['beats', 0, 'copy', 'vi', 'altText'], ''),
    );
    expect(controller.applyPlan(controller.currentToken, broken), BoardApplyOutcome.rejectedPlan);
    setSurface(tester, const Size(360, 640));
    await tester.pumpWidget(boardHost(BoardView(controller: controller), textScale: 1.0));
    expect(find.byKey(const ValueKey<String>('board_fallback')), findsOneWidget);
    expect(find.textContaining('Bảng soạn sẵn'), findsOneWidget);
    expect(controller.beatIndex, 0, reason: 'fallback không được tự nhảy beat');
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('chụp ảnh render CI: 2 plan × 2 khổ × 2 font × 2 locale', (WidgetTester tester) async {
    final Directory outDir = Directory('build/previews');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    final List<String> written = <String>[];
    for (final Size surface in kViewportSizes) {
      final String sizeName = '${surface.width.round()}x${surface.height.round()}';
      for (final double scale in kTextScales) {
        for (int planIndex = 0; planIndex < 2; planIndex++) {
          for (final String locale in kBoardLocales) {
            final String step = planIndex == 0 ? 'mq1_01_s2' : 'mq1_03_s2';
            final String name = 'board-$step-$sizeName-font${scale.toStringAsFixed(1)}-$locale';
            final GlobalKey boundary = GlobalKey(debugLabel: name);
            final Map<String, dynamic> plan = composedPlan(planIndex);
            final BoardController controller = BoardController(
              sessionId: 'shot-$name',
              locale: locale,
              lessonId: plan['lessonId']! as String,
              stepId: plan['stepId']! as String,
            );
            expect(
              controller.applyPlan(controller.currentToken, validateComposed(planIndex, locale: locale)),
              BoardApplyOutcome.applied,
            );
            setSurface(tester, surface);
            await tester.pumpWidget(boardHost(
              RepaintBoundary(key: boundary, child: BoardView(controller: controller)),
              textScale: scale,
              surface: surface,
            ));
            expect(tester.takeException(), isNull);
            final RenderRepaintBoundary render =
                boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
            final ui.Image image =
                (await tester.runAsync(() async => render.toImage(pixelRatio: 2.0)))!;
            final ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            image.dispose();
            expect(bytes, isNotNull, reason: '$name không encode được PNG');
            final File file = File('${outDir.path}/$name.png');
            file.writeAsBytesSync(bytes!.buffer.asUint8List());
            expect(file.lengthSync(), greaterThan(2000), reason: '$name ảnh rỗng');
            written.add('$name=${file.lengthSync()}B');
            controller.dispose();
          }
        }
      }
    }
    expect(written, hasLength(kViewportSizes.length * kTextScales.length * 2 * kBoardLocales.length));
    // render.txt là kênh duy nhất CI in đủ; giữ một dòng tóm tắt ở đây để đối chiếu tên file.
    // ignore: avoid_print
    print('board previews: ${written.join(' ')}');
  });
}
