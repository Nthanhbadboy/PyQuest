// PQC-020 R3 finding B — bằng chứng cỡ chữ ở ROOT THẬT.
//
// Vì sao file này tồn tại: `pyquest_app.dart` từng bọc app bằng
// `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.2)`, còn ảnh 2× của render
// lại lấy qua `pushMapAtTextScale` — một route MainMap thứ hai tự override
// MediaQuery trong Navigator. Cả hai đường đều không trả lời câu hỏi "người dùng
// chọn 2× trong hệ thống thì app production hiển thị thế nào". File này dựng đúng
// `PyQuestApp`, đổi cỡ chữ ở tầng hệ thống (`platformDispatcher`) và đo
// `MediaQuery.textScalerOf` tại hub + sheet thật. Không host giả, không route bypass.
//
// Giới hạn: đây là widget test linear scaler. Không kết luận Android nonlinear font
// scaling, TalkBack hay thiết bị thật từ file này.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/app/activity.dart';
import 'package:pyquest/app/activity_registry.dart';
import 'package:pyquest/app/app_services.dart';
import 'package:pyquest/app/pyquest_app.dart';
import 'package:pyquest/modules/main_map/activity_sheet.dart';
import 'package:pyquest/modules/main_map/main_map_screen.dart';
import 'package:pyquest/modules/main_quest/main_quest_module.dart';
import 'package:pyquest/modules/robot_maze/robot_maze_module.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_helpers.dart';

Future<AppServices> createServices() async => AppServices.create(
  bundle: rootBundle,
  databaseFactory: databaseFactoryFfiNoIsolate,
  databasePath: inMemoryDatabasePath,
  clock: FakeClock(DateTime(2026, 10, 19, 9)),
  audioEnabled: false,
  startSessionTimer: false,
);

/// Cột `expected` là giá trị hệ thống yêu cầu, không phải giá trị app được phép cắt.
const List<double> kScales = <double>[1, 1.3, 2];
const List<Size> kViewports = <Size>[Size(360, 640), Size(390, 844)];

Map<String, String> placeNames(String languageCode) => languageCode == 'vi'
    ? const <String, String>{
        'main_quest': 'Tháp Python',
        'robot_maze': 'Mê Cung Robo',
        'dragon_jump': 'Núi Lửa',
        'catch_stars': 'Đài Thiên Văn',
        'bug_hunter': 'Xưởng Bitsy',
        'achievement_house': 'Nhà Thành Tích',
      }
    : const <String, String>{
        'main_quest': 'Python Tower',
        'robot_maze': 'Robo Maze',
        'dragon_jump': 'Volcano',
        'catch_stars': 'Observatory',
        'bug_hunter': "Bitsy's Workshop",
        'achievement_house': 'Achievement House',
      };

/// Pumps the real app at [scale]; pump lại cùng một cây widget giữ nguyên State của
/// `MainMapScreen`, nên đây là cách hợp lệ để đổi system scale khi app đang mở.
Future<void> pumpRoot(
  WidgetTester tester,
  AppServices services, {
  required Locale locale,
}) async {
  await tester.pumpWidget(
    PyQuestApp(
      servicesFactory: (_) async => services,
      systemLocalesReader: () => <Locale>[locale],
      minSplash: Duration.zero,
    ),
  );
  await pumpFor(tester, const Duration(seconds: 2));
}

/// Escalate hệ thống thực sự tới tay widget: đọc từ chính element của screen.
double scalerAt(WidgetTester tester, Finder finder) =>
    MediaQuery.textScalerOf(tester.element(finder)).scale(16);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUpAll(loadAppFonts);

  testWidgets(
    'root matrix 12 config: system scale thật tới hub + sheet, mode tự chọn, controls chạm được',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final AppServices services = (await tester.runAsync(createServices))!;
      await tester.runAsync(() => services.settings.setIntroSeen());
      addTearDown(services.dispose);

      for (final Size viewport in kViewports) {
        tester.view.physicalSize = viewport;
        for (final Locale locale in <Locale>[
          const Locale('vi'),
          const Locale('en'),
        ]) {
          for (final double scale in kScales) {
            final String cfg =
                '${viewport.width.toInt()}x${viewport.height.toInt()}'
                '/${locale.languageCode}/${scale}x';
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );

            await pumpRoot(tester, services, locale: locale);

            // 1) Scaler ở hub PHẢI là mức hệ thống, không phải mức cap của app.
            final double hubScaled = scalerAt(
              tester,
              find.byType(MainMapScreen),
            );
            expect(
              hubScaled,
              closeTo(16 * scale, 0.01),
              reason: 'hub ở $cfg phải nhận scaler hệ thống, không bị cap',
            );

            // 2) Mode mặc định theo ngưỡng 1.5 của chính screen (production rule).
            final bool directory = scale >= 1.5;
            expect(
              find.byKey(
                ValueKey<String>(
                  directory ? 'main_map_mode_places' : 'main_map_mode_village',
                ),
              ),
              findsOneWidget,
              reason: 'mode mặc định sai ở $cfg',
            );

            // 3) Sáu tên + sáu target ở mode đang bật.
            final Map<String, String> names = placeNames(locale.languageCode);
            for (final ActivityModule module in activityRegistry) {
              final String id = module.def.id;
              expect(
                find.text(names[id]!),
                findsWidgets,
                reason: 'thiếu tên $id ở $cfg',
              );
              expect(
                find.byKey(
                  ValueKey<String>(
                    directory ? 'directory_place_$id' : 'map_label_$id',
                  ),
                ),
                findsOneWidget,
                reason: 'thiếu target $id ở $cfg',
              );
            }

            // 4) Controls đầu màn vẫn cuộn/chạm được ở mọi config.
            for (final String key in <String>[
              'energy_pill',
              'daily_quests_button',
              'settings_button',
            ]) {
              final Finder control = find.byKey(ValueKey<String>(key));
              await tester.ensureVisible(control);
              await tester.pump();
              expect(
                control.hitTestable(),
                findsOneWidget,
                reason: '$key không chạm được ở $cfg',
              );
            }

            // 5) Sheet thật cùng nhận scaler hệ thống (không phải hub một mình).
            final Finder firstPlace = find.byKey(
              ValueKey<String>(
                directory
                    ? 'directory_place_main_quest'
                    : 'map_label_main_quest',
              ),
            );
            await tester.tap(firstPlace);
            await pumpFor(tester, const Duration(milliseconds: 900));
            expect(
              find.byType(ActivitySheet),
              findsOneWidget,
              reason: 'sheet không mở ở $cfg',
            );
            final double sheetScaled = scalerAt(
              tester,
              find.byType(ActivitySheet),
            );
            expect(
              sheetScaled,
              closeTo(16 * scale, 0.01),
              reason: 'sheet ở $cfg phải nhận scaler hệ thống',
            );
            await tester.binding.handlePopRoute();
            await pumpFor(tester, const Duration(milliseconds: 700));
            expect(
              find.byType(ActivitySheet),
              findsNothing,
              reason: 'sheet không đóng ở $cfg',
            );

            expect(
              tester.takeException(),
              isNull,
              reason: 'layout exception ở $cfg',
            );
            // Receipt cho handoff: một dòng/config, đọc được từ log focused.
            // ignore: avoid_print
            print(
              'R3-ROOT $cfg hubScaler=$hubScaled sheetScaler=$sheetScaled '
              'mode=${directory ? "places" : "village"}',
            );

            // Xả timer của toast/mini-game trước khi đổi config, cùng bài học với
            // `finish()` của harness render.
            await tester.pumpWidget(const SizedBox.shrink());
            await pumpFor(tester, const Duration(milliseconds: 1100));
          }
        }
      }
    },
  );

  testWidgets(
    'đổi system scale khi app đang mở: tự chuyển mode theo 1.5, ưu tiên thủ công được giữ, không reset tiến trình',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final AppServices services = (await tester.runAsync(createServices))!;
      await tester.runAsync(() => services.settings.setIntroSeen());
      addTearDown(services.dispose);
      tester.platformDispatcher.textScaleFactorTestValue = 1;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpRoot(tester, services, locale: const Locale('vi'));
      final int energyBefore = services.energy.current;
      expect(
        find.byKey(const ValueKey<String>('main_map_mode_village')),
        findsOneWidget,
      );

      // 1 → 2×: chưa ai chọn mode nên hub phải tự sang directory.
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      await pumpRoot(tester, services, locale: const Locale('vi'));
      expect(
        find.byKey(const ValueKey<String>('main_map_mode_places')),
        findsOneWidget,
        reason: '2× hệ thống phải tự bật directory theo ngưỡng 1.5',
      );
      expect(
        scalerAt(tester, find.byType(MainMapScreen)),
        closeTo(32, 0.01),
        reason: 'root không còn cap 1.2',
      );

      // Người dùng tự chọn village → preference thủ công thắng, kể cả khi scale
      // đổi lại lần nữa.
      await tester.tap(
        find.byKey(const ValueKey<String>('main_map_mode_village')),
      );
      await pumpFor(tester, const Duration(milliseconds: 300));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      await pumpRoot(tester, services, locale: const Locale('vi'));
      expect(
        find.byKey(const ValueKey<String>('main_map_mode_village')),
        findsOneWidget,
        reason: 'chọn tay phải được giữ theo contract hiện tại',
      );

      // Mở sheet rồi đóng: focus/scroll trả về, energy và tiến trình không đổi.
      await tester.tap(
        find.byKey(const ValueKey<String>('map_label_main_quest')),
      );
      await pumpFor(tester, const Duration(milliseconds: 900));
      expect(find.byType(ActivitySheet), findsOneWidget);
      await tester.binding.handlePopRoute();
      await pumpFor(tester, const Duration(milliseconds: 700));
      expect(find.byType(ActivitySheet), findsNothing);
      final FocusNode placeNode = tester
          .widget<TextButton>(
            find.descendant(
              of: find.byKey(const ValueKey<String>('map_label_main_quest')),
              matching: find.byType(TextButton),
            ),
          )
          .focusNode!;
      expect(
        FocusManager.instance.primaryFocus,
        same(placeNode),
        reason: 'đóng sheet phải trả focus về đúng nút đã mở',
      );
      expect(
        services.energy.current,
        energyBefore,
        reason: 'xem/đóng sheet không được đổi năng lượng',
      );
      expect(tester.takeException(), isNull);
      // ignore: avoid_print
      print(
        'R3-ROOT scale-change energy=$energyBefore->${services.energy.current}',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpFor(tester, const Duration(milliseconds: 1100));
    },
  );

  testWidgets(
    'smoke 2× ở root thật: sheet → MainQuest prerequisite và sheet → Robot Maze home → Back, ghi scaler tại destination',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final AppServices services = (await tester.runAsync(createServices))!;
      await tester.runAsync(() => services.settings.setIntroSeen());
      addTearDown(services.dispose);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpRoot(tester, services, locale: const Locale('vi'));
      // 2× → directory; người mới thì Bug Hunter còn khóa nên CTA là bài học.
      await tester.tap(
        find.byKey(const ValueKey<String>('directory_place_bug_hunter')),
      );
      await pumpFor(tester, const Duration(milliseconds: 900));
      expect(
        find.byKey(const Key('sheet_go_lesson')),
        findsOneWidget,
        reason: 'prerequisite CTA phải hiện ở 2× directory',
      );
      await tester.tap(find.byKey(const Key('sheet_go_lesson')));
      await pumpFor(tester, const Duration(milliseconds: 1400));
      expect(find.byType(MainQuestHomeScreen), findsOneWidget);
      final double questScaled = scalerAt(
        tester,
        find.byType(MainQuestHomeScreen),
      );
      expect(
        questScaled,
        closeTo(32, 0.01),
        reason: 'route thật phải thừa hưởng scaler hệ thống',
      );
      await tester.binding.handlePopRoute();
      await pumpFor(tester, const Duration(milliseconds: 700));
      expect(
        find.byType(MainMapScreen),
        findsOneWidget,
        reason: 'Back từ MainQuest phải về hub',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('directory_place_robot_maze')),
      );
      await pumpFor(tester, const Duration(milliseconds: 900));
      await tester.tap(find.byKey(const Key('sheet_open')));
      await pumpFor(tester, const Duration(milliseconds: 1500));
      expect(find.byType(RobotMazeHomeScreen), findsOneWidget);
      final double mazeScaled = scalerAt(
        tester,
        find.byType(RobotMazeHomeScreen),
      );
      expect(
        mazeScaled,
        closeTo(32, 0.01),
        reason: 'Robot Maze home ở 2× phải nhận scaler hệ thống',
      );
      await tester.binding.handlePopRoute();
      await pumpFor(tester, const Duration(milliseconds: 700));
      expect(find.byType(MainMapScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      // ignore: avoid_print
      print('R3-ROOT 2x-routes mainQuest=$questScaled maze=$mazeScaled');
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpFor(tester, const Duration(milliseconds: 1100));
    },
  );
}
