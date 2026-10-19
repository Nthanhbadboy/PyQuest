// PQC-022 — bề mặt 2,5D r56 (Welcome + ActivitySheet) và r43 (Main Quest journey).
//
// Vì sao file này tồn tại: `docs/design/arrival-entrance-r56` và
// `docs/design/chapter-journey-r43` chốt layout bằng số đo thật (scene sheet
// 180px, scene welcome 300px -> 250px khi chữ >=1.5x, portrait 115×140 và
// 152×175, "nội dung đứng trước artwork" ở chữ lớn), nhưng chưa test nào chứng
// minh Flutter dựng đúng các số đó. Ở đây mọi kết luận lấy từ `RenderBox` thật
// của widget tree đang render — không so chuỗi CSS, không đọc ảnh render, không
// nới tolerance: reorder được kiểm bằng vị trí trên/dưới thật của hai widget.
//
// Phạm vi: `activity_sheet.dart`, `main_map_screen.dart`, `main_quest_module.dart`
// và 4 asset mới trong `app/assets/images/**`. Không chạm dragon_jump /
// catch_stars / robot_maze / achievements / bug_hunter (PQC-023 làm song song).
//
// Hợp đồng điều hướng vẫn kiểm qua route thật (`showPQSheet`) như
// `activity_sheet_thumbnails_test.dart`: pop result là 'open' / 'lesson:<id>' /
// null. Thêm artwork không được đổi hành vi, không được thêm phí, không được
// nhân đôi slot thumbnail mà test đó đếm.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/app/activity.dart';
import 'package:pyquest/app/activity_registry.dart';
import 'package:pyquest/app/app_scope.dart';
import 'package:pyquest/app/app_services.dart';
import 'package:pyquest/app/pyquest_app.dart';
import 'package:pyquest/modules/main_map/activity_sheet.dart';
import 'package:pyquest/modules/main_map/main_map_screen.dart';
import 'package:pyquest/modules/main_quest/lesson_screen.dart';
import 'package:pyquest/modules/main_quest/main_quest_module.dart';
import 'package:pyquest/shared/characters/characters.dart';
import 'package:pyquest/shared/theme/app_theme.dart';
import 'package:pyquest/shared/widgets/chunky_button.dart';
import 'package:pyquest/shared/widgets/common.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_helpers.dart';

/// Asset r56 đã chép vào app, kèm kích thước gốc trong
/// `docs/design/arrival-entrance-r56/assets/provenance.json`.
const Map<String, Size> kR56AppAssets = <String, Size>{
  'assets/images/arrival_r56.webp': Size(720, 894),
  'assets/images/main_quest_r56.webp': Size(671, 1000),
  'assets/images/py_token_r56.png': Size(438, 512),
  'assets/images/bitsy_token_r56.png': Size(465, 512),
};

/// Số đo ASSET_PLAN r56, ghi lại thành con số để layout không tự đổi âm thầm.
const double kSheetSceneHeight = 180;
const double kWelcomeSceneHeight = 300;
const double kWelcomeSceneHeightLarge = 250;
const Size kSheetGuideSize = Size(115, 140);
const Size kWelcomeGuideSize = Size(152, 175);

/// Ngân sách byte cho phần asset mới của PQC-022 (cùng tinh thần PQD-002 §B:
/// ràng buộc TRÊN, không dùng ">8 KiB" làm proxy cho "không phải placeholder").
const int kMaxR56AssetBytes = 300_000;
const int kMaxR56AssetSetBytes = 700_000;

Future<AppServices> createServices() async => AppServices.create(
  bundle: rootBundle,
  databaseFactory: databaseFactoryFfiNoIsolate,
  databasePath: inMemoryDatabasePath,
  clock: FakeClock(DateTime(2026, 10, 19, 12)),
  audioEnabled: false,
  startSessionTimer: false,
);

/// Giải mã bằng codec ảnh thật: asset sai định dạng hoặc không được pubspec glob
/// đem vào bundle là đỏ ngay ở đây, không phải lúc nhìn capture.
Future<Size> decodeAsset(String asset) async {
  final ByteData data = await rootBundle.load(asset);
  final ui.Codec codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(),
  );
  try {
    final ui.FrameInfo frame = await codec.getNextFrame();
    final Size size = Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );
    frame.image.dispose();
    return size;
  } finally {
    codec.dispose();
  }
}

Finder imageOfAsset(String asset) => find.byWidgetPredicate(
  (Widget w) =>
      w is Image &&
      w.image is AssetImage &&
      (w.image as AssetImage).assetName == asset,
);

/// Slot thumbnail mà `activity_sheet_thumbnails_test.dart` đếm: ĐÚNG một
/// `Container` có `BoxDecoration.image` là `AssetImage`.
Finder get thumbSlot => find.byWidgetPredicate(
  (Widget w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration! as BoxDecoration).image?.image is AssetImage,
);

ActivityModule moduleById(String id) =>
    activityRegistry.firstWhere((ActivityModule m) => m.def.id == id);

const ActivityStatus kUnlocked = ActivityStatus(
  progressLabel: '3/12 bài',
  stars: 4,
  detailLines: <String>['Chặng 1: Những dòng đầu tiên'],
  recommended: true,
);

const ActivityStatus kLocked = ActivityStatus(
  progressLabel: 'Chưa mở',
  locked: true,
  lockReason: 'Hoàn thành bài 3 để mở Xưởng Săn Lỗi.',
  unlockLessonId: 'mq1_03',
);

/// Cùng cơ chế scale app thật dùng. Override phải nằm DƯỚI MaterialApp vì
/// MaterialApp tự lắp MediaQuery từ view (bài học trong
/// `activity_sheet_thumbnails_test.dart`).
Widget sheetHost(Widget child, {double textScale = 1.0}) {
  return MaterialApp(
    theme: buildPyQuestTheme(),
    home: Scaffold(
      body: Builder(
        builder: (BuildContext context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child,
        ),
      ),
    ),
  );
}

Widget appHome(AppServices services, Widget child, {double textScale = 1.0}) {
  return AppScope(
    services: services,
    child: MaterialApp(
      theme: buildPyQuestTheme(),
      builder: (BuildContext context, Widget? navigator) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: navigator!,
      ),
      home: child,
    ),
  );
}

/// Dựng `PyQuestApp` thật ở một cỡ chữ hệ thống (như root test của PQC-020 R3),
/// để panel chào hiện ra đúng đường production, không phải dialog dựng tay.
Future<void> pumpRoot(
  WidgetTester tester,
  AppServices services, {
  required double scale,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    PyQuestApp(
      servicesFactory: (_) async => services,
      systemLocalesReader: () => <Locale>[const Locale('vi')],
      minSplash: Duration.zero,
    ),
  );
  await pumpFor(tester, const Duration(seconds: 2));
}

void usePhone(
  WidgetTester tester, {
  required Size logical,
  required double dpr,
}) {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = Size(logical.width * dpr, logical.height * dpr);
  addTearDown(tester.view.reset);
}

/// Mép trên thật của widget trong cây đang render.
double topOf(WidgetTester tester, Finder finder) =>
    tester.getTopLeft(finder.first).dy;

Finder keyOf(String name) => find.byKey(ValueKey<String>(name));
/// Nút mở sheet qua `showPQSheet` thật; future pop được đưa ngược ra test để
/// kiểm kết quả điều hướng chứ không chỉ kiểm widget tồn tại.
class _SheetLauncher extends StatelessWidget {
  const _SheetLauncher({
    required this.module,
    required this.status,
    required this.onPopped,
  });

  final ActivityModule module;
  final ActivityStatus status;
  final void Function(Future<String?> future) onPopped;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ChunkyButton(
          key: const ValueKey<String>('probe_open_sheet'),
          label: 'probe',
          onPressed: () => onPopped(
            showPQSheet<String>(
              context,
              builder: (BuildContext context) =>
                  ActivitySheet(module: module, status: status),
            ),
          ),
        ),
      ),
    );
  }
}

/// `PQColors.berry` — viền mà `_LessonCard` vẽ khi `highlighted` (0xFFEC5C93,
/// KHÔNG phải `PQColors.accent` 0xFFFF2E63: nhầm hai constant này là một trong
/// hai lỗi làm đỏ 863d20a, và nó chỉ lộ ra khi đọc code thật, không đọc label).
const Color kBerryBorder = Color(0xFFEC5C93);

/// Màu VIỀN của hộp lesson, đọc từ widget thật (cùng kiểu đọc Container đầu tiên
/// bên trong key mà `main_map_scene_route_test.dart` đã dùng), không suy từ label.
Color cardBorderColorFor(WidgetTester tester, String lessonId) {
  final Container card = tester.widget<Container>(
    find
        .descendant(
          of: find.byKey(
            ValueKey<String>('lesson_card_$lessonId'),
            skipOffstage: false,
          ),
          matching: find.byType(Container, skipOffstage: false),
        )
        .first,
  );
  // `BoxDecoration.border` có kiểu tĩnh là `BoxBorder?` (KHÔNG phải `Border?`) —
  // viết `final Border? border = ...` là `invalid_assignment`, và error phân tích
  // làm cả file không compile => 12 ca của file này không chạy, ordinary tụt từ
  // 460 xuống 444 (bằng chứng ở 354a338). Cast tường minh rồi mới đọc `.top`.
  final BoxDecoration decoration = card.decoration! as BoxDecoration;
  final Border border = decoration.border! as Border;
  return border.top.color;
}


/// Key của `RepaintBoundary` mô phỏng `_captureKey` trong `render_screens_test
/// .dart` để gọi `toImage` trên đúng loại layer mà harness dùng.
final GlobalKey captureKey = GlobalKey();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUpAll(() async {
    await loadAppFonts();
  });

  testWidgets('asset r56 vào tới app: giải mã thật, đúng provenance, trong ngân sách', (
    WidgetTester tester,
  ) async {
    var total = 0;
    for (final MapEntry<String, Size> entry in kR56AppAssets.entries) {
      late Size size;
      late int bytes;
      await tester.runAsync(() async {
        size = await decodeAsset(entry.key);
        final ByteData data = await rootBundle.load(entry.key);
        bytes = data.lengthInBytes;
      });
      expect(
        size,
        entry.value,
        reason: '${entry.key} phải giữ đúng kích thước gốc của study',
      );
      expect(bytes, greaterThan(0), reason: '${entry.key} rỗng');
      expect(
        bytes,
        lessThanOrEqualTo(kMaxR56AssetBytes),
        reason: '${entry.key} = $bytes B vượt $kMaxR56AssetBytes B',
      );
      total += bytes;
      // ignore: avoid_print
      print('PQC022 asset ${entry.key} size=$size bytes=$bytes');
    }
    expect(
      total,
      lessThanOrEqualTo(kMaxR56AssetSetBytes),
      reason: 'cả bộ asset r56 = $total B, vượt ngân sách',
    );
  });

  group('ActivitySheet 2,5D (r56)', () {
    for (final ActivityModule module in activityRegistry) {
      testWidgets('${module.def.id}: scene 180px + guide + slot đã pin', (
        WidgetTester tester,
      ) async {
        usePhone(tester, logical: const Size(360, 640), dpr: 2.0);
        await tester.pumpWidget(
          sheetHost(ActivitySheet(module: module, status: kUnlocked)),
        );
        await pumpFor(tester, const Duration(milliseconds: 300));

        expect(keyOf('sheet_scene'), findsOneWidget);
        expect(
          tester.getSize(keyOf('sheet_scene')).height,
          kSheetSceneHeight,
          reason: 'ASSET_PLAN r56: header scene 180px, không co theo cỡ chữ',
        );
        expect(keyOf('sheet_guide'), findsOneWidget);
        expect(imageOfAsset(kSheetSceneAsset), findsOneWidget);

        // Scene phải là Image.asset, không phải DecorationImage thứ hai: test
        // thumbnail đếm ĐÚNG một slot 104×104.
        expect(thumbSlot, findsOneWidget);
        expect(tester.getSize(thumbSlot), const Size(104, 104));
        final Container box = tester.widget<Container>(thumbSlot);
        final BoxDecoration decoration = box.decoration! as BoxDecoration;
        expect(
          (decoration.image!.image as AssetImage).assetName,
          module.def.thumbnail,
          reason: '${module.def.id} phải nạp đúng thumbnail đã pin',
        );

        // Tên canonical từ ActivityDef, không lấy nhãn viết tắt của marker r53.
        expect(find.text(module.def.name), findsWidgets);
        expect(keyOf('sheet_close'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('sáu sheet ở 360×640 cỡ 2.0×: không layout exception, CTA tới được', (
      WidgetTester tester,
    ) async {
      usePhone(tester, logical: const Size(360, 640), dpr: 2.0);
      for (final ActivityModule module in activityRegistry) {
        await tester.pumpWidget(
          sheetHost(
            ActivitySheet(module: module, status: kUnlocked),
            textScale: 2.0,
          ),
        );
        await pumpFor(tester, const Duration(milliseconds: 250));
        final Finder cta = keyOf('sheet_open');
        await tester.scrollUntilVisible(
          cta,
          160,
          scrollable: find.byType(Scrollable).first,
        );
        await pumpFor(tester, const Duration(milliseconds: 200));
        expect(cta, findsOneWidget, reason: '${module.def.id} mất CTA ở 2×');
        expect(
          tester.getRect(cta).height,
          greaterThanOrEqualTo(44),
          reason: 'CTA của ${module.def.id} phải >=44px ở 2×',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'layout exception mới ở ${module.def.id} 2×',
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpFor(tester, const Duration(milliseconds: 400));
      }
    });

    testWidgets('chữ >=1.5× đảo thứ tự: nội dung đứng TRƯỚC artwork', (
      WidgetTester tester,
    ) async {
      usePhone(tester, logical: const Size(390, 844), dpr: 3.0);
      final ActivityModule module = moduleById('main_quest');
      for (final double scale in <double>[1.0, 1.3, 2.0]) {
        await tester.pumpWidget(
          sheetHost(
            ActivitySheet(module: module, status: kUnlocked),
            textScale: scale,
          ),
        );
        await pumpFor(tester, const Duration(milliseconds: 250));
        final double sceneTop = topOf(tester, keyOf('sheet_scene'));
        final double bodyTop = topOf(
          tester,
          find.textContaining(module.def.tagline),
        );
        // Receipt cho handoff: đọc straight từ log, không phải suy từ ảnh.
        // ignore: avoid_print
        print('PQC022 sheet scale=$scale sceneTop=$sceneTop bodyTop=$bodyTop');
        if (scale >= kR56LargeTextScale) {
          expect(
            bodyTop,
            lessThan(sceneTop),
            reason: '$scale× phải đưa chữ lên trước scene (SPEC r56 §4)',
          );
        } else {
          expect(
            sceneTop,
            lessThan(bodyTop),
            reason: '$scale× phải mở đầu bằng scene',
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpFor(tester, const Duration(milliseconds: 400));
      }
    });

    testWidgets('portrait: Py và Bitsy dùng token study, host khác giữ painter', (
      WidgetTester tester,
    ) async {
      usePhone(tester, logical: const Size(360, 640), dpr: 2.0);
      for (final MapEntry<String, String> entry in kR56HostToken.entries) {
        await tester.pumpWidget(
          sheetHost(
            ActivitySheet(
              module: moduleById(entry.key),
              status: kUnlocked,
            ),
          ),
        );
        await pumpFor(tester, const Duration(milliseconds: 300));
        expect(
          imageOfAsset(entry.value),
          findsOneWidget,
          reason: '${entry.key} phải vẽ portrait token r56 ${entry.value}',
        );
        expect(
          tester.getSize(keyOf('sheet_guide')),
          kSheetGuideSize,
          reason: 'ASSET_PLAN r56: portrait 115×140, không thu nhỏ ở chữ lớn',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpFor(tester, const Duration(milliseconds: 300));
      }

      await tester.pumpWidget(
        sheetHost(
          ActivitySheet(
            module: moduleById('dragon_jump'),
            status: kUnlocked,
          ),
        ),
      );
      await pumpFor(tester, const Duration(milliseconds: 300));
      expect(
        find.byType(CharacterView),
        findsWidgets,
        reason: 'Robo/Pip giữ CharacterView painter (ASSET_PLAN: không copy thêm)',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('CTA qua showPQSheet thật: pop open / lesson:<id> không đổi', (
      WidgetTester tester,
    ) async {
      usePhone(tester, logical: const Size(360, 640), dpr: 2.0);
      final AppServices services = (await tester.runAsync(createServices))!;
      addTearDown(services.dispose);

      for (final (ActivityStatus status, String result) in <(ActivityStatus, String)>[
        (kUnlocked, 'open'),
        (kLocked, 'lesson:mq1_03'),
      ]) {
        Future<String?>? popped;
        final bool locked = status.locked;
        await tester.pumpWidget(
          appHome(
            services,
            _SheetLauncher(
              module: moduleById('main_quest'),
              status: status,
              onPopped: (Future<String?> future) => popped = future,
            ),
          ),
        );
        await pumpFor(tester, const Duration(milliseconds: 400));
        await tester.tap(keyOf('probe_open_sheet'));
        await pumpFor(tester, const Duration(milliseconds: 700));

        final Finder cta = keyOf(locked ? 'sheet_go_lesson' : 'sheet_open');
        expect(cta, findsOneWidget, reason: 'thiếu CTA cho state locked=$locked');
        await tester.scrollUntilVisible(
          cta,
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await pumpFor(tester, const Duration(milliseconds: 200));
        await tester.tap(cta);
        await pumpFor(tester, const Duration(milliseconds: 700));
        expect(
          await popped!,
          result,
          reason: 'nút ${locked ? "sheet_go_lesson" : "sheet_open"} phải pop $result',
        );
        await pumpFor(tester, const Duration(milliseconds: 500));
      }
    });

    testWidgets('sheet_close pop null và không mở activity', (
      WidgetTester tester,
    ) async {
      usePhone(tester, logical: const Size(360, 640), dpr: 2.0);
      final AppServices services = (await tester.runAsync(createServices))!;
      addTearDown(services.dispose);
      Future<String?>? popped;
      await tester.pumpWidget(
        appHome(
          services,
          _SheetLauncher(
            module: moduleById('main_quest'),
            status: kUnlocked,
            onPopped: (Future<String?> future) => popped = future,
          ),
        ),
      );
      await pumpFor(tester, const Duration(milliseconds: 400));
      await tester.tap(keyOf('probe_open_sheet'));
      await pumpFor(tester, const Duration(milliseconds: 700));
      await tester.tap(keyOf('sheet_close'));
      await pumpFor(tester, const Duration(milliseconds: 700));
      expect(await popped!, isNull, reason: 'Đóng phải pop null như Để sau');
      expect(
        find.byType(ActivitySheet),
        findsNothing,
        reason: 'sheet còn mở sau khi Đóng',
      );
      expect(services.energy.current, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  });

  group('Welcome r56 ở root thật', () {
    testWidgets('scene 300px + bước 1/3 + next/previous/close, barrier không đóng', (
      WidgetTester tester,
    ) async {
      usePhone(tester, logical: const Size(390, 844), dpr: 3.0);
      final AppServices services = (await tester.runAsync(createServices))!;
      addTearDown(services.dispose);
      await pumpRoot(tester, services, scale: 1.0);

      expect(find.byType(MainMapScreen), findsOneWidget);
      expect(keyOf('welcome_scene'), findsOneWidget);
      expect(
        tester.getSize(keyOf('welcome_scene')).height,
        kWelcomeSceneHeight,
        reason: 'ASSET_PLAN r56: welcome scene 300px ở cỡ chữ thường',
      );
      expect(imageOfAsset(kSheetSceneAsset), findsWidgets);
      expect(find.textContaining('Bước 1/3'), findsOneWidget);
      expect(find.text('Chào mừng tới Đảo Khởi Đầu!'), findsOneWidget);
      expect(keyOf('welcome_previous'), findsNothing);
      expect(keyOf('welcome_next'), findsOneWidget);
      expect(keyOf('welcome_close'), findsOneWidget);

      // Nhấn nền không được coi là đã đọc xong (SPEC r56 §4).
      await tester.tapAt(const Offset(4, 4));
      await pumpFor(tester, const Duration(milliseconds: 300));
      expect(keyOf('welcome_next'), findsOneWidget);

      await tester.tap(keyOf('welcome_next'));
      await pumpFor(tester, const Duration(milliseconds: 400));
      expect(find.textContaining('Bước 2/3'), findsOneWidget);
      expect(keyOf('welcome_previous'), findsOneWidget);
      // Bước của Py dùng token study mới, không phải painter.
      expect(imageOfAsset('assets/images/py_token_r56.png'), findsOneWidget);
      expect(
        tester.getSize(keyOf('welcome_guide')).width,
        kWelcomeGuideSize.width,
      );

      await tester.tap(keyOf('welcome_previous'));
      await pumpFor(tester, const Duration(milliseconds: 400));
      expect(find.textContaining('Bước 1/3'), findsOneWidget);

      for (var i = 0; i < 3; i++) {
        await tester.tap(keyOf('welcome_next'));
        await pumpFor(tester, const Duration(milliseconds: 400));
      }
      expect(keyOf('welcome_next'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2.0×: panel full-bleed, scene 250px, chữ trước scene, CTA cuộn tới được', (
      WidgetTester tester,
    ) async {
      usePhone(tester, logical: const Size(360, 640), dpr: 2.0);
      final AppServices services = (await tester.runAsync(createServices))!;
      addTearDown(services.dispose);
      await pumpRoot(tester, services, scale: 2.0);

      expect(keyOf('welcome_scene'), findsOneWidget);
      final double sceneHeight = tester.getSize(keyOf('welcome_scene')).height;
      final double sceneTop = topOf(tester, keyOf('welcome_scene'));
      final double titleTop = topOf(
        tester,
        find.text('Chào mừng tới Đảo Khởi Đầu!'),
      );
      // ignore: avoid_print
      print(
        'PQC022 welcome 2x sceneHeight=$sceneHeight sceneTop=$sceneTop '
        'titleTop=$titleTop',
      );
      expect(
        sceneHeight,
        kWelcomeSceneHeightLarge,
        reason: 'ASSET_PLAN r56: ở chữ >=1.5x scene welcome còn 250px',
      );
      expect(
        titleTop,
        lessThan(sceneTop),
        reason: 'SPEC r56 §4: chữ đứng trước artwork ở 2×',
      );
      expect(
        tester.getSize(keyOf('welcome_guide')).height,
        kWelcomeGuideSize.height,
        reason: 'portrait 152×175 không bị thu ở chữ lớn',
      );
      // Footer nằm ngoài vùng cuộn theo r56, nên CTA phải ở trong khung nhìn mà
      // không cần cuộn: đó là cách kiểm "CTA luôn với tới được" ở 2×.
      final Rect nextRect = tester.getRect(keyOf('welcome_next'));
      // ignore: avoid_print
      print('PQC022 welcome 2x nextRect=$nextRect');
      expect(nextRect.bottom, lessThanOrEqualTo(640));
      expect(nextRect.top, greaterThanOrEqualTo(0));
      expect(nextRect.height, greaterThanOrEqualTo(36));
      expect(tester.takeException(), isNull);
    });
  });

  group('Main Quest journey r43', () {
    // `ListView` của màn này lười: child ngoài cacheExtent CHƯA được build, nên
    // mọi phép kiểm ở nửa dưới danh sách (kể cả kiểm tồn tại key) phải cuộn tới
    // trước. Đây là bài học từ đỏ 863d20a: `skipOffstage: false` không cứu được
    // vì element chưa tồn tại trong tree.
    Future<void> scrollTo(WidgetTester tester, Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await pumpFor(tester, const Duration(milliseconds: 250));
    }

    testWidgets('cảnh vườn tháp + ba bệ + quick continue ở 1× và 2×', (
      WidgetTester tester,
    ) async {
      for (final double scale in <double>[1.0, 2.0]) {
        usePhone(
          tester,
          logical: scale == 1.0 ? const Size(390, 844) : const Size(360, 640),
          dpr: scale == 1.0 ? 3.0 : 2.0,
        );
        final AppServices services = (await tester.runAsync(createServices))!;
        addTearDown(services.dispose);
        await tester.pumpWidget(
          appHome(services, const MainQuestHomeScreen(), textScale: scale),
        );
        await pumpFor(tester, const Duration(milliseconds: 500));

        // Đỉnh màn hình: đo TRƯỚC khi cuộn xuống, vì cuộn xong thì dải cảnh có
        // thể bị thải khỏi cacheExtent và không còn build.
        expect(
          keyOf('quest_quick_continue'),
          findsOneWidget,
          reason: 'thiếu quick continue ở $scale×',
        );
        expect(
          keyOf('lesson_card_mq1_01'),
          findsOneWidget,
          reason:
              '$scale×: thẻ bài đầu tiên phải nằm trong khung nhìn khi vừa mở màn',
        );
        final double ctaHeight = tester
            .getSize(keyOf('quest_quick_continue'))
            .height;
        expect(
          ctaHeight,
          greaterThanOrEqualTo(36),
          reason: 'CTA nhanh không được teo dưới 36px cao ở $scale×',
        );
        Size sceneSize = Size.zero;
        if (scale < kTowerLargeTextScale) {
          // Cỡ chữ thường: artwork là lớp không gian, đứng đầu danh sách.
          expect(
            keyOf('tower_25d_scene'),
            findsOneWidget,
            reason: 'thiếu dải cảnh 2,5D ở $scale×',
          );
          expect(
            keyOf('tower_guide'),
            findsOneWidget,
            reason: 'thiếu guide Py trên dải cảnh ở $scale×',
          );
          expect(
            imageOfAsset(kTowerSceneAsset),
            findsOneWidget,
            reason:
                'scene vườn tháp phải là Image.asset thật, không phải BoxDecoration',
          );
          expect(
            imageOfAsset(kPyHostTokenAsset),
            findsOneWidget,
            reason: 'guide Py dùng token r56, không phải painter',
          );
          sceneSize = tester.getSize(keyOf('tower_25d_scene'));
          expect(
            sceneSize.height,
            kTowerSceneHeight,
            reason: 'r43 §1: ở cỡ chữ thường, dải cảnh là lớp không gian 180px',
          );
          expect(
            topOf(tester, keyOf('tower_25d_scene')),
            lessThan(topOf(tester, find.textContaining('CHẶNG 1'))),
            reason: '$scale×: artwork đứng đầu danh sách, chữ theo sau',
          );
        } else {
          // Từ 1.5x: "content before artwork" — dải cảnh không còn là artwork
          // 2,5D (key tower_25d_scene biến mất), chỉ còn seal + Continue gọn.
          expect(
            keyOf('tower_25d_scene'),
            findsNothing,
            reason: '$scale×: artwork vẫn chiếm 180px thay vì trả chỗ cho chữ',
          );
          expect(
            imageOfAsset(kTowerSceneAsset),
            findsNothing,
            reason: '$scale×: không phóng artwork nên không còn Image của scene',
          );
          expect(
            find.textContaining('CHẶNG 1'),
            findsOneWidget,
            reason: '$scale×: panel chặng phải thấy được ngay khi mở màn',
          );
        }

        // 12 bài một chương (main_quest_ch1.json) -> ba bệ, mỗi bệ 4 bài; khoảng
        // bài ghi bằng en dash, số bài luôn đi kèm nên màu không phải tín hiệu duy nhất.
        const List<String> bandLabels = <String>['Bệ 1–4', 'Bệ 5–8', 'Bệ 9–12'];
        for (var g = 0; g < 3; g++) {
          final Finder band = keyOf('quest_pedestal_$g');
          await scrollTo(tester, band);
          expect(band, findsOneWidget, reason: 'thiếu dải bệ $g ở $scale×');
          expect(
            find.textContaining(bandLabels[g]),
            findsOneWidget,
            reason: 'thiếu nhãn "${bandLabels[g]}" ở $scale×',
          );
        }
        expect(
          find.textContaining('đã xong'),
          findsNothing,
          reason: 'người mới chưa xong bài nào thì không bệ nào được đánh dấu xong',
        );
        final Object? pending = tester.takeException();
        // ignore: avoid_print
        print(
          'PQC022-MQ ${scale}x ctaH=$ctaHeight scene=${sceneSize.width}x'
          '${sceneSize.height} exc=$pending',
        );
        expect(pending, isNull, reason: 'layout exception ở Main Quest $scale×');
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpFor(tester, const Duration(milliseconds: 400));
      }
    });

    testWidgets('chạm bệ chỉ đổi highlight dẫn bài, không mở lesson và không trừ phí', (
      WidgetTester tester,
    ) async {
      usePhone(tester, logical: const Size(390, 844), dpr: 3.0);
      final AppServices services = (await tester.runAsync(createServices))!;
      addTearDown(services.dispose);
      await tester.pumpWidget(appHome(services, const MainQuestHomeScreen()));
      await pumpFor(tester, const Duration(milliseconds: 500));

      final int energyBefore = services.energy.current;
      expect(find.byType(LessonScreen), findsNothing);
      final Finder band2 = keyOf('quest_pedestal_2');
      // Cuộn tới CHÍNH CÁI BỆ sẽ chạm (không cuộn tới thẻ phía dưới):
      // `scrollUntilVisible` tiến theo từng bước 160px nên sau khi canh thẻ,
      // bệ có thể bị tràn lên trên đỉnh khung nhìn và `tap` sẽ hụt.
      // `SliverList` còn THẢI element ngoài cacheExtent, nên mọi phép đọc màu
      // phải chạy lúc thẻ đang ở gần khung nhìn, không đọc lại sau khi đã cuộn
      // đi chỗ khác (bài học đỏ 863d20a + 238bebb).
      await scrollTo(tester, band2);
      expect(
        cardBorderColorFor(tester, 'mq1_09'),
        isNot(kBerryBorder),
        reason: 'chưa chạm bệ thì chưa có highlight',
      );
      await tester.tap(band2);
      await pumpFor(tester, const Duration(milliseconds: 400));
      expect(
        find.byType(LessonScreen),
        findsNothing,
        reason: 'chạm bệ là thao tác xem, không được mở bài',
      );
      expect(
        services.energy.current,
        energyBefore,
        reason: 'chọn bệ không được trừ năng lượng',
      );
      expect(
        cardBorderColorFor(tester, 'mq1_09'),
        kBerryBorder,
        reason: 'chạm bệ 3 phải đặt highlight lên bài đầu nhóm (r43)',
      );
      expect(
        cardBorderColorFor(tester, 'mq1_10'),
        isNot(kBerryBorder),
        reason: 'highlight chỉ đứng trên bài dẫn, không lan cả nhóm',
      );
      expect(tester.takeException(), isNull);
    });

    // Tách LÀM HAI CA để `Failing tests:` trong log maintenance chỉ đúng nửa nào
    // đỏ: CI không công bố trace của ca này (bị cắt khỏi 18000 ký tự cuối), nên
    // tên ca chính là kênh bằng chứng duy nhất còn lại.
    testWidgets('openLessonId đặt highlight đúng thẻ, không lan sang thẻ bên', (
      WidgetTester tester,
    ) async {
      usePhone(tester, logical: const Size(360, 640), dpr: 2.0);
      final AppServices services = (await tester.runAsync(createServices))!;
      addTearDown(services.dispose);
      await tester.pumpWidget(
        appHome(
          services,
          const MainQuestHomeScreen(openLessonId: 'mq1_03'),
          textScale: 2.0,
        ),
      );
      await pumpFor(tester, const Duration(milliseconds: 800));

      final Finder deepLink = keyOf('lesson_card_mq1_03');
      await scrollTo(tester, deepLink);
      expect(deepLink, findsOneWidget, reason: 'mất key hợp đồng cũ lesson_card_mq1_03');
      // Viền berry là bằng chứng `openLessonId` đã tới screen; thẻ bên cạnh phải
      // KHÔNG có viền đó, nếu không phép kiểm này chỉ là trang trí.
      final Color edge = cardBorderColorFor(tester, 'mq1_03');
      final Color neighbour = cardBorderColorFor(tester, 'mq1_02');
      // ignore: avoid_print
      print('PQC022-MQ deep-link edge=$edge neighbour=$neighbour');
      expect(
        edge,
        kBerryBorder,
        reason: 'mq1_03 phải được highlight bằng viền berry',
      );
      expect(
        neighbour,
        isNot(kBerryBorder),
        reason: 'viền berry chỉ xuất hiện trên bài được deep-link',
      );
      expect(
        find.byType(LessonScreen),
        findsNothing,
        reason: 'r43: openLessonId chỉ highlight, KHÔNG tự mở bài',
      );
      expect(tester.takeException(), isNull);
    });

    // Ba ca tách rời (tên ca trong `Failing tests:` là kênh duy nhất còn lại để
    // chỉ ra bước đỏ, vì CI cắt trace của file này khỏi log tail).
    Future<AppServices> bootMq2x(WidgetTester tester) async {
      usePhone(tester, logical: const Size(360, 640), dpr: 2.0);
      final AppServices services = (await tester.runAsync(createServices))!;
      addTearDown(services.dispose);
      await tester.pumpWidget(
        appHome(
          services,
          const MainQuestHomeScreen(openLessonId: 'mq1_03'),
          textScale: 2.0,
        ),
      );
      await pumpFor(tester, const Duration(milliseconds: 800));
      return services;
    }

    testWidgets('key hợp đồng cũ lesson_card_mq1_01 còn trên Main Quest 2.0x', (
      WidgetTester tester,
    ) async {
      await bootMq2x(tester);
      expect(
        keyOf('lesson_card_mq1_01'),
        findsOneWidget,
        reason: 'mất key hợp đồng cũ lesson_card_mq1_01',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('cuộn tới đáy Main Quest 2.0x thì open_playground tới được', (
      WidgetTester tester,
    ) async {
      await bootMq2x(tester);
      // Đếm Scrollable TRƯỚC khi assert: nếu hub/nested list có hơn một
      // `Scrollable` thì `Scrollable.first` trong `scrollTo` là sai chỗ.
      final int scrollables = find.byType(Scrollable).evaluate().length;
      // ignore: avoid_print
      print(
        'PQC022-KEYS scrollables=$scrollables '
        'top=${keyOf('lesson_card_mq1_01').evaluate().length} '
        'pg=${keyOf('open_playground').evaluate().length}',
      );
      final Finder playground = keyOf('open_playground');
      await tester.scrollUntilVisible(
        playground,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await pumpFor(tester, const Duration(milliseconds: 250));
      expect(
        playground,
        findsOneWidget,
        reason: 'mất key hợp đồng cũ open_playground',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Main Quest 2.0x không để lại exception sau khi dựng 12 thẻ', (
      WidgetTester tester,
    ) async {
      await bootMq2x(tester);
      for (final String id in <String>[
        'mq1_01',
        'mq1_04',
        'mq1_08',
        'mq1_12',
      ]) {
        final Finder card = keyOf('lesson_card_$id');
        await tester.scrollUntilVisible(
          card,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await pumpFor(tester, const Duration(milliseconds: 250));
        expect(
          card,
          findsOneWidget,
          reason: 'thẻ $id không tới được ở 2.0× (360×640)',
        );
      }
      expect(tester.takeException(), isNull);
    });

    // Cấu hình GIỐNG harness render (`render_screens_test.dart`: 390x844, dpr
    // 3.0, textScaleFactorTestValue 1.0 rồi 2.0). Render là gate "đúng 10 ca"
    // nhưng CI KHÔNG công bố log render (`.output.text` in `(missing:
    // render.txt)`), nên đây là kênh duy nhất để có bằng chứng; ca này đã chạy
    // XANH ở `238bebb` (không nằm trong `Failing tests`) tức ba surface của
    // PQC-022 không sinh exception ở cấu hình render.
    testWidgets('cấu hình render 390×844 dpr3 ở 1.0× và 2.0×: không exception', (
      WidgetTester tester,
    ) async {
      for (final double scale in <double>[1.0, 2.0]) {
        usePhone(tester, logical: const Size(390, 844), dpr: 3.0);
        final AppServices services = (await tester.runAsync(createServices))!;
        addTearDown(services.dispose);

        await tester.pumpWidget(
          RepaintBoundary(
            key: captureKey,
            child: appHome(
              services,
              const MainQuestHomeScreen(),
              textScale: scale,
            ),
          ),
        );
        await pumpFor(tester, const Duration(milliseconds: 600));
        // `capture()` của harness render gọi toImage(pixelRatio: 1.5) trên
        // RepaintBoundary gốc. Đó là khác biệt còn lại giữa ca render và các ca
        // thường của tôi, nên phải gọi lại đúng lệnh đó; nếu chỗ này xanh mà
        // render vẫn 9/10 thì ca đỏ nằm ở bước điều hướng của harness, không
        // phải ở surface của PQC-022.
        // `runAsync<Object?>` sẽ suy ra T = Object từ nhánh `catch` rồi báo
        // `return_of_invalid_type_from_closure` (chính là error đã làm đỏ
        // 9940e6b). Nên đóng gói lỗi vào biến cục bộ, closure trả `void`.
        Object? captureError;
        await tester.runAsync<void>(() async {
          try {
            final RenderRepaintBoundary boundary = captureKey
                .currentContext!
                .findRenderObject()! as RenderRepaintBoundary;
            final ui.Image image = await boundary.toImage(pixelRatio: 1.5);
            final ByteData? bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            if (bytes == null) captureError = 'null png bytes';
          } catch (err) {
            captureError = err;
          }
        });
        // ignore: avoid_print
        print('PQC022-RENDER capture ${scale}x err=$captureError');
        expect(
          captureError,
          isNull,
          reason: 'capture() kiểu harness render lỗi ở $scale×',
        );
        final Object? mqPending = tester.takeException();
        // ignore: avoid_print
        print('PQC022-RENDER mq ${scale}x exc=$mqPending');
        expect(
          mqPending,
          isNull,
          reason: 'Main Quest exception ở $scale× (cấu hình render)',
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpFor(tester, const Duration(milliseconds: 200));

        await tester.pumpWidget(
          sheetHost(
            ActivitySheet(module: moduleById('main_quest'), status: kUnlocked),
            textScale: scale,
          ),
        );
        await pumpFor(tester, const Duration(milliseconds: 400));
        final Object? sheetPending = tester.takeException();
        // ignore: avoid_print
        print('PQC022-RENDER sheet-unlocked ${scale}x exc=$sheetPending');
        expect(
          sheetPending,
          isNull,
          reason: 'ActivitySheet mở ở $scale× (cấu hình render) có exception',
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpFor(tester, const Duration(milliseconds: 200));

        await tester.pumpWidget(
          sheetHost(
            ActivitySheet(module: moduleById('bug_hunter'), status: kLocked),
            textScale: scale,
          ),
        );
        await pumpFor(tester, const Duration(milliseconds: 400));
        final Object? lockedPending = tester.takeException();
        // ignore: avoid_print
        print('PQC022-RENDER sheet-locked ${scale}x exc=$lockedPending');
        expect(
          lockedPending,
          isNull,
          reason: 'a02_sheet_locked ở $scale× có exception',
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpFor(tester, const Duration(milliseconds: 200));

        await pumpRoot(tester, services, scale: scale);
        final Object? welcomePending = tester.takeException();
        // ignore: avoid_print
        print('PQC022-RENDER welcome ${scale}x exc=$welcomePending');
        expect(welcomePending, isNull, reason: 'a00_welcome ở $scale× có exception');
        for (var i = 0; i < 3; i++) {
          final Finder next = keyOf('welcome_next');
          expect(next, findsOneWidget, reason: 'mất welcome_next lần $i ở $scale×');
          await tester.tap(next);
          await pumpFor(tester, const Duration(milliseconds: 400));
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpFor(tester, const Duration(milliseconds: 400));
      }
    });
  });

  // Chuỗi thao tác của `render A: first launch` — ca render duy nhất chạm cả
  // welcome + hub + sheet khóa, cũng là ca bị nghi của `9 passed, 1 failed`.
  // Làm lại đúng trình tự đó trong ordinary suite là kênh bằng chứng duy nhất
  // còn mở, vì CI không công bố log render.
  group('Render A replica', () {
    testWidgets(
      'hub 2.0x tu bat directory, ve 1.0x roi sheet khoa van vao duoc bai hoc',
      (WidgetTester tester) async {
        usePhone(tester, logical: const Size(390, 844), dpr: 3.0);
        final AppServices services = (await tester.runAsync(createServices))!;
        addTearDown(services.dispose);
        await tester.runAsync(
          () => services.settings.setRaw('intro_seen', '0'),
        );

        await pumpRoot(tester, services, scale: 2.0);
        for (var i = 0; i < 3; i++) {
          await tester.tap(keyOf('welcome_next'));
          await pumpFor(tester, const Duration(milliseconds: 500));
        }
        expect(find.byType(MainMapScreen), findsOneWidget);
        expect(
          keyOf('directory_place_main_quest'),
          findsOneWidget,
          reason: '2x hệ thống phải tự bật directory ở root thật (như render A)',
        );
        final double hubScale = MediaQuery.textScalerOf(
          tester.element(find.byType(MainMapScreen)),
        ).scale(16);
        // ignore: avoid_print
        print('PQC022-RENDER-A hubScale=$hubScale');
        expect(
          hubScale,
          closeTo(32, 0.01),
          reason: 'hub phải nhận scaler 32px trên 16px ở 2.0×',
        );

        await tester.tap(keyOf('main_map_mode_village'));
        await pumpFor(tester, const Duration(milliseconds: 500));
        await pumpRoot(tester, services, scale: 1.0);
        expect(find.byType(MainMapScreen), findsOneWidget);

        await tester.ensureVisible(keyOf('map_label_bug_hunter').first);
        await pumpFor(tester, const Duration(milliseconds: 400));
        await tester.tap(keyOf('map_label_bug_hunter'), warnIfMissed: false);
        await pumpFor(tester, const Duration(milliseconds: 900));
        expect(find.byType(ActivitySheet), findsOneWidget);
        final Rect cta = tester.getRect(keyOf('sheet_go_lesson'));
        final double vpHeight =
            tester.view.physicalSize.height / tester.view.devicePixelRatio;
        // ignore: avoid_print
        print('PQC022-RENDER-A cta=${cta.top}..${cta.bottom} vp=$vpHeight');
        expect(
          cta.bottom <= vpHeight,
          isTrue,
          reason: 'sheet_go_lesson phải trong khung nhìn, nếu không tap() của harness hụt',
        );
        // Giống harness: tap TRỰC TIẾP, không ensureVisible, warnIfMissed mặc định.
        await tester.tap(keyOf('sheet_go_lesson'));
        await pumpFor(tester, const Duration(milliseconds: 1400));
        expect(
          find.byType(MainQuestHomeScreen),
          findsOneWidget,
          reason: 'sheet khóa của bug_hunter phải dẫn tới bài học prerequisite',
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
