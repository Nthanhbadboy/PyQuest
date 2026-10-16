import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/core/clock.dart';

class FakeClock extends Clock {
  FakeClock(this.current);
  DateTime current;
  @override
  DateTime now() => current;
  void advance(Duration d) => current = current.add(d);
}

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

