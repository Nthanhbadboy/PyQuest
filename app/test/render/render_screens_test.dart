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
import 'package:pyquest/shared/characters/cast.dart';
import 'package:pyquest/shared/characters/characters.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../test_helpers.dart';

final GlobalKey _captureKey = GlobalKey();

Future<void> loadMaterialIcons() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final file = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (!file.existsSync()) return;
  final loader = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  await loader.load();
}

Future<void> capture(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 50));
  await tester.runAsync(() async {
    final boundary = _captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/previews/$name.png');
    await file.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

/// A fixed answer used only inside previews, so the AI-labelled state of the
/// tutor panel can be screenshotted without a provider or a credential.
const String _previewAnswer = 'Bạn đang dùng biến đúng cách rồi!\n'
    'Thử đổi giá trị này xem máy in ra gì nhé:\n'
    '```python\ndiem = 7\nprint(diem)\n```\n'
    'Đoán trước kết quả rồi chạy thử để kiểm chứng.';

Future<AppServices> seeded(WidgetTester tester, {bool rich = false, bool tutorAi = false}) async {
  final clock = FakeClock(DateTime(2026, 10, 15, 16));
  final s = (await tester.runAsync(() => AppServices.create(
        bundle: rootBundle,
        databaseFactory: databaseFactoryFfiNoIsolate,
        databasePath: inMemoryDatabasePath,
        clock: clock,
        audioEnabled: false,
        startSessionTimer: false,
        tutorConfig: tutorAi ? const TutorConfig(endpoint: 'https://preview.invalid') : null,
        tutorProvider: tutorAi ? const StaticTutorProvider(_previewAnswer) : null,
      )))!;
  await tester.runAsync(() async {
    await s.settings.setIntroSeen();
    if (rich) {
      for (final (id, stars, next) in [('rm_01', 3, 'rm_02'), ('rm_02', 2, 'rm_03'), ('rm_03', 3, 'rm_04')]) {
        await s.events.emit(StandardEvent(
          type: EventTypes.levelCompleted,
          sourceId: 'robot_maze',
          data: {'level_id': id, 'stars': stars, 'score': 100, 'next_level_id': next},
        ));
      }
      for (final l in ['mq1_01', 'mq1_02', 'mq1_03']) {
        await s.events.emit(StandardEvent(
          type: EventTypes.lessonCompleted,
          sourceId: 'main_quest',
          data: {'lesson_id': l, 'chapter_id': 'code_apprentice', 'skills': <String>[], 'score': 100},
        ));
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
    for (final a in [
      'assets/images/island_map.webp',
      'assets/images/thumb_maze.webp',
      'assets/images/thumb_tower.webp',
      'assets/images/thumb_volcano.webp',
      'assets/images/thumb_observatory.webp',
      'assets/images/thumb_workshop.webp',
      'assets/images/thumb_house.webp',
    ]) {
      await precacheImage(AssetImage(a), ctx);
    }
  });
}

Future<void> tap(WidgetTester tester, String key, {int ms = 1200}) async {
  final f = find.byKey(ValueKey(key));
  await tester.ensureVisible(f.first);
  await tester.pump();
  await tester.tap(f.first, warnIfMissed: false);
  await pumpFor(tester, Duration(milliseconds: ms));
}

Future<void> home(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).last).popUntil((r) => r.isFirst);
  await pumpFor(tester, const Duration(seconds: 2));
}

Future<AppServices> start(WidgetTester tester, {bool rich = true, bool intro = false, bool small = false, bool tutorAi = false}) async {
  // Default: 390 x 844 @3x. Small: 360 x 640 @2x (older/compact Android phones).
  tester.view.physicalSize = small ? const Size(720, 1280) : const Size(1170, 2532);
  tester.view.devicePixelRatio = small ? 2.0 : 3.0;
  addTearDown(tester.view.reset);
  final s = await seeded(tester, rich: rich, tutorAi: tutorAi);
  if (intro) await tester.runAsync(() => s.settings.setRaw('intro_seen', '0'));
  await tester.pumpWidget(RepaintBoundary(key: _captureKey, child: PyQuestApp(servicesFactory: (_) async => s, minSplash: Duration.zero)));
  await pumpFor(tester, const Duration(seconds: 2));
  await precacheMap(tester);
  await pumpFor(tester, const Duration(milliseconds: 400));
  return s;
}

Future<void> finish(WidgetTester tester, AppServices s) async {
  s.dispose();
  await pumpFor(tester, const Duration(seconds: 4));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUpAll(() async {
    await loadAppFonts();
    await loadMaterialIcons();
  });

  testWidgets('render A: first launch', (tester) async {
    final s = await start(tester, rich: false, intro: true);
    await capture(tester, 'a00_welcome');
    for (var i = 0; i < 3; i++) {
      await tap(tester, 'welcome_next', ms: 500);
    }
    await capture(tester, 'a01_map_new_player');
    await tap(tester, 'map_label_bug_hunter', ms: 900);
    await capture(tester, 'a02_sheet_locked');
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
    for (final k in ['palette_down', 'palette_down', 'palette_down', 'palette_right']) {
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
    await tester.enterText(find.byKey(const ValueKey('code_editor_field')), 'for i in range(5):\n    right()\nfor i in range(5):\n    down()\n');
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
    await tester.enterText(find.byKey(const ValueKey('code_editor_field')), 'print("Robo thông minh"');
    await tap(tester, 'lesson_check', ms: 600);
    await capture(tester, 'c05_lesson_code_error');
    await tester.enterText(find.byKey(const ValueKey('code_editor_field')), 'print("Robo thông minh")');
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
    for (var i = 0; i < 60 && find.byKey(const ValueKey('result_title')).evaluate().isEmpty; i++) {
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
    final s = await start(tester, small: true);
    await capture(tester, 'f00_small_map');
    await tap(tester, 'map_label_robot_maze', ms: 900);
    await tap(tester, 'sheet_open', ms: 1500);
    await tap(tester, 'maze_level_4', ms: 1500);
    for (final k in ['palette_down', 'palette_down', 'palette_down', 'palette_down', 'palette_right', 'palette_right']) {
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
    await tester.pumpWidget(RepaintBoundary(
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
                          CharacterView(id: member.id, size: 104, animate: false),
                          Text(member.name,
                              style: const TextStyle(
                                  fontFamily: 'Baloo2',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  height: 1.1,
                                  color: Color(0xFF2E1D12))),
                          Text(
                            member.topics.take(2).map((t) => t.vi).join(', '),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 11.5,
                                height: 1.2,
                                color: Color(0xFF5A4334)),
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
    ));
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
    await tester.enterText(find.byKey(const ValueKey('tutor_input')), 'Vì sao code của mình không chạy?');
    await pumpFor(tester, const Duration(milliseconds: 200));
    await tap(tester, 'tutor_send', ms: 1500);
    await capture(tester, 'h01_tutor_offline_answer');
    await tap(tester, 'tutor_hint_ladder', ms: 1200);
    await capture(tester, 'h02_tutor_hint_ladder');
    await finish(tester, s);
  });

  testWidgets('render I: tutor panel with an AI answer (static preview provider)', (tester) async {
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
  });
}
