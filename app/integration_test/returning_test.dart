// Runs after journey_test.dart on the same device: proves progress was saved
// on disk and restored after the app process was restarted.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pyquest/app/pyquest_app.dart';

import 'harness.dart';

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  tearDownAll(finishScreenshots);

  testWidgets('returning player sees saved progress', (tester) async {
    step('40 returning player sees saved progress');
    await startScreenshots();
    await tester.pumpWidget(const PyQuestApp());
    final end = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(end) &&
        find.byKey(const ValueKey('settings_button')).evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await wait(tester, 1500);
    expect(find.byKey(const ValueKey('welcome_next')), findsNothing,
        reason: 'intro was already seen');
    await shot('40_relaunch_map');

    await tapKey(tester, 'map_label_robot_maze');
    await tapKey(tester, 'sheet_open', waitMs: 1600);
    expect(find.textContaining('2/10'), findsWidgets,
        reason: 'two maze levels were completed before the restart');
    await shot('41_relaunch_maze_levels');
    await toMap(tester);

    await tapKey(tester, 'map_label_main_quest');
    await tapKey(tester, 'sheet_open', waitMs: 1600);
    expect(find.text('Ôn tập'), findsWidgets, reason: 'lesson 1 is completed');
    await shot('42_relaunch_tower');
    await toMap(tester);

    await tapKey(tester, 'map_label_achievement_house');
    await tapKey(tester, 'sheet_open', waitMs: 1800);
    expect(find.text('Bước Chân Đầu Tiên'), findsWidgets);
    expect(find.text('Dòng Code Đầu Tiên'), findsWidgets);
    await shot('43_relaunch_achievements');
  });
}
