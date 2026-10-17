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
import 'package:pyquest/modules/tutor/board/board_layout.dart';
import 'package:pyquest/modules/tutor/board/board_models.dart';
import 'package:pyquest/modules/tutor/board/board_view.dart';
import 'package:pyquest/shared/theme/app_theme.dart';

import '../test_helpers.dart';
import 'board_test_support.dart';

const List<Size> kViewportSizes = <Size>[Size(360, 640), Size(390, 844)];
/// 1.0 / 1.3 / 2.0: 1.3 là hệ số Android hay dùng và là bậc mà font thật của app bắt đầu khác
/// với số học trong layout — bỏ nó thì bug "tô một chỗ, neo một nẻo" lọt.
const List<double> kTextScales = <double>[1.0, 1.3, 2.0];
const List<String> kBoardLocales = <String>['vi', 'en'];
const List<String> kBoardControlKeys = <String>['board_previous', 'board_replay', 'board_next'];

String stepOf(int planIndex) => planIndex == 0 ? 'mq1_01_s2' : 'mq1_03_s2';

/// Host của mọi ca widget test.
///
/// rev 9 §R9-B1: trước đây file này không nạp font thật, nên toàn bộ hình học đo trên Ahem —
/// `loadAppFonts()` trong `board_previews_test.dart` chỉ có hiệu lực trong file/isolate của nó.
/// Ahem rộng 1em/vuông 1em, JetBrainsMono và font body của app thì không: khi đó mọi assertion
/// width/height là số của một font không ai dùng, đỏ hay xanh đều không đại diện cho ảnh thật.
Widget boardHost(Widget child, {required double textScale, Size surface = const Size(360, 640)}) {
  return MediaQuery(
    data: MediaQueryData(size: surface, textScaler: TextScaler.linear(textScale)),
    child: MaterialApp(
      theme: ThemeData(fontFamily: PQFonts.body, scaffoldBackgroundColor: Colors.white),
      home: Scaffold(body: SafeArea(child: child)),
    ),
  );
}

void setSurface(WidgetTester tester, Size surface) {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Văn bản thật của một node vẽ (RichText duy nhất bên trong node đó).
String nodeText(WidgetTester tester, String key) {
  final Iterable<Element> found =
      find.descendant(of: find.byKey(ValueKey<String>(key)), matching: find.byType(RichText)).evaluate();
  expect(found, isNotEmpty, reason: '$key phải có chữ để đọc, không phải một hộp rỗng');
  return found.map((Element e) => (e.widget as RichText).text.toPlainText()).join('\n');
}

/// Chuỗi đang được **tô sáng** trong một node: nghiệm thu R7-B là màu nền trên chữ, không phải
/// một dòng mô tả "đã in đậm cái này".
List<String> highlightedIn(WidgetTester tester, String key) {
  final RichText rich = tester.widget<RichText>(
    find.descendant(of: find.byKey(ValueKey<String>(key)), matching: find.byType(RichText)).first,
  );
  final List<String> out = <String>[];
  rich.text.visitChildren((InlineSpan span) {
    if (span is TextSpan && span.style?.backgroundColor != null) out.add(span.text ?? '');
    return true;
  });
  return out;
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
  String codeText = '',
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
  await tester.pumpWidget(boardHost(BoardView(controller: controller, codeText: codeText),
      textScale: textScale, surface: surface));
  return controller;
}

void main() {
  setUpAll(() async {
    // Font thật của app, cùng khuôn với `board_previews_test.dart` — geometry chỉ có nghĩa khi
    // đo trên đúng font sẽ render.
    await loadAppFonts();
  });

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

  // rev 7 §R7-B: bảng phải **vẽ** từ op — code thật được tô, nhóm có đúng số vật, ô kết quả
  // có nội dung, shape theo geometry, connector nối hai hộp. Bằng chứng ở đây là hình học và
  // span màu của renderer, không phải một chuỗi "đã tô" in ra.
  group('R7-B: layer vẽ từ op', () {
    testWidgets('dòng code là node có key, tô sáng bằng màu trên đúng token', (WidgetTester tester) async {
      await pumpBoard(tester, planIndex: 0, codeText: 'print("Xin chào!")');
      expect(find.byKey(const ValueKey<String>('board_code_line_0')), findsOneWidget);
      expect(nodeText(tester, 'board_code_line_0'), 'print("Xin chào!")',
          reason: 'nội dung code phải nguyên văn, không rút gọn, không dịch');
      expect(highlightedIn(tester, 'board_code_line_0'), <String>['print'],
          reason: 'beat 1 nói về `print` -> đúng token đó có nền, không phải cả dòng');
      expect(find.byKey(const ValueKey<String>('board_group_0_1')), findsNothing,
          reason: 'beat này không có tokenGroup thì không được vẽ nhóm');
    });

    testWidgets('op text của beat vẽ thành hộp chữ riêng, không lẫn vào caption',
        (WidgetTester tester) async {
      final BoardController c = await pumpBoard(tester, planIndex: 1);
      // beat 1 plan 1 chỉ có highlightLine + hai nhóm: không có op text nào được bịa thành hộp.
      expect(find.byKey(const ValueKey<String>('board_prose_0_0')), findsNothing);
      c.next();
      await tester.pump();
      c.next();
      await tester.pump();
      c.next();
      await tester.pump();
      expect(c.beatIndex, 3);
      expect(find.byKey(const ValueKey<String>('board_prose_3_0')), findsOneWidget);
      expect(nodeText(tester, 'board_prose_3_0'), contains('Quan sát trước khi kết luận'));
      expect(nodeText(tester, 'board_caption'), isNotEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hai tokenGroup: hộp nhóm 4 rộng hơn nhóm 3 đúng một ô', (WidgetTester tester) async {
      await pumpBoard(tester, planIndex: 1, codeText: 'print(3 + 4)\nprint("3 + 4")');
      expect(find.byKey(const ValueKey<String>('board_group_0_1')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('board_group_0_2')), findsOneWidget);
      final Rect left = tester.getRect(find.byKey(const ValueKey<String>('board_group_0_1')));
      final Rect right = tester.getRect(find.byKey(const ValueKey<String>('board_group_0_2')));
      expect(right.width - left.width, closeTo(24.0, 0.01),
          reason: '(chipSize + chipGap) cho một vật thêm -> số vật thật đã điều khiển hình học');
      expect(right.top, closeTo(left.top, 0.01), reason: 'trái/phải phải ở cùng một hàng');
      expect(right.left, greaterThan(left.right + 15),
          reason: 'nhóm thứ hai nằm bên phải nhóm thứ nhất, không xếp dọc/chồng lấn');
      expect(right.right, lessThanOrEqualTo(360));
      //rev 7: trẻ không phải đọc object ID nội bộ để hiểu 3+4 — ID không được thành chữ.
      expect(find.textContaining('stone-'), findsNothing);
      expect(highlightedIn(tester, 'board_code_line_0'), <String>['print(3 + 4)']);
      expect(highlightedIn(tester, 'board_code_line_1'), isEmpty,
          reason: 'beat này chỉ tô dòng 1; dòng 2 chưa được nhắc tới');
    });

    testWidgets('vi và en: nhãn đổi, code và dấu tô không đổi', (WidgetTester tester) async {
      await pumpBoard(tester, planIndex: 1, locale: 'vi', codeText: 'print(3 + 4)\nprint("3 + 4")');
      expect(semanticLabels(tester, find.byKey(const ValueKey<String>('board_group_0_1'))),
          contains('Ba viên đá ở nhóm bên trái'));
      expect(nodeText(tester, 'board_code_line_0'), 'print(3 + 4)');
      final List<String> viMarked = highlightedIn(tester, 'board_code_line_0');
      await pumpBoard(tester, planIndex: 1, locale: 'en', codeText: 'print(3 + 4)\nprint("3 + 4")');
      expect(semanticLabels(tester, find.byKey(const ValueKey<String>('board_group_0_1'))),
          contains('Three stones in the left group'));
      expect(nodeText(tester, 'board_code_line_0'), 'print(3 + 4)',
          reason: 'code của trẻ không dịch — đổi ngôn ngữ chỉ đổi phần người');
      expect(highlightedIn(tester, 'board_code_line_0'), viMarked);
    });

    testWidgets('clearTutorLayer: node beat trước biến mất, dấu tô cũng mất', (WidgetTester tester) async {
      final BoardController c = await pumpBoard(tester,
          planIndex: 1, codeText: 'print(3 + 4)\nprint("3 + 4")');
      expect(find.byKey(const ValueKey<String>('board_group_0_1')), findsOneWidget);
      c.next();
      await tester.pump();
      expect(c.currentBeat!.beatId, 'mq1_03_s2.b2');
      expect(find.byKey(const ValueKey<String>('board_group_0_1')), findsNothing);
      expect(highlightedIn(tester, 'board_code_line_0'), isEmpty,
          reason: 'lau bảng là xóa cả dấu tô, không chỉ các ô nổi');
      expect(find.byKey(const ValueKey<String>('board_group_1_1')), findsOneWidget);
      final Rect loneGroup = tester.getRect(find.byKey(const ValueKey<String>('board_group_1_1')));
      final Rect canvas = tester.getRect(find.byKey(const ValueKey<String>('board_canvas')));
      expect(loneGroup.left, closeTo(canvas.left + 8, 0.5),
          reason: 'group đơn phải neo ở gutter; không bị đẩy sang phải khi không có sibling');
      expect(find.byKey(const ValueKey<String>('board_output_1_2')), findsOneWidget);
      expect(nodeText(tester, 'board_output_1_2'), contains('7'));
      expect(nodeText(tester, 'board_output_1_2'), isNot(contains('3 + 4')),
          reason: 'ô kết quả onlyFirstLine không được chứa dòng thứ hai của code');
    });

    testWidgets('connector ở beat 3: một vùng vẽ trải từ dòng code tới ô kết quả',
        (WidgetTester tester) async {
      final BoardController c = await pumpBoard(tester, planIndex: 0, codeText: 'print("Xin chào!")');
      c.next();
      await tester.pump();
      c.next();
      await tester.pump();
      expect(c.currentBeat!.beatId, 'mq1_01_s2.b3');
      expect(find.byKey(const ValueKey<String>('board_output_2_1')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('board_connector_2_0')), findsOneWidget);
      final Rect link = tester.getRect(find.byKey(const ValueKey<String>('board_connector_2_0')));
      final Rect line = tester.getRect(find.byKey(const ValueKey<String>('board_code_line_0')));
      final Rect out = tester.getRect(find.byKey(const ValueKey<String>('board_output_2_1')));
      expect(find.descendant(of: find.byKey(const ValueKey<String>('board_connector_2_0')),
              matching: find.byType(RichText)), findsNothing,
          reason: 'connector là nét vẽ, không phải dòng chữ kể tên hai id');
      expect(find.textContaining('cmd-print'), findsNothing,
          reason: 'mũi tên không được in id nội bộ thay vì nối hai hộp');
      expect(link.top, lessThanOrEqualTo(line.top + 0.01), reason: 'mũi tên phải bắt đầu từ dòng code');
      expect(link.bottom, greaterThanOrEqualTo(out.bottom - 0.01), reason: 'và kết thúc ở ô kết quả');
      expect(tester.takeException(), isNull);
    });

    testWidgets('codeSnippet khác code trên bảng -> block code riêng có chữ thật',
        (WidgetTester tester) async {
      final BoardController c = await pumpBoard(tester, planIndex: 0, codeText: 'print("Xin chào!")');
      expect(find.byKey(const ValueKey<String>('board_code_snippet_0_0')), findsNothing,
          reason: 'beat 1 đọc lại đúng dòng code đang có thì không vẽ trùng');
      for (int i = 0; i < 3; i++) {
        expect(c.next() || c.learnerAdvance(), isTrue, reason: 'không tới được beat ${i + 1}');
        await tester.pump();
      }
      expect(c.beatIndex, 3, reason: 'ba bước advance phải đưa tới beat cuối');
      const Key snippetKey = ValueKey<String>('board_code_snippet_3_1');
      expect(find.byKey(snippetKey), findsOneWidget,
          reason: 'beat 4 đưa câu lệnh chưa có trên bảng -> phải có block code riêng');
      expect(nodeText(tester, 'board_code_snippet_3_1'), 'print("Robo thông minh")');
      // rev 7 §R8-C: hộp mẫu cao `số dòng × lineHeight` trong khi con của nó là Container có
      // padding 2+2 và border 1+1 — thiếu 6px đó thì RenderBox báo overflow và ca này đỏ vì
      // `takeException`. Số đo ở đây là của renderer, nên log CI tự giải thích được lệch bao nhiêu.
      final double box = tester.getSize(find.byKey(snippetKey)).height;
      final double text = textHeightIn(tester, find.byKey(snippetKey));
      expect(text, greaterThan(0), reason: 'block mẫu không có chữ để đo');
      expect(box - text, inInclusiveRange(-0.5, 12),
          reason: 'hộp $box so với chữ $text: padding/border chưa được tính vào hộp');
      expect(tester.takeException(), isNull, reason: 'board nổ khi dựng block code mẫu');
    });

    testWidgets('không có codeText thì bảng vẫn dựng được (chế độ caption-only của host thật)',
        (WidgetTester tester) async {
      await pumpBoard(tester, planIndex: 1);
      expect(find.byKey(const ValueKey<String>('board_code_line_0')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('board_code_line_1')), findsNothing,
          reason: 'không có code thì panel một dòng rỗng, không được bịa thêm dòng');
      expect(tester.takeException(), isNull);
    });
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

  // rev 9 §R9-C3: ca Tab PHAI BAT DAU TU MOT BEAT GIUA. O beat 0, `board_previous` bị disable
  // THẬT (`canGoPrevious == false` -> `Focus(canRequestFocus: false)`), nên không vòng Tab nào chạm
  // đủ ba control: đó là hành vi đúng của UI, không phải traversal lặp. Viết ở beat 0 thì test đỏ
  // vì lý do sai, và sửa bằng cách ép nút Previous bật lên là gian lận.
  testWidgets('Tab (beat giữa): mỗi lần tới một control board MỚI, đủ ba control', (WidgetTester tester) async {
    final BoardController controller = await pumpBoard(tester, planIndex: 0);
    controller.next();
    await tester.pump();
    controller.next();
    await tester.pump();
    expect(controller.canGoPrevious, isTrue,
        reason: 'ca nay dung o beat giua de ca ba nut deu ben; beatIndex = ${controller.beatIndex}');
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

    /// Ca riêng cho beat 0: nút Previous bị disable là CHỦ Ý, nên nó không nhận focus — nhưng
    /// traversal không được chết: Tab vẫn quay vòng giữa các control còn bật.
  testWidgets('Tab (beat 0): Previous disabled không nhận focus, vòng Tab vẫn quay', (WidgetTester tester) async {
    final BoardController controller = await pumpBoard(tester, planIndex: 0);
    expect(controller.canGoPrevious, isFalse, reason: 'beat đầu thì Previous phải disabled');
    final Set<String> visited = <String>{};
    for (int i = 0; i < kBoardControlKeys.length + 1; i++) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final String? key = focusedBoardControlKey();
      expect(key, isNotNull, reason: 'Tab ${i + 1} không rơi vào control board nào');
      expect(key, isNot('board_previous'), reason: 'nút disabled mà vẫn nhận focus là sai');
      visited.add(key!);
    }
    expect(visited, containsAll(<String>['board_replay', 'board_next']),
        reason: 'hai control còn lại phải tới được: $visited');
    expect(tester.takeException(), isNull);
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

  testWidgets('R10-D1-visible: initial VI prose and ordered output', (WidgetTester tester) async {
    // Visible text is checked through Text widgets and ordered output lines. The actual localized
    // accessibility label is checked separately in R10-D1-sem; it must not leak into visible text.
    final BoardController controller = await pumpBoard(tester,
        planIndex: 1,
        locale: 'vi',
        reduceMotion: true,
        codeText: 'print(3 + 4)\nprint("3 + 4")');
    controller.learner.addStroke('net-cua-tre');
    while (controller.beatIndex < 2) {
      expect(controller.next() || controller.learnerAdvance(), isTrue,
          reason: 'không tới được beat 2 (đang ở ${controller.beatIndex})');
      await tester.pump();
    }
    // Op `output` của beat 2 là chỗ có altText; lấy thẳng từ plan đã ghép để không tự bịa nhãn.
    final List<dynamic> beatOps = ((composedPlan(1)['beats']! as List<dynamic>)[2]
        as Map<String, dynamic>)['ops']! as List<dynamic>;
    final Map<String, dynamic> alt =
        (beatOps[1] as Map<String, dynamic>)['altText']! as Map<String, dynamic>;
    final String viAlt = alt['vi']! as String;
    final String enAlt = alt['en']! as String;
    expect(viAlt, isNot(enAlt), reason: 'hai bản altText phải khác nhau thì ca này mới phân biệt được');
    // At 360×640 the accumulated tutor content can put the output below the initial viewport.
    // Bring the actual semantic target into view; otherwise a viewport-pruned semantics query is
    // indistinguishable from a missing/localization-broken node.
    await tester.ensureVisible(find.byKey(const ValueKey<String>('board_output_2_1_label')));
    await tester.pumpAndSettle();

    final List<String> vi = allBoardTexts(tester);
    expect(vi, contains('Tiếp'), reason: 'nhãn điều khiển phải là tiếng Việt: $vi');
    expect(vi, contains('Kết quả chạy'), reason: 'nhãn ô kết quả theo locale: $vi');
    expect(vi, contains(controller.currentCopy!.caption),
        reason: 'caption đang áp dụng phải có mặt trong chữ nhìn thấy');
    expect(outputLines(tester, 'board_output_2_1'), <String>['7', '3 + 4'],
        reason: 'ô kết quả của cả đoạn: đúng hai dòng, đúng thứ tự');
    expect(find.byKey(const ValueKey<String>('board_output_1_2')), findsNothing,
        reason: 'output mới thay ô out-box cũ; không để hai kết quả hiện hành cùng nhãn');
    expect(nodeText(tester, 'board_code_line_1'), 'print("3 + 4")');
    // A11y is asserted in a separate focused test so a failing visible-output assertion cannot
    // hide whether the semantic node itself is present and correctly localized.
    expect(vi.any((String t) => t == viAlt), isFalse,
        reason: 'altText không được thành chữ nhìn thấy: đó là kênh riêng');

    expect(tester.takeException(), isNull);
  });

  testWidgets('R10-D2-visible: same controller updates visible text VI→EN',
      (WidgetTester tester) async {
    final BoardController controller = await pumpBoard(tester,
        planIndex: 1, locale: 'vi', reduceMotion: true, codeText: 'print(3 + 4)\nprint("3 + 4")');
    controller.learner.addStroke('net-cua-tre');
    while (controller.beatIndex < 2) {
      expect(controller.next() || controller.learnerAdvance(), isTrue);
      await tester.pump();
    }
    await tester.ensureVisible(find.byKey(const ValueKey<String>('board_output_2_1_label')));
    await tester.pumpAndSettle();
    controller.setLocale('en');
    await tester.pumpAndSettle();
    expect(controller.beatIndex, 2);
    expect(controller.learner.strokes, <String>['net-cua-tre']);
    final List<String> en = allBoardTexts(tester);
    expect(en, contains('Next'), reason: 'nhãn resolve trong builder đang rebuild: $en');
    expect(en, isNot(contains('Tiếp')));
    expect(en, contains('Run output'));
    expect(en, isNot(contains('Kết quả chạy')));
    expect(en, contains(controller.currentCopy!.caption));
    expect(outputLines(tester, 'board_output_2_1'), <String>['7', '3 + 4']);
    expect(nodeText(tester, 'board_code_line_1'), 'print("3 + 4")');
    expect(tester.takeException(), isNull);
  });

  testWidgets('R10-D3-visible: VI→EN→VI preserves beat, ink and localized prose',
      (WidgetTester tester) async {
    final BoardController controller = await pumpBoard(tester,
        planIndex: 1, locale: 'vi', reduceMotion: true, codeText: 'print(3 + 4)\nprint("3 + 4")');
    controller.learner.addStroke('roundtrip-ink');
    while (controller.beatIndex < 2) {
      expect(controller.next() || controller.learnerAdvance(), isTrue);
      await tester.pump();
    }
    await tester.ensureVisible(find.byKey(const ValueKey<String>('board_output_2_1_label')));
    await tester.pumpAndSettle();
    controller.setLocale('en');
    await tester.pumpAndSettle();
    expect(controller.learner.strokes, <String>['roundtrip-ink'], reason: 'ink must survive VI→EN');
    expect(controller.learnerAdvance(), isTrue, reason: 'đến beat chờ trẻ bằng ý định của trẻ');
    await tester.pumpAndSettle();
    expect(nodeText(tester, 'board_prose_3_0'), startsWith('Look before'));
    controller.setLocale('vi');
    await tester.pumpAndSettle();
    expect(controller.beatIndex, 3);
    expect(controller.learner.strokes, <String>['roundtrip-ink'], reason: 'ink must survive EN→VI');
    expect(allBoardTexts(tester), contains('Tiếp'));
    expect(nodeText(tester, 'board_prose_3_0'), startsWith('Quan sát'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('R00-D1-initial: VI setup applies at beat 0 without framework exception',
      (WidgetTester tester) async {
    final BoardController controller = await pumpBoard(tester,
        planIndex: 1, locale: 'vi', reduceMotion: true, codeText: 'print(3 + 4)\nprint("3 + 4")');
    expect(controller.beatIndex, 0,
        reason: 'beat=${controller.beatIndex}, beatId=${controller.currentBeat?.beatId}, locale=${controller.locale}');
    expect(tester.takeException(), isNull,
        reason: 'after initial pump: beat=${controller.beatIndex}, locale=${controller.locale}');
  });

  testWidgets('R00-D1-advance: same-controller next reaches output beat 2',
      (WidgetTester tester) async {
    final BoardController controller = await pumpBoard(tester,
        planIndex: 1, locale: 'vi', reduceMotion: true, codeText: 'print(3 + 4)\nprint("3 + 4")');
    final List<String> checkpoints = <String>[];
    while (controller.beatIndex < 2) {
      checkpoints.add('before next: beat=${controller.beatIndex}, beatId=${controller.currentBeat?.beatId}');
      expect(controller.next() || controller.learnerAdvance(), isTrue,
          reason: checkpoints.join(' | '));
      await tester.pump();
      checkpoints.add('after pump: beat=${controller.beatIndex}, beatId=${controller.currentBeat?.beatId}');
      expect(tester.takeException(), isNull, reason: checkpoints.join(' | '));
    }
    expect(controller.beatIndex, 2, reason: checkpoints.join(' | '));
  });

  testWidgets('R00-D1-key: beat 2 materializes output widget and semantics wrapper',
      (WidgetTester tester) async {
    final BoardController controller = await pumpBoard(tester,
        planIndex: 1, locale: 'vi', reduceMotion: true, codeText: 'print(3 + 4)\nprint("3 + 4")');
    while (controller.beatIndex < 2) {
      expect(controller.next() || controller.learnerAdvance(), isTrue);
      await tester.pump();
    }
    expect(find.byKey(const ValueKey<String>('board_output_2_1')), findsOneWidget,
        reason: 'beat=${controller.beatIndex}, beatId=${controller.currentBeat?.beatId}, locale=${controller.locale}');
    expect(find.byKey(const ValueKey<String>('board_output_2_1_label')), findsOneWidget,
        reason: 'beat=${controller.beatIndex}, beatId=${controller.currentBeat?.beatId}, locale=${controller.locale}');
    expect(tester.takeException(), isNull);
  });

  testWidgets('R00-D1-scroll: target geometry and offset before/after ensureVisible',
      (WidgetTester tester) async {
    final BoardController controller = await pumpBoard(tester,
        planIndex: 1, locale: 'vi', reduceMotion: true, codeText: 'print(3 + 4)\nprint("3 + 4")');
    while (controller.beatIndex < 2) {
      expect(controller.next() || controller.learnerAdvance(), isTrue,
          reason: 'advance failed at beat=${controller.beatIndex}, locale=${controller.locale}');
      await tester.pump();
      expect(tester.takeException(), isNull,
          reason: 'exception after advance: beat=${controller.beatIndex}, locale=${controller.locale}');
    }
    final Finder target = find.byKey(const ValueKey<String>('board_output_2_1_label'));
    final Finder viewportFinder = find.byType(SingleChildScrollView);
    expect(target, findsOneWidget, reason: 'pre-scroll target count=${target.evaluate().length}');
    expect(viewportFinder, findsOneWidget);
    final Rect targetBefore = tester.getRect(target);
    final Rect viewport = tester.getRect(viewportFinder);
    final double offsetBefore = tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    final Rect targetAfter = tester.getRect(target);
    final double offsetAfter = tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
    expect(tester.takeException(), isNull,
        reason: 'after ensureVisible targetBefore=$targetBefore targetAfter=$targetAfter '
            'viewport=$viewport offset=$offsetBefore->$offsetAfter beat=${controller.beatIndex} '
            'locale=${controller.locale}');
    expect(targetAfter.overlaps(viewport), isTrue,
        reason: 'target did not enter viewport: before=$targetBefore after=$targetAfter '
            'viewport=$viewport offset=$offsetBefore->$offsetAfter');
  });

  testWidgets('R10-D1-sem-VI: output node contains the authored Vietnamese label',
      (WidgetTester tester) async {
    final BoardController controller = await pumpBoard(tester,
        planIndex: 1, locale: 'vi', reduceMotion: true, codeText: 'print(3 + 4)\nprint("3 + 4")');
    while (controller.beatIndex < 2) {
      expect(controller.next() || controller.learnerAdvance(), isTrue);
      await tester.pump();
    }
    await tester.ensureVisible(find.byKey(const ValueKey<String>('board_output_2_1_label')));
    await tester.pumpAndSettle();
    final List<dynamic> beatOps = ((composedPlan(1)['beats']! as List<dynamic>)[2]
        as Map<String, dynamic>)['ops']! as List<dynamic>;
    // Controller beat index 2 is fixture beat 3: op 0 highlights the second code line and op 1
    // is the whole-run output. Read that output's authored label, not the previous beat's group.
    final Map<String, dynamic> alt =
        (beatOps[1] as Map<String, dynamic>)['altText']! as Map<String, dynamic>;
    final String viAlt = alt['vi']! as String;
    final String actual = tester
        .getSemantics(find.byKey(const ValueKey<String>('board_output_2_1_label')))
        .label;
    expect(actual, contains(viAlt), reason: 'expected VI "$viAlt", actual "$actual"');
    expect(actual, isNot(contains(alt['en']! as String)),
        reason: 'initial VI node must not expose EN: "$actual"');
  }, semanticsEnabled: true);

  testWidgets('R10-D2-sem: sau setLocale(en), semantic output cập nhật sang EN',
      (WidgetTester tester) async {
    final BoardController controller = await pumpBoard(tester,
        planIndex: 1, locale: 'vi', reduceMotion: true, codeText: 'print(3 + 4)\nprint("3 + 4")');
    while (controller.beatIndex < 2) {
      expect(controller.next() || controller.learnerAdvance(), isTrue);
      await tester.pump();
    }
    await tester.ensureVisible(find.byKey(const ValueKey<String>('board_output_2_1_label')));
    await tester.pumpAndSettle();
    final List<dynamic> beatOps = ((composedPlan(1)['beats']! as List<dynamic>)[2]
        as Map<String, dynamic>)['ops']! as List<dynamic>;
    final Map<String, dynamic> alt =
        (beatOps[1] as Map<String, dynamic>)['altText']! as Map<String, dynamic>;
    controller.setLocale('en');
    await tester.pumpAndSettle();
    final String actual = tester
        .getSemantics(find.byKey(const ValueKey<String>('board_output_2_1_label')))
        .label;
    expect(actual, contains(alt['en']! as String), reason: 'expected EN, actual "$actual"');
    expect(actual, isNot(contains(alt['vi']! as String)));
  }, semanticsEnabled: true);

  testWidgets('R10-D3-sem: sau advance và EN→VI, semantic output trở lại VI',
      (WidgetTester tester) async {
    final BoardController controller = await pumpBoard(tester,
        planIndex: 1, locale: 'vi', reduceMotion: true, codeText: 'print(3 + 4)\nprint("3 + 4")');
    while (controller.beatIndex < 2) {
      expect(controller.next() || controller.learnerAdvance(), isTrue);
      await tester.pump();
    }
    await tester.ensureVisible(find.byKey(const ValueKey<String>('board_output_2_1_label')));
    await tester.pumpAndSettle();
    final List<dynamic> beatOps = ((composedPlan(1)['beats']! as List<dynamic>)[2]
        as Map<String, dynamic>)['ops']! as List<dynamic>;
    final Map<String, dynamic> alt =
        (beatOps[1] as Map<String, dynamic>)['altText']! as Map<String, dynamic>;
    controller.setLocale('en');
    await tester.pumpAndSettle();
    expect(controller.learnerAdvance(), isTrue);
    await tester.pumpAndSettle();
    expect(nodeText(tester, 'board_prose_3_0'), startsWith('Look before'));
    controller.setLocale('vi');
    await tester.pumpAndSettle();
    expect(controller.beatIndex, 3);
    await tester.ensureVisible(find.byKey(const ValueKey<String>('board_output_2_1_label')));
    await tester.pumpAndSettle();
    final String actual = tester
        .getSemantics(find.byKey(const ValueKey<String>('board_output_2_1_label')))
        .label;
    expect(actual, contains(alt['vi']! as String), reason: 'expected VI after EN→VI, actual "$actual"');
    expect(actual, isNot(contains(alt['en']! as String)));
  }, semanticsEnabled: true);

  testWidgets('r7 §R7-C: fallback notice lưu MÃ, câu chữ theo locale hiện hành', (WidgetTester tester) async {
    final Map<String, dynamic> plan = composedPlan(0);
    final BoardController controller = BoardController(
      sessionId: 'locale-fallback-session',
      locale: 'vi',
      lessonId: plan['lessonId']! as String,
      stepId: plan['stepId']! as String,
    );
    addTearDown(controller.dispose);
    expect(controller.applyPlan(controller.currentToken, validateComposed(0)), BoardApplyOutcome.applied);
    final BoardValidation broken = validateComposed(
      0,
      source: mutatedSource(0, <Object>['beats', 0, 'ops', 1, 'token'], 'printf'),
    );
    expect(broken.accepted, isFalse);
    // Lỗi xảy ra lúc board đang ở VI.
    expect(controller.applyPlan(controller.currentToken, broken), BoardApplyOutcome.rejectedPlan);
    setSurface(tester, const Size(360, 640));
    await tester.pumpWidget(boardHost(BoardView(controller: controller), textScale: 1.0));
    expect(controller.fallbackReason, BoardFallbackReason.rejectedPlan);
    expect(allBoardTexts(tester).any((String t) => t.contains('Bảng tác giả không hợp lệ')), isTrue);

    controller.setLocale('en');
    await tester.pump();
    final List<String> en = allBoardTexts(tester);
    expect(en.any((String t) => t.contains('The authored board was rejected')), isTrue,
        reason: 'notice phải được dịch lại theo locale mới, không treo câu tiếng cũ: $en');
    expect(en.any((String t) => t.contains('Bảng tác giả không hợp lệ')), isFalse);
    // Controller không giữ chuỗi đã dịch — chỉ giữ mã.
    expect(controller.fallbackReason!.name, 'rejectedPlan');
    expect(tester.takeException(), isNull);
  });

  // rev 8 §R8-C: ma trận 96 combo (2 plan × 4 beat × 2 locale × 2 khổ 360x640/390x844 ×
  // fontScale {1.0, 1.3, 2.0}). MỖI NHÓM KIỂM TRA LÀ MỘT declaration, và mỗi declaration dựng lại
  // TẤT CẢ 96 combo. Trước đây mỗi combo một declaration: khi cả 96 cùng đỏ thì báo cáo CI (giữ
  // đầu + đuôi, cắt giữa) chỉ hiện bốn tên và không ai biết nhóm kiểm tra nào sai — thông tin
  // duy nhất còn lại là "96 đỏ". Gộp theo nhóm thì tên declaration chính là chẩn đoán, còn
  // coverage không giảm: vẫn đi từng combo bằng pumpWidget + next()/learnerAdvance() thật.
  //
  // Mọi số đo lấy từ renderer (`getRect`/`getSize`/cây `RichText` thật), không so với công thức
  // chữ trong model — ngoại lệ duy nhất là nhóm (7), nơi so TỶ SỐ giữa hai lần dựng thật.
  testWidgets('ma trận 96 ca · (1) khung chrome, đủ control, không nổ khi dựng', (WidgetTester tester) async {
    final List<String> bad = await forEachMatrixCombo(tester, (MatrixProbe p) {
      for (final String key in <String>[
        'board_scaffold', 'board_title', 'board_say', 'board_caption', 'board_ink', 'board_canvas',
        ...kBoardControlKeys,
      ]) {
        expect(p.box(key), findsOneWidget, reason: '${p.tag}: thiếu $key');
      }
      for (final String key in kBoardControlKeys) {
        final Size s = p.sizeOf(key);
        expect(s.width, greaterThanOrEqualTo(48), reason: '${p.tag}: $key rộng ${s.width}');
        expect(s.height, greaterThanOrEqualTo(48), reason: '${p.tag}: $key cao ${s.height}');
      }
      expect(tester.takeException(), isNull, reason: '${p.tag}: board nổ khi dựng/cỡ chữ');
    });
    expect(bad, isEmpty, reason: '${bad.length}/96 combo hỏng:\n${bad.join('\n')}');
  });

  testWidgets('ma trận 96 ca · (2) hộp của mỗi op đang thấy nằm trong canvas', (WidgetTester tester) async {
    final List<String> bad = await forEachMatrixCombo(tester, (MatrixProbe p) {
      for (final BoardVisibleOp entry in p.visible) {
        for (final String key in p.expectedKeys(entry)) {
          expect(p.box(key), findsOneWidget,
              reason: '${p.tag}: op ${entry.op.kind.wire} không có hộp $key');
          final Rect r = p.rectOf(key);
          expect(r.right, lessThanOrEqualTo(p.canvas.right + 0.5),
              reason: '${p.tag}: $key tràn phải (${r.right} > ${p.canvas.right})');
          expect(r.bottom, lessThanOrEqualTo(p.canvas.bottom + 0.5),
              reason: '${p.tag}: $key tràn dưới (${r.bottom} > ${p.canvas.bottom})');
          expect(r.left, greaterThanOrEqualTo(p.canvas.left - 0.5), reason: '${p.tag}: $key tràn trái');
          expect(r.top, greaterThanOrEqualTo(p.canvas.top - 0.5), reason: '${p.tag}: $key tràn trên');
        }
      }
    });
    expect(bad, isEmpty, reason: '${bad.length}/96 combo hỏng:\n${bad.join('\n')}');
  });

  testWidgets('ma trận 96 ca · (3) hộp của beat sau chưa được vẽ', (WidgetTester tester) async {
    final List<String> bad = await forEachMatrixCombo(tester, (MatrixProbe p) {
      for (final BoardVisibleOp future in boardOpsAfter(p.plan, p.beat)) {
        for (final String key in boardNodeKeys(future)) {
          expect(p.box(key), findsNothing,
              reason: '${p.tag}: $key là của beat ${future.beatIndex}, chưa tới mà đã vẽ');
        }
      }
    });
    expect(bad, isEmpty, reason: '${bad.length}/96 combo hỏng:\n${bad.join('\n')}');
  });

  testWidgets('ma trận 96 ca · (4) nhóm vật = số ô × (18+6), đo từng ô một', (WidgetTester tester) async {
    final List<String> bad = await forEachMatrixCombo(tester, (MatrixProbe p) {
      final double step = BoardLayout.chipSize + BoardLayout.chipGap;
      for (final BoardVisibleOp entry in p.visible) {
        if (entry.op.kind != BoardOpKind.tokenGroup) continue;
        // Key mang beat của CHÍNH op (bảng tích luỹ: hộp của beat trước vẫn còn trên bảng).
        final String key = 'board_group_${entry.beatIndex}_${entry.opIndex}';
        final Rect r = p.rectOf(key);
        expect(r.width, closeTo(entry.op.tokenIds.length * step, 0.51),
            reason: '${p.tag}: $key có ${entry.op.tokenIds.length} vật, rộng ${r.width}');
        double previousRight = r.left;
        for (int k = 0; k < entry.op.tokenIds.length; k++) {
          final Rect chip = p.rectOf('${key}_chip_$k');
          expect(chip.width, closeTo(step, 0.51), reason: '${p.tag}: vật $k rộng ${chip.width}');
          expect(chip.left, closeTo(previousRight, 0.51),
              reason: '${p.tag}: vật $k lệch nhịp: ${chip.left} vs $previousRight');
          previousRight = chip.right;
        }
      }
    });
    expect(bad, isEmpty, reason: '${bad.length}/96 combo hỏng:\n${bad.join('\n')}');
  });

  testWidgets('ma trận 96 ca · (5) hộp chữ: cao độ hộp ôm đúng chữ đã xếp, kể chrome', (WidgetTester tester) async {
    final List<String> bad = await forEachMatrixCombo(tester, (MatrixProbe p) {
      for (final BoardVisibleOp entry in p.visible) {
        final BoardOpKind kind = entry.op.kind;
        if (kind != BoardOpKind.text && kind != BoardOpKind.output && kind != BoardOpKind.codeSnippet) {
          continue;
        }
        final List<String> keys = p.expectedKeys(entry);
        if (keys.isEmpty) continue; // `codeSnippet` trùng code thì không có hộp riêng
        final String key = keys.single;
        final Rect r = p.rectOf(key);
        final double text = p.textHeight(key);
        expect(r.height - text, inInclusiveRange(-0.5, 12),
            reason: '${p.tag}: $key cao ${r.height}, chữ đã xếp $text -> hộp không theo nội dung');
        if (kind == BoardOpKind.output) {
          final int lines = entry.op.value.split('\n').length;
          final int rich =
              find.descendant(of: p.box(key), matching: find.byType(RichText)).evaluate().length;
          expect(rich, lines + 1,
              reason: '${p.tag}: $key phải có ${lines + 1} dòng chữ (kể nhãn), thấy $rich');
        }
      }
    });
    expect(bad, isEmpty, reason: '${bad.length}/96 combo hỏng:\n${bad.join('\n')}');
  });

  testWidgets('ma trận 96 ca · (6) dòng code: nguyên văn code của bước, không bị co chữ', (WidgetTester tester) async {
    final List<String> bad = await forEachMatrixCombo(tester, (MatrixProbe p) {
      for (final BoardNode node in p.layout.nodes) {
        if (node.kind != BoardNodeKind.codeLine) continue;
        expect(p.box(node.key), findsOneWidget, reason: '${p.tag}: thiếu ${node.key}');
        expect(p.text(node.key), node.runs.map((BoardRun r) => r.text).join(),
            reason: '${p.tag}: ${node.key} không nguyên văn code của bước học');
        // `FittedBox(scaleDown)` cho phép co chữ để vừa hộp; "không tràn" lúc đó chỉ có nghĩa là
        // chữ đã nhỏ lại. So chữ với CHÍNH hộp đang dựng (không dùng công thức cỡ chữ): cao hơn
        // hộp = tràn, thấp hơn hộp = chữ đang bị co hoặc layout và widget dùng hai số khác nhau.
        final Size natural = tester
            .getSize(find.descendant(of: p.box(node.key), matching: find.byType(RichText)).first);
        final double boxHeight = p.sizeOf(node.key).height;
        expect(natural.height, lessThanOrEqualTo(boxHeight + 0.5),
            reason: '${p.tag}: ${node.key} cao hơn hộp của nó ($natural > $boxHeight)');
        expect(boxHeight - natural.height, lessThanOrEqualTo(1.0),
            reason: '${p.tag}: ${node.key} có hộp cao hơn chữ ${(boxHeight - natural.height).toStringAsFixed(2)}px '
                '-> `lineHeight` của layout và cỡ chữ đã vẽ không còn cùng một số');
        expect(natural.width, lessThanOrEqualTo(p.sizeOf(node.key).width + 0.5),
            reason: '${p.tag}: ${node.key} phải co chữ để vừa hộp '
                '(${natural.width} > ${p.sizeOf(node.key).width})');
      }
    });
    expect(bad, isEmpty, reason: '${bad.length}/96 combo hỏng:\n${bad.join('\n')}');
  });

  // (7) rev 10 §R10-D: tách phép đo cỡ chữ khỏi phép đo highlight. Dùng statement thật, đúng với
  // plan, trên một dòng ngắn không wrap; các ca highlight/host mismatch được kiểm riêng. Board tự
  // scale cỡ chữ (`scaler.scale(...)`) rồi tắt kế thừa scaler; kiểm fontSize, noScaling và line
  // height độc lập để phân biệt scale sai với paragraph reflow.
  //   (a) cỡ chữ THẬT của paragraph đã tô = 13 × scale   -> 'layer nuốt scale' cho 13 ở 2.0,
  //       'host mượn clamp 1.2 của LessonScreen' cho 15.6;
  //   (b) paragraph mang `TextScaler.noScaling`           -> scale bị áp HAI LẦN;
  //   (c) tỷ số cao độ của MỘT dòng ngắn chắc chắn không wrap = đúng 2.0 -> reflow không được lẫn
  //       vào số đo (bản cũ so tổng cao độ ba hộp, nên đổi font sang font thật là tỷ số đổi theo
  //       lý do sai, và 1,832 đã_trượt qua mắt người).
  for (final Size surface in kViewportSizes) {
    final String sizeName = '${surface.width.round()}x${surface.height.round()}';
    for (final String locale in kBoardLocales) {
      testWidgets(
        '§R10-D: scale một dòng không wrap, không lẫn reflow, $sizeName/$locale',
        (WidgetTester tester) async {
          Future<(double, TextScaler, double, double)> measureAt(double scale) async {
            await pumpBoard(tester,
                planIndex: 0,
                surface: surface,
                textScale: scale,
                locale: locale,
                codeText: 'print("Xin chào!")'); // statement đúng của plan; không wrap ở 360/font 2.0
            await tester.pumpAndSettle();
            final Finder line = find
                .descendant(
                    of: find.byKey(const ValueKey<String>('board_code_line_0')),
                    matching: find.byType(RichText))
                .first;
            final RichText painted = tester.widget<RichText>(line);
            final TextSpan root = painted.text as TextSpan;
            final TextPainter expected = TextPainter(
              text: painted.text,
              textDirection: painted.textDirection,
              textScaler: painted.textScaler,
            )..layout(maxWidth: double.infinity);
            final double expectedHeight = expected.height;
            expected.dispose();
            return (root.style!.fontSize!, painted.textScaler, tester.getSize(line).height, expectedHeight);
          }

          final (double sizeOne, TextScaler scalerOne, double heightOne, double expectedHeightOne) =
              await measureAt(1.0);
          final (double sizeTwo, TextScaler scalerTwo, double heightTwo, double expectedHeightTwo) =
              await measureAt(2.0);
          expect(sizeOne, closeTo(13.0, 0.01), reason: '$sizeName/$locale: cỡ chữ ở 1.0 = $sizeOne');
          expect(sizeTwo, closeTo(26.0, 0.01),
              reason: '$sizeName/$locale: cỡ chữ ở 2.0 = $sizeTwo — 13 = scale bị nuốt, '
                  '15.6 = host kẹp 1.2 của app bị mượn để áp vào board');
          expect(scalerOne.scale(100), closeTo(100.0, 0.01),
              reason: '$sizeName/$locale: paragraph không được tự nhân scale lần hai');
          expect(scalerTwo.scale(100), closeTo(100.0, 0.01),
              reason: '$sizeName/$locale: scale đã áp ở cỡ chữ rồi, paragraph phải mang noScaling');
          expect(heightOne, closeTo(expectedHeightOne, 0.5),
              reason: '$sizeName/$locale: line 1 actual=$heightOne expected TextPainter=$expectedHeightOne');
          expect(heightTwo, closeTo(expectedHeightTwo, 0.5),
              reason: '$sizeName/$locale: line 2 actual=$heightTwo expected TextPainter=$expectedHeightTwo; '
                  'fontSize=$sizeTwo scaler=${scalerTwo.scale(100)}');
          // (d) wrap được phép, tràn thì không: hộp phải cao đủ cho đoạn chữ đã xếp dòng.
          final Size box = tester.getSize(find.byKey(const ValueKey<String>('board_code_line_0')));
          final Size text = tester.getSize(find
              .descendant(
                  of: find.byKey(const ValueKey<String>('board_code_line_0')),
                  matching: find.byType(RichText))
              .first);
          expect(text.width, lessThanOrEqualTo(box.width + 0.5),
              reason: '$sizeName/$locale: chữ ${text.width} ngang hơn hộp ${box.width}');
          expect(text.height, lessThanOrEqualTo(box.height + 0.5),
              reason: '$sizeName/$locale: chữ ${text.height} cao hơn hộp ${box.height}');
        },
      );
    }
  }
}



/// Mọi chữ nhìn thấy được trong cây: `Text.data` và cả `RichText` (TextSpan nhiều đoạn),
/// vì renderer hợp lệ có thể tô sáng bằng span thay vì một chuỗi duy nhất.
/// Hộp mà renderer buộc phải dựng cho một op (key do layout sinh theo khuôn `beat_opIndex`).
/// `codeSnippet` chỉ có hộp khi câu lệnh KHÁC code đang có trên bảng, còn `highlight*` và
/// `clearTutorLayer` là trạng thái của dòng code — hai ca đó do layout test và ca
/// "block code riêng" ở dưới lo, không phải chỗ này.
List<String> boardNodeKeys(BoardVisibleOp entry) {
  final String suffix = '${entry.beatIndex}_${entry.opIndex}';
  switch (entry.op.kind) {
    case BoardOpKind.text:
      return <String>['board_prose_$suffix'];
    case BoardOpKind.output:
      return <String>['board_output_$suffix'];
    case BoardOpKind.simpleShape:
      return <String>['board_shape_$suffix'];
    case BoardOpKind.tokenGroup:
      return <String>['board_group_$suffix'];
    case BoardOpKind.connector:
      return <String>['board_connector_$suffix'];
    case BoardOpKind.codeSnippet:
      // rev 9 §R9-C1: `codeSnippet` CÓ hộp riêng khi nó khác code đang có trên bảng — đó là
      // "block code riêng có chữ thật" của greeting b1 và numbers b4, hai ca mà bản trước bỏ
      // khỏi 96 combo chỉ vì hàm này trả []. Trường hợp ngược lại (snippet trùng code) thì không
      // có hộp nào, xem [snippetNeedsBox].
      return <String>['board_code_snippet_$suffix'];
    case BoardOpKind.highlightToken:
    case BoardOpKind.highlightLine:
    case BoardOpKind.clearTutorLayer:
    case BoardOpKind.unknown:
      return const <String>[];
  }
}

/// Ops của các beat CHƯA tới — dùng để chứng minh bảng không vẽ trước nội dung tương lai.
List<BoardVisibleOp> boardOpsAfter(TeachingPlan plan, int beat) {
  final List<BoardVisibleOp> out = <BoardVisibleOp>[];
  for (int b = beat + 1; b < plan.beats.length; b++) {
    for (int i = 0; i < plan.beats[b].ops.length; i++) {
      out.add(BoardVisibleOp(beatIndex: b, opIndex: i, op: plan.beats[b].ops[i]));
    }
  }
  return out;
}

/// `codeSnippet` chỉ có hộp riêng khi ít nhất một dòng của nó CHƯA xuất hiện trong `code` mà host
/// đưa vào — viết lại đúng điều kiện của layout (`snippet.any((l) => !codeLines.contains(l))`) để
/// test đòi sự tồn tại của hộp mà không phải đo lại số đo của hộp.
bool snippetNeedsBox(BoardOp op, String code, String locale) {
  final List<String> lines = code.split('\n');
  return op.proseFor(locale).split('\n').any((String l) => !lines.contains(l));
}

/// Tổng chiều cao chữ mà renderer đã xếp bên trong một hộp.
///
/// Dùng `getSize` + `Finder.at` thay vì `getAllSize`/`getSizeList`: vòng trước tôi đoán tên API
/// nhóm này và trả giá bằng một run đỏ vì `undefined_method` (đỏ cả file, 23 ca không chạy).
double textHeightIn(WidgetTester tester, Finder box) {
  final Finder texts = find.descendant(of: box, matching: find.byType(RichText));
  final int count = texts.evaluate().length;
  double sum = 0;
  for (int i = 0; i < count; i++) {
    sum += tester.getSize(texts.at(i)).height;
  }
  return sum;
}

/// Các dòng của một ô kết quả, **theo thứ tự vẽ**, không tính nhãn header.
///
/// Renderer đặt mỗi dòng output thành một `Text` riêng — nên đừng tìm chuỗi gộp
/// `'7\n3 + 4'` trong `allBoardTexts`: không có widget nào mang chuỗi đó, và đó là lý do ca
/// live-locale cũ đỏ dù bảng vẽ đúng.
List<String> outputLines(WidgetTester tester, String key) => find
    .descendant(of: find.byKey(ValueKey<String>(key)), matching: find.byType(RichText))
    .evaluate()
    .map((Element e) => (e.widget as RichText).text.toPlainText())
    .toList()
    .sublist(1);

List<String> allBoardTexts(WidgetTester tester) {
  final List<String> out = <String>[];
  for (final Element e in find.byType(Text).evaluate()) {
    final Text w = e.widget as Text;
    final String? data = w.data;
    if (data != null) out.add(data);
  }
  for (final Element e in find.byType(RichText).evaluate()) {
    final dynamic w = e.widget;
    final dynamic inline = w.text;
    out.add(inline.toPlainText() as String);
  }
  return out;
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

/// Một combo đã dựng của ma trận: widget đang nằm trên cây + những thứ nhóm kiểm tra cần đo.
class MatrixProbe {
  MatrixProbe({
    required this.tester,
    required this.tag,
    required this.beat,
    required this.locale,
    required this.code,
    required this.plan,
    required this.visible,
    required this.layout,
    required this.canvas,
  });

  final WidgetTester tester;
  final String tag;
  final int beat;
  final String locale;
  final String code;
  final TeachingPlan plan;
  final List<BoardVisibleOp> visible;

  /// Layout dựng lại với ĐÚNG số đo canvas đang thấy. Chỉ dùng để lấy danh sách node/chuỗi kỳ vọng;
  /// mọi assertion về kích thước vẫn so giữavới hộp đã vẽ, không so với số ở đây.
  final BoardLayout layout;
  final Rect canvas;

  /// Key của các hộp mà op này bắt buộc phải dựng, đã lọc theo điều kiện thật của layout
  /// (`codeSnippet` chỉ có hộp khi nó khác code của host — rev 9 §R9-C1).
  List<String> expectedKeys(BoardVisibleOp entry) => boardNodeKeys(entry)
      .where((String k) =>
          !k.startsWith('board_code_snippet_') || snippetNeedsBox(entry.op, code, locale))
      .toList();

  Finder box(String key) => find.byKey(ValueKey<String>(key));
  Size sizeOf(String key) => tester.getSize(box(key));
  Rect rectOf(String key) => tester.getRect(box(key));
  double textHeight(String key) => textHeightIn(tester, box(key));
  String text(String key) => nodeText(tester, key);
}

/// Dựng lại từng combo trong 96 combo và gom lỗi của [body] về cho declaration gọi nó.
///
/// Lý do gom lỗi: `flutter analyze` và `flutter test --reporter expanded` đều bị cắt giữa trong
/// báo cáo CI, nên 96 failure rải ở 96 declaration chỉ còn lại bốn cái tên. Ở đây một declaration
/// trả về danh sách `tag → dòng lỗi đầu tiên`, đủ để biết nhóm nào sai và sai ở combo nào khi đọc
/// log đầy đủ, mà không làm mất ca nào.
Future<List<String>> forEachMatrixCombo(
  WidgetTester tester,
  void Function(MatrixProbe p) body,
) async {
  final List<String> bad = <String>[];
  int seen = 0;
  for (final Size surface in kViewportSizes) {
    final String sizeName = '${surface.width.round()}x${surface.height.round()}';
    for (final double scale in kTextScales) {
      for (final String locale in kBoardLocales) {
        for (int planIndex = 0; planIndex < 2; planIndex++) {
          final String code = exampleCodeForStep(stepOf(planIndex));
          for (int beat = 0; beat < 4; beat++) {
            seen++;
            final String tag =
                '${stepOf(planIndex)} b$beat · $locale · $sizeName · font ${scale.toStringAsFixed(1)}';
            try {
              final BoardController controller = await pumpBoard(tester,
                  planIndex: planIndex,
                  surface: surface,
                  textScale: scale,
                  locale: locale,
                  reduceMotion: true,
                  codeText: code);
              for (int i = 0; i < beat; i++) {
                // Beat nào đang chờ trẻ thì luật R7-D cấm board tự nhảy: đường hợp lệ để tới beat
                // sau là Ý ĐỊNH CỦA TRẺ (`learnerAdvance`), không phải `next()` nội bộ.
                if (!controller.next() && !controller.learnerAdvance()) {
                  throw StateError('không tới được beat $beat (dừng ở ${controller.beatIndex})');
                }
              }
              await tester.pumpAndSettle();
              expect(controller.beatIndex, beat);
              final TeachingPlan plan = validateComposed(planIndex, locale: locale).plan!;
              final Rect canvas =
                  tester.getRect(find.byKey(const ValueKey<String>('board_canvas')));
              final List<BoardVisibleOp> visible = visibleOpsThrough(plan, beat);
              body(MatrixProbe(
                tester: tester,
                tag: tag,
                beat: beat,
                locale: locale,
                code: code,
                plan: plan,
                visible: visible,
                canvas: canvas,
                layout: BoardLayout.build(
                  visible: visible,
                  codeText: code,
                  width: canvas.width,
                  lineHeight: 13 * scale * 1.35,
                  altOf: (BoardOp op) => op.altFor(locale),
                  proseOf: (BoardOp op) => op.proseFor(locale),
                  outputHeader: locale == 'en' ? 'Run output' : 'Kết quả chạy',
                ),
              ));
            } on Object catch (e) {
              // Bắt mọi loại: một combo hỏng không được xoá thông tin của 95 combo còn lại.
              final String diagnostic = e.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
              bad.add('$tag → ${diagnostic.length > 700 ? diagnostic.substring(0, 700) : diagnostic}');
            }
          }
        }
      }
    }
  }
  expect(seen, 96, reason: 'ma trận phải đúng 96 combo (2 plan × 4 beat × 2 locale × 2 khổ × 3 scale)');
  return bad;
}
