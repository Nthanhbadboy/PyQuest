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

  testWidgets('Vietnamese modal BackButton has its localized tooltip',
      (WidgetTester tester) async {
    await _openModalHarness(tester);
    expect(find.byTooltip('Quay lại'), findsOneWidget);
  });

  testWidgets('Vietnamese modal BackButton exposes its localized semantic label',
      (WidgetTester tester) async {
    await _openModalHarness(tester);
    await tester.pump();
    expect(find.byTooltip('Quay lại'), findsOneWidget);
    final Finder backIcon = find.byType(Icon);
    expect(backIcon, findsOneWidget);
    final String label = tester.getSemantics(backIcon).label;
    expect(label, contains('Quay lại'));
    expect(label, isNot(contains('Back')));
  }, semanticsEnabled: true, variant: TargetPlatformVariant.only(TargetPlatform.android));

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
  });

  testWidgets('modal BackButton semantic label tracks a system locale change',
      (WidgetTester tester) async {
    final _LocaleHarness harness = await _openModalHarness(tester);
    expect(find.byTooltip('Quay lại'), findsOneWidget);

    harness.osLocales
      ..clear()
      ..add(const Locale('en', 'US'));
    harness.binding.syncSystemLocales();
    await tester.pump(const Duration(milliseconds: 150));

    final Finder backEn = find.byTooltip('Back');
    expect(backEn, findsOneWidget);
    final Finder backIcon = find.byType(Icon);
    expect(backIcon, findsOneWidget);
    final String label = tester.getSemantics(backIcon).label;
    expect(label, contains('Back'));
    expect(label, isNot(contains('Quay lại')));
    await tester.tap(backEn);
    await tester.pump(const Duration(milliseconds: 150));
  }, semanticsEnabled: true, variant: TargetPlatformVariant.only(TargetPlatform.android));
}

Future<_LocaleHarness> _openModalHarness(WidgetTester tester) async {
  AppDatabase? database;
  SettingsService? settings;
  AppLocaleBinding? binding;
  addTearDown(() async {
    try {
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      try {
        binding?.dispose();
      } finally {
        try {
          settings?.dispose();
        } finally {
          if (database != null) await tester.runAsync(database.close);
        }
      }
    }
  });

  final AppDatabase openedDatabase = await tester.runAsync(() => AppDatabase.open(
        factory: databaseFactoryFfiNoIsolate,
        path: inMemoryDatabasePath,
      )) as AppDatabase;
  database = openedDatabase;
  final SettingsService openedSettings = SettingsService(SettingsRepository(openedDatabase));
  settings = openedSettings;
  await tester.runAsync(openedSettings.load);
  final List<Locale> osLocales = <Locale>[const Locale('vi', 'VN')];
  final AppLocaleBinding localeBinding = AppLocaleBinding(
    settings: openedSettings,
    systemLocales: () => List<Locale>.unmodifiable(osLocales),
  )..syncSystemLocales();
  binding = localeBinding;
  await tester.pumpWidget(_localizedHost(localeBinding));
  await tester.pump(const Duration(milliseconds: 100));
  unawaited(showDialog<void>(
    context: tester.element(find.byType(Navigator).first),
    builder: (BuildContext context) => const AlertDialog(
      title: Text('Locale semantics'),
      actions: <Widget>[BackButton()],
    ),
  ));
  await tester.pump(const Duration(milliseconds: 150));
  return _LocaleHarness(localeBinding, osLocales);
}

class _LocaleHarness {
  const _LocaleHarness(this.binding, this.osLocales);

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
