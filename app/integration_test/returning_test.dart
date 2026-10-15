// Runs after journey_test.dart on the same device: proves progress was saved
// on disk and restored after the app process was restarted.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pyquest/app/pyquest_app.dart';

late IntegrationTestWidgetsFlutterBinding binding;

Future<void> wait(WidgetTester tester, int ms) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tapKey(WidgetTester tester, String key, {int waitMs = 900}) async {
  final f = find.byKey(ValueKey(key));
  await tester.ensureVisible(f.first);
  await wait(tester, 200);
  await tester.tap(f.first);
  await wait(tester, waitMs);
}

Future<void> toMap(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).last).popUntil((r) => r.isFirst);
  await wait(tester, 1200);
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('returning player sees saved progress', (tester) async {
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpWidget(const PyQuestApp());
    final end = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(end) && find.byKey(const ValueKey('settings_button')).evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await wait(tester, 1500);
    expect(find.byKey(const ValueKey('welcome_next')), findsNothing, reason: 'intro was already seen');
    await binding.takeScreenshot('40_relaunch_map');

    await tapKey(tester, 'map_label_robot_maze');
    await tapKey(tester, 'sheet_open', waitMs: 1600);
    expect(find.textContaining('2/10'), findsWidgets, reason: 'two maze levels were completed before the restart');
    await binding.takeScreenshot('41_relaunch_maze_levels');
    await toMap(tester);

    await tapKey(tester, 'map_label_main_quest');
    await tapKey(tester, 'sheet_open', waitMs: 1600);
    expect(find.text('Ôn tập'), findsWidgets, reason: 'lesson 1 is completed');
    await binding.takeScreenshot('42_relaunch_tower');
    await toMap(tester);

    await tapKey(tester, 'map_label_achievement_house');
    await tapKey(tester, 'sheet_open', waitMs: 1800);
    expect(find.text('Bước Chân Đầu Tiên'), findsWidgets);
    expect(find.text('Dòng Code Đầu Tiên'), findsWidgets);
    await binding.takeScreenshot('43_relaunch_achievements');
  });
}
