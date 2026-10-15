// Real-device journey used by CI (Android emulator). Each section is its own
// test so one failure does not hide the rest; progress persists between them
// because they share the same on-device database.
//
// Progress markers, bounded screenshots and the shared helpers live in
// harness.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pyquest/app/pyquest_app.dart';

import 'harness.dart';

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  tearDownAll(finishScreenshots);

  testWidgets('01 first launch and island map', (tester) async {
    step('01 first launch and island map');
    await startScreenshots();
    await tester.pumpWidget(const PyQuestApp(minSplash: Duration(milliseconds: 2500)));
    await wait(tester, 900);
    await shot('01_splash');
    await waitFor(tester, 'welcome_next');
    await wait(tester, 800);
    expect(find.byKey(const ValueKey('welcome_next')), findsOneWidget);
    await shot('02_welcome');
    for (var i = 0; i < 3; i++) {
      await tapKey(tester, 'welcome_next', waitMs: 700);
    }
    await wait(tester, 800);
    await shot('03_main_map');
    expect(find.text('Tháp Python'), findsWidgets);
  });

  testWidgets('02 robot maze level 1', (tester) async {
    step('02 robot maze level 1');
    await boot(tester);
    await tapKey(tester, 'map_label_robot_maze');
    await shot('04_activity_sheet');
    await tapKey(tester, 'sheet_open', waitMs: 1600);
    await shot('05_maze_levels');
    await tapKey(tester, 'maze_level_1', waitMs: 1600);
    await shot('06_maze_level1');
    for (var i = 0; i < 4; i++) {
      await tapKey(tester, 'palette_right', waitMs: 250);
    }
    await shot('07_maze_program');
    await tapKey(tester, 'maze_run', waitMs: 900);
    await shot('08_maze_running');
    await wait(tester, 4000);
    expect(find.byKey(const ValueKey('result_title')), findsOneWidget);
    await wait(tester, 1500);
    await shot('09_maze_result');
    await tapKey(tester, 'result_primary', waitMs: 1800);
    await shot('10_maze_level2');
    for (final k in ['palette_right', 'palette_right', 'palette_right', 'palette_down', 'palette_down', 'palette_down']) {
      await tapKey(tester, k, waitMs: 200);
    }
    await tapKey(tester, 'maze_run', waitMs: 5000);
    await shot('11_maze_level2_result');
  });

  testWidgets('03 main quest lesson 1', (tester) async {
    step('03 main quest lesson 1');
    await boot(tester);
    await tapKey(tester, 'map_label_main_quest');
    await tapKey(tester, 'sheet_open', waitMs: 1600);
    await shot('12_python_tower');
    await tapKey(tester, 'lesson_card_mq1_01', waitMs: 1600);
    await shot('13_lesson_story');
    await tapKey(tester, 'lesson_continue', waitMs: 600);
    await tapKey(tester, 'example_run', waitMs: 800);
    await shot('14_lesson_example_run');
    await tapKey(tester, 'lesson_continue', waitMs: 600);
    await tapKey(tester, 'choice_1', waitMs: 300);
    await tapKey(tester, 'lesson_check', waitMs: 800);
    await shot('15_lesson_wrong_choice');
    await tapKey(tester, 'choice_0', waitMs: 300);
    await tapKey(tester, 'lesson_check', waitMs: 800);
    await tapKey(tester, 'lesson_continue', waitMs: 600);
    await tester.tap(find.text('"PyQuest"').first);
    await wait(tester, 400);
    await tapKey(tester, 'lesson_check', waitMs: 900);
    await shot('16_lesson_fill_correct');
    await tapKey(tester, 'lesson_continue', waitMs: 600);
    await tester.enterText(find.byKey(const ValueKey('code_editor_field')), 'print("Robo thong minh"');
    await wait(tester, 400);
    await tapKey(tester, 'lesson_check', waitMs: 900);
    await shot('17_lesson_code_error');
    await tester.enterText(find.byKey(const ValueKey('code_editor_field')), 'print("Robo thông minh")');
    await wait(tester, 400);
    await tapKey(tester, 'lesson_check', waitMs: 900);
    await shot('18_lesson_code_correct');
    await tapKey(tester, 'lesson_continue', waitMs: 2500);
    await shot('19_lesson_complete');
    expect(find.byKey(const ValueKey('lesson_complete_title')), findsOneWidget);
  });

  testWidgets('04 dragon jump run', (tester) async {
    step('04 dragon jump run');
    await boot(tester);
    await tapKey(tester, 'map_label_dragon_jump');
    await tapKey(tester, 'sheet_open', waitMs: 1600);
    await shot('20_dragon_home');
    await tapKey(tester, 'dragon_play', waitMs: 1500);
    final area = find.byKey(const ValueKey('dragon_tap_area'));
    for (var i = 0; i < 14; i++) {
      await tester.tap(area);
      await wait(tester, i.isEven ? 450 : 700);
      if (i == 7) await shot('21_dragon_play');
    }
    // Stop jumping: Pip will eventually bump into obstacles and the run ends.
    for (var i = 0; i < 40 && find.byKey(const ValueKey('result_title')).evaluate().isEmpty; i++) {
      await wait(tester, 1000);
    }
    await wait(tester, 1500);
    await shot('22_dragon_result');
  });

  testWidgets('05 catch the stars', (tester) async {
    step('05 catch the stars');
    await boot(tester);
    await tapKey(tester, 'map_label_catch_stars');
    await tapKey(tester, 'sheet_open', waitMs: 1600);
    await shot('23_stars_home');
    await tapKey(tester, 'stars_play', waitMs: 1500);
    final area = find.byKey(const ValueKey('stars_area'));
    final size = tester.getSize(area);
    for (var i = 0; i < 24; i++) {
      await tester.tapAt(Offset(size.width * (0.2 + 0.6 * ((i * 37) % 10) / 10), size.height * 0.7));
      await wait(tester, 500);
      if (i == 14) await shot('24_stars_play');
    }
    for (var i = 0; i < 40 && find.byKey(const ValueKey('result_title')).evaluate().isEmpty; i++) {
      await wait(tester, 1000);
    }
    await wait(tester, 1500);
    await shot('25_stars_result');
  });

  testWidgets('06 creator workshop with python', (tester) async {
    step('06 creator workshop with python');
    await boot(tester);
    await tapKey(tester, 'map_label_robot_maze');
    await tapKey(tester, 'sheet_open', waitMs: 1600);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('open_workshop')), 300,
        scrollable: find.byType(Scrollable).first);
    await wait(tester, 500);
    await tapKey(tester, 'open_workshop', waitMs: 1600);
    await shot('26_workshop');
    await tapKey(tester, 'workshop_code', waitMs: 1800);
    await tester.enterText(
      find.byKey(const ValueKey('code_editor_field')),
      'for i in range(5):\n    right()\nfor i in range(5):\n    down()\n',
    );
    await wait(tester, 500);
    await shot('27_workshop_code');
    await tapKey(tester, 'maze_run', waitMs: 6000);
    await shot('28_workshop_verified');
  });

  testWidgets('07 achievements, energy, quests, locked bug hunter', (tester) async {
    step('07 achievements, energy, quests, locked bug hunter');
    await boot(tester);
    await tapKey(tester, 'map_label_achievement_house');
    await tapKey(tester, 'sheet_open', waitMs: 1800);
    await shot('29_achievement_house');
    await toMap(tester);
    await tapKey(tester, 'energy_pill', waitMs: 900);
    await shot('30_energy_sheet');
    await tester.tapAt(const Offset(20, 60));
    await wait(tester, 700);
    await tapKey(tester, 'daily_quests_button', waitMs: 900);
    await shot('31_daily_quests');
    await tester.tapAt(const Offset(20, 60));
    await wait(tester, 700);
    await tapKey(tester, 'map_label_bug_hunter', waitMs: 900);
    await shot('32_bug_hunter_locked');
    await tester.tapAt(const Offset(20, 60));
    await wait(tester, 700);
    await shot('33_map_after_play');
  });
}
