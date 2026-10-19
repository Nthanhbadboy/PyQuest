import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/app/app_scope.dart';
import 'package:pyquest/app/app_services.dart';
import 'package:pyquest/modules/catch_stars/catch_stars_module.dart';
import 'package:pyquest/modules/dragon_jump/dragon_jump_module.dart';
import 'package:pyquest/shared/theme/app_theme.dart';
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

  testWidgets('Dragon Jump r54 2.5D home and play surfaces work at 1x and 2x', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(720, 1280);
    addTearDown(tester.view.reset);

    final AppServices s = await _makeServices(tester);
    await tester.pumpWidget(_host(s, const DragonHomeScreen(), scale: 2.0));
    await pumpFor(tester, const Duration(milliseconds: 500));

    expect(
      find.byKey(const ValueKey<String>('dragon_25d_scene')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('dragon_play')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tapAndSettle(
      tester,
      find.byKey(const ValueKey<String>('dragon_play')),
    );
    expect(
      find.byKey(const ValueKey<String>('dragon_jump_btn')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('dragon_jump_btn')));
    await pumpFor(tester, const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Catch Stars r55 2.5D home and play surfaces work at 1x and 2x', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(720, 1280);
    addTearDown(tester.view.reset);

    final AppServices s = await _makeServices(tester);
    await tester.pumpWidget(_host(s, const CatchStarsHomeScreen(), scale: 2.0));
    await pumpFor(tester, const Duration(milliseconds: 500));

    expect(
      find.byKey(const ValueKey<String>('stars_25d_scene')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('stars_play')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tapAndSettle(
      tester,
      find.byKey(const ValueKey<String>('stars_play')),
    );
    expect(
      find.byKey(const ValueKey<String>('stars_move_left')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('stars_move_right')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('stars_move_right')));
    await pumpFor(tester, const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpFor(tester, const Duration(milliseconds: 1100));
  });
}
