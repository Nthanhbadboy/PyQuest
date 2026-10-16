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
  <Object>[0, 0, 'code-highlight', '', ''],
  <Object>[0, 1, 'quote-tokens', '', ''],
  <Object>[
      0, 2, 'connector-single-output', 'board_code_line_0', 'board_output_2_',
    ],
  <Object>[0, 3, 'wait-task', '', ''],
  <Object>[1, 0, 'groups-3-4-line-highlight', '', ''],
  <Object>[1, 1, 'cleared-group-7-first-line', '', ''],
  <Object>[1, 2, 'whole-run-two-lines', '', ''],
  <Object>[1, 3, 'shape-wait', '', ''],
];

/// Bốn khung hẹp nhất (360×640, font 2.0) — nơi dễ tràn chữ nhất, chụp cả vi và en.
const List<List<Object>> kSmallCaptures = <List<Object>>[
  <Object>[
      0, 2, 'connector-single-output', 'board_code_line_0', 'board_output_2_',
    ],
  <Object>[0, 3, 'wait-task', '', ''],
  <Object>[1, 0, 'groups-3-4-line-highlight', '', ''],
  <Object>[1, 2, 'whole-run-two-lines', '', ''],
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
    required this.inkRows,
    required this.inkSpan,
    required this.boxesMissing,
    required this.gapNote,
  });

  final int bytes;
  final int levels;
  final List<int> corner;
  final int width;
  final int height;
  final String path;
  /// Số hàng ảnh có điểm tối trong dải nối của `connector` và tổng số hàng của dải (-1 / 0 khi
  /// ảnh không có mũi tên). Đây là bằng chứng "mũi tên cắt ngang khoảng trống", không phải
  /// "trên ảnh có một nét nào đó".
  final int inkRows;
  final int inkSpan;
  /// Một trong hai hộp mà mũi tên phải nối **không có** trên cây widget.
  final bool boxesMissing;
  /// Hai prefix đã dùng để tra hộp, để dòng manifest tự giải thích phép đo.
  final String gapNote;

  String describe(String name) => '$name | ${width}x$height | $bytes B | $levels mức sáng | '
      'góc RGBA ${corner.join(',')}'
      '${inkRows >= 0 ? ' | mực dải nối $inkRows/$inkSpan hàng' : ''}'
      '${boxesMissing ? ' | THIẾU HỘP NỐI ($gapNote)' : ''}'
      ' | commit ${_commit()}';
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
      final String fromPrefix = job[4] as String;
      final String toPrefix = job[5] as String;
      final bool small = surface == kSmallSurface;
      for (final String locale in kPreviewLocales) {
        for (final double scale in kPreviewScales) {
          // Khổ hẹp chỉ cần font 2.0 (case xấu nhất); khổ chính chạy cả hai font, hai locale.
          if (small && scale != 2.0) continue;
          final String name = 'board-${stepName(planIndex)}-b${beatIndex + 1}-$why-'
              '${surface.width.round()}x${surface.height.round()}'
              '-font${scale.toStringAsFixed(1)}-$locale';
          try {
            final _Shot shot = await _captureBoard(tester, outDir, name, planIndex, beatIndex,
                surface, scale, locale, fromPrefix, toPrefix);
            manifest.add(shot.describe(name));
          } on Object catch (e) {
            // Một phép đo hỏng không được khai tử cả bộ ảnh: CI chỉ thấy những file đã ghi ra đĩa,
            // và vòng trước 32 ảnh đã biến mất chỉ vì ca đo đầu tiên abort giữa vòng lặp. Lỗi vẫn
            // làm đỏ test (dòng check bên dưới), nhưng design còn đủ 40 ảnh để mở.
            manifest.add('$name → ĐO HỎNG: $e'); // giữ nguyên message, kể cả nhiều dòng
          }
        }
      }
    }
    expect(manifest, hasLength(kPrimaryCaptures.length * 4 + kSmallCaptures.length * 2),
        reason: 'bộ ảnh phải phủ từng beat ở vi/en và font 2.0: ${manifest.length}');
    expect(manifest.where((String n) => n.contains('-b1-')), isNotEmpty,
        reason: 'tên ảnh phải chứa beat, không chỉ plan');
    expect(manifest.where((String n) => n.contains('ĐO HỎNG')).toList(), isEmpty,
        reason: 'có combo đo ảnh hỏng; danh sách nằm ở cuối log của file này');
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
  String locale, [
  String fromPrefix = '',
  String toPrefix = '',
]) async {
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

  // rev 8 §R8-B1: với beat có `connector`, phải thấy **mực vẽ băng qua khoảng trống** giữa hai hộp.
  // Hai hộp lấy từ CHÍNH cây widget đang dựng — key của hộp nguồn và hộp đích do bảng capture khai
  // — chứ không dựng lại `BoardLayout` trong test: vòng trước tôi rebuild layout bằng số đo tự đưa
  // (`13 * scale * 1.35`, thiếu measurer mà view bơm vào) rồi lấy mẫu ở chỗ model *tưởng* là mũi
  // tên, tức là đo trí tưởng tượng của mình chứ không đo thứ máy đã vẽ.
  // Tiêu chuẩn: số HÀNG ảnh có điểm tối trong dải giữa đáy hộp cao hơn và đỉnh hộp thấp hơn. Nét
  // nối thật phủ gần hết dải; một nét ngang lơ lửng (lỗi cũ: hai điểm cùng ở độ cao trung bình) chỉ
  // để lại 1-3 hàng. Cách này không phụ thuộc số đo font hay làm tròn một điểm ảnh.
  int bandTop = -1, bandBottom = -1;
  bool boxesMissing = false;
  if (fromPrefix.isNotEmpty && toPrefix.isNotEmpty) {
    final Offset origin = tester.getTopLeft(find.byKey(boundary));
    final Rect? from = boxRectForPrefix(tester, fromPrefix);
    final Rect? to = boxRectForPrefix(tester, toPrefix);
    // Không `expect` ở đây: mọi thứ trước cú `toImage` đều có thể làm mất cả ảnh, mà ảnh là bằng
    // chứng design cần mở. Thiếu hộp thì chỉ đánh dấu, và kiểm tra sẽ chạy SAU khi ảnh đã ghi.
    boxesMissing = from == null || to == null;
    final double gapTop = from == null ? 0 : (to == null ? 0 : (from.bottom < to.bottom ? from.bottom : to.bottom));
    final double gapBottom = from == null ? 0 : (to == null ? 0 : (from.top > to.top ? from.top : to.top));
    bandTop = ((gapTop - origin.dy) * 1.5).round();
    bandBottom = ((gapBottom - origin.dy) * 1.5).round();
    if (bandBottom < bandTop) {
      final int t = bandTop;
      bandTop = bandBottom;
      bandBottom = t;
    }
    if (boxesMissing) {
      bandTop = -1;
      bandBottom = -1;
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
    int inkRows = -1;
    if (bandBottom >= 0) {
      final int y1 = bandBottom > image.height ? image.height : bandBottom;
      int rows = 0;
      // Quét hết bề rộng: dải này nằm GIỮA hai hộp, nơi không có chữ nào khác của beat được vẽ,
      // nên mọi điểm tối trong đó đều là của mũi tên.
      for (int y = bandTop < 0 ? 0 : bandTop; y <= y1; y++) {
        for (int x = 0; x < image.width; x++) {
          final int at = (y * image.width + x) * 4;
          if (at + 3 >= pixels.length) break;
          if (pixels[at + 3] != 255) continue; // chỉ tính điểm opaque; transparent là lỗi khác
          final int lum = (pixels[at] * 299 + pixels[at + 1] * 587 + pixels[at + 2] * 114) ~/ 1000;
          if (lum < 150) {
            rows++;
            break;
          }
        }
      }
      inkRows = rows;
    }
    final _Shot measured = _Shot(
      bytes: file.lengthSync(),
      levels: _distinctLuminanceLevels(pixels),
      corner: <int>[pixels[0], pixels[1], pixels[2], pixels[3]],
      width: size[0],
      height: size[1],
      path: file.path,
      inkRows: inkRows,
      inkSpan: bandBottom - bandTop + 1,
      boxesMissing: boxesMissing,
      gapNote: '$fromPrefix|$toPrefix',
    );
    image.dispose();
    return measured;
  });
  expect(shot, isNotNull, reason: '$name: runAsync không trả số đo');
  // `expect(isNotNull)` không tạo promotion, còn `shot!` chỉ ảnh hưởng các dòng SAU nó: bind một
  // biến không-nullable để mọi phép kiểm tra bên dưới dùng chung (bảy lỗi
  // `unchecked_use_of_nullable_value` ở run `1b91482` là do tôi tin `shot!` đứng cuối thay vì đầu).
  final _Shot s = shot!;
  // Assert đặt NGOÀI `runAsync`: trong zone fake-async của `testWidgets`, một exception từ
  // `runAsync` có thể bị nuốt; số liệu đưa ra ngoài rồi kiểm vẫn rõ ràng khi đọc log CI.
  expect(s.bytes, greaterThan(4000), reason: '$name: ảnh quá nhỏ, nhiều khả năng chỉ có nền');
  expect(s.levels, greaterThanOrEqualTo(8),
      reason: '$name: chỉ ${s.levels} mức sáng = một dải màu đặc, không phải chữ đọc được');
  expect(s.corner[3], 255, reason: '$name: góc trên-trái trong suốt -> publisher ra nền đen');
  expect(s.corner[0], greaterThan(200), reason: '$name: nền capture không sáng như đã khai');
  // Ảnh phải đúng khổ boundary nhân pixelRatio: đây là bằng chứng "đo trên ảnh", không phải on
  // file, và chặn trường hợp chụp nhằm một node rỗng 1x1.
  expect(s.width, (surface.width * 1.5).round(), reason: '$name: bề rộng ảnh không khớp surface');
  expect(s.height, (surface.height * 1.5).round(), reason: '$name: chiều cao ảnh không khớp surface');
  expect(s.boxesMissing, isFalse,
      reason: '$name: mũi tên phải nối hai hộp thật, nhưng không tìm thấy hộp nào có key khớp '
          '${s.gapNote} -> ảnh này không có gì để đối chiếu');
  if (s.inkRows >= 0) {
    final int span = s.inkSpan;
    expect(span, greaterThan(1), reason: '$name: dải nối rỗng ($span hàng) — không có chỗ nào để vẽ');
    // Ít nhất nửa dải phải có mực: nét nối thật thì liên tục từ hộp nguồn xuống hộp đích.
    expect(s.inkRows * 2 >= span, isTrue,
        reason: '$name: mũi tên chỉ phủ ${s.inkRows}/$span hàng của khoảng nối -> nó không nối '
            'hai hộp (một nét ngang ở độ cao trung bình sẽ trượt kiểm tra này)');
    expect(s.inkRows, lessThanOrEqualTo(span), reason: '$name: đếm hàng vô lý ${s.inkRows}>$span');
  }

  return s;
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

/// Rect của hộp đầu tiên trong cây có key `ValueKey<String>` bắt đầu bằng [prefix].
///
/// Trả null khi không có hộp nào như vậy — đó là phát hiện thật về bảng (mũi tên trỏ vào một hộp
/// không được vẽ), không phải lỗi của phép đo, nên người gọi kiểm bằng `expect(isNotNull)`.
Rect? boxRectForPrefix(WidgetTester tester, String prefix) {
  final Finder boxes = find.byWidgetPredicate((Widget w) =>
      w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith(prefix));
  if (boxes.evaluate().isEmpty) return null;
  return tester.getRect(boxes.first);
}
