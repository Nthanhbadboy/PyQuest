@Tags(['render'])
library;

// Renders key screens to PNG (build/previews/) with the real fonts so the UI
// can be reviewed without a device. Not a golden test: nothing is compared.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/app/app_services.dart';
import 'package:pyquest/app/pyquest_app.dart';
import 'package:pyquest/core/events.dart';
import 'package:pyquest/modules/tutor/tutor_config.dart';
import 'package:pyquest/modules/tutor/tutor_provider.dart';
import 'package:pyquest/modules/main_map/main_map_screen.dart';
import 'package:pyquest/modules/main_quest/main_quest_module.dart';
import 'package:pyquest/shared/characters/cast.dart';
import 'package:pyquest/shared/characters/characters.dart';
import 'package:pyquest/shared/widgets/sprite_cache.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../test_helpers.dart';

final GlobalKey _captureKey = GlobalKey();

Future<void> loadMaterialIcons() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final file = File(
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (!file.existsSync()) return;
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  await loader.load();
}

Future<void> capture(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 50));
  await tester.runAsync(() async {
    final boundary =
        _captureKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/previews/$name.png');
    await file.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

/// A fixed answer used only inside previews, so the AI-labelled state of the
/// tutor panel can be screenshotted without a provider or a credential.
const String _previewAnswer =
    'Bạn đang dùng biến đúng cách rồi!\n'
    'Thử đổi giá trị này xem máy in ra gì nhé:\n'
    '```python\ndiem = 7\nprint(diem)\n```\n'
    'Đoán trước kết quả rồi chạy thử để kiểm chứng.';

Future<AppServices> seeded(
  WidgetTester tester, {
  bool rich = false,
  bool tutorAi = false,
}) async {
  final clock = FakeClock(DateTime(2026, 10, 15, 16));
  final s = (await tester.runAsync(
    () => AppServices.create(
      bundle: rootBundle,
      databaseFactory: databaseFactoryFfiNoIsolate,
      databasePath: inMemoryDatabasePath,
      clock: clock,
      audioEnabled: false,
      startSessionTimer: false,
      tutorConfig: tutorAi
          ? const TutorConfig(endpoint: 'https://preview.invalid')
          : null,
      tutorProvider: tutorAi ? const StaticTutorProvider(_previewAnswer) : null,
    ),
  ))!;
  await tester.runAsync(() async {
    await s.settings.setIntroSeen();
    if (rich) {
      for (final (id, stars, next) in [
        ('rm_01', 3, 'rm_02'),
        ('rm_02', 2, 'rm_03'),
        ('rm_03', 3, 'rm_04'),
      ]) {
        await s.events.emit(
          StandardEvent(
            type: EventTypes.levelCompleted,
            sourceId: 'robot_maze',
            data: {
              'level_id': id,
              'stars': stars,
              'score': 100,
              'next_level_id': next,
            },
          ),
        );
      }
      for (final l in ['mq1_01', 'mq1_02', 'mq1_03']) {
        await s.events.emit(
          StandardEvent(
            type: EventTypes.lessonCompleted,
            sourceId: 'main_quest',
            data: {
              'lesson_id': l,
              'chapter_id': 'code_apprentice',
              'skills': <String>[],
              'score': 100,
            },
          ),
        );
      }
      await s.store.addInt('dragon_jump', 'coins', 180);
      await s.energy.spend(7);
    }
  });
  return s;
}

Future<void> precacheMap(WidgetTester tester) async {
  final ctx = tester.element(find.byType(Scaffold).first);
  await tester.runAsync(() async {
    await SpriteCache.preloadAll();
    for (final a in [
      'assets/images/village_r53.webp',
      'assets/images/thumb_maze.webp',
      'assets/images/thumb_tower.webp',
      'assets/images/thumb_volcano.webp',
      'assets/images/thumb_observatory.webp',
      'assets/images/thumb_workshop.webp',
      'assets/images/thumb_house.webp',
      'assets/images/arrival_r56.webp',
      'assets/images/main_quest_r56.webp',
      'assets/images/py_token_r56.png',
      'assets/images/bitsy_token_r56.png',
      'assets/images/maze_trail_r45.webp',
      'assets/images/maze_workbench_r46.webp',
      'assets/images/garden_stage_r50.webp',
      'assets/images/hedge_token_r50.png',
      'assets/images/robo_token_r50.png',
      'assets/images/robo_celebration_r52.webp',
      'assets/images/volcano_trail_r54.webp',
      'assets/images/pip_token_r54.png',
      'assets/images/basalt_token_r54.png',
      'assets/images/beetle_token_r54.png',
      'assets/images/observatory_sky_r55.webp',
      'assets/images/jar_token_r55.png',
      'assets/images/star_token_r55.png',
      'assets/images/meteor_token_r55.png',
      'assets/images/bug_workshop_r36.webp',
      'assets/images/achievement_room_r39.webp',
      'assets/images/journal_recap_r36.webp',
      'assets/images/garden_kiosk_r41.webp',
    ]) {
      await precacheImage(AssetImage(a), ctx);
    }
  });
}

/// Cuộn hub thật tới một target, thay vì đo một widget đang nằm ngoài màn hình.
Future<void> scrollHubTo(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(ValueKey<String>(key)).first);
  await pumpFor(tester, const Duration(milliseconds: 400));
}

Future<void> tap(WidgetTester tester, String key, {int ms = 1200}) async {
  final f = find.byKey(ValueKey(key), skipOffstage: false);
  await tester.ensureVisible(f.first);
  await tester.pump();
  await tester.tap(f.first, warnIfMissed: false);
  await pumpFor(tester, Duration(milliseconds: ms));
}

Future<void> home(WidgetTester tester) async {
  tester
      .state<NavigatorState>(find.byType(Navigator).last)
      .popUntil((r) => r.isFirst);
  await pumpFor(tester, const Duration(seconds: 2));
}

/// Widget gốc đang được pump. Render A/F đổi cỡ chữ hệ thống rồi pump lại ĐÚNG cây
/// này, nên State của MainMapScreen (mode, scroll, focus) còn nguyên — đó mới là
/// bằng chứng "app đang mở mà scale đổi", không phải một app vừa khởi động lại.
Widget? _rootHost;

Future<AppServices> start(
  WidgetTester tester, {
  bool rich = true,
  bool intro = false,
  bool small = false,
  bool tutorAi = false,
  List<Locale>? systemLocales,
}) async {
  // Default: 390 x 844 @3x. Small: 360 x 640 @2x (older/compact Android phones).
  tester.view.physicalSize = small
      ? const Size(720, 1280)
      : const Size(1170, 2532);
  tester.view.devicePixelRatio = small ? 2.0 : 3.0;
  addTearDown(tester.view.reset);
  final s = await seeded(tester, rich: rich, tutorAi: tutorAi);
  if (intro) await tester.runAsync(() => s.settings.setRaw('intro_seen', '0'));
  _rootHost = RepaintBoundary(
    key: _captureKey,
    child: PyQuestApp(
      servicesFactory: (_) async => s,
      systemLocalesReader: systemLocales == null ? null : () => systemLocales,
      minSplash: Duration.zero,
    ),
  );
  await tester.pumpWidget(_rootHost!);
  await pumpFor(tester, const Duration(seconds: 2));
  await precacheMap(tester);
  await pumpFor(tester, const Duration(milliseconds: 400));
  return s;
}

/// Cỡ chữ hệ thống thật: đặt giá trị trên platformDispatcher rồi pump lại cây app
/// đang chạy. R3 finding B bỏ hẳn helper bypass — một `MediaQuery` override trong
/// route MainMap thứ hai không phải bằng chứng cho app root.
Future<void> setSystemTextScale(WidgetTester tester, double scale) async {
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(_rootHost!);
  await pumpFor(tester, const Duration(milliseconds: 900));
}

/// Scaler mà hub THẬT đang nhận trên 16px — con số ghi vào receipt ảnh 2x.
double hubTextScale(WidgetTester tester) => MediaQuery.textScalerOf(
  tester.element(find.byType(MainMapScreen)),
).scale(16);

Future<void> finish(WidgetTester tester, AppServices s) async {
  s.dispose();
  await pumpFor(tester, const Duration(seconds: 4));
  // Gỡ cây widget rồi pump thêm một nhịp dài hơn Timer dài nhất mà mini-game hẹn,
  // nếu không render D có thể kết thúc đúng giữa lúc Catch Stars vừa đặt
  // `Future.delayed(900ms)` cho màn hình kết quả → "A Timer is still pending even
  // after the widget tree was disposed" và đỏ cả render job không liên quan gì tới
  // thay đổi đang được kiểm. Đây là sửa harness (chỉ `app/test/**`), không nới assert.
  await tester.pumpWidget(const SizedBox.shrink());
  await pumpFor(tester, const Duration(milliseconds: 1100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUpAll(() async {
    await loadAppFonts();
    await loadMaterialIcons();
  });

  testWidgets('render A: first launch', (tester) async {
    final s = await start(
      tester,
      rich: false,
      intro: true,
      systemLocales: const <Locale>[Locale('vi')],
    );
    await capture(tester, 'a00_welcome');
    for (var i = 0; i < 3; i++) {
      await tap(tester, 'welcome_next', ms: 500);
    }
    await capture(tester, 'a01_map_new_player');
    await capture(tester, 'r1a_map_390_vi_1x');
    // Một khung nhìn 390x844 không chứa đủ sáu nhãn, nên "đủ sáu" phải có cả pha
    // cuối của scene thật (R3 E2: full scene / scroll-bottom).
    await scrollHubTo(tester, 'map_label_achievement_house');
    await capture(tester, 'r1a_map_390_vi_1x_bottom');
    await scrollHubTo(tester, 'map_label_main_quest');
    await setSystemTextScale(tester, 2);
    expect(
      find.byKey(const ValueKey<String>('directory_place_main_quest')),
      findsOneWidget,
      reason: '2x hệ thống phải tự bật directory ở root thật',
    );
    expect(hubTextScale(tester), closeTo(32, 0.01));
    // ignore: avoid_print
    print(
      'R3-RENDER r1a_map_390_vi_2x effectiveScale16=${hubTextScale(tester)}',
    );
    await capture(tester, 'r1a_map_390_vi_2x');
    await tester.tap(
      find.byKey(const ValueKey<String>('main_map_mode_village')),
    );
    await pumpFor(tester, const Duration(milliseconds: 500));
    await capture(tester, 'r1a_map_390_vi_2x_village');
    await scrollHubTo(tester, 'map_label_achievement_house');
    await capture(tester, 'r1a_map_390_vi_2x_village_bottom');
    await setSystemTextScale(tester, 1);
    expect(find.byType(MainMapScreen), findsOneWidget);

    await tap(tester, 'map_label_bug_hunter', ms: 900);
    await capture(tester, 'a02_sheet_locked');
    await capture(tester, 'r1a_locked_activity_sheet');
    await tester.tap(find.byKey(const ValueKey<String>('sheet_go_lesson')));
    await pumpFor(tester, const Duration(milliseconds: 1400));
    expect(find.byType(MainQuestHomeScreen), findsOneWidget);
    await capture(tester, 'r1a_locked_prerequisite_route');
    await home(tester);
    await capture(tester, 'r1a_map_after_route_return');
    await finish(tester, s);
  });

  testWidgets('render B: robot maze', (tester) async {
    final s = await start(tester);
    await capture(tester, 'b00_map_progress');
    await tap(tester, 'map_label_robot_maze', ms: 900);
    await capture(tester, 'b01_sheet_maze');
    await tap(tester, 'sheet_open', ms: 1500);
    await capture(tester, 'b02_maze_home');
    await tap(tester, 'maze_level_1', ms: 1500);
    for (var i = 0; i < 4; i++) {
      await tap(tester, 'palette_right', ms: 150);
    }
    await tap(tester, 'maze_show_python', ms: 300);
    await capture(tester, 'b03_maze_program_python');
    await tap(tester, 'maze_run', ms: 5000);
    await capture(tester, 'b04_maze_result');
    await tap(tester, 'result_back', ms: 1500);
    await tap(tester, 'maze_level_4', ms: 1500);
    for (final k in [
      'palette_down',
      'palette_down',
      'palette_down',
      'palette_right',
    ]) {
      await tap(tester, k, ms: 150);
    }
    await tap(tester, 'maze_run', ms: 4000);
    await capture(tester, 'b05_maze_fail');
    await tap(tester, 'back_button', ms: 1200);
    await tester.drag(find.byType(ListView).first, const Offset(0, -1400));
    await pumpFor(tester, const Duration(milliseconds: 600));
    await tap(tester, 'open_workshop', ms: 1500);
    await capture(tester, 'b06_workshop');
    await tap(tester, 'workshop_code', ms: 1800);
    await tester.enterText(
      find.byKey(const ValueKey('code_editor_field')),
      'for i in range(5):\n    right()\nfor i in range(5):\n    down()\n',
    );
    await pumpFor(tester, const Duration(milliseconds: 400));
    await capture(tester, 'b07_workshop_code');
    await tap(tester, 'maze_run', ms: 6000);
    await capture(tester, 'b08_workshop_verified');
    await finish(tester, s);
  });

  testWidgets('render C: lesson flow', (tester) async {
    final s = await start(tester, rich: false);
    await tap(tester, 'map_label_main_quest', ms: 900);
    await tap(tester, 'sheet_open', ms: 1500);
    await capture(tester, 'c00_tower_new');
    await tap(tester, 'lesson_card_mq1_01', ms: 1500);
    await capture(tester, 'c01_lesson_story');
    await tap(tester, 'lesson_continue', ms: 500);
    await tap(tester, 'example_run', ms: 500);
    await capture(tester, 'c02_lesson_example');
    await tap(tester, 'lesson_continue', ms: 500);
    await tap(tester, 'choice_1', ms: 300);
    await tap(tester, 'lesson_check', ms: 500);
    await capture(tester, 'c03_lesson_choice_wrong');
    await tap(tester, 'choice_0', ms: 300);
    await tap(tester, 'lesson_check', ms: 500);
    await tap(tester, 'lesson_continue', ms: 500);
    await tester.tap(find.text('"PyQuest"').first);
    await pumpFor(tester, const Duration(milliseconds: 300));
    await tap(tester, 'lesson_check', ms: 600);
    await capture(tester, 'c04_lesson_fill_correct');
    await tap(tester, 'lesson_continue', ms: 500);
    await tester.enterText(
      find.byKey(const ValueKey('code_editor_field')),
      'print("Robo thông minh"',
    );
    await tap(tester, 'lesson_check', ms: 600);
    await capture(tester, 'c05_lesson_code_error');
    await tester.enterText(
      find.byKey(const ValueKey('code_editor_field')),
      'print("Robo thông minh")',
    );
    await tap(tester, 'lesson_check', ms: 600);
    await capture(tester, 'c06_lesson_code_ok');
    await tap(tester, 'lesson_continue', ms: 2500);
    await capture(tester, 'c07_lesson_complete');
    await finish(tester, s);
  });

  testWidgets('render D: arcade games', (tester) async {
    final s = await start(tester);
    await tap(tester, 'map_label_dragon_jump', ms: 900);
    await tap(tester, 'sheet_open', ms: 1500);
    await capture(tester, 'd00_dragon_home');
    await tap(tester, 'dragon_shop', ms: 900);
    await capture(tester, 'd01_dragon_shop');
    await tester.tapAt(const Offset(20, 60));
    await pumpFor(tester, const Duration(milliseconds: 800));
    await tap(tester, 'dragon_play', ms: 1200);
    final area = find.byKey(const ValueKey('dragon_tap_area'));
    for (var i = 0; i < 6; i++) {
      await tester.tap(area);
      await pumpFor(tester, const Duration(milliseconds: 700));
    }
    await capture(tester, 'd02_dragon_play');
    for (
      var i = 0;
      i < 60 && find.byKey(const ValueKey('result_title')).evaluate().isEmpty;
      i++
    ) {
      await pumpFor(tester, const Duration(milliseconds: 500));
    }
    await pumpFor(tester, const Duration(seconds: 2));
    await capture(tester, 'd03_dragon_result');
    await tap(tester, 'result_map', ms: 2000);
    await tap(tester, 'map_label_catch_stars', ms: 900);
    await tap(tester, 'sheet_open', ms: 1500);
    await capture(tester, 'd04_stars_home');
    await tap(tester, 'open_atlas', ms: 1300);
    await capture(tester, 'd05_star_atlas');
    await tap(tester, 'back_button', ms: 1200);
    await tap(tester, 'stars_play', ms: 1200);
    for (var i = 0; i < 16; i++) {
      await tester.tapAt(Offset(80.0 + (i * 53) % 240, 650));
      await pumpFor(tester, const Duration(milliseconds: 500));
    }
    await capture(tester, 'd06_stars_play');
    await finish(tester, s);
  });

  testWidgets('render E: house, bugs, sheets, playground', (tester) async {
    final s = await start(tester);
    await tap(tester, 'energy_pill', ms: 900);
    await capture(tester, 'e00_energy_sheet');
    await tester.tapAt(const Offset(20, 60));
    await pumpFor(tester, const Duration(milliseconds: 800));
    await tap(tester, 'daily_quests_button', ms: 900);
    await capture(tester, 'e01_daily_quests');
    await tester.tapAt(const Offset(20, 60));
    await pumpFor(tester, const Duration(milliseconds: 800));
    await tap(tester, 'settings_button', ms: 900);
    await capture(tester, 'e02_settings');
    await tester.tapAt(const Offset(20, 60));
    await pumpFor(tester, const Duration(milliseconds: 800));
    await tap(tester, 'map_label_achievement_house', ms: 900);
    await tap(tester, 'sheet_open', ms: 1500);
    await capture(tester, 'e03_house_badges');
    await tap(tester, 'room_1', ms: 600);
    await capture(tester, 'e04_house_wall');
    await home(tester);
    await tap(tester, 'map_label_bug_hunter', ms: 900);
    await tap(tester, 'sheet_open', ms: 1500);
    await capture(tester, 'e05_bug_home');
    await tap(tester, 'puzzle_bh_01', ms: 1500);
    await tap(tester, 'bug_run', ms: 800);
    await capture(tester, 'e06_bug_puzzle_run');
    await tester.tap(find.byKey(const ValueKey('code_line_2')));
    await pumpFor(tester, const Duration(milliseconds: 900));
    await capture(tester, 'e07_bug_fix_picker');
    await tester.tapAt(const Offset(20, 60));
    await pumpFor(tester, const Duration(milliseconds: 800));
    await home(tester);
    await tap(tester, 'map_label_main_quest', ms: 900);
    await tap(tester, 'sheet_open', ms: 1500);
    await tester.drag(find.byType(ListView).first, const Offset(0, -1600));
    await pumpFor(tester, const Duration(milliseconds: 600));
    await tap(tester, 'open_playground', ms: 1500);
    await tap(tester, 'playground_run', ms: 800);
    await capture(tester, 'e08_playground');
    await finish(tester, s);
  });

  testWidgets('render F: small phone 360x640', (tester) async {
    final s = await start(
      tester,
      small: true,
      systemLocales: const <Locale>[Locale('en')],
    );
    await capture(tester, 'f00_small_map');
    await capture(tester, 'r1a_map_360_en_1x');
    await scrollHubTo(tester, 'map_label_achievement_house');
    await capture(tester, 'r1a_map_360_en_1x_bottom');
    await scrollHubTo(tester, 'map_label_main_quest');
    await setSystemTextScale(tester, 2);
    expect(
      find.byKey(const ValueKey<String>('directory_place_main_quest')),
      findsOneWidget,
      reason: '2x hệ thống phải tự bật directory ở root 360',
    );
    expect(hubTextScale(tester), closeTo(32, 0.01));
    // ignore: avoid_print
    print(
      'R3-RENDER r1a_map_360_en_2x effectiveScale16=${hubTextScale(tester)}',
    );
    await capture(tester, 'r1a_map_360_en_2x');
    await tester.tap(
      find.byKey(const ValueKey<String>('main_map_mode_village')),
    );
    await pumpFor(tester, const Duration(milliseconds: 500));
    await capture(tester, 'r1a_map_360_en_2x_village');
    await scrollHubTo(tester, 'map_label_achievement_house');
    await capture(tester, 'r1a_map_360_en_2x_village_bottom');
    await setSystemTextScale(tester, 1);
    expect(find.byType(MainMapScreen), findsOneWidget);
    await tap(tester, 'map_label_robot_maze', ms: 900);
    await tap(tester, 'sheet_open', ms: 1500);
    await tap(tester, 'maze_level_4', ms: 1500);
    for (final k in [
      'palette_down',
      'palette_down',
      'palette_down',
      'palette_down',
      'palette_right',
      'palette_right',
    ]) {
      await tap(tester, k, ms: 150);
    }
    await capture(tester, 'f01_small_maze');
    await home(tester);
    await tap(tester, 'map_label_main_quest', ms: 900);
    await tap(tester, 'sheet_open', ms: 1500);
    await tap(tester, 'lesson_card_mq1_04', ms: 1500);
    await tap(tester, 'lesson_continue', ms: 500);
    await tap(tester, 'example_run', ms: 500);
    await capture(tester, 'f02_small_lesson');
    await home(tester);
    await tap(tester, 'map_label_dragon_jump', ms: 900);
    await tap(tester, 'sheet_open', ms: 1500);
    await capture(tester, 'f03_small_dragon_home');
    await finish(tester, s);
  });

  testWidgets('render G: cast gallery', (tester) async {
    tester.view.physicalSize = const Size(1170, 3100);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _captureKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ColoredBox(
            color: const Color(0xFFFFF5DE),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  children: [
                    for (final member in CastRegistry.members)
                      SizedBox(
                        width: 116,
                        child: Column(
                          children: [
                            CharacterView(
                              id: member.id,
                              size: 104,
                              animate: false,
                            ),
                            Text(
                              member.name,
                              style: const TextStyle(
                                fontFamily: 'Baloo2',
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                height: 1.1,
                                color: Color(0xFF2E1D12),
                              ),
                            ),
                            Text(
                              member.topics.take(2).map((t) => t.vi).join(', '),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 11.5,
                                height: 1.2,
                                color: Color(0xFF5A4334),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await pumpFor(tester, const Duration(milliseconds: 400));
    await capture(tester, 'g00_cast_gallery');
  });

  testWidgets('render H: tutor panel, offline build', (tester) async {
    final s = await start(tester);
    await tap(tester, 'map_label_main_quest', ms: 900);
    await tap(tester, 'sheet_open', ms: 1500);
    await tap(tester, 'lesson_card_mq1_04', ms: 1500);
    await tap(tester, 'lesson_tutor', ms: 1200);
    await capture(tester, 'h00_tutor_offline_open');
    await tester.enterText(
      find.byKey(const ValueKey('tutor_input')),
      'Vì sao code của mình không chạy?',
    );
    await pumpFor(tester, const Duration(milliseconds: 200));
    await tap(tester, 'tutor_send', ms: 1500);
    await capture(tester, 'h01_tutor_offline_answer');
    await tap(tester, 'tutor_hint_ladder', ms: 1200);
    await capture(tester, 'h02_tutor_hint_ladder');
    await finish(tester, s);
  });

  testWidgets(
    'render I: tutor panel with an AI answer (static preview provider)',
    (tester) async {
      final s = await start(tester, tutorAi: true);
      await tap(tester, 'map_label_main_quest', ms: 900);
      await tap(tester, 'sheet_open', ms: 1500);
      await tap(tester, 'lesson_card_mq1_04', ms: 1500);
      await tap(tester, 'lesson_tutor', ms: 1200);
      await tap(tester, 'tutor_quick_explain', ms: 1500);
      await capture(tester, 'i00_tutor_ai_answer');
      await tap(tester, 'tutor_quick_challenge', ms: 1500);
      await tap(tester, 'tutor_close', ms: 900);
      await capture(tester, 'i01_lesson_with_tutor_button');
      await finish(tester, s);
    },
  );

  // PQD-002 §B: bộ "before" đủ sáu ActivitySheet + Bug Hunter locked, MỘT harness,
  // MỘT seed, cả hai khung nhìn. Đây là ảnh nền để so khi (và chỉ khi) PQC-002 được
  // duyệt art — bản thân nó không phải bằng chứng "art đã đạt".
  testWidgets('render J: activity sheet before-set (six + locked)', (
    tester,
  ) async {
    const List<String> ids = <String>[
      'main_quest',
      'robot_maze',
      'dragon_jump',
      'catch_stars',
      'bug_hunter',
      'achievement_house',
    ];
    final AppServices seededProgress = await start(tester);
    // PQC-009 item 3: đây là chỗ DUY NHẤT mở lần lượt cả sáu sheet qua route thật của
    // app, nên số đo ImageCache công bố ở đây (render log không bị cắt giữa như test
    // log, trích được con số thật thay vì suy từ W*H*4). Chỉ in, không assert: job
    // render là kênh bằng chứng, không phải nơi đặt cửa chặn ai đó.
    final ImageCache sixSheetCache = PaintingBinding.instance.imageCache;
    final List<String> cacheTrace = <String>[];
    for (var i = 0; i < ids.length; i++) {
      await tap(tester, 'map_label_${ids[i]}', ms: 900);
      // Fake async không chạy I/O thật: phải cho ảnh của sheet kịp nạp qua pipeline
      // của chính widget tree rồi mới đọc số, nếu không chỉ đo được cache của nền đảo.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      cacheTrace.add(
        'j0$i=${sixSheetCache.currentSize}entries/${sixSheetCache.currentSizeBytes}B',
      );
      await capture(tester, 'j0${i}_sheet_${ids[i]}');
      await home(tester);
    }
    // ignore: avoid_print
    print(
      'PQC-009 imageCache khi mở lần lượt sáu sheet (cache của engine trên máy CI, '
      'KHÔNG phải RAM/GPU thiết bị): ${cacheTrace.join(' -> ')}',
    );
    await finish(tester, seededProgress);

    // Người chơi mới toanh: Bug Hunter còn khoá, CTA là "Đi tới bài học".
    final AppServices newPlayer = await start(tester, rich: false, intro: true);
    for (var i = 0; i < 3; i++) {
      await tap(tester, 'welcome_next', ms: 500);
    }
    await tap(tester, 'map_label_bug_hunter', ms: 900);
    await capture(tester, 'j06_sheet_bug_hunter_locked');
    await finish(tester, newPlayer);

    final AppServices smallPhone = await start(tester, small: true);
    await tap(tester, 'map_label_robot_maze', ms: 900);
    await capture(tester, 'j07_small_sheet_robot_maze');
    await home(tester);
    await finish(tester, smallPhone);

    final AppServices smallNew = await start(
      tester,
      small: true,
      rich: false,
      intro: true,
    );
    for (var i = 0; i < 3; i++) {
      await tap(tester, 'welcome_next', ms: 500);
    }
    await tap(tester, 'map_label_bug_hunter', ms: 900);
    await capture(tester, 'j08_small_sheet_bug_hunter_locked');
    await finish(tester, smallNew);
  });
}
