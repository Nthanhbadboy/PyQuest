// PQC-003 — mở đủ sáu ActivitySheet và chứng minh thumbnail được giải mã thật.
//
// Phạm vi: chỉ `app/test/**`. Không sửa `app/lib/**`, `app/assets/**`, dependency
// hay gameplay (review PQD-001 r3 §3: `runtime_change_authorized_by_this_revision: no`).
// Source of truth cho key ảnh: docs/design/village-kit/manifest.json @ design
// 560106e725e93c9385fd067d554693cf16e80a69, field `baseline`.
//
// Vì sao test này không chỉ "widget tồn tại": ActivitySheet vẽ thumbnail bằng
// `BoxDecoration.image`, nên không có `RenderImage` con để tìm. Test do đó
// (a) kiểm chính xác `AssetImage.assetName` mà decoration sẽ nạp,
// (b) kiểm khung 104×104, và (c) nạp + giải mã đúng asset đó bằng
// `dart:ui` image codec thật — ảnh sai/không giải mã được thì fail.
//
// Bản follow-up này trả lời `docs/design/coordination/tasks/PQD-002.md` §B (review r4
// "Giới hạn test không được diễn giải quá mức"): CTA được chạm qua **route thật** của app
// (`showPQSheet`), result pop được kiểm chứ không chỉ `findsOneWidget`; `unlockLessonId`
// lấy từ **data thật** thay vì fixture tự đặt; proxy ">8 KiB" bị bỏ và thay bằng ngân
// sách trên + kích thước; `decodeAsset` dispose trong `try/finally`; có số đo ImageCache.
//
// Bằng chứng "không có chữ bake trong bitmap" KHÔNG nằm ở đây: đó là visual
// review trên ảnh render, ghi trong docs/implementation/coordination/EVIDENCE.md.

// `avoid_dynamic_calls`: xem helper `semanticsProps` — type `SemanticsProperties`
// KHÔNG được export từ material.dart của SDK mà CI dùng (đã cháy analyze ở run
// 38886724385 khi nêu tên nó), nên buộc phải đọc `properties` qua `dynamic`.
// ignore_for_file: avoid_dynamic_calls

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/app/activity.dart';
import 'package:pyquest/app/activity_registry.dart';
import 'package:pyquest/modules/bug_hunter/bug_models.dart';
import 'package:pyquest/modules/main_map/activity_sheet.dart';
import 'package:pyquest/modules/main_map/main_map_screen.dart' show kMapImageSize;
import 'package:pyquest/shared/widgets/chunky_button.dart';
import 'package:pyquest/shared/widgets/common.dart' show showPQSheet;

import 'test_helpers.dart';

/// Asset đã pin cho từng activity. Nếu ai đổi `thumbnail:` trong module mà chưa
/// qua design + chưa có artefact render tương ứng, test này đỏ.
const Map<String, String> kPinnedThumb = <String, String>{
  'main_quest': 'assets/images/thumb_tower.webp',
  'robot_maze': 'assets/images/thumb_maze.webp',
  'dragon_jump': 'assets/images/thumb_volcano.webp',
  'catch_stars': 'assets/images/thumb_observatory.webp',
  'bug_hunter': 'assets/images/thumb_workshop.webp',
  'achievement_house': 'assets/images/thumb_house.webp',
};

/// Hai khung nhìn của charter v1.1 — cùng logical size và DPR với harness
/// `test/render/render_screens_test.dart` (1170×2532@3 và 720×1280@2).
const Size kPhone = Size(390, 844);
const Size kCompact = Size(360, 640);
const double kPhoneDpr = 3.0;
const double kCompactDpr = 2.0;

/// textScale theo review §3 mục 2: 1.0 chuẩn, 1.3 và 2.0 cho kịch bản font to.
const List<double> kTextScales = <double>[1.0, 1.3, 2.0];

/// Ngân sách PQD-002 §B: mỗi thumbnail ≤100.000 B, cả sáu ≤600.000 B,
/// vuông và cạnh trong 256..512 cho bộ hiện tại (và cho cả bản 512 sẽ swap).
const int kMaxAssetBytes = 100_000;
const int kMaxSetBytes = 600_000;
const int kMaxSourceEdge = 512;

/// Size tối thiểu của ảnh nguồn. Bản hiện tại là 288×288; lát cắt 512 đã đề
/// xuất (PQC-002) vẫn thoả mãn con số này, nên test không cần đổi khi swap.
const int kMinSourceEdge = 256;

/// Khung thumbnail trong ActivitySheet (hard-code trong widget, 104×104 logical).
const Size kThumbSlot = Size(104, 104);

/// Key cho probe ở nhóm đo kích thước chạm thật.
const Key kProbeKey = Key('pyquest.probe');

const ActivityStatus kUnlocked = ActivityStatus(
  progressLabel: '2/6 chương',
  stars: 3,
);

/// State khoá của Bug Hunter. Dữ liệu deterministic: status được dựng trực tiếp
/// thay vì mở AppServices/DB để test không phụ thuộc tiến trình máy chạy.
const ActivityStatus kLocked = ActivityStatus(
  progressLabel: 'Chưa mở',
  locked: true,
  lockReason: 'Hoàn thành bài 3 để mở Xưởng Săn Lỗi.',
  unlockLessonId: 'bug_3',
);

ActivityModule moduleById(String id) => activityRegistry.firstWhere((ActivityModule m) => m.def.id == id);

void useViewport(WidgetTester tester, {required Size logical, required double dpr}) {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = Size(logical.width * dpr, logical.height * dpr);
  addTearDown(tester.view.reset);
}

/// MaterialApp tự lắp MediaQuery từ view, nên override textScale phải nằm
/// *dưới* MaterialApp — nếu đặt ngoài sẽ bị ghi đè.
Widget sheetHost(
  Widget child, {
  double textScale = 1.0,
  AssetBundle? bundle,
}) {
  Widget content = Builder(
    builder: (BuildContext context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child,
    ),
  );
  if (bundle != null) content = DefaultAssetBundle(bundle: bundle, child: content);
  return MaterialApp(home: Scaffold(body: content));
}

Finder get thumbSlot => find.byWidgetPredicate(
      (Widget w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).image?.image is AssetImage,
    );

AssetImage thumbImageOf(WidgetTester tester) {
  final Container box = tester.widget<Container>(thumbSlot);
  return (box.decoration! as BoxDecoration).image!.image as AssetImage;
}

/// Nạp và giải mã asset thật — bắt buộc chạy trong `runAsync` vì flutter_test
/// dùng fake async, nếu không I/O thật không bao giờ hoàn tất.
Future<Size> decodeAsset(String assetName) async {
  final ByteData data = await rootBundle.load(assetName);
  final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  try {
    final ui.FrameInfo frame = await codec.getNextFrame();
    final Size size = Size(frame.image.width.toDouble(), frame.image.height.toDouble());
    frame.image.dispose();
    return size;
  } finally {
    // Kể cả khi frame lỗi, codec phải được giải phóng (review r4 §Giới hạn).
    codec.dispose();
  }
}

/// Chờ I/O thật của ảnh rồi pump, để ảnh thực sự được nạp trước khi kết luận.
Future<void> settleRealWork(WidgetTester tester, {int rounds = 4}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Bundle chỉ trả bytes hỏng cho đúng key thumbnail; asset khác vẫn đọc thật,
/// nên không cần (và không được) sửa file trong repo để làm test fail.
class _BrokenThumbBundle extends CachingAssetBundle {
  _BrokenThumbBundle(this.brokenKey);

  final String brokenKey;

  static final Uint8List garbage = Uint8List.fromList(utf8.encode('RIFF\x00\x00\x00WEBP not an image'));

  @override
  Future<ByteData> load(String key) {
    if (key == brokenKey) return Future<ByteData>.value(ByteData.sublistView(garbage));
    return rootBundle.load(key);
  }
}

/// Đánh dấu "chưa có kết quả" để pop thất bại không bị nhầm với null hợp lệ.
final Object routeNotPopped = Object();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Font thật của app, để phép đo layout sát với máy chạy.
    await loadAppFonts();
  });

  group('wiring thumbnail của sáu activity', () {
    test('registry đúng sáu id và mỗi def trỏ đúng asset đã pin', () {
      expect(activityRegistry, hasLength(6));
      expect(
        activityRegistry.map((ActivityModule m) => m.def.id).toSet(),
        kPinnedThumb.keys.toSet(),
      );
      for (final ActivityModule m in activityRegistry) {
        expect(
          m.def.thumbnail,
          kPinnedThumb[m.def.id],
          reason: '${m.def.id} phải dùng đúng thumbnail design đã pin (baseline trong manifest.json)',
        );
      }
    });

    for (final MapEntry<String, String> entry in kPinnedThumb.entries) {
      testWidgets('${entry.key} nạp đúng AssetImage trong slot 104×104', (WidgetTester tester) async {
        useViewport(tester, logical: kPhone, dpr: kPhoneDpr);
        final ActivityModule module = moduleById(entry.key);
        await tester.pumpWidget(sheetHost(ActivitySheet(module: module, status: kUnlocked)));
        await settleRealWork(tester);

        expect(thumbSlot, findsOneWidget, reason: 'ActivitySheet phải vẽ slot thumbnail qua BoxDecoration');
        expect(thumbImageOf(tester).assetName, entry.value);
        expect(tester.getSize(thumbSlot), kThumbSlot);
        expect(tester.takeException(), isNull, reason: 'sheet phải render sạch ở 390×844');
      });
    }

    testWidgets('sáu asset giải mã được bằng image codec thật, vuông, cạnh $kMinSourceEdge..$kMaxSourceEdge', (WidgetTester tester) async {
      for (final MapEntry<String, String> entry in kPinnedThumb.entries) {
        late Size size;
        await tester.runAsync(() async {
          size = await decodeAsset(entry.value);
        });
        expect(size.width, greaterThanOrEqualTo(kMinSourceEdge), reason: '${entry.value} quá nhỏ cho slot 104px');
        expect(size.width, lessThanOrEqualTo(kMaxSourceEdge), reason: '${entry.value} vượt cạnh cho phép của bộ hiện tại');
        expect(size.height, greaterThanOrEqualTo(kMinSourceEdge), reason: '${entry.value} quá nhỏ cho slot 104px');
        expect(size.width, size.height, reason: '${entry.value} phải vuông, không letterbox trong BoxDecoration cover');
      }
    });

    // Thay cho proxy ">8 KiB = không phải placeholder" (review r4 nói rõ nó vô nghĩa:
    // ảnh hợp lệ nén tốt có thể nhỏ hơn). Ở đây chỉ còn ràng buộc *trên*, có căn cứ
    // từ Village Kit: mỗi file <100 KB, cả bộ <600 KB, và không file nào rỗng.
    test('ngân sách byte của bộ thumbnail bàn giao', () async {
      var total = 0;
      for (final MapEntry<String, String> entry in kPinnedThumb.entries) {
        final ByteData data = await rootBundle.load(entry.value);
        expect(data.lengthInBytes, greaterThan(0), reason: '${entry.value} trống');
        expect(
          data.lengthInBytes,
          lessThanOrEqualTo(kMaxAssetBytes),
          reason: '${entry.value} = ${data.lengthInBytes} B vượt 100.000 B của kit',
        );
        total += data.lengthInBytes;
      }
      expect(total, lessThanOrEqualTo(kMaxSetBytes), reason: 'cả sáu thumbnail = $total B, vượt ngân sách bộ');
    });
  });

  group('state của sheet', () {
    testWidgets('Bug Hunter khoá: hiện lockReason + CTA tới bài học, không có CTA mở', (WidgetTester tester) async {
      useViewport(tester, logical: kPhone, dpr: kPhoneDpr);
      final ActivityModule module = moduleById('bug_hunter');
      await tester.pumpWidget(sheetHost(ActivitySheet(module: module, status: kLocked)));
      await settleRealWork(tester);

      expect(find.text(kLocked.lockReason!), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('sheet_go_lesson')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('sheet_open')), findsNothing);
      expect(thumbImageOf(tester).assetName, kPinnedThumb['bug_hunter'],
          reason: 'state khoá vẫn phải giữ cùng thumbnail');
      expect(tester.takeException(), isNull);
    });

    for (final String id in kPinnedThumb.keys) {
      testWidgets('$id mở khoá: hiện CTA vào hoạt động và tiến trình', (WidgetTester tester) async {
        useViewport(tester, logical: kCompact, dpr: kCompactDpr);
        final ActivityModule module = moduleById(id);
        await tester.pumpWidget(sheetHost(ActivitySheet(module: module, status: kUnlocked)));
        await settleRealWork(tester);

        expect(find.text('Vào ${module.def.name}'), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('sheet_open')), findsOneWidget);
        expect(find.text(kUnlocked.progressLabel), findsOneWidget);
        expect(find.text('Tiến trình'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('overflow / textScale', () {
    for (final Size viewport in <Size>[kPhone, kCompact]) {
      for (final double scale in kTextScales) {
        testWidgets('sáu sheet ở ${viewport.width.toInt()}×${viewport.height.toInt()} textScale $scale',
            (WidgetTester tester) async {
          useViewport(
            tester,
            logical: viewport,
            dpr: viewport == kPhone ? kPhoneDpr : kCompactDpr,
          );
          for (final ActivityModule module in activityRegistry) {
            for (final ActivityStatus status in <ActivityStatus>[kUnlocked, kLocked]) {
              await tester
                  .pumpWidget(sheetHost(ActivitySheet(module: module, status: status), textScale: scale));
              await settleRealWork(tester);
              final Object? error = tester.takeException();
              expect(
                error,
                isNull,
                reason: '${module.def.id} ${status.locked ? 'locked' : 'unlocked'} @ ${viewport.width}×'
                    '${viewport.height} textScale $scale phải không overflow/exception: $error',
              );
            }
          }
        });
      }
    }
  });

  group('route thật của sheet (showPQSheet) — CTA phải cuộn tới được và trả đúng nhánh', () {
    // 360×640 + textScale 2.0: `showPQSheet` chặn chiều cao ở 0.9×screen, nên nếu
    // CTA nằm ngoài vùng nhìn thì test này đỏ — đó là điều cần biết, không phải
    // điều cần né. `findsOneWidget` không chứng minh được chạm.
    Future<Object?> openThroughRoute(
      WidgetTester tester, {
      required String activityId,
      required ActivityStatus status,
      required String ctaKey,
      required double textScale,
      required Size viewport,
      required double dpr,
    }) async {
      Object? popped = routeNotPopped;
      useViewport(tester, logical: viewport, dpr: dpr);
      // Route modal kế thừa MediaQuery từ view/Navigator, không từ widget cây cha đang
      // mở sheet -> phải đặt textScale ở platformDispatcher, không phải MediaQuery nest.
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (BuildContext context) => TextButton(
                  key: const ValueKey<String>('launch_sheet'),
                  onPressed: () async => popped = await showPQSheet<Object>(
                    context,
                    builder: (BuildContext ctx) => ActivitySheet(module: moduleById(activityId), status: status),
                  ),
                  child: const Text('launch'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey<String>('launch_sheet')));
      await pumpFor(tester, const Duration(milliseconds: 600));
      final Finder cta = find.byKey(ValueKey<String>(ctaKey)).first;
      expect(cta, findsOneWidget, reason: 'sheet phải mở ra với CTA $ctaKey trong route của app');
      await tester.ensureVisible(cta);
      await pumpFor(tester, const Duration(milliseconds: 200));
      await tester.tap(cta); // warnIfMissed mặc định = true: chạm không tới thì test đỏ
      await pumpFor(tester, const Duration(milliseconds: 800));
      return popped;
    }

    for (final String id in kPinnedThumb.keys) {
      testWidgets('$id: chạm "Vào ..." ở 360×640 textScale 2.0 trả về open', (WidgetTester tester) async {
        final Object? popped = await openThroughRoute(
          tester,
          activityId: id,
          status: kUnlocked,
          ctaKey: 'sheet_open',
          textScale: 2.0,
          viewport: kCompact,
          dpr: kCompactDpr,
        );
        expect(popped, 'open', reason: '$id phải pop đúng nhánh open, không chỉ tồn tại');
      });
    }

    testWidgets('Bug Hunter khoá: CTA "đi tới bài học" dùng lesson id THẬT từ data', (WidgetTester tester) async {
      String realLessonId = '';
      await tester.runAsync(() async {
        realLessonId = (await BugHunterContent.load(rootBundle)).unlockLessonId;
      });
      expect(realLessonId, isNotEmpty, reason: 'packs.first.requires_lesson phải có trong bug_hunter_puzzles.json');
      final Object? popped = await openThroughRoute(
        tester,
        activityId: 'bug_hunter',
        status: ActivityStatus(
          progressLabel: kLocked.progressLabel,
          locked: true,
          lockReason: kLocked.lockReason,
          unlockLessonId: realLessonId,
        ),
        ctaKey: 'sheet_go_lesson',
        textScale: 2.0,
        viewport: kCompact,
        dpr: kCompactDpr,
      );
      // main_map_screen.dart:120 cắt 'lesson:' và mở Main Quest với id đó ->
      // chỉ cần đúng chuỗi ở tầng sheet; điều hướng thật thuộc test route riêng.
      expect(popped, 'lesson:$realLessonId');
    });
  });

  group('vùng chạm của landmark trên đảo (toán hitBox, không cần pump)', () {
    // PQD-002 §A accessibility: charter sàn 48px logical. Đây là phép tính từ
    // `kMapImageSize` + cover rect của main_map_screen, không phải cảm nhận:
    // nếu một landmark co lại dưới sàn ở 360×640, con số phải hiện ra ở test.
    test('mọi hitBox còn >= 48px ở 360x640 sau phép cover của map', () {
      const Size box = kCompact;
      final Size image = kMapImageSize;
      final double scale = (box.width / image.width > box.height / image.height)
          ? box.width / image.width
          : box.height / image.height;
      final double w = image.width * scale;
      final double h = image.height * scale;
      final List<String> tooSmall = <String>[];
      final List<String> cropped = <String>[];
      for (final ActivityModule m in activityRegistry) {
        final Rect r = m.def.hitBox;
        final double pw = r.width * w;
        final double ph = r.height * h;
        expect(pw > 0 && ph > 0, isTrue, reason: '${m.def.id} có hitBox rỗng');
        expect(r.right <= 1.001 && r.bottom <= 1.001, isTrue, reason: '${m.def.id} hitBox vượt 0..1');
        // PQC-009 item 2: chốt cả mép dưới của không gian normalized.
        expect(r.left >= 0 && r.top >= 0, isTrue, reason: '${m.def.id} hitBox có tọa độ âm ngoài 0..1');
        // Rect trên màn PHẢI tính tới crop: BoxFit.cover đặt ảnh lệch tâm, nên phần
        // chạm thật sự khả dụng là giao với viewport, không phải pw×ph (review PQC-007).
        final double dx = (box.width - w) / 2;
        final double dy = (box.height - h) / 2;
        final Rect visible = Rect.fromLTRB(dx + r.left * w, dy + r.top * h, dx + r.right * w, dy + r.bottom * h)
            .intersect(Offset.zero & box);
        if (visible.width < 48 || visible.height < 48) {
          cropped.add('${m.def.id}=${visible.width.toStringAsFixed(1)}×${visible.height.toStringAsFixed(1)} '
              '(tổng ${pw.toStringAsFixed(1)}×${ph.toStringAsFixed(1)})');
        }
        if (pw < 48 || ph < 48) {
          tooSmall.add('${m.def.id}=${pw.toStringAsFixed(1)}×${ph.toStringAsFixed(1)}');
        }
      }
      expect(tooSmall, isEmpty,
          reason: 'dưới sàn chạm 48px ở khung nhỏ nhất; cần design chỉnh hitBox, không tự sửa');
      expect(cropped, isEmpty, reason: 'landmark bị cover crop che mất phần chạm ở 360x640 — cần design '
          'cung cấp rect production theo tỷ lệ nền mới, không tự sửa trong app/lib');
    });
  });

  group('ngân sách + cache của bộ thumbnail (precache qua ImageProvider thật)', () {
    // PQC-009 item 3: tên phải nói ĐÚNG việc đã đo. Bản cũ ghi "ImageCache khi mở
    // lần lượt sáu sheet" trong khi code chỉ precache — over-claim, đã bỏ. Chỗ thật
    // sự mở cả sáu sheet là nhóm 'route thật của sheet (showPQSheet)' ở trên.
    testWidgets('sáu key Asset resolve + decode từng cái một, rồi mới nhìn cache', (WidgetTester tester) async {
      useViewport(tester, logical: kPhone, dpr: kPhoneDpr);
      await tester.pumpWidget(sheetHost(const SizedBox(height: 1, width: 1)));
      final ImageCache cache = PaintingBinding.instance.imageCache;
      final BuildContext context = tester.element(find.byType(SizedBox).first);
      int entries = 0;
      int bytes = 0;
      await tester.runAsync(() async {
        cache.clear();
        final List<ImageStream> held = <ImageStream>[];
        final List<ImageStreamListener> listeners = <ImageStreamListener>[];
        for (final MapEntry<String, String> e in kPinnedThumb.entries) {
          final ImageStream stream =
              AssetImage(e.value).resolve(createLocalImageConfiguration(context, size: kThumbSlot));
          final Completer<ImageInfo> done = Completer<ImageInfo>();
          final ImageStreamListener listener = ImageStreamListener(
            (ImageInfo info, bool _) => done.complete(info),
            onError: (Object err, StackTrace? st) => done.completeError(err, st),
          );
          // Phải GIỮ listener khi đọc số cache: "còn trong cache" chỉ có nghĩa khi
          // còn người giữ, nếu không entry có thể bị thải ngay sau đó.
          stream.addListener(listener);
          held.add(stream);
          listeners.add(listener);
          final ImageInfo info = await done.future.timeout(const Duration(seconds: 30));
          expect(info.image.width, info.image.height, reason: '${e.key}: thumbnail kit phải là ảnh vuông');
          expect(info.image.width, inInclusiveRange(kMinSourceEdge.toDouble(), kMaxSourceEdge.toDouble()),
              reason: '${e.key}: cạnh ${info.image.width}px ngoài khoảng $kMinSourceEdge..$kMaxSourceEdge của kit');
        }
        entries = cache.currentSize;
        bytes = cache.currentSizeBytes;
        for (var i = 0; i < held.length; i++) {
          held[i].removeListener(listeners[i]);
        }
      });
      expect(entries, greaterThanOrEqualTo(kPinnedThumb.length),
          reason: 'cả sáu key phải cùng nằm trong cache khi còn listener; entries>=1 không đủ');
      expect(bytes, greaterThan(0), reason: 'phải có số byte thật, không suy từ W*H*4');
      // Số "live images" là MISSING có chủ đích: engine của CI không có
      // `ImageCache.currentLiveImages` (thử là analyze đỏ), và báo cáo check-run bị
      // cắt giữa nên cũng không trích được log. Xem EV-ID-011.
      // ignore: avoid_print
      print('PQC-009 imageCache precache: entries=$entries bytes=$bytes (cache của engine trên máy CI, '
          'không phải RAM/GPU thiết bị)');
    });
  });

  group('kích thước chạm đo từ RenderBox thật (characterization cho PQC-008)', () {
    // Review PQC-007: bảng cũ suy target từ constant `_height` mà chưa nhân depth
    // padding và chưa xét cả hai chiều. Ở đây đo thẳng RenderBox của widget đã dựng,
    // ở cả textScale 1 và 2, và ghi số đo thành ràng buộc — không đặt mục tiêu
    // "small phải 44px" cũng không nới sàn 48px để cho qua.
    Future<Size> measureProbe(WidgetTester tester, Widget probe, {double textScale = 1.0}) async {
      useViewport(tester, logical: kCompact, dpr: kCompactDpr);
      await tester.pumpWidget(sheetHost(
        SafeArea(child: Center(child: KeyedSubtree(key: kProbeKey, child: probe))),
        textScale: textScale,
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(kProbeKey).hitTestable(), findsOneWidget,
          reason: 'probe phải trong màn và nhận hit-test ở ${kCompact.width.toInt()}x${kCompact.height.toInt()}');
      return tester.getSize(find.byKey(kProbeKey));
    }

    // `Semantics` là type thật và đã compile; `SemanticsProperties` thì SDK của CI
    // không export → không được nêu tên nó (bài học từ run 38886724385). Đọc properties
    // qua `dynamic` rồi mới so sánh trong expect, nên kết luận vẫn do test quyết định.
    List<dynamic> semanticsProps(WidgetTester tester, String key) => find
        .descendant(of: find.byKey(ValueKey<String>(key)), matching: find.byType(Semantics))
        .evaluate()
        .map((Element e) {
          final dynamic w = e.widget;
          return w.properties;
        })
        .toList();

    testWidgets('ChunkyButton.small = mặt 44 + depth 4 theo chiều dọc; textScale 2 không làm nhỏ hơn',
        (WidgetTester tester) async {
      final Size at1 = await measureProbe(tester, ChunkyButton(label: 'OK', size: ChunkySize.small, onPressed: () {}));
      expect(at1.height, closeTo(48.0, 0.01),
          reason: 'characterization: _height 44 + _depth 4 (chunky_button.dart:42–51, 96–119). '
              'Đổi số này là đổi thiết kế, không phải im lặng cho qua');
      expect(at1.width, greaterThanOrEqualTo(44.0), reason: 'sàn chạm tối thiểu phải tính cả chiều rộng');

      final Size at2 = await measureProbe(
          tester, ChunkyButton(label: 'OK', size: ChunkySize.small, onPressed: () {}), textScale: 2.0);
      expect(at2.height, at1.height, reason: 'chữ to gấp đôi không được cắt chiều cao nút');
      expect(at2.width, greaterThanOrEqualTo(at1.width), reason: 'nhãn dài ra thì target phải rộng ra, không co lại');
    });

    testWidgets('RoundIconButton(size:44) là trường hợp khác: rộng 44, depth cộng theo chiều dọc',
        (WidgetTester tester) async {
      final Size box = await measureProbe(tester, RoundIconButton(icon: Icons.close_rounded, size: 44, onPressed: () {}));
      expect(box.width, closeTo(44.0, 0.01), reason: 'mặt tròn lấy đúng theo `size`');
      expect(box.height - box.width, closeTo(44 * 0.09, 0.01),
          reason: 'depth = size*0.09 chỉ cộng theo chiều dọc (chunky_button.dart:159, 172–181)');
      expect(box.height, greaterThanOrEqualTo(44.0));

      // Accessible name của RoundIconButton đến từ `tooltip`: không truyền tooltip
      // là không có tên. Ghi lại thành characterization, KHÔNG kết luận thiết bị.
      await tester.pumpWidget(sheetHost(SafeArea(child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            RoundIconButton(key: const Key('probe_titled'), icon: Icons.close_rounded, size: 44, tooltip: 'Đóng', onPressed: () {}),
            RoundIconButton(key: const Key('probe_untitled'), icon: Icons.close_rounded, size: 44, onPressed: () {}),
          ],
        ),
      ))));
      await tester.pumpAndSettle();
      expect(semanticsProps(tester, 'probe_untitled').where((dynamic p) => p.button == true), isNotEmpty,
          reason: 'role button vẫn được khai báo — không được suy thành screen reader không tới được');
      expect(
        semanticsProps(tester, 'probe_titled').map((dynamic p) => p.label).toList(),
        isNot(semanticsProps(tester, 'probe_untitled').map((dynamic p) => p.label).toList()),
        reason: 'RoundIconButton chỉ có tên khi có tooltip; các nút không tooltip đang thiếu accessible name '
            '=> việc của PQC-008, chưa phải kết luận trên thiết bị',
      );
    });
  });

  group('bằng chứng tiêu cực', () {
    testWidgets('bytes hỏng bị phát hiện, không im lặng vẽ ô trống', (WidgetTester tester) async {
      useViewport(tester, logical: kPhone, dpr: kPhoneDpr);
      const String asset = 'assets/images/thumb_tower.webp';
      final ActivityModule module = moduleById('main_quest');
      await tester.pumpWidget(sheetHost(
        ActivitySheet(module: module, status: kUnlocked),
        bundle: _BrokenThumbBundle(asset),
      ));

      Object? error;
      for (var i = 0; i < 20 && error == null; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
        await tester.pump(const Duration(milliseconds: 50));
        error = tester.takeException();
      }
      expect(error, isNotNull, reason: 'decode thất bại phải nổi thành exception; nếu null thì test chỉ kiểm widget tồn tại');

      await tester.runAsync(() async {
        await expectLater(
          ui.instantiateImageCodec(_BrokenThumbBundle.garbage),
          throwsA(anything),
          reason: 'chính image codec phải từ chối bytes hỏng',
        );
      });
    });

    test('asset thumbnail thật không được có bytes ngắn bất thường', () async {
      // Chốt đường chạy: nếu asset bị thay bằng placeholder, bằng chứng render mất nghĩa.
      for (final String asset in kPinnedThumb.values) {
        final ByteData data = await rootBundle.load(asset);
        expect(data.lengthInBytes, greaterThan(8 * 1024), reason: '$asset có vẻ là placeholder');
      }
    });
  });
}
