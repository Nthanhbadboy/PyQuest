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

Future<AppServices> seeded(WidgetTester tester, {bool rich = false}) async {
  final clock = FakeClock(DateTime(2026, 10, 15, 16));
  final s = (await tester.runAsync(() => AppServices.create(
        bundle: rootBundle,
        databaseFactory: databaseFactoryFfiNoIsolate,
        databasePath: inMemoryDatabasePath,
        clock: clock,
        audioEnabled: false,
        startSessionTimer: false,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUpAll(() async {
    await loadAppFonts();
    await loadMaterialIcons();
  });

  Future<void> setPhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532); // 390 x 844 @3x
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('render: map, sheets, robot maze', (tester) async {
    await setPhone(tester);
    final s = await seeded(tester, rich: true);
    await tester.pumpWidget(RepaintBoundary(key: _captureKey, child: PyQuestApp(servicesFactory: (_) async => s, minSplash: Duration.zero)));
    await pumpFor(tester, const Duration(seconds: 2));
    await precacheMap(tester);
    await pumpFor(tester, const Duration(milliseconds: 500));
    await capture(tester, 'a01_map');
    await tap(tester, 'map_label_robot_maze', ms: 900);
    await capture(tester, 'a02_sheet_maze');
    await tap(tester, 'sheet_open', ms: 1500);
    await capture(tester, 'a03_maze_home');
    await tap(tester, 'maze_level_4', ms: 1500);
    for (final k in ['palette_down', 'palette_down', 'palette_down', 'palette_right']) {
      await tap(tester, k, ms: 150);
    }
    await capture(tester, 'a04_maze_play');
    await tap(tester, 'maze_run', ms: 1200);
    await capture(tester, 'a05_maze_running');
    await pumpFor(tester, const Duration(seconds: 3));
    await capture(tester, 'a06_maze_fail');
    s.dispose();
    await pumpFor(tester, const Duration(seconds: 4));
  });

  testWidgets('render: python tower and lesson', (tester) async {
    await setPhone(tester);
    final s = await seeded(tester, rich: true);
    await tester.pumpWidget(RepaintBoundary(key: _captureKey, child: PyQuestApp(servicesFactory: (_) async => s, minSplash: Duration.zero)));
    await pumpFor(tester, const Duration(seconds: 2));
    await tap(tester, 'map_label_main_quest', ms: 900);
    await tap(tester, 'sheet_open', ms: 1500);
    await capture(tester, 'b01_tower');
    await tap(tester, 'lesson_card_mq1_04', ms: 1500);
    await tap(tester, 'lesson_continue', ms: 500);
    await tap(tester, 'example_run', ms: 500);
    await capture(tester, 'b02_lesson_example');
    await tap(tester, 'lesson_continue', ms: 500);
    await tap(tester, 'choice_1', ms: 300);
    await tap(tester, 'lesson_check', ms: 500);
    await capture(tester, 'b03_lesson_choice_wrong');
    s.dispose();
    await pumpFor(tester, const Duration(seconds: 4));
  });

  testWidgets('render: games and house', (tester) async {
    await setPhone(tester);
    final s = await seeded(tester, rich: true);
    await tester.pumpWidget(RepaintBoundary(key: _captureKey, child: PyQuestApp(servicesFactory: (_) async => s, minSplash: Duration.zero)));
    await pumpFor(tester, const Duration(seconds: 2));
    await tap(tester, 'map_label_dragon_jump', ms: 900);
    await tap(tester, 'sheet_open', ms: 1500);
    await capture(tester, 'c01_dragon_home');
    await tap(tester, 'dragon_play', ms: 1200);
    await tester.tap(find.byKey(const ValueKey('dragon_tap_area')));
    await pumpFor(tester, const Duration(milliseconds: 1800));
    await tester.tap(find.byKey(const ValueKey('dragon_tap_area')));
    await pumpFor(tester, const Duration(milliseconds: 300));
    await capture(tester, 'c02_dragon_play');
    tester.state<NavigatorState>(find.byType(Navigator).last).popUntil((r) => r.isFirst);
    await pumpFor(tester, const Duration(seconds: 2));
    await tap(tester, 'map_label_catch_stars', ms: 900);
    await tap(tester, 'sheet_open', ms: 1500);
    await capture(tester, 'c03_stars_home');
    await tap(tester, 'stars_play', ms: 1200);
    await tester.tapAt(const Offset(200, 600));
    await pumpFor(tester, const Duration(seconds: 3));
    await capture(tester, 'c04_stars_play');
    tester.state<NavigatorState>(find.byType(Navigator).last).popUntil((r) => r.isFirst);
    await pumpFor(tester, const Duration(seconds: 2));
    await tap(tester, 'map_label_achievement_house', ms: 900);
    await tap(tester, 'sheet_open', ms: 1500);
    await capture(tester, 'c05_house');
    tester.state<NavigatorState>(find.byType(Navigator).last).popUntil((r) => r.isFirst);
    await pumpFor(tester, const Duration(seconds: 2));
    await tap(tester, 'map_label_bug_hunter', ms: 900);
    await tap(tester, 'sheet_open', ms: 1500);
    await capture(tester, 'c06_bug_home');
    s.dispose();
    await pumpFor(tester, const Duration(seconds: 4));
  });
}
