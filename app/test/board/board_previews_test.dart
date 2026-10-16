/// Ảnh bằng chứng cho `PQC-010`: **16 PNG do CI thật chụp**, 2 plan × {360×640, 390×844} ×
/// font {1.0, 2.0} × {vi, en}, ghi vào `build/previews/` để bước `ci/publish_previews.py` đăng.
///
/// Vì sao test này là test **thường**, không tag `render`: `ci.yml` chạy `flutter test
/// --exclude-tags render` rồi `flutter test --tags render test/render` — đặt một file
/// `@Tags(['render'])` ngoài `test/render/` là nó **không chạy ở cả hai bước**, tức là ảnh
/// "có" mà không có ai chụp. Cũng không có route ẩn hay debug launcher nào (rev 5 nói rõ:
/// **không** thêm). Ảnh này là nội dung tác giả, **chưa nối LessonScreen/AI/voice**.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/modules/tutor/board/board_controller.dart';
import 'package:pyquest/modules/tutor/board/board_models.dart';
import 'package:pyquest/modules/tutor/board/board_view.dart';

import 'board_test_support.dart';

const List<Size> kPreviewSizes = <Size>[Size(360, 640), Size(390, 844)];
const List<double> kPreviewScales = <double>[1.0, 2.0];
const List<String> kPreviewLocales = <String>['vi', 'en'];

void main() {
  testWidgets('chụp board-*.png: 2 plan × 2 khổ × 2 font × 2 locale', (WidgetTester tester) async {
    final Directory outDir = Directory('build/previews');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    final List<String> written = <String>[];
    for (final Size surface in kPreviewSizes) {
      final String sizeName = '${surface.width.round()}x${surface.height.round()}';
      for (final double scale in kPreviewScales) {
        for (int planIndex = 0; planIndex < 2; planIndex++) {
          for (final String locale in kPreviewLocales) {
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
            addTearDown(controller.dispose);
            expect(
              controller.applyPlan(controller.currentToken, validateComposed(planIndex, locale: locale)),
              BoardApplyOutcome.applied,
              reason: '$name: plan bị reject thì ảnh cũng vô nghĩa',
            );
            tester.view.physicalSize = surface;
            tester.view.devicePixelRatio = 1.0;
            await tester.pumpWidget(MediaQuery(
              data: MediaQueryData(size: surface, textScaler: TextScaler.linear(scale)),
              child: MaterialApp(
                home: Scaffold(
                  body: SafeArea(
                    child: RepaintBoundary(
                      key: boundary,
                      child: BoardView(controller: controller),
                    ),
                  ),
                ),
              ),
            ));
            expect(tester.takeException(), isNull, reason: '$name: board nổ khi dựng');
            // Đúng khuôn đã chứng minh trong repo (`render_screens_test.dart:34-46`): một nhịp
            // pump cho painted, rồi **toàn bộ** toImage + toByteData + write nằm GỌN trong
            // `runAsync`. Gọi `toByteData` ngoài runAsync là nguyên nhân đỏ ở run `ca2050a`:
            // widget test chạy trong zone giả lập nên encode ảnh thật không chờ được ở đó.
            await tester.pump(const Duration(milliseconds: 50));
            final int size = (await tester.runAsync(() async {
              final RenderRepaintBoundary render =
                  boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
              final ui.Image image = await render.toImage(pixelRatio: 2.0);
              // Không nêu tên type `ByteData`: SDK của CI không export nó qua material
              // (run trước đỏ ở `undefined_class`) — để trình biên dịch suy luận.
              final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
              final File file = File('${outDir.path}/$name.png');
              await file.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
              return file.lengthSync();
            }))!;
            // Ảnh của một bảng chữ phải có nội dung: dưới 2 KB nghĩa là chỉ có nền trắng.
            expect(size, greaterThan(2000), reason: '$name: ảnh rỗng');
            written.add('$name=${size}B');
          }
        }
      }
    }
    expect(written, hasLength(kPreviewSizes.length * kPreviewScales.length * 2 * kPreviewLocales.length));
    // `render.txt` là kênh CI in đủ; giữ dòng tóm tắt để đối chiếu tên file với ảnh đã đăng.
    // ignore: avoid_print
    print('board previews: ${written.join(' ')}');
  });
}
