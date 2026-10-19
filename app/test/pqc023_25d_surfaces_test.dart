import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/app/app_scope.dart';
import 'package:pyquest/app/app_services.dart';
import 'package:pyquest/modules/achievements/achievement_house_module.dart';
import 'package:pyquest/modules/bug_hunter/bug_hunter_module.dart';
import 'package:pyquest/modules/daily_quests/daily_quests_sheet.dart';
import 'package:pyquest/modules/energy/energy_widgets.dart';
import 'package:pyquest/modules/main_quest/adventure_recap_screen.dart';
import 'package:pyquest/modules/main_quest/lesson_complete_screen.dart';
import 'package:pyquest/modules/main_quest/playground_screen.dart';
import 'package:pyquest/modules/robot_maze/robot_maze_module.dart';
import 'package:pyquest/shared/characters/characters.dart';
import 'package:pyquest/shared/theme/app_theme.dart';
import 'package:pyquest/shared/widgets/result_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_helpers.dart';

Future<AppServices> _makeServices(WidgetTester tester) async {
  final AppServices s = (await tester.runAsync(
    () => AppServices.create(
      bundle: rootBundle,
      databaseFactory: databaseFactoryFfiNoIsolate,
      databasePath: inMemoryDatabasePath,
      clock: FakeClock(DateTime(2026, 10, 19, 10)),
      audioEnabled: false,
      startSessionTimer: false,
    ),
  ))!;
  addTearDown(s.dispose);
  return s;
}

Widget _host(AppServices services, Widget child, {double scale = 1.0}) {
  return AppScope(
    services: services,
    child: MaterialApp(
      theme: buildPyQuestTheme(),
      builder: (BuildContext context, Widget? navigator) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: navigator!,
      ),
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUpAll(() async {
    await loadAppFonts();
  });

  testWidgets('Robot Maze r45/r46/r50 2.5D home and workshop work at 2x', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(720, 1280);
    addTearDown(tester.view.reset);

    final AppServices s = await _makeServices(tester);
    await tester.pumpWidget(_host(s, const RobotMazeHomeScreen(), scale: 2.0));
    await pumpFor(tester, const Duration(milliseconds: 500));

    expect(
      find.byKey(const ValueKey<String>('maze_25d_scene')),
      findsOneWidget,
    );
    final Finder openWorkshop = find.byKey(
      const ValueKey<String>('open_workshop'),
    );
    await tester.scrollUntilVisible(
      openWorkshop,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('maze_workshop_25d_banner')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tapAndSettle(tester, openWorkshop);
    expect(
      find.byKey(const ValueKey<String>('workshop_25d_badge')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpFor(tester, const Duration(milliseconds: 1100));
  });

  testWidgets('Achievement House r39 2.5D scene and rooms work at 2x', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(720, 1280);
    addTearDown(tester.view.reset);

    final AppServices s = await _makeServices(tester);
    await tester.pumpWidget(
      _host(s, const AchievementHouseScreen(), scale: 2.0),
    );
    await pumpFor(tester, const Duration(milliseconds: 500));

    expect(
      find.byKey(const ValueKey<String>('achievement_25d_scene')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    final Finder room1 = find.byKey(const ValueKey<String>('room_1'));
    await tester.ensureVisible(room1);
    await tester.pump();
    await tester.tap(room1);
    await pumpFor(tester, const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpFor(tester, const Duration(milliseconds: 1100));
  });

  testWidgets('Bug Hunter r36 2.5D home works at 2x', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(720, 1280);
    addTearDown(tester.view.reset);

    final AppServices s = await _makeServices(tester);
    await tester.pumpWidget(_host(s, const BugHunterHomeScreen(), scale: 2.0));
    await pumpFor(tester, const Duration(milliseconds: 500));

    expect(
      find.byKey(const ValueKey<String>('bug_hunter_25d_scene')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpFor(tester, const Duration(milliseconds: 1100));
  });

  testWidgets('PQC-024 Daily Quests, Energy, and Result 2.5D work at 2x', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(720, 1280);
    addTearDown(tester.view.reset);

    final AppServices s = await _makeServices(tester);
    await tester.pumpWidget(
      _host(
        s,
        const LevelResultScreen(
          data: LevelResultData(
            gameName: 'Mê Cung Robo',
            levelTitle: 'Màn 1',
            success: true,
            stars: 3,
            host: CharacterId.robo,
            hostLine: 'Tuyệt vời!',
          ),
        ),
        scale: 2.0,
      ),
    );
    await pumpFor(tester, const Duration(milliseconds: 500));

    expect(
      find.byKey(const ValueKey<String>('result_25d_scene')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    final BuildContext ctx = tester.element(find.byType(LevelResultScreen));
    showEnergySheet(ctx);
    await pumpFor(tester, const Duration(milliseconds: 600));
    expect(
      find.byKey(const ValueKey<String>('energy_25d_scene')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    Navigator.of(ctx).pop();
    await pumpFor(tester, const Duration(milliseconds: 500));

    await tester.runAsync(() => s.quests.ensureToday());
    showDailyQuests(ctx);
    await pumpFor(tester, const Duration(milliseconds: 600));
    expect(
      find.byKey(const ValueKey<String>('daily_quests_25d_scene')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpFor(tester, const Duration(milliseconds: 2200));
  });

  testWidgets('PQC-025 Adventure Recap, Playground, Lesson Complete 2.5D 2x', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(720, 1280);
    addTearDown(tester.view.reset);

    final AppServices s = await _makeServices(tester);
    await tester.pumpWidget(
      _host(s, const AdventureRecapScreen(), scale: 2.0),
    );
    await pumpFor(tester, const Duration(milliseconds: 500));
    expect(
      find.byKey(const ValueKey<String>('recap_25d_scene')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(_host(s, const PlaygroundScreen(), scale: 2.0));
    await pumpFor(tester, const Duration(milliseconds: 500));
    expect(
      find.byKey(const ValueKey<String>('playground_25d_scene')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      _host(
        s,
        LessonCompleteScreen(
          lesson: s.mainQuest.lessons.first,
          firstTime: true,
          exercises: 2,
          mistakes: 0,
          duration: const Duration(seconds: 42),
          notices: const [],
          chapterCompleted: false,
        ),
        scale: 2.0,
      ),
    );
    await pumpFor(tester, const Duration(milliseconds: 500));
    expect(
      find.byKey(const ValueKey<String>('lesson_complete_25d_scene')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpFor(tester, const Duration(milliseconds: 1500));
  });
}
