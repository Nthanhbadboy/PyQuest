import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/app/app_services.dart';
import 'package:pyquest/app/pyquest_app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_helpers.dart';

Future<void> loadAppFonts() async {
  const fonts = {
    'Baloo2': ['Baloo2-SemiBold.ttf', 'Baloo2-Bold.ttf', 'Baloo2-ExtraBold.ttf'],
    'Nunito': ['Nunito-Medium.ttf', 'Nunito-Bold.ttf', 'Nunito-ExtraBold.ttf', 'Nunito-Black.ttf'],
    'JetBrainsMono': ['JetBrainsMono-Medium.ttf', 'JetBrainsMono-Bold.ttf'],
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key);
    for (final f in entry.value) {
      loader.addFont(rootBundle.load('assets/fonts/$f'));
    }
    await loader.load();
  }
}

/// Pumps frames for [d] without waiting for (endless) idle animations to settle.
Future<void> pumpFor(WidgetTester tester, Duration d, {Duration step = const Duration(milliseconds: 50)}) async {
  var elapsed = Duration.zero;
  while (elapsed < d) {
    await tester.pump(step);
    elapsed += step;
  }
}

Future<void> tapAndSettle(WidgetTester tester, Finder f, {Duration wait = const Duration(milliseconds: 900)}) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await pumpFor(tester, wait);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUpAll(loadAppFonts);

  testWidgets('new player: map → Robot Maze level 1 solved → result → progress saved', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final clock = FakeClock(DateTime(2026, 10, 15, 10));
    final services = (await tester.runAsync(() => AppServices.create(
          bundle: rootBundle,
          databaseFactory: databaseFactoryFfiNoIsolate,
          databasePath: inMemoryDatabasePath,
          clock: clock,
          audioEnabled: false,
          startSessionTimer: false,
        )))!;

    await tester.pumpWidget(PyQuestApp(servicesFactory: (_) async => services, minSplash: Duration.zero));
    await pumpFor(tester, const Duration(seconds: 2));

    // First launch shows the welcome guide (3 pages).
    expect(find.text('Chào mừng tới Đảo Khởi Đầu!'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tapAndSettle(tester, find.byKey(const ValueKey('welcome_next')), wait: const Duration(milliseconds: 500));
    }
    expect(find.text('Chào mừng tới Đảo Khởi Đầu!'), findsNothing);

    // The map shows every place.
    for (final name in ['Tháp Python', 'Mê Cung Robo', 'Núi Lửa Pip', 'Đài Thiên Văn', 'Xưởng Bitsy', 'Nhà Thành Tích']) {
      expect(find.text(name), findsWidgets, reason: name);
    }

    // Bug Hunter is gated behind Main Quest lesson 3.
    await tapAndSettle(tester, find.byKey(const ValueKey('map_label_bug_hunter')));
    expect(find.byKey(const ValueKey('sheet_go_lesson')), findsOneWidget);
    await tester.tapAt(const Offset(20, 40));
    await pumpFor(tester, const Duration(milliseconds: 600));

    // Open Robot Maze.
    await tapAndSettle(tester, find.byKey(const ValueKey('map_label_robot_maze')));
    await tapAndSettle(tester, find.byKey(const ValueKey('sheet_open')), wait: const Duration(milliseconds: 1500));
    expect(find.text('Xưởng Mê Cung'), findsWidgets);

    // Level 1 costs 2 energy.
    await tapAndSettle(tester, find.byKey(const ValueKey('maze_level_1')), wait: const Duration(milliseconds: 1500));
    expect(services.energy.current, 18);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(const ValueKey('palette_right')));
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.tap(find.byKey(const ValueKey('maze_run')));
    await pumpFor(tester, const Duration(seconds: 5));

    // Result screen.
    expect(find.byKey(const ValueKey('result_title')), findsOneWidget);
    expect(find.text('Hoàn hảo!'), findsOneWidget);
    expect(find.text('Bước Chân Đầu Tiên'), findsWidgets);

    await tapAndSettle(tester, find.byKey(const ValueKey('result_map')), wait: const Duration(seconds: 2));
    expect(find.text('Mê Cung Robo'), findsWidgets);

    final record = (await tester.runAsync(() => services.progress.levelRecord('robot_maze', 'rm_01')))!;
    expect(record.stars, 3);
    expect(services.achievements.isUnlocked('first_steps'), isTrue);

    services.dispose();
    await pumpFor(tester, const Duration(seconds: 4));
  });

  testWidgets('Main Quest lesson 1 can be completed with real code', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final clock = FakeClock(DateTime(2026, 10, 15, 10));
    final services = (await tester.runAsync(() => AppServices.create(
          bundle: rootBundle,
          databaseFactory: databaseFactoryFfiNoIsolate,
          databasePath: inMemoryDatabasePath,
          clock: clock,
          audioEnabled: false,
          startSessionTimer: false,
        )))!;
    await tester.runAsync(() => services.settings.setIntroSeen());

    await tester.pumpWidget(PyQuestApp(servicesFactory: (_) async => services, minSplash: Duration.zero));
    await pumpFor(tester, const Duration(seconds: 2));

    await tapAndSettle(tester, find.byKey(const ValueKey('map_label_main_quest')));
    await tapAndSettle(tester, find.byKey(const ValueKey('sheet_open')), wait: const Duration(milliseconds: 1500));
    await tapAndSettle(tester, find.byKey(const ValueKey('lesson_card_mq1_01')), wait: const Duration(milliseconds: 1500));
    expect(services.energy.current, 19);

    // 1. story
    await tapAndSettle(tester, find.byKey(const ValueKey('lesson_continue')), wait: const Duration(milliseconds: 500));
    // 2. example: run it, then continue
    await tapAndSettle(tester, find.byKey(const ValueKey('example_run')), wait: const Duration(milliseconds: 500));
    expect(find.text('Xin chào!'), findsWidgets);
    await tapAndSettle(tester, find.byKey(const ValueKey('lesson_continue')), wait: const Duration(milliseconds: 500));
    // 3. choice: answer index 0 is print("Robo")
    await tapAndSettle(tester, find.byKey(const ValueKey('choice_0')), wait: const Duration(milliseconds: 200));
    await tapAndSettle(tester, find.byKey(const ValueKey('lesson_check')), wait: const Duration(milliseconds: 500));
    await tapAndSettle(tester, find.byKey(const ValueKey('lesson_continue')), wait: const Duration(milliseconds: 500));
    // 4. fill: pick the "PyQuest" chip
    await tapAndSettle(tester, find.text('"PyQuest"').first, wait: const Duration(milliseconds: 200));
    await tapAndSettle(tester, find.byKey(const ValueKey('lesson_check')), wait: const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('lesson_continue')), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const ValueKey('lesson_continue')), wait: const Duration(milliseconds: 500));
    // 5. write: a wrong answer first, then the right one
    await tester.enterText(find.byKey(const ValueKey('code_editor_field')), 'print("Robo")');
    await tapAndSettle(tester, find.byKey(const ValueKey('lesson_check')), wait: const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('lesson_continue')), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('code_editor_field')), 'print("Robo thông minh")');
    await tapAndSettle(tester, find.byKey(const ValueKey('lesson_check')), wait: const Duration(milliseconds: 500));
    await tapAndSettle(tester, find.byKey(const ValueKey('lesson_continue')), wait: const Duration(seconds: 2));

    expect(find.byKey(const ValueKey('lesson_complete_title')), findsOneWidget);
    expect(find.text('Dòng Code Đầu Tiên'), findsWidgets);
    final done = (await tester.runAsync(() => services.progress.completedLessons()))!;
    expect(done, contains('mq1_01'));

    services.dispose();
    await pumpFor(tester, const Duration(seconds: 4));
  });
}
