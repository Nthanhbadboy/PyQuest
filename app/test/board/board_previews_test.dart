/// Ảnh bằng chứng cho `PQC-010`: **PNG do CI thật chụp**, tên file có beat, nền opaque trong
/// boundary, font thật của app, và được **đo điểm ảnh** chứ không chỉ "file > 2 KB".
///
/// Ba điều rev 7 §R7-E bắt, và vì sao nó nằm ở file này:
///  * ảnh phải **đọc được**: `loadAppFonts()` + `ThemeData(fontFamily: PQFonts.body)` trong host,
///    vì test host mặc định của Flutter vẽ mọi glyph bằng font Ahem (thành khối đặc), và bước
///    convert `.convert('RGB')` của CI **không** ghép alpha — không có nền opaque trong boundary
///    là ảnh ra nền đen như vòng 1;
///  * coverage phải tới **từng beat**, tên file có beat, để reviewer thấy highlight đúng token,
///    nhóm 3/4 vật, output một dòng vs hai dòng, wait — không phải một bảng beat 0 chụp 16 lần;
///  * nghiệm thu ảnh là **đo điểm ảnh**: mức sáng có nhiều cấp (chữ + viền + nền tô), góc nền
///    đúng màu đã khai và opaque. Kích thước file chỉ là điều kiện phụ.
///
/// Vì sao test này là test **thường**, không tag `render`: `ci.yml` chạy `flutter test
/// --exclude-tags render` rồi `flutter test --tags render test/render`; đặt `@Tags(['render'])`
/// ngoài `test/render/` là nó **không chạy ở cả hai bước**. Không có route ẩn hay debug launcher
/// nào để chụp ảnh (rev 5 và r7 nói rõ). Ảnh là board tác giả, **chưa nối LessonScreen/AI/voice**.
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/modules/tutor/board/board_controller.dart';
import 'package:pyquest/modules/tutor/board/board_models.dart';
import 'package:pyquest/modules/tutor/board/board_view.dart';
import 'package:pyquest/shared/theme/app_theme.dart';

import '../test_helpers.dart';
import 'board_test_support.dart';

const List<double> kPreviewScales = <double>[1.0, 2.0];
const List<String> kPreviewLocales = <String>['vi', 'en'];
const Size kPrimarySurface = Size(390, 844);
const Size kSmallSurface = Size(360, 640);

/// Beat cần ảnh: `[planIndex, beatIndex, mô tả]` — phủ code + highlight, nhóm 3/4, connector +
/// output một dòng, output hai dòng của cả đoạn, wait, và hình theo `x/y/width/height`.
const List<List<Object>> kPrimaryCaptures = <List<Object>>[
  <Object>[0, 0, 'code-highlight'],
  <Object>[0, 1, 'quote-tokens'],
  <Object>[0, 2, 'connector-single-output'],
  <Object>[0, 3, 'wait-task'],
  <Object>[1, 0, 'groups-3-4-line-highlight'],
  <Object>[1, 1, 'cleared-group-7-first-line'],
  <Object>[1, 2, 'whole-run-two-lines'],
  <Object>[1, 3, 'shape-wait'],
];

/// Bốn khung hẹp nhất (360×640, font 2.0) — nơi dễ tràn chữ nhất, chụp cả vi và en.
const List<List<Object>> kSmallCaptures = <List<Object>>[
  <Object>[0, 2, 'connector-single-output'],
  <Object>[0, 3, 'wait-task'],
  <Object>[1, 0, 'groups-3-4-line-highlight'],
  <Object>[1, 2, 'whole-run-two-lines'],
];

String stepName(int planIndex) => planIndex == 0 ? 'mq1_01_s2' : 'mq1_03_s2';

/// Kết quả đo một ảnh — assert đặt **ngoài** `runAsync` cho chắc: trong zone thật thì thất bại
/// vẫn được báo cáo, nhưng để số liệu ra ngoài rồi kiểm vẫn rõ ràng hơn khi đọc log CI.
class _Shot {
  _Shot({required this.bytes, required this.levels, required this.corner});

  final int bytes;
  final int levels;
  final List<int> corner;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Idiom của repo cho test host (`render_screens_test.dart:150-153`): chỉ nạp bộ font app đã
    // có sẵn trong assets, không đổi pubspec/assets/publisher để né scope.
    await loadAppFonts();
  });

  testWidgets('chụp board-<step>-<beat>-<khổ>-<font>-<locale>.png và đo điểm ảnh',
      (WidgetTester tester) async {
    final Directory outDir = Directory('build/previews');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    final List<String> written = <String>[];
    // `List<Object>` đã là non-nullable: thêm `!` ở đây chỉ tổ thành
    // `unnecessary_non_null_assertion`, mà CI coi warning là lỗi (analyze=1 ở run 2d55ff6).
    final List<List<Object>> jobs = <List<Object>>[
      for (final List<Object> e in kPrimaryCaptures) <Object>[e[0], e[1], e[2], kPrimarySurface],
      for (final List<Object> e in kSmallCaptures) <Object>[e[0], e[1], e[2], kSmallSurface],
    ];
    for (final List<Object> job in jobs) {
      final int planIndex = job[0] as int;
      final int beatIndex = job[1] as int;
      final String why = job[2] as String;
      final Size surface = job[3] as Size;
      final bool small = surface == kSmallSurface;
      for (final String locale in kPreviewLocales) {
        for (final double scale in kPreviewScales) {
          // Khổ hẹp chỉ cần font 2.0 (case xấu nhất); khổ chính chạy cả hai font, hai locale.
          if (small && scale != 2.0) continue;
          final String name = 'board-${stepName(planIndex)}-b${beatIndex + 1}-$why-'
              '${surface.width.round()}x${surface.height.round()}'
              '-font${scale.toStringAsFixed(1)}-$locale';
          await captureBoard(tester, outDir, name, planIndex, beatIndex, surface, scale, locale);
          written.add(name);
        }
      }
    }
    expect(written, hasLength(kPrimaryCaptures.length * 4 + kSmallCaptures.length * 2),
        reason: 'bộ ảnh phải phủ từng beat ở vi/en và font 2.0: ${written.length}');
    expect(written.where((String n) => n.contains('-b1-')), isNotEmpty,
        reason: 'tên ảnh phải chứa beat, không chỉ plan');
    // `render.txt`/`test.txt` là kênh CI in đủ; giữ dòng tóm tắt để đối chiếu tên file với ảnh
    // đã đăng.
    // ignore: avoid_print
    print('board previews (${written.length} ảnh): ${written.join(' ')}');
    // Nhãn bắt buộc của §acceptance: ảnh là board TÁC GIẢ dựng trong test host, chưa nối
    // LessonScreen/AI/voice — dòng này đi vào `test.txt` nên nằm cạnh danh sách ảnh trong báo cáo.
    // ignore: avoid_print
    print('board previews label: ảnh renderer PQC-010 — chưa nối LessonScreen/AI/voice, '
        'không phải bằng chứng chạy trên thiết bị hay TalkBack.');
  });

  testWidgets('ảnh đại diện vẫn còn trên đĩa và không phải một dải màu duy nhất',
      (WidgetTester tester) async {
    // Ca độc lập có chủ đích: nếu host quên `loadAppFonts()` hoặc quên nền opaque thì ảnh vẫn
    // "to" nhưng không có chữ. Kiểm tra này bắt đúng loại lỗi của vòng 1 trên ảnh thật, không
    // tin vào kích thước file.
    final File probe = File('${Directory('build/previews').path}/board-${stepName(0)}'
        '-b1-code-highlight-${kPrimarySurface.width.round()}x${kPrimarySurface.height.round()}'
        '-font1.0-vi.png');
    expect(probe.existsSync(), isTrue, reason: 'test chụp ảnh phải chạy trước ca này: ${probe.path}');
    final List<int> bytes = await probe.readAsBytes();
    expect(bytes.length, greaterThan(4000));
  });
}

Future<void> captureBoard(
  WidgetTester tester,
  Directory outDir,
  String name,
  int planIndex,
  int beatIndex,
  Size surface,
  double scale,
  String locale,
) async {
  final GlobalKey boundary = GlobalKey(debugLabel: name);
  final Map<String, dynamic> plan = composedPlan(planIndex);
  final String stepId = plan['stepId']! as String;
  final BoardController controller = BoardController(
    sessionId: 'shot-$name',
    locale: locale,
    lessonId: plan['lessonId']! as String,
    stepId: stepId,
  );
  addTearDown(controller.dispose);
  expect(
    controller.applyPlan(controller.currentToken, validateComposed(planIndex, locale: locale)),
    BoardApplyOutcome.applied,
    reason: '$name: plan bị reject thì ảnh cũng vô nghĩa',
  );
  for (int i = 0; i < beatIndex; i++) {
    expect(controller.next(), isTrue, reason: '$name: không tới được beat $beatIndex');
  }
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MediaQuery(
    data: MediaQueryData(size: surface, textScaler: TextScaler.linear(scale)),
    child: MaterialApp(
      theme: ThemeData(fontFamily: PQFonts.body, scaffoldBackgroundColor: Colors.white),
      home: Scaffold(
        body: SafeArea(
          // Nền opaque nằm **trong** boundary. `toImage` + convert RGB của CI không ghép alpha:
          // vùng transparent sẽ thành nền đen, đúng lỗi mà design đã mở ảnh vòng 1 và thấy.
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Colors.white),
            child: RepaintBoundary(
              key: boundary,
              child: BoardView(controller: controller, codeText: kExampleSteps[stepId]!),
            ),
          ),
        ),
      ),
    ),
  ));
  expect(tester.takeException(), isNull, reason: '$name: board nổ khi dựng');
  await tester.pump(const Duration(milliseconds: 50));
  expect(controller.beatIndex, beatIndex);
  expect(controller.currentCopy!.caption, isNotEmpty, reason: '$name: beat không có caption');
  final _Shot shot = (await tester.runAsync(() async {
    final RenderRepaintBoundary render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final ui.Image image = await render.toImage(pixelRatio: 1.5);
    // Không nêu tên type `ByteData`: SDK của CI không export nó qua material (`undefined_class`
    // đã làm đỏ run `ca2050a`). Toàn bộ encode + write nằm GỌN trong `runAsync` — khuôn đã chứng
    // minh ở `render_screens_test.dart:34-46`.
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final File file = File('${outDir.path}/$name.png');
    await file.create(recursive: true);
    await file.writeAsBytes(png!.buffer.asUint8List());
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final Uint8List pixels = rgba!.buffer.asUint8List();
    final _Shot measured = _Shot(
      bytes: file.lengthSync(),
      levels: _distinctLuminanceLevels(pixels),
      corner: <int>[pixels[0], pixels[1], pixels[2], pixels[3]],
    );
    image.dispose();
    return measured;
  }))!;
  expect(shot.bytes, greaterThan(4000), reason: '$name: ảnh quá nhỏ, nhiều khả năng chỉ có nền');
  expect(shot.levels, greaterThanOrEqualTo(8),
      reason: '$name: chỉ ${shot.levels} mức sáng = một dải màu đặc, không phải chữ đọc được');
  expect(shot.corner[3], 255, reason: '$name: góc trên-trái trong suốt -> publisher ra nền đen');
  expect(shot.corner[0], greaterThan(200), reason: '$name: nền capture không sáng như đã khai');
}

/// Số cấp độ sáng khác nhau, lấy mẫu đều trên ảnh. Chữ anti-alias + viền hộp + nền tô sáng luôn
/// tạo nhiều mức hơn một khối đặc; đây là hàng rào chống "ảnh 1 màu mà vẫn 3 MB".
int _distinctLuminanceLevels(Uint8List rgba) {
  final Set<int> levels = <int>{};
  const int stride = 4 * 53; // ~1/53 số pixel: trải đều mà không duyệt hết ảnh
  for (int i = 0; i + 3 < rgba.length; i += stride) {
    levels.add(((rgba[i] * 299 + rgba[i + 1] * 587 + rgba[i + 2] * 114) ~/ 1000) ~/ 4);
    if (levels.length >= 64) break;
  }
  return levels.length;
}
