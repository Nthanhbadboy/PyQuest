import 'dart:async';

import 'package:flutter/foundation.dart';
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
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  testWidgets('Vietnamese modal BackButton has its localized tooltip',
      (WidgetTester tester) async {
    final _LocaleHarness harness = await _openModalHarness(tester);
    expect(find.byTooltip('Quay lại'), findsOneWidget);
    await _disposeHarness(tester, harness);
  });

  testWidgets('Vietnamese modal BackButton exposes its localized semantic label',
      (WidgetTester tester) async {
    final _LocaleHarness harness = await _openModalHarness(tester);
    final Finder backVi = find.byTooltip('Quay lại');
    expect(backVi, findsOneWidget);
    final SemanticsHandle semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    await tester.pump();
    expect(tester.getSemantics(find.byType(IconButton)).label, 'Quay lại');
    await _disposeHarness(tester, harness);
  });

  testWidgets('modal BackButton tooltip tracks a system locale change',
      (WidgetTester tester) async {
    final _LocaleHarness harness = await _openModalHarness(tester);
    expect(find.byTooltip('Quay lại'), findsOneWidget);
    harness.osLocales
      ..clear()
      ..add(const Locale('en', 'US'));
    harness.binding.syncSystemLocales();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.byTooltip('Back'), findsOneWidget);
    await _disposeHarness(tester, harness);
  });

  testWidgets('modal BackButton semantic label tracks a system locale change',
      (WidgetTester tester) async {
    final _LocaleHarness harness = await _openModalHarness(tester);
    expect(find.byTooltip('Quay lại'), findsOneWidget);
    final SemanticsHandle semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    await tester.pump();

    harness.osLocales
      ..clear()
      ..add(const Locale('en', 'US'));
    harness.binding.syncSystemLocales();
    await tester.pump(const Duration(milliseconds: 150));

    final Finder backEn = find.byTooltip('Back');
    expect(backEn, findsOneWidget);
    expect(tester.getSemantics(find.byType(IconButton)).label, 'Back');
    await tester.tap(backEn);
    await tester.pump(const Duration(milliseconds: 150));
    await _disposeHarness(tester, harness);
  });

}

Future<_LocaleHarness> _openModalHarness(WidgetTester tester) async {
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
  final _LocaleHarness harness = _LocaleHarness(settings, binding, osLocales);
  unawaited(showDialog<void>(
    context: tester.element(find.byType(Navigator).first),
    builder: (BuildContext context) => const AlertDialog(
      title: Text('Locale semantics'),
      actions: <Widget>[BackButton()],
    ),
  ));
  await tester.pump(const Duration(milliseconds: 150));
  return harness;
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
