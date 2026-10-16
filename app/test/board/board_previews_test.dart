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

  // R9-A: cấu trúc `jobs` là thứ đã làm 0 ảnh được đăng ở `8647916` — mỗi entry capture có NĂM
  // field (plan, beat, nhãn, fromPrefix, toPrefix) còn vòng build `jobs` chỉ sinh BỐN, nên
  // `job[4]`/`job[5]` ném RangeError trước cả cú chụp. Kiểm hợp đồng dữ liệu ở đây để lần sau
  // sai là đỏ ĐÚNG TÊN, không phải im lặng mất trọn bộ ảnh.
  test('cấu trúc capture: mỗi entry 5 field, jobs ra 40 combo, chỉ beat có mũi tên khai hai hộp', () {
    final List<List<Object>> all = <List<Object>>[...kPrimaryCaptures, ...kSmallCaptures];
    for (final List<Object> e in all) {
      expect(e, hasLength(5),
          reason: 'mỗi entry phải là [plan, beat, nhãn, fromPrefix, toPrefix], thấy ${e.length}');
      expect(e[0] as int, inInclusiveRange(0, 1), reason: 'chỉ có hai plan authored: $e');
      expect(e[1] as int, inInclusiveRange(0, 3), reason: 'mỗi plan bốn beat: $e');
      final String why = e[2] as String;
      expect(why, isNotEmpty);
      final bool hasArrow = why.contains('connector');
      expect((e[3] as String).isNotEmpty, hasArrow,
          reason: '$why: beat có mũi tên BẮT BUỘC khai hộp ở hai đầu, beat khác thì không');
      expect((e[4] as String).isNotEmpty, hasArrow, reason: '$why: thiếu prefix hộp đích');
    }
    // Khổ hẹp chỉ chụp font 2.0 (case xấu nhất) nên số combo là 8*2*2 + 4*2, không phải *4.
    final int combos =
        kPrimaryCaptures.length * kPreviewLocales.length * kPreviewScales.length +
            kSmallCaptures.length * kPreviewLocales.length;
    expect(combos, 40, reason: 'bộ ảnh dự kiến là 40 combo, không phải $combos');
  });

  // R9-A (yêu cầu "chụp một combo và mở ảnh publish đúng SHA, rồi 40 ảnh"): ca này chạy TRƯỚC và
  // ghi thẳng vào `build/previews` với đúng tên mà job đầu tiên của vòng 40 sẽ dùng, nên nếu vòng
  // đó chết giữa đường, publisher vẫn còn MỘT ảnh board ở đúng SHA để reviewer mở. Nó vẫn tự chụp
  // chứ không đọc lại ảnh của test khác (đọc ảnh người khác viết thì ảnh cũ trên đĩa vẫn cho xanh).
  testWidgets('pipeline ảnh còn sống: chụp MỘT combo, mở lại bằng chính số đo của nó',
      (WidgetTester tester) async {
    final Directory outDir = Directory('build/previews');
    final _Shot shot = await _captureBoard(tester, outDir,
        'board-mq1_01_s2-b1-code-highlight-390x844-font1.0-vi', 0, 0, kPrimarySurface, 1.0, 'vi');
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
    expect(shot.height, (kPrimarySurface.height * 1.5).round(), reason: 'ảnh không đúng khổ đã khai');
  });

  testWidgets('chụp board-<step>-<beat>-<khổ>-<font>-<locale>.png và đo điểm ảnh',
      (WidgetTester tester) async {
    final Directory outDir = Directory('build/previews');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    final List<String> manifest = <String>[];
    final List<String> failures = <String>[];
    // `List<Object>` đã là non-nullable: thêm `!` ở đây chỉ tổ thành
    // `unnecessary_non_null_assertion`, mà CI coi warning là lỗi (analyze=1 ở run 2d55ff6).
    final List<List<Object>> jobs = <List<Object>>[
      for (final List<Object> e in kPrimaryCaptures)
        <Object>[e[0], e[1], e[2], kPrimarySurface, e[3], e[4]],
      for (final List<Object> e in kSmallCaptures)
        <Object>[e[0], e[1], e[2], kSmallSurface, e[3], e[4]],
    ];
    // R9-A chính là chỗ này: entry capture có NĂM field, `jobs` chèn thêm surface thành SÁU. Vòng
    // `8647916` jobs chỉ có bốn field nên `job[4]`/`job[5]` ném RangeError TRƯỚC cả `_captureBoard`
    // -> không một ảnh nào được ghi, publisher không có gì đăng, và báo cáo chỉ còn bốn cái tên.
    expect(jobs.every((List<Object> j) => j.length == 6), isTrue,
        reason: 'jobs phải mang đủ plan/beat/nhãn/surface/fromPrefix/toPrefix');
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
          } on Object catch (e, st) {
            // Một phép đo hỏng không được khai tử cả bộ ảnh: publisher chỉ lấy những file đã ghi ra
            // đĩa, và mất 32/40 ảnh là mất luôn bằng chứng design cần mở. Lỗi vẫn làm đỏ test ở
            // dòng check cuối, nhưng phần tử ở đây phải đủ để KHÔNG phải đoán: kèm message đầy đủ
            // và hai dòng stack, vì report CI cắt giữa log.
            failures.add(name);
            manifest.add('$name → ĐO HỎNG: $e || ${_stackHint(st)}');
          }
        }
      }
    }
    // R9-A: ghi + in manifest TRƯỚC mọi assertion tổng. Vòng trước câu check `ĐO HỎNG isEmpty`
    // đứng TRƯỚC chỗ write/print, nên đúng lúc có combo hỏng thì phần chi tiết — thứ duy nhất có
    // giá trị chẩn đoán — lại không chạy.
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
    expect(manifest, hasLength(kPrimaryCaptures.length * 4 + kSmallCaptures.length * 2),
        reason: 'bộ ảnh phải phủ từng beat ở vi/en và font 2.0: ${manifest.length}');
    expect(manifest.where((String n) => n.contains('-b1-')), isNotEmpty,
        reason: 'tên ảnh phải chứa beat, không chỉ plan');
    expect(failures, isEmpty,
        reason: '${failures.length} combo đo ảnh hỏng: ${failures.join(', ')} — chi tiết ở '
            'MANIFEST.txt và ở các dòng in phía trên');
    // Bộ đếm này nói thẳng publisher có gì trong tay, thay vì để người đọc suy ra từ số ảnh đã đăng.
    final List<String> onDisk = outDir
        .listSync()
        .map((FileSystemEntity e) => e.uri.pathSegments.last)
        .where((String n) => n.startsWith('board-') && n.endsWith('.png'))
        .toList()..sort();
    expect(onDisk, hasLength(40),
        reason: 'build/previews phải có 40 ảnh board để publish, thấy ${onDisk.length}: '
            '${onDisk.take(3).join(", ")}');
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
  // Capture the authored teaching target in the viewport before reading any geometry. The old
  // run measured off-screen RenderBoxes against the fixed viewport and cropped the meaningful
  // lower half from its screenshots. For connector beats, bring the destination output into view;
  // for wait/snippet beats, prefer the snippet/example box when present.
  final Finder target = fromPrefix.isNotEmpty
      ? find.byWidgetPredicate((Widget w) =>
          w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith(toPrefix))
      : find.byWidgetPredicate((Widget w) => w.key is ValueKey<String> &&
          ((w.key! as ValueKey<String>).value.startsWith('board_code_snippet_') ||
              (w.key! as ValueKey<String>).value.startsWith('board_output_') ||
              (beatIndex == 0 && (w.key! as ValueKey<String>).value.startsWith('board_group_'))));
  if (target.evaluate().isNotEmpty) {
    await tester.ensureVisible(target.first);
    await tester.pumpAndSettle();
  }
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
  Rect? fromRectMeasured;
  Rect? toRectMeasured;
  if (fromPrefix.isNotEmpty && toPrefix.isNotEmpty) {
    final Offset origin = tester.getTopLeft(find.byKey(boundary));
    final Rect? from = boxRectForPrefix(tester, fromPrefix);
    final Rect? to = boxRectForPrefix(tester, toPrefix);
    fromRectMeasured = from;
    toRectMeasured = to;
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
      gapNote: '$fromPrefix|$toPrefix from=$fromRectMeasured to=$toRectMeasured '
          'band=$bandTop..$bandBottom viewport=${surface.width}x${surface.height}',
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
    expect(bandTop, greaterThanOrEqualTo(0),
        reason: '$name source-to-destination band starts above the captured viewport: ${s.gapNote}');
    expect(bandBottom, lessThan(s.height),
        reason: '$name source-to-destination band ends below the captured viewport: ${s.gapNote}');
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

/// Vài dòng stack đủ để biết lỗi nở ra từ đâu. `ci/report.py` cắt giữa log và raw log không tải
/// được, nên manifest + các dòng in của chính test này là kênh chẩn đoán duy nhất còn sống.
String _stackHint(StackTrace st) {
  final List<String> rows =
      st.toString().split('\n').where((String l) => l.trim().isNotEmpty).toList();
  final List<String> mine =
      rows.where((String l) => l.contains('board_previews_test.dart')).take(2).toList();
  final List<String> chosen = mine.isEmpty ? rows.take(2).toList() : mine;
  return chosen.join(' | ');
}
