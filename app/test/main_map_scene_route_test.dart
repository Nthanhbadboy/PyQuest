import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/app/activity_registry.dart';
import 'package:pyquest/app/app_scope.dart';
import 'package:pyquest/app/app_services.dart';
import 'package:pyquest/core/events.dart';
import 'package:pyquest/l10n/generated/app_localizations.dart';
import 'package:pyquest/modules/main_map/activity_sheet.dart';
import 'package:pyquest/modules/main_map/main_map_screen.dart';
import 'package:pyquest/modules/main_quest/main_quest_module.dart';
import 'package:pyquest/modules/robot_maze/robot_maze_module.dart';
import 'package:pyquest/shared/widgets/chunky_button.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_helpers.dart';

Future<AppServices> _services() => AppServices.create(
  bundle: rootBundle,
  databaseFactory: databaseFactoryFfiNoIsolate,
  databasePath: inMemoryDatabasePath,
  clock: FakeClock(DateTime(2026, 10, 18, 12)),
  audioEnabled: false,
  startSessionTimer: false,
);

Widget _host(AppServices services) => AppScope(
  services: services,
  child: MaterialApp(
    locale: const Locale('vi'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: const MainMapScreen(),
  ),
);

Future<void> _pumpStatus(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pump();
}

Future<void> _tapPlace(WidgetTester tester, String id) async {
  final Finder place = find.byKey(ValueKey<String>('map_label_$id'));
  expect(place, findsOneWidget);
  await tester.ensureVisible(place);
  await tester.pump();
  await tester.tap(place);
  await pumpFor(tester, const Duration(milliseconds: 800));
}

Future<void> _leaveActivity(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).last).pop();
  await pumpFor(tester, const Duration(milliseconds: 1200));
  await _pumpStatus(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUpAll(() async {
    await loadAppFonts();
  });

  testWidgets(
    'real map sheets route to MainQuest and Maze and restore map scroll',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final AppServices services = (await tester.runAsync(_services))!;
      await tester.runAsync(() => services.settings.setIntroSeen());
      addTearDown(services.dispose);
      final List<StandardEvent> events = <StandardEvent>[];
      final StreamSubscription<StandardEvent> subscription = services
          .events
          .stream
          .listen(events.add);
      addTearDown(subscription.cancel);

      await tester.pumpWidget(_host(services));
      await _pumpStatus(tester);
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/images/village_r53.webp'),
          tester.element(find.byType(MainMapScreen)),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('main_map_village_scene')),
        findsOneWidget,
      );
      expect(find.byType(ActivitySheet), findsNothing);

      final Finder villageScroll = find.byKey(
        const PageStorageKey<String>('main_map_village_scroll'),
      );
      await tester.drag(villageScroll, const Offset(0, -120));
      await tester.pump(const Duration(milliseconds: 300));
      final ScrollController mapController = tester
          .widget<SingleChildScrollView>(villageScroll)
          .controller!;
      final double beforeRouteOffset = mapController.offset;
      final Finder mainQuestButton = find.descendant(
        of: find.byKey(const ValueKey<String>('map_label_main_quest')),
        matching: find.byType(TextButton),
      );
      final FocusNode mainQuestFocus = tester
          .widget<TextButton>(mainQuestButton)
          .focusNode!;
      expect(beforeRouteOffset, greaterThan(0));

      await _tapPlace(tester, 'main_quest');
      expect(
        mapController.offset,
        closeTo(beforeRouteOffset, 0.5),
        reason: 'activating an already-visible place preserves map scroll',
      );
      expect(find.byType(ActivitySheet), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('sheet_open')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('sheet_open')));
      await pumpFor(tester, const Duration(milliseconds: 1400));
      expect(find.byType(MainQuestHomeScreen), findsOneWidget);
      await _leaveActivity(tester);
      expect(mapController.offset, closeTo(beforeRouteOffset, 0.5));
      expect(
        FocusManager.instance.primaryFocus,
        mainQuestFocus,
        reason: 'focus returns to the place that opened the route',
      );
      expect(
        events
            .where(
              (StandardEvent event) => event.type == EventTypes.activityOpened,
            )
            .map((event) => event.get<String>('activity_id')),
        <String>['main_quest'],
      );
      expect(tester.takeException(), isNull);

      await _tapPlace(tester, 'robot_maze');
      expect(find.byType(ActivitySheet), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('sheet_open')));
      await pumpFor(tester, const Duration(milliseconds: 1400));
      expect(find.byType(RobotMazeHomeScreen), findsOneWidget);
      await _leaveActivity(tester);
      expect(mapController.offset, closeTo(beforeRouteOffset, 0.5));
      expect(
        events
            .where(
              (StandardEvent event) => event.type == EventTypes.activityOpened,
            )
            .map((event) => event.get<String>('activity_id')),
        <String>['main_quest', 'robot_maze'],
      );

      for (final String id in <String>[
        'dragon_jump',
        'catch_stars',
        'achievement_house',
      ]) {
        await _tapPlace(tester, id);
        expect(find.byType(ActivitySheet), findsOneWidget);
        expect(
          find.text(
            activityRegistry
                .firstWhere((module) => module.def.id == id)
                .def
                .name,
          ),
          findsOneWidget,
        );
        final Finder cancel = find.widgetWithText(ChunkyButton, 'Để sau');
        await tester.ensureVisible(cancel);
        await tester.tap(cancel);
        await pumpFor(tester, const Duration(milliseconds: 700));
        expect(find.byType(ActivitySheet), findsNothing);
      }
      expect(
        events
            .where(
              (StandardEvent event) => event.type == EventTypes.activityOpened,
            )
            .map((event) => event.get<String>('activity_id')),
        <String>['main_quest', 'robot_maze'],
        reason:
            'opening and cancelling other real sheets must not record a visit',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'registry Tab order and Enter/Space/Back activate the real map buttons',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final AppServices services = (await tester.runAsync(_services))!;
      await tester.runAsync(() => services.settings.setIntroSeen());
      addTearDown(services.dispose);

      await tester.pumpWidget(_host(services));
      await _pumpStatus(tester);

      FocusNode markerFocus(String id) {
        final Finder button = find.descendant(
          of: find.byKey(ValueKey<String>('map_label_$id')),
          matching: find.byType(TextButton),
        );
        return tester.widget<TextButton>(button).focusNode!;
      }

      final FocusNode python = markerFocus('main_quest');
      final FocusNode maze = markerFocus('robot_maze');
      python.requestFocus();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, python);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus,
        maze,
        reason: 'Tab follows activityRegistry order, not map coordinates',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await pumpFor(tester, const Duration(milliseconds: 700));
      expect(
        find.byType(ActivitySheet),
        findsOneWidget,
        reason: 'Enter activates the focused place',
      );
      await tester.binding.handlePopRoute();
      await pumpFor(tester, const Duration(milliseconds: 700));
      expect(
        find.byType(ActivitySheet),
        findsNothing,
        reason: 'Back closes the existing activity sheet',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await pumpFor(tester, const Duration(milliseconds: 700));
      expect(
        find.byType(ActivitySheet),
        findsOneWidget,
        reason: 'Space activates the focused place',
      );
      await tester.binding.handlePopRoute();
      await pumpFor(tester, const Duration(milliseconds: 700));
      expect(find.byType(ActivitySheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'locked Bitsy keeps its real prerequisite route and cancel emits no visit',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.reset);
      final AppServices services = (await tester.runAsync(_services))!;
      await tester.runAsync(() => services.settings.setIntroSeen());
      addTearDown(services.dispose);
      final List<StandardEvent> events = <StandardEvent>[];
      final StreamSubscription<StandardEvent> subscription = services
          .events
          .stream
          .listen(events.add);
      addTearDown(subscription.cancel);

      await tester.pumpWidget(_host(services));
      await _pumpStatus(tester);

      await _tapPlace(tester, 'bug_hunter');
      expect(find.byType(ActivitySheet), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('sheet_go_lesson')),
        findsOneWidget,
      );
      final Finder villageScroll = find.byKey(
        const PageStorageKey<String>('main_map_village_scroll'),
      );
      final double beforePrerequisiteOffset = tester
          .widget<SingleChildScrollView>(villageScroll)
          .controller!
          .offset;
      final Finder bugHunterButton = find.descendant(
        of: find.byKey(const ValueKey<String>('map_label_bug_hunter')),
        matching: find.byType(TextButton),
      );
      final FocusNode bugHunterFocus = tester
          .widget<TextButton>(bugHunterButton)
          .focusNode!;
      final String unlockLessonId =
          (await activityRegistry
                  .firstWhere((module) => module.def.id == 'bug_hunter')
                  .status(services))
              .unlockLessonId!;
      final Finder lessonAction = find.byKey(
        const ValueKey<String>('sheet_go_lesson'),
      );
      await tester.ensureVisible(lessonAction);
      await tester.tap(lessonAction);
      await pumpFor(tester, const Duration(milliseconds: 1200));
      expect(find.byType(MainQuestHomeScreen), findsOneWidget);
      expect(
        find.byKey(ValueKey<String>('lesson_card_$unlockLessonId')),
        findsOneWidget,
      );
      expect(
        events
            .where(
              (StandardEvent event) => event.type == EventTypes.activityOpened,
            )
            .map((event) => event.get<String>('activity_id')),
        <String>['main_quest'],
      );
      await _leaveActivity(tester);
      expect(
        tester.widget<SingleChildScrollView>(villageScroll).controller!.offset,
        closeTo(beforePrerequisiteOffset, 0.5),
        reason:
            'return from the real unlockLessonId route preserves the village scroll',
      );
      expect(
        FocusManager.instance.primaryFocus,
        bugHunterFocus,
        reason:
            'focus returns to the locked place after its prerequisite route',
      );

      await _tapPlace(tester, 'robot_maze');
      expect(find.byType(ActivitySheet), findsOneWidget);
      final Finder cancel = find.widgetWithText(ChunkyButton, 'Để sau');
      await tester.ensureVisible(cancel);
      await tester.tap(cancel);
      await pumpFor(tester, const Duration(milliseconds: 700));
      expect(find.byType(ActivitySheet), findsNothing);
      expect(
        events.where(
          (StandardEvent event) => event.type == EventTypes.activityOpened,
        ),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
