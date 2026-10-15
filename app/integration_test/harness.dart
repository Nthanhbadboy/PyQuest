// Shared helpers for the on-device journeys that CI runs on the Android
// emulator. They add bounded waits and progress markers so a stuck step is
// visible in the CI log instead of hanging until `flutter drive` gives up.
//
// Every line the harness prints starts with [progressTag] and carries the
// current step name, so the log answers "what was the test doing?" directly.
import 'dart:async';

import 'package:flutter/material.dart';   // also re-exports debugPrint
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pyquest/app/pyquest_app.dart';

/// Tag on every progress line; CI greps the test log for it.
const String progressTag = '[PYQUEST]';

late IntegrationTestWidgetsFlutterBinding binding;

String _step = 'startup';
final Map<String, String> _screenshotFailures = <String, String>{};

void progress(String message) => debugPrint('$progressTag [$_step] $message');

/// Names the current step for every following progress line.
void step(String name) {
  _step = name;
  progress('--- start');
}

/// Android needs the Flutter surface converted to an image view before
/// `takeScreenshot` works. Bounded: if the platform side never answers (for
/// example when the activity was recreated under an already-converted engine),
/// the test keeps running and each screenshot reports its own failure.
Future<void> startScreenshots() async {
  progress('convertFlutterSurfaceToImage: begin');
  final stopwatch = Stopwatch()..start();
  try {
    await binding
        .convertFlutterSurfaceToImage()
        .timeout(const Duration(seconds: 30));
    progress('convertFlutterSurfaceToImage: done in '
        '${stopwatch.elapsedMilliseconds}ms');
  } on TimeoutException {
    progress('convertFlutterSurfaceToImage: TIMEOUT after 30s - continuing; '
        'screenshots will report their own failure');
  }
}

/// Bounded screenshot. Records the failure with the screenshot name and the
/// step it happened in instead of hanging or throwing an anonymous timeout.
/// [settleMs] lets the current screen finish animating before the capture.
Future<void> shot(String name,
    {Duration timeout = const Duration(seconds: 20), int settleMs = 400}) async {
  final stopwatch = Stopwatch()..start();
  progress('takeScreenshot $name: begin');
  try {
    await Future<void>.delayed(Duration(milliseconds: settleMs));
    await binding.takeScreenshot(name).timeout(timeout);
    progress('takeScreenshot $name: ok in ${stopwatch.elapsedMilliseconds}ms');
  } on TimeoutException {
    _screenshotFailures[name] = 'timeout after ${timeout.inSeconds}s';
    progress('takeScreenshot $name: TIMEOUT after ${timeout.inSeconds}s '
        '(step: $_step)');
  } catch (error) {
    _screenshotFailures[name] = '$error';
    progress('takeScreenshot $name: FAILED (step: $_step): $error');
  }
}

/// Reports the screenshot outcome at the end of the run. A test failure that
/// happened earlier is still reported by the test framework; this only adds
/// information, it never replaces it.
void finishScreenshots() {
  if (_screenshotFailures.isEmpty) {
    progress('screenshots: all captured');
    return;
  }
  final summary = _screenshotFailures.entries
      .map((entry) => '${entry.key} (${entry.value})')
      .join(', ');
  progress('screenshots: ${_screenshotFailures.length} failed -> $summary');
  fail('screenshots failed: $summary');
}

Future<void> wait(WidgetTester tester, int ms) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Waits (real time) until [key] is on screen, up to [timeoutMs].
Future<bool> waitFor(WidgetTester tester, String key, {int timeoutMs = 20000}) async {
  final end = DateTime.now().add(Duration(milliseconds: timeoutMs));
  while (DateTime.now().isBefore(end)) {
    if (find.byKey(ValueKey(key)).evaluate().isNotEmpty) return true;
    await tester.pump(const Duration(milliseconds: 200));
  }
  progress('waitFor $key: not found within ${timeoutMs}ms');
  return false;
}

Future<void> tapKey(WidgetTester tester, String key, {int waitMs = 900}) async {
  progress('tap $key');
  final f = find.byKey(ValueKey(key));
  await tester.ensureVisible(f.first);
  await wait(tester, 200);
  await tester.tap(f.first);
  await wait(tester, waitMs);
}

/// Pumps the real app and waits until the main map is up.
Future<void> boot(WidgetTester tester) async {
  progress('boot: begin');
  await startScreenshots();
  await tester.pumpWidget(const PyQuestApp());
  final ready = await waitFor(tester, 'settings_button');
  progress('boot: map ready=$ready');
  await wait(tester, 1200);
}

Future<void> toMap(WidgetTester tester) async {
  progress('back to map');
  final nav = tester.state<NavigatorState>(find.byType(Navigator).last);
  nav.popUntil((r) => r.isFirst);
  await wait(tester, 1200);
}
