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
// Bằng chứng "không có chữ bake trong bitmap" KHÔNG nằm ở đây: đó là visual
// review trên ảnh render, ghi trong docs/implementation/coordination/EVIDENCE.md.

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/app/activity.dart';
import 'package:pyquest/app/activity_registry.dart';
import 'package:pyquest/modules/main_map/activity_sheet.dart';

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

/// Size tối thiểu của ảnh nguồn. Bản hiện tại là 288×288; lát cắt 512 đã đề
/// xuất (PQC-002) vẫn thoả mãn con số này, nên test không cần đổi khi swap.
const int kMinSourceEdge = 256;

/// Khung thumbnail trong ActivitySheet (hard-code trong widget, 104×104 logical).
const Size kThumbSlot = Size(104, 104);

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
  return (box.decoration! as BoxDecoration).image!.image! as AssetImage;
}

/// Nạp và giải mã asset thật — bắt buộc chạy trong `runAsync` vì flutter_test
/// dùng fake async, nếu không I/O thật không bao giờ hoàn tất.
Future<Size> decodeAsset(String assetName) async {
  final ByteData data = await rootBundle.load(assetName);
  final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final ui.FrameInfo frame = await codec.getNextFrame();
  final Size size = Size(frame.image.width.toDouble(), frame.image.height.toDouble());
  frame.image.dispose();
  codec.dispose();
  return size;
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

    testWidgets('sáu asset giải mã được bằng image codec thật, ≥${kMinSourceEdge}px và vuông', (WidgetTester tester) async {
      for (final MapEntry<String, String> entry in kPinnedThumb.entries) {
        late Size size;
        await tester.runAsync(() async {
          size = await decodeAsset(entry.value);
        });
        expect(size.width, greaterThanOrEqualTo(kMinSourceEdge), reason: '${entry.value} quá nhỏ cho slot 104px');
        expect(size.height, greaterThanOrEqualTo(kMinSourceEdge), reason: '${entry.value} quá nhỏ cho slot 104px');
        expect(size.width, size.height, reason: '${entry.value} phải vuông, không letterbox trong BoxDecoration cover');
      }
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
