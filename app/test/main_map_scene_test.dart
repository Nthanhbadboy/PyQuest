import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/app/activity.dart';
import 'package:pyquest/app/activity_registry.dart';
import 'package:pyquest/app/app_scope.dart';
import 'package:pyquest/app/app_services.dart';
import 'package:pyquest/core/clock.dart';
import 'package:pyquest/l10n/generated/app_localizations.dart';
import 'package:pyquest/modules/main_map/main_map_scene_state.dart';
import 'package:pyquest/modules/main_map/main_map_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_helpers.dart';

Future<AppServices> createServices() async => AppServices.create(
  bundle: rootBundle,
  databaseFactory: databaseFactoryFfiNoIsolate,
  databasePath: inMemoryDatabasePath,
  clock: FakeClock(DateTime(2026, 10, 18, 12)),
  audioEnabled: false,
  startSessionTimer: false,
);

Widget mainMapHost(
  AppServices services, {
  required Locale locale,
  required double textScale,
}) {
  return AppScope(
    services: services,
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(
        builder: (BuildContext context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: const MainMapScreen(),
        ),
      ),
    ),
  );
}

const ActivityStatus readyStatus = ActivityStatus(progressLabel: 'ready');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUpAll(() async {
    await loadAppFonts();
  });

  testWidgets(
    'six activities stay visible and localized across the 12 viewport/locale/scale cases',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final AppServices services = (await tester.runAsync(createServices))!;
      await tester.runAsync(() => services.settings.setIntroSeen());
      addTearDown(services.dispose);

      for (final Size viewport in <Size>[
        const Size(360, 640),
        const Size(390, 844),
      ]) {
        tester.view.physicalSize = viewport;
        for (final Locale locale in <Locale>[
          const Locale('vi'),
          const Locale('en'),
        ]) {
          for (final double scale in <double>[1, 1.3, 2]) {
            await tester.pumpWidget(
              mainMapHost(services, locale: locale, textScale: scale),
            );
            await pumpFor(tester, const Duration(milliseconds: 250));

            final bool directory = scale >= 1.5;
            expect(
              find.byKey(
                ValueKey<String>(
                  directory ? 'main_map_mode_places' : 'main_map_mode_village',
                ),
              ),
              findsOneWidget,
              reason:
                  'default mode at $viewport, ${locale.languageCode}, $scale×',
            );
            expect(
              find.byKey(const ValueKey<String>('energy_pill')),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey<String>('daily_quests_button')),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey<String>('settings_button')),
              findsOneWidget,
            );

            final List<String> expectedNames = locale.languageCode == 'vi'
                ? <String>[
                    'Tháp Python',
                    'Mê Cung Robo',
                    'Núi Lửa',
                    'Đài Thiên Văn',
                    'Xưởng Bitsy',
                    'Nhà Thành Tích',
                  ]
                : <String>[
                    'Python Tower',
                    'Robo Maze',
                    'Volcano',
                    'Observatory',
                    "Bitsy's Workshop",
                    'Achievement House',
                  ];
            for (final String name in expectedNames) {
              expect(
                find.text(name),
                findsWidgets,
                reason: 'all six places remain named at $viewport, $scale×',
              );
            }
            for (final ActivityModule module in activityRegistry) {
              expect(
                find.byKey(
                  ValueKey<String>(
                    directory
                        ? 'directory_place_${module.def.id}'
                        : 'map_label_${module.def.id}',
                  ),
                ),
                findsOneWidget,
              );
            }
            expect(
              tester.takeException(),
              isNull,
              reason:
                  'no overflow at $viewport, ${locale.languageCode}, $scale×',
            );
          }
        }
      }
    },
  );

  testWidgets(
    'all six village markers expose named, actionable button semantics',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final SemanticsHandle semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);
      final AppServices services = (await tester.runAsync(createServices))!;
      await tester.runAsync(() => services.settings.setIntroSeen());
      addTearDown(services.dispose);

      await tester.pumpWidget(
        mainMapHost(services, locale: const Locale('vi'), textScale: 1),
      );
      await pumpFor(tester, const Duration(milliseconds: 300));
      const Map<String, String> names = <String, String>{
        'main_quest': 'Tháp Python',
        'robot_maze': 'Mê Cung Robo',
        'dragon_jump': 'Núi Lửa',
        'catch_stars': 'Đài Thiên Văn',
        'bug_hunter': 'Xưởng Bitsy',
        'achievement_house': 'Nhà Thành Tích',
      };
      for (final MapEntry<String, String> entry in names.entries) {
        final Finder marker = find.byKey(
          ValueKey<String>('map_label_${entry.key}'),
        );
        await tester.ensureVisible(marker);
        await tester.pump();
        final SemanticsNode node = tester.getSemantics(marker);
        expect(
          node.hasAction(SemanticsAction.tap),
          isTrue,
          reason: '${entry.key} has a real accessible action',
        );
        expect(
          node.label,
          contains(entry.value),
          reason: '${entry.key} has a localized accessible name',
        );
      }
      await tester.tap(
        find.byKey(const ValueKey<String>('main_map_mode_places')),
      );
      await tester.pump();
      for (final MapEntry<String, String> entry in names.entries) {
        final Finder place = find.byKey(
          ValueKey<String>('directory_place_${entry.key}'),
        );
        await tester.ensureVisible(place);
        await tester.pump();
        final SemanticsNode node = tester.getSemantics(place);
        expect(
          node.hasAction(SemanticsAction.tap),
          isTrue,
          reason: '${entry.key} directory entry is actionable',
        );
        expect(
          node.label,
          contains(entry.value),
          reason: '${entry.key} directory name remains localized',
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'village and directory keep independent scroll positions and user-selected mode',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.reset);
      final AppServices services = (await tester.runAsync(createServices))!;
      await tester.runAsync(() => services.settings.setIntroSeen());
      addTearDown(services.dispose);

      await tester.pumpWidget(
        mainMapHost(services, locale: const Locale('vi'), textScale: 1),
      );
      await pumpFor(tester, const Duration(milliseconds: 250));
      final Finder village = find.byKey(
        const PageStorageKey<String>('main_map_village_scroll'),
      );
      await tester.drag(village, const Offset(0, -150));
      await tester.pump(const Duration(milliseconds: 250));
      final ScrollController villageController = tester
          .widget<SingleChildScrollView>(village)
          .controller!;
      final double villageOffset = villageController.offset;
      expect(villageOffset, greaterThan(0));

      await tester.tap(
        find.byKey(const ValueKey<String>('main_map_mode_places')),
      );
      await tester.pump();
      final Finder directory = find.byKey(
        const PageStorageKey<String>('main_map_directory_scroll'),
      );
      expect(directory, findsOneWidget);
      await tester.drag(directory, const Offset(0, -170));
      await tester.pump(const Duration(milliseconds: 250));
      final ScrollController directoryController = tester
          .widget<SingleChildScrollView>(directory)
          .controller!;
      final double directoryOffset = directoryController.offset;
      expect(directoryOffset, greaterThan(0));

      await tester.tap(
        find.byKey(const ValueKey<String>('main_map_mode_village')),
      );
      await tester.pump();
      expect(villageController.offset, closeTo(villageOffset, 0.5));
      await tester.tap(
        find.byKey(const ValueKey<String>('main_map_mode_places')),
      );
      await tester.pump();
      expect(directoryController.offset, closeTo(directoryOffset, 0.5));

      // A deliberate user choice wins over the automatic large-text fallback.
      await tester.pumpWidget(
        mainMapHost(services, locale: const Locale('en'), textScale: 2),
      );
      await tester.pump();
      expect(
        find.byKey(const PageStorageKey<String>('main_map_directory_scroll')),
        findsOneWidget,
      );
      expect(find.text('Places'), findsOneWidget);
      expect(directoryController.offset, closeTo(directoryOffset, 0.5));
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'status failures stay local and retry only reloads the requested module',
    () async {
      int failingAttempts = 0;
      int healthyAttempts = 0;
      final MainMapSceneStatusController controller =
          MainMapSceneStatusController(<String, MainMapStatusLoader>{
            'bug_hunter': () async {
              failingAttempts++;
              if (failingAttempts == 1) {
                throw StateError('temporary status error');
              }
              return const ActivityStatus(
                progressLabel: 'unlocked',
                unlockLessonId: 'real-lesson-id',
              );
            },
            'robot_maze': () async {
              healthyAttempts++;
              return readyStatus;
            },
          });
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(controller.places['bug_hunter']!.phase, MainMapPlacePhase.error);
      expect(controller.places['robot_maze']!.phase, MainMapPlacePhase.ready);
      expect(healthyAttempts, 1);

      await controller.retry('bug_hunter');
      expect(controller.places['bug_hunter']!.phase, MainMapPlacePhase.ready);
      expect(
        controller.places['bug_hunter']!.status!.unlockLessonId,
        'real-lesson-id',
      );
      expect(failingAttempts, 2);
      expect(
        healthyAttempts,
        1,
        reason:
            'retry must not reload healthy routes or emit activity-open behavior',
      );
    },
  );

  test(
    'out-of-order status responses cannot replace the newest refresh',
    () async {
      final Completer<ActivityStatus> stale = Completer<ActivityStatus>();
      final Completer<ActivityStatus> current = Completer<ActivityStatus>();
      int calls = 0;
      final MainMapSceneStatusController controller =
          MainMapSceneStatusController(<String, MainMapStatusLoader>{
            'main_quest': () => ++calls == 1 ? stale.future : current.future,
          });
      addTearDown(controller.dispose);

      final Future<void> firstRefresh = controller.refresh();
      final Future<void> secondRefresh = controller.refresh();
      current.complete(const ActivityStatus(progressLabel: 'current'));
      await secondRefresh;
      stale.complete(
        const ActivityStatus(progressLabel: 'stale', locked: true),
      );
      await firstRefresh;

      expect(controller.places['main_quest']!.status!.progressLabel, 'current');
      expect(controller.places['main_quest']!.status!.locked, isFalse);
    },
  );

  test('late completion after dispose is ignored', () async {
    final Completer<ActivityStatus> late = Completer<ActivityStatus>();
    final MainMapSceneStatusController controller =
        MainMapSceneStatusController(<String, MainMapStatusLoader>{
          'main_quest': () => late.future,
        });
    final Future<void> refresh = controller.refresh();
    controller.dispose();
    late.complete(readyStatus);
    await refresh;
    expect(controller.places['main_quest']!.phase, MainMapPlacePhase.loading);
  });
}
