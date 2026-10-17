import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/app/locale_binding.dart';
import 'package:pyquest/core/settings_service.dart';
import 'package:pyquest/data/database/app_database.dart';
import 'package:pyquest/data/repositories/state_repositories.dart';
import 'package:pyquest/l10n/generated/app_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  testWidgets('Vietnamese BackButton exposes its localized semantic label on a modal route',
      (WidgetTester tester) async {
    final _LocaleHarness harness = await _createHarness(tester);
    await _showModal(tester);
    final SemanticsHandle semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);

    final Finder backVi = find.byTooltip('Quay lại');
    expect(backVi, findsOneWidget, reason: 'Vietnamese BackButton tooltip missing');
    expect(tester.getSemantics(backVi).label, 'Quay lại',
        reason: 'Vietnamese BackButton semantic label was not localized');

    await _disposeHarness(tester, harness);
  });

  testWidgets('modal BackButton semantic label follows a system locale change',
      (WidgetTester tester) async {
    final _LocaleHarness harness = await _createHarness(tester);
    await _showModal(tester);
    final SemanticsHandle semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);

    expect(find.byTooltip('Quay lại'), findsOneWidget,
        reason: 'modal route did not start in Vietnamese');
    harness.osLocales
      ..clear()
      ..add(const Locale('en', 'US'));
    harness.binding.syncSystemLocales();
    await tester.pump(const Duration(milliseconds: 150));

    final Finder backEn = find.byTooltip('Back');
    expect(backEn, findsOneWidget, reason: 'English BackButton tooltip did not replace Vietnamese');
    expect(tester.getSemantics(backEn).label, 'Back',
        reason: 'English BackButton semantic label was not localized');

    await tester.tap(backEn);
    await tester.pump(const Duration(milliseconds: 150));
    await _disposeHarness(tester, harness);
  });
}

Future<_LocaleHarness> _createHarness(WidgetTester tester) async {
  final AppDatabase database = await tester.runAsync(() => AppDatabase.open(
        factory: databaseFactoryFfiNoIsolate,
        path: inMemoryDatabasePath,
      )) as AppDatabase;
  final SettingsService settings = SettingsService(SettingsRepository(database));
  await tester.runAsync(settings.load);
  final List<Locale> osLocales = <Locale>[const Locale('vi', 'VN')];
  final AppLocaleBinding binding = AppLocaleBinding(
    settings: settings,
    systemLocales: () => List<Locale>.unmodifiable(osLocales),
  )..syncSystemLocales();
  await tester.pumpWidget(_localizedHost(binding));
  await tester.pump(const Duration(milliseconds: 100));
  return _LocaleHarness(settings, binding, osLocales);
}

Future<void> _showModal(WidgetTester tester) async {
  unawaited(showDialog<void>(
    context: tester.element(find.byType(Navigator).first),
    builder: (BuildContext context) => const AlertDialog(
      title: Text('Locale semantics'),
      actions: <Widget>[BackButton()],
    ),
  ));
  await tester.pump(const Duration(milliseconds: 150));
}

Future<void> _disposeHarness(WidgetTester tester, _LocaleHarness harness) async {
  await tester.pumpWidget(const SizedBox.shrink());
  harness.binding.dispose();
  harness.settings.dispose();
}

class _LocaleHarness {
  const _LocaleHarness(this.settings, this.binding, this.osLocales);

  final SettingsService settings;
  final AppLocaleBinding binding;
  final List<Locale> osLocales;
}

Widget _localizedHost(AppLocaleBinding binding) => AnimatedBuilder(
      animation: binding,
      builder: (BuildContext context, Widget? _) => MaterialApp(
        locale: binding.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(body: Text('Locale semantics host')),
      ),
    );
