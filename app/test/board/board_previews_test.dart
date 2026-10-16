/// Ảnh bằng chứng cho `PQC-010`: **PNG do CI thật chụp**, tên file có beat, nền opaque nằm
/// TRONG boundary, font thật của app, và mỗi ảnh được **đo điểm ảnh của chính nó**.
///
/// Ba điều rev 7 §R7-E + rev 8 §R8-A bắt, và vì sao nó nằm ở file này:
///  * ảnh phải **đọc được**: `loadAppFonts()` + `ThemeData(fontFamily: PQFonts.body)` trong host,
///    vì test host mặc định của Flutter vẽ mọi glyph bằng font Ahem (thành khối đặc);
///  * boundary `RepaintBoundary` phải là **node ngoài cùng**. `toImage()` chỉ lấy phần subtree
///    của nó, còn `convert('RGB')` của CI không ghép alpha — nên nền trắng đặt LÀM ANCESTOR thì
///    ảnh ra nền đen đúng như vòng 1, còn đặt BÊN TRONG boundary thì màu nền đi vào điểm ảnh;
///  * nghiệm thu ảnh là **đo điểm ảnh của ảnh vừa chụp**, không phải suy từ kích thước file, và
///    không đọc lại file mà một test khác viết ra (test cũ xanh nhờ ảnh còn sót trên đĩa).
///
/// Mỗi ảnh in một dòng manifest có `GITHUB_SHA` (chính là `tested_code_commit` của run) để ảnh
/// tự nói nó được chụp từ code nào. Coverage theo **từng beat**, vì reviewer cần thấy highlight
/// đúng token, nhóm 3/4 vật, output một dòng vs hai dòng, wait — chứ không phải một bảng beat 0
/// chụp 16 lần.
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
import 'package:pyquest/modules/tutor/board/board_layout.dart';
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

/// Số đo lấy từ chính ảnh vừa render: kích thước PNG, số cấp độ sáng, màu góc.
class _Shot {
  _Shot({
    required this.bytes,
    required this.levels,
    required this.corner,
    required this.width,
    required this.height,
    required this.path,
    this.ink = const <int>[],
  });

  final int bytes;
  final int levels;
  final List<int> corner;
  final int width;
  final int height;
  final String path;
  /// RGBA tại giữa nét vẽ của `connector` (4 số mỗi điểm) — bằng chứng mực thật nằm ở chỗ mũi tên
  /// phải đi qua, không phải bằng chứng "có một đường nào đó trên ảnh".
  final List<int> ink;

  String describe(String name) => '$name | ${width}x$height | $bytes B | $levels mức sáng | '
      'góc RGBA ${corner.join(',')} | commit ${_commit()}';
}

/// `tested_code_commit` của run CI; rỗng khi chạy ở máy cá nhân thì nói rõ là local.
String _commit() {
  final String? sha = Platform.environment['GITHUB_SHA'];
  return (sha == null || sha.isEmpty) ? 'local' : sha.substring(0, sha.length < 12 ? sha.length : 12);
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
    final List<String> manifest = <String>[];
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
          final _Shot shot = await _captureBoard(
              tester, outDir, name, planIndex, beatIndex, surface, scale, locale);
          manifest.add(shot.describe(name));
        }
      }
    }
    expect(manifest, hasLength(kPrimaryCaptures.length * 4 + kSmallCaptures.length * 2),
        reason: 'bộ ảnh phải phủ từng beat ở vi/en và font 2.0: ${manifest.length}');
    expect(manifest.where((String n) => n.contains('-b1-')), isNotEmpty,
        reason: 'tên ảnh phải chứa beat, không chỉ plan');
    // `render.txt`/`test.txt` là kênh CI in đủ; MANIFEST đi cùng ảnh để ảnh tự giải thích nó là
    // gì, chụp từ commit nào, và đã được đo ra sao.
    File('${outDir.path}/MANIFEST.txt').writeAsStringSync('${manifest.join('\n')}\n');
    // ignore: avoid_print
    print('board previews (${manifest.length} ảnh) @ ${_commit()}');
    for (final String line in manifest) {
      // ignore: avoid_print
      print('  $line');
    }
    // Nhãn bắt buộc của §acceptance: ảnh là board TÁC GIẢ dựng trong test host, chưa nối
    // LessonScreen/AI/voice — dòng này đi vào `test.txt` nên nằm cạnh danh sách ảnh trong báo cáo.
    // ignore: avoid_print
    print('board previews label: ảnh renderer PQC-010 — chưa nối LessonScreen/AI/voice, '
        'không phải bằng chứng chạy trên thiết bị hay TalkBack.');
  });

  testWidgets('ảnh đại diện vẫn còn trên đĩa và không phải một dải màu duy nhất',
      (WidgetTester tester) async {
    // Rev 8 §R8-A: ca này **tự chụp lấy một ảnh** thay vì đọc lại file mà test trước để lại —
    // đọc file người khác viết thì ảnh cũ trên đĩa vẫn cho xanh, tức là test không phát hiện
    // được gì. Nó giữ đúng điều nó tên: mở ảnh ra, đếm số cấp độ sáng và kiểm màu nền.
    final Directory outDir =
        Directory('${Directory('build/previews').path}/probe-${DateTime.now().microsecondsSinceEpoch}');
    final _Shot shot = await _captureBoard(tester, outDir, 'probe-single-band', 0, 0, kPrimarySurface, 1.0, 'vi');
    final File file = File(shot.path);
    expect(file.existsSync(), isTrue, reason: 'ảnh phải được chính ca này ghi ra: ${file.path}');
    final Uint8List bytes = file.readAsBytesSync();
    expect(bytes.sublist(0, 8), <int>[137, 80, 78, 71, 13, 10, 26, 10],
        reason: 'không phải PNG hợp lệ thì không có gì để mở');
    expect(shot.bytes, greaterThan(4000), reason: 'ảnh quá nhỏ, nhiều khả năng chỉ có nền');
    // Một dải màu đặc = 1 mức sáng. Font Ahem (thiếu `loadAppFonts`) hoặc mất nền trong boundary
    // đều cho ảnh "to nhưng không có chữ"; số cấp sáng là thứ phân biệt được hai trường hợp đó.
    expect(shot.levels, greaterThanOrEqualTo(8),
        reason: 'chỉ ${shot.levels} mức sáng = một dải màu, không phải chữ đọc được');
    expect(shot.corner, <int>[255, 255, 255, 255],
        reason: 'góc trên-trái phải là nền trắng opaque, không phải transparent (publisher ra nền đen)');
    expect(shot.width, (kPrimarySurface.width * 1.5).round(), reason: 'ảnh không đúng khổ đã khai');
  });
}

/// Dựng board ở beat cần chụp, boundary là node **ngoài cùng**, và trả số đo của ảnh vừa render.
/// Riêng tư theo kiểu trả về: `_Shot` là loại tư, để hàm công khai trả nó sẽ dính
/// `library_private_types_in_public_api` (CI bật analyze và coi đó là vết bẩn trong báo cáo).
Future<_Shot> _captureBoard(
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
    // Host của ảnh bằng chứng KHÔNG mượn `TextScaler` đã kẹp 1.2 của app: `MediaQueryData` trực
    // tiếp ở đây means fontScale 2.0 đến renderer nguyên 2.0 — đó là thứ thiết bị sẽ làm.
    child: MaterialApp(
      theme: ThemeData(fontFamily: PQFonts.body, scaffoldBackgroundColor: Colors.white),
      home: Scaffold(
        body: SafeArea(
          // `RepaintBoundary` ngoài cùng + `ColoredBox` BÊN TRONG: `toImage` chỉ chụp subtree của
          // boundary, và `convert('RGB')` của CI không ghép alpha nên mọi vùng transparent sẽ
          // thành nền đen. Đặt màu nền ngoài boundary = ảnh đen dù màn hình vẫn trắng.
          child: RepaintBoundary(
            key: boundary,
            child: ColoredBox(
              color: Colors.white,
              child: SizedBox(
                width: surface.width,
                height: surface.height,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: BoardView(controller: controller, codeText: kExampleSteps[stepId]!),
                ),
              ),
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

  // rev 8 §R8-B1: với beat có `connector`, phải thấy **mực vẽ** ở giữa khoảng nối. Điểm lấy từ
  // hình học mà layout tính cho đúng canvas đang vẽ (độ rộng đo từ renderer), rồi nhân
  // pixelRatio và trừ gốc của boundary — nên nó là bằng chứng trên ảnh, không phải trên model.
  // Nét ngang kiểu cũ (hai điểm cùng y trung bình) không đi qua điểm này.
  final List<Offset> inkPoints = <Offset>[];
  late Offset canvasOrigin;
  if (name.contains('connector')) {
    final Size canvasSize = tester.getSize(find.byKey(const ValueKey<String>('board_canvas')));
    final Offset canvasTopLeft = tester.getTopLeft(find.byKey(const ValueKey<String>('board_canvas')));
    // Gốc của boundary trong toạ độ màn hình: `toImage` trả ảnh tính từ đây, không phải từ
    // canvas — hiệu hai cái là phần đệm trắng mà `ColoredBox` đã tô sẵn.
    final Offset boundaryTopLeft = tester.getTopLeft(find.byKey(boundary));
    canvasOrigin = canvasTopLeft - boundaryTopLeft;
    final TeachingPlan model = validateComposed(planIndex).plan!;
    final BoardLayout geometry = BoardLayout.build(
      visible: visibleOpsThrough(model, beatIndex),
      codeText: kExampleSteps[stepId]!,
      width: canvasSize.width,
      // `13 * scale * 1.35`: cùng công thức `_codeFontSize`/`lineHeight` mà `_TutorLayer` dùng.
      lineHeight: 13 * scale * 1.35,
      altOf: (BoardOp op) => op.altFor(locale),
      proseOf: (BoardOp op) => op.proseFor(locale),
      outputHeader: locale == 'en' ? 'Run output' : 'Kết quả chạy',
    );
    expect(geometry.connectors, isNotEmpty, reason: '$name: plan có connector mà geometry không có');
    for (final BoardConnector link in geometry.connectors) {
      inkPoints.add(Offset((link.start.x + link.end.x) / 2, (link.start.y + link.end.y) / 2));
    }
  }

  final _Shot? shot = await tester.runAsync(() async {
    final RenderRepaintBoundary render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final ui.Image image = await render.toImage(pixelRatio: 1.5);
    // Không nêu tên type `ByteData`: SDK của CI không export nó qua material (`undefined_class`
    // đã làm đỏ run `ca2050a`). Toàn bộ encode + write + đọc điểm ảnh nằm GỌN trong `runAsync` —
    // khuôn đã chứng minh ở `render_screens_test.dart:34-46`.
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final File file = File('${outDir.path}/$name.png');
    await file.create(recursive: true);
    await file.writeAsBytes(png!.buffer.asUint8List());
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final Uint8List pixels = rgba!.buffer.asUint8List();
    final List<int> size = _pngSize(file.readAsBytesSync());
    final List<int> ink = <int>[];
    for (final Offset point in inkPoints) {
      final int cx = ((canvasOrigin.dx + point.dx) * 1.5).round();
      final int cy = ((canvasOrigin.dy + point.dy) * 1.5).round();
      // Ô 3×3 quanh điểm giữa nét: nét 2.2px và một điểm duy nhất thì phụ thuộc làm tròn. 3×3
      // vẫn là "đúng chỗ mũi tên phải đi qua", không phải "gần gần chỗ đó".
      int bestLum = -1;
      List<int> bestRgba = const <int>[];
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          final int sx = cx + dx;
          final int sy = cy + dy;
          if (sx < 0 || sy < 0 || sx >= image.width || sy >= image.height) continue;
          final int at = (sy * image.width + sx) * 4;
          final List<int> rgba =
              <int>[pixels[at], pixels[at + 1], pixels[at + 2], pixels[at + 3]];
          final int lum = (rgba[0] * 299 + rgba[1] * 587 + rgba[2] * 114) ~/ 1000;
          if (bestLum < 0 || lum < bestLum) {
            bestLum = lum;
            bestRgba = rgba;
          }
        }
      }
      ink.add(bestLum);
      ink.addAll(bestLum < 0 ? <int>[-1, -1, -1, -1] : bestRgba);
    }
    final _Shot measured = _Shot(
      bytes: file.lengthSync(),
      levels: _distinctLuminanceLevels(pixels),
      corner: <int>[pixels[0], pixels[1], pixels[2], pixels[3]],
      width: size[0],
      height: size[1],
      path: file.path,
      ink: ink,
    );
    image.dispose();
    return measured;
  });
  expect(shot, isNotNull, reason: '$name: runAsync không trả số đo');
  // Assert đặt NGOÀI `runAsync`: trong zone fake-async của `testWidgets`, một exception từ
  // `runAsync` có thể bị nuốt; số liệu đưa ra ngoài rồi kiểm vẫn rõ ràng khi đọc log CI.
  expect(shot!.bytes, greaterThan(4000), reason: '$name: ảnh quá nhỏ, nhiều khả năng chỉ có nền');
  expect(shot.levels, greaterThanOrEqualTo(8),
      reason: '$name: chỉ ${shot.levels} mức sáng = một dải màu đặc, không phải chữ đọc được');
  expect(shot.corner[3], 255, reason: '$name: góc trên-trái trong suốt -> publisher ra nền đen');
  expect(shot.corner[0], greaterThan(200), reason: '$name: nền capture không sáng như đã khai');
  // Ảnh phải đúng khổ boundary nhân pixelRatio: đây là bằng chứng "đo trên ảnh", không phải on
  // file, và chặn trường hợp chụp nhằm một node rỗng 1x1.
  expect(shot.width, (surface.width * 1.5).round(), reason: '$name: bề rộng ảnh không khớp surface');
  expect(shot.height, (surface.height * 1.5).round(), reason: '$name: chiều cao ảnh không khớp surface');
  if (inkPoints.isNotEmpty) {
    // Mỗi điểm 5 số: [độ sáng nhỏ nhất, R, G, B, A] — đủ để log CI tự giải thích mà không phải đoán.
    expect(shot.ink, hasLength(inkPoints.length * 5), reason: '$name: không lấy được mẫu mực vẽ');
    for (int k = 0; k + 4 < shot.ink.length; k += 5) {
      final List<int> sample = shot.ink.sublist(k, k + 5);
      expect(sample[0], greaterThanOrEqualTo(0), reason: '$name: điểm lấy mẫu rơi ngoài ảnh: $sample');
      expect(sample[0], lessThan(150),
          reason: '$name: giữa khoảng nối không có mực (tối nhất $sample) -> mũi tên không nối hai hộp');
      expect(sample[4], 255,
          reason: '$name: nét vẽ RGBA $sample: transparent sẽ thành nền đen khi publish');
    }
  }
  return shot;
}

/// Rộng và cao đọc từ header IHDR của PNG — không cần giải mã toàn ảnh.
List<int> _pngSize(Uint8List bytes) {
  // `throw`, không `expect`: helper chạy trong `runAsync`, nơi exception của expect bị zone
  // thật nuốt và ca test chỉ đỏ vì timeout — khó đọc hơn nhiều so với một thông báo thẳng.
  if (bytes.length <= 24) throw StateError('PNG ngắn hơn header: ${bytes.length} byte');
  return <int>[(bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19],
      (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23]];
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
