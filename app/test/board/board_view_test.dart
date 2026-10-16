/// Widget test cho `BoardView` (`PQC-010`), tách **mỗi mối lo một test** để tên test đã là
/// chẩn đoán: `ci/report.py` cắt `test.txt` giữa dòng nên lý do thật không về tới tôi, còn tên
/// thì về đủ.
///
/// Host là `MaterialApp` trần, **không** qua `PyQuestApp` — không mượn clamp `textScaler` 1.2
/// của app để làm giả "font 2.0 không tràn" (rev 4 §D7). Test tự đọc `MediaQuery` để chứng minh
/// scale 2.0 được áp thật.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/modules/tutor/board/board_controller.dart';
import 'package:pyquest/modules/tutor/board/board_models.dart';
import 'package:pyquest/modules/tutor/board/board_view.dart';

import 'board_test_support.dart';

const List<Size> kViewportSizes = <Size>[Size(360, 640), Size(390, 844)];
const List<double> kTextScales = <double>[1.0, 2.0];
const List<String> kBoardControlKeys = <String>['board_previous', 'board_replay', 'board_next'];

String stepOf(int planIndex) => planIndex == 0 ? 'mq1_01_s2' : 'mq1_03_s2';

Widget boardHost(Widget child, {required double textScale, Size surface = const Size(360, 640)}) {
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

/// Key của control đang nhận focus: đi ngược từ node focus tới widget mang `ValueKey` quen thuộc.
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

/// Dựng board với plan đã duyệt; trả về controller. `dispose` do teardown lo — test nào tự
/// dispose thêm sẽ nổ assert của `ChangeNotifier`, nên ở đây không test nào tự gọi.
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
  addTearDown(controller.dispose);
  final BoardApplyOutcome outcome =
      controller.applyPlan(controller.currentToken, validateComposed(planIndex, locale: locale));
  expect(outcome, BoardApplyOutcome.applied, reason: 'host test phải nhận được plan đã duyệt');
  setSurface(tester, surface);
  await tester.pumpWidget(boardHost(BoardView(controller: controller),
      textScale: textScale, surface: surface));
  return controller;
}

void main() {
  testWidgets('host giữ textScale 2.0, không dùng clamp 1.2 của app', (WidgetTester tester) async {
    double? sampled;
    await tester.pumpWidget(boardHost(
      Builder(builder: (BuildContext context) {
        sampled = MediaQuery.of(context).textScaler.scale(100);
        return const SizedBox.shrink();
      }),
      textScale: 2.0,
    ));
    expect(sampled, 200.0);
  });

  for (final Size surface in kViewportSizes) {
    final String sizeName = '${surface.width.round()}x${surface.height.round()}';
    for (final double scale in kTextScales) {
      for (int planIndex = 0; planIndex < 2; planIndex++) {
        testWidgets(
          '${stepOf(planIndex)} @ $sizeName font ${scale.toStringAsFixed(1)} — dựng được, không overflow',
          (WidgetTester tester) async {
            await pumpBoard(tester,
                planIndex: planIndex, surface: surface, textScale: scale);
            expect(tester.takeException(), isNull);
            expect(find.byKey(const ValueKey<String>('board_scaffold')), findsOneWidget);
            expect(find.byKey(const ValueKey<String>('board_title')), findsOneWidget);
            expect(find.byKey(const ValueKey<String>('board_caption')), findsOneWidget);
            expect(find.byKey(const ValueKey<String>('board_ink')), findsOneWidget);
            for (final String key in kBoardControlKeys) {
              expect(find.byKey(ValueKey<String>(key)), findsOneWidget, reason: 'thiếu $key');
            }
          },
        );
      }
    }
  }

  for (final double scale in kTextScales) {
    testWidgets(
      'control của board >= 48x48 logical px ở 360x640 font ${scale.toStringAsFixed(1)}',
      (WidgetTester tester) async {
        await pumpBoard(tester,
            planIndex: 0, surface: const Size(360, 640), textScale: scale);
        for (final String key in kBoardControlKeys) {
          final Rect rect = tester.getRect(find.byKey(ValueKey<String>(key)));
          expect(rect.width, greaterThanOrEqualTo(48), reason: '$key rộng ${rect.width}');
          expect(rect.height, greaterThanOrEqualTo(48), reason: '$key cao ${rect.height}');
        }
      },
    );
  }

  testWidgets('bảng cuộn dọc: Scrollable tồn tại, kéo không nổ', (WidgetTester tester) async {
    await pumpBoard(tester, planIndex: 1, surface: const Size(360, 640), textScale: 2.0);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -60));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('nội dung hiển thị nguyên văn: không diễn giải markup trong Text',
      (WidgetTester tester) async {
    await pumpBoard(tester, planIndex: 0);
    // '<' và ngoặc kép là text thường; board không có kênh markup nào để diễn giải.
    final BoardController c = await controllerOf(tester);
    expect(c.currentCopy!.caption, contains('print'));
    expect(find.textContaining('print'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clearTutorLayer không xóa nét của trẻ', (WidgetTester tester) async {
    final BoardController controller = await pumpBoard(tester, planIndex: 1, surface: const Size(390, 844));
    controller.learner.addStroke('net-a');
    controller.learner.addStroke('net-b');
    await tester.pump();
    controller.next(); // beat này mở đầu bằng clearTutorLayer
    await tester.pump();
    expect(controller.learner.strokes, hasLength(2));
    expect(find.byKey(const ValueKey<String>('board_ink')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chính trẻ xóa được nét của mình', (WidgetTester tester) async {
    final BoardController controller = await pumpBoard(tester, planIndex: 0);
    controller.learner.addStroke('net-x');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('board_ink_clear')));
    await tester.pump();
    expect(controller.learner.strokes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bấm Tiếp/Trước/Xem lại đổi beat thật', (WidgetTester tester) async {
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

  testWidgets('Tab: mỗi lần tới một control board MỚI, đủ ba control', (WidgetTester tester) async {
    await pumpBoard(tester, planIndex: 0);
    final Set<String> visited = <String>{};
    for (int i = 0; i < kBoardControlKeys.length; i++) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
      expect(HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.tab), isTrue,
          reason: 'Tab ${i + 1} không được ghi nhận là Tab');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final String? key = focusedBoardControlKey();
      expect(key, isNotNull, reason: 'Tab ${i + 1} không rơi vào control board nào');
      expect(visited, isNot(contains(key)), reason: 'Tab ${i + 1} quay lại $key — traversal lặp');
      visited.add(key!);
    }
    expect(visited, containsAll(kBoardControlKeys));
  });

  testWidgets('Enter trên nút đang focus kích hoạt thật (đo trên board_next)',
      (WidgetTester tester) async {
    final BoardController controller = await pumpBoard(tester, planIndex: 0);
    final int before = controller.beatIndex;
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
    expect(controller.beatIndex, before + 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('semantics: altText của design là nhãn thật, không phải nhãn chung',
      (WidgetTester tester) async {
    await pumpBoard(tester, planIndex: 0);
    final Map<String, dynamic> pack = copyPackByBeat()['mq1_01_s2.b1']!;
    final Map<String, dynamic> vi =
        (pack['copy']! as Map<String, dynamic>)['vi']! as Map<String, dynamic>;
    final String alt = vi['altText']! as String;
    final List<String> labels = semanticLabels(tester, find.byType(BoardView));
    expect(labels, isNotEmpty, reason: 'board phải tự khai semantics, không trông vào Text');
    expect(labels.any((String l) => l.contains(alt)), isTrue,
        reason: 'altText đã duyệt của design phải là nhãn của một node: $labels');
    expect(labels.any((String l) => _genericLabel.hasMatch(l.trim())), isFalse,
        reason: 'không được lấy "Ảnh minh họa" làm nhãn: $labels');
    expect(labels.any((String l) => l.contains('1/4')), isTrue,
        reason: 'vị trí beat phải đọc được bởi reader: $labels');
    expect(tester.takeException(), isNull);
  });

  testWidgets('plan bị reject: có nhãn fallback, không bảng trắng, không tự nhảy beat',
      (WidgetTester tester) async {
    final Map<String, dynamic> plan = composedPlan(0);
    final BoardController controller = BoardController(
      sessionId: 'fallback-session',
      locale: 'vi',
      lessonId: plan['lessonId']! as String,
      stepId: plan['stepId']! as String,
    );
    addTearDown(controller.dispose);
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
    expect(controller.beatIndex, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('đổi locale tại chỗ: cùng beat, copy khác, ink giữ nguyên',
      (WidgetTester tester) async {
    final BoardController controller = await pumpBoard(tester, planIndex: 0, locale: 'vi');
    controller.learner.addStroke('net-cua-tre');
    controller.next();
    await tester.pump();
    final String viCaption = controller.currentCopy!.caption;
    final int beatIndex = controller.beatIndex;
    controller.setLocale('en');
    await tester.pump();
    expect(controller.beatIndex, beatIndex, reason: 'đổi ngôn ngữ không đưa trẻ về beat đầu');
    expect(controller.currentCopy!.caption, isNot(equals(viCaption)));
    expect(controller.learner.strokes, <String>['net-cua-tre']);
    expect(find.byKey(const ValueKey<String>('board_caption')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<BoardController> controllerOf(WidgetTester tester) async =>
    tester.widget<BoardView>(find.byType(BoardView)).controller;

final RegExp _genericLabel = RegExp(r'^(ảnh|hình|image|illustration|graphic)(\s*minh\s*h[ọo]a)?\.?$',
    caseSensitive: false);

/// Nhãn của mọi node `Semantics` trong `subtree`.
///
/// Đây là idiom **đã có trong repo** (`lesson_route_regression_test.dart:133-143`): đọc
/// `Semantics.properties` từ widget tree, không nêu tên type `SemanticsProperties` (SDK của CI
/// không export nó) và không dùng `find.bySemanticsLabel` — cách đó cần cây semantics đang bật và
/// đã làm chính test này đỏ ở run `ca1e0e3`.
List<String> semanticLabels(WidgetTester tester, Finder subtree) => find
    .descendant(of: subtree, matching: find.byType(Semantics))
    .evaluate()
    .map((Element e) {
      final dynamic w = e.widget;
      final dynamic label = w.properties.label;
      return label is String ? label : '';
    })
    .where((String s) => s.isNotEmpty)
    .toList();
