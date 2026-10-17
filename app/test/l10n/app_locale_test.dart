import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pyquest/app/app_services.dart';
import 'package:pyquest/app/locale_binding.dart';
import 'package:pyquest/app/pyquest_app.dart';
import 'package:pyquest/core/localization/locale_preference.dart';
import 'package:pyquest/core/settings_service.dart';
import 'package:pyquest/data/database/app_database.dart';
import 'package:pyquest/data/repositories/state_repositories.dart';
import 'package:pyquest/l10n/generated/app_localizations.dart';
import 'package:pyquest/shared/l10n/pq_l10n.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUpAll(loadAppFonts);

  // ---------------------------------------------------------------- adapter unit
  group('AppLocaleBinding', () {
    test('bootstrapLocale maps the OS list with no stored preference yet', () {
      expect(AppLocaleBinding.bootstrapLocale(const <Locale>[Locale('vi', 'VN')]), const Locale('vi'));
      expect(AppLocaleBinding.bootstrapLocale(const <Locale>[Locale('ja'), Locale('vi')]), const Locale('vi'));
      expect(AppLocaleBinding.bootstrapLocale(const <Locale>[Locale('fr', 'FR')]), const Locale('en'));
      expect(AppLocaleBinding.bootstrapLocale(const <Locale>[]), const Locale('en'));
    });

    test('system preference follows the ordered OS list and never persists it', () async {
      final _Fixture fixture = await _openFixture(const <String, String>{});
      addTearDown(fixture.close);
      final SettingsService settings = fixture.service();
      addTearDown(settings.dispose);
      await settings.load();

      final AppLocaleBinding binding = AppLocaleBinding(
        settings: settings,
        systemLocales: () => const <Locale>[Locale('vi', 'VN')],
      );
      addTearDown(binding.dispose);
      binding.syncSystemLocales();

      expect(binding.systemLocaleTags, <String>['vi-VN']);
      expect(binding.locale, const Locale('vi'));
      // Cast dialogue and the live tutor voice are built from this getter.
      expect(settings.lang, PqLang.vi);
      expect(settings.raw(SettingsService.localePreferenceKey), isNull);
      expect((await fixture.repository.all())[SettingsService.localePreferenceKey], isNull);
    });

    test('an unsupported OS list falls back to English without writing a preference', () async {
      final _Fixture fixture = await _openFixture(const <String, String>{});
      addTearDown(fixture.close);
      final SettingsService settings = fixture.service();
      addTearDown(settings.dispose);
      await settings.load();

      final AppLocaleBinding binding = AppLocaleBinding(
        settings: settings,
        systemLocales: () => const <Locale>[Locale('fr', 'FR'), Locale('de')],
      );
      addTearDown(binding.dispose);
      binding.syncSystemLocales();

      expect(binding.locale, const Locale('en'));
      expect(settings.localeResolution.usedEnglishFallback, isTrue);
      expect(settings.lang, PqLang.en);
      expect((await fixture.repository.all())[SettingsService.localePreferenceKey], isNull);
    });

    test('an explicit preference keeps winning while the OS list changes', () async {
      final _Fixture fixture = await _openFixture(const <String, String>{});
      addTearDown(fixture.close);
      final SettingsService settings = fixture.service();
      addTearDown(settings.dispose);
      await settings.load();

      final List<Locale> osList = <Locale>[const Locale('vi', 'VN')];
      final AppLocaleBinding binding =
          AppLocaleBinding(settings: settings, systemLocales: () => osList);
      addTearDown(binding.dispose);
      binding.syncSystemLocales();
      expect(await settings.setLocalePreference(LocalePreference.en), isTrue);
      expect(binding.locale, const Locale('en'));

      osList
        ..clear()
        ..add(const Locale('vi', 'VN'));
      binding.syncSystemLocales();
      expect(binding.locale, const Locale('en'));
      expect(settings.lang, PqLang.en);

      // Back to `system`: the OS list applies again, still without a new write.
      expect(await settings.setLocalePreference(LocalePreference.system), isTrue);
      binding.syncSystemLocales();
      expect(binding.locale, const Locale('vi'));
      expect(settings.raw(SettingsService.localePreferenceKey), 'system');
    });
  });

  // ------------------------------------------------------------------ app root
  group('app root locale wiring', () {
    // A factory that never resolves keeps the app on the splash: the stored preference is
    // unknown there, so the OS list is the only input.
    Future<void> pumpSplash(WidgetTester tester) async {
      tester.platformDispatcher.localesTestValue = <Locale>[const Locale('vi', 'VN')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(
        PyQuestApp(servicesFactory: (_) => Completer<AppServices>().future, minSplash: Duration.zero),
      );
      await pumpFor(tester, const Duration(milliseconds: 600));
    }

    testWidgets('splash shows the motto while the services are still loading',
        (WidgetTester tester) async {
      await pumpSplash(tester);
      expect(find.text('Build Your Game. Rule Your World.'), findsOneWidget);
    });

    testWidgets('splash locale follows the OS list before settings exist',
        (WidgetTester tester) async {
      await pumpSplash(tester);
      final BuildContext context = tester.element(find.text('Build Your Game. Rule Your World.'));
      expect(Localizations.localeOf(context), const Locale('vi'));
    });

    testWidgets('splash framework strings come from the Vietnamese delegate',
        (WidgetTester tester) async {
      await pumpSplash(tester);
      final BuildContext context = tester.element(find.text('Build Your Game. Rule Your World.'));
      expect(MaterialLocalizations.of(context).cancelButtonLabel, 'Huỷ');
      expect(MaterialLocalizations.of(context).closeButtonLabel, 'Đóng');
    });

    testWidgets('splash generated greeting is Vietnamese', (WidgetTester tester) async {
      await pumpSplash(tester);
      final BuildContext context = tester.element(find.text('Build Your Game. Rule Your World.'));
      expect(AppLocalizations.delegate.isSupported(const Locale('vi')), isTrue);
      final AppLocalizations? l10n = AppLocalizations.of(context);
      expect(l10n, isNotNull);
      expect(l10n!.localeName, 'vi');
      expect(l10n.foundationGreeting('Pip'), 'Xin chào Pip!');
    });

    testWidgets('loaded app follows the OS list; framework strings and tutor language switch',
        (WidgetTester tester) async {
      tester.platformDispatcher.localesTestValue = <Locale>[const Locale('vi', 'VN')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final AppServices services = await _openServices(tester);

      await tester.pumpWidget(
          PyQuestApp(servicesFactory: (_) async => services, minSplash: Duration.zero));
      await pumpFor(tester, const Duration(milliseconds: 600));

      expect(_localeOf(tester), const Locale('vi'));
      expect(_materialOf(tester).cancelButtonLabel, 'Huỷ');
      expect(_materialOf(tester).closeButtonLabel, 'Đóng');
      // What the cast and the live tutor voice are built from (SettingsService.lang).
      expect(services.settings.lang, PqLang.vi);
      // Following the OS must not persist a resolved language (PQC-014 contract).
      expect(services.settings.raw(SettingsService.localePreferenceKey), isNull);

      tester.platformDispatcher.localesTestValue = <Locale>[const Locale('fr', 'FR')];
      await pumpFor(tester, const Duration(milliseconds: 300));
      expect(_localeOf(tester), const Locale('en'));
      expect(_materialOf(tester).cancelButtonLabel, 'Cancel');
      expect(_materialOf(tester).closeButtonLabel, 'Close');
      expect(services.settings.lang, PqLang.en);
      expect(services.settings.raw(SettingsService.localePreferenceKey), isNull);
    });

    testWidgets('a manual choice survives an OS change and is stored', (WidgetTester tester) async {
      tester.platformDispatcher.localesTestValue = <Locale>[const Locale('vi', 'VN')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final AppServices services = await _openServices(tester);

      await tester.pumpWidget(
          PyQuestApp(servicesFactory: (_) async => services, minSplash: Duration.zero));
      await pumpFor(tester, const Duration(milliseconds: 600));
      expect(_localeOf(tester), const Locale('vi'));

      await tester.runAsync(() => services.settings.setLocalePreference(LocalePreference.en));
      await pumpFor(tester, const Duration(milliseconds: 300));
      expect(_localeOf(tester), const Locale('en'));
      expect(services.settings.lang, PqLang.en);
      expect(services.settings.raw(SettingsService.localePreferenceKey), 'en');

      // OS flips to Vietnamese: the explicit choice must not be overwritten.
      tester.platformDispatcher.localesTestValue = <Locale>[const Locale('vi', 'VN')];
      await pumpFor(tester, const Duration(milliseconds: 300));
      expect(_localeOf(tester), const Locale('en'));
      expect(services.settings.lang, PqLang.en);
      expect(services.settings.raw(SettingsService.localePreferenceKey), 'en');

      // Back to `system`: the OS list applies again.
      await tester.runAsync(() => services.settings.setLocalePreference(LocalePreference.system));
      await pumpFor(tester, const Duration(milliseconds: 300));
      expect(_localeOf(tester), const Locale('vi'));
      expect(services.settings.lang, PqLang.vi);
    });

    testWidgets('resume re-reads system locales on the splash and after app load',
        (WidgetTester tester) async {
      final List<Locale> osLocales = <Locale>[const Locale('en', 'US')];
      await tester.pumpWidget(
        PyQuestApp(
          servicesFactory: (_) => Completer<AppServices>().future,
          systemLocalesReader: () => List<Locale>.unmodifiable(osLocales),
          minSplash: Duration.zero,
        ),
      );
      await pumpFor(tester, const Duration(milliseconds: 150));
      expect(
        Localizations.localeOf(tester.element(find.text('Build Your Game. Rule Your World.'))),
        const Locale('en'),
      );

      osLocales
        ..clear()
        ..add(const Locale('vi', 'VN'));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(
        Localizations.localeOf(tester.element(find.text('Build Your Game. Rule Your World.'))),
        const Locale('vi'),
      );

      final AppServices services = await _openServices(tester);
      await tester.pumpWidget(
        PyQuestApp(
          key: const ValueKey<String>('loaded-root'),
          servicesFactory: (_) async => services,
          systemLocalesReader: () => List<Locale>.unmodifiable(osLocales),
          minSplash: Duration.zero,
        ),
      );
      await pumpFor(tester, const Duration(milliseconds: 300));
      expect(_localeOf(tester), const Locale('vi'));

      await tester.runAsync(() => services.settings.setLocalePreference(LocalePreference.vi));
      await pumpFor(tester, const Duration(milliseconds: 100));
      osLocales
        ..clear()
        ..add(const Locale('en', 'US'));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpFor(tester, const Duration(milliseconds: 100));
      expect(_localeOf(tester), const Locale('vi'), reason: 'manual preference must win on resume');
      expect(services.settings.lang, PqLang.vi);

      await tester.runAsync(() => services.settings.setLocalePreference(LocalePreference.system));
      await pumpFor(tester, const Duration(milliseconds: 100));
      expect(_localeOf(tester), const Locale('en'),
          reason: 'system mode uses the OS list refreshed on resume');
      expect(services.settings.raw(SettingsService.localePreferenceKey), 'system');

      // Unmount removes both the lifecycle observer and settings listener. A later resume
      // must not mutate the detached service through the old root binding.
      await tester.pumpWidget(const SizedBox.shrink());
      osLocales
        ..clear()
        ..add(const Locale('vi', 'VN'));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(services.settings.lang, PqLang.en);
      services.dispose();
      services.settings.dispose();
    });

    testWidgets('resetAllProgress reload keeps the synchronized system locale without persisting it',
        (WidgetTester tester) async {
      final List<Locale> osLocales = <Locale>[const Locale('vi', 'VN')];
      final AppServices services = await _openServices(tester);
      await tester.pumpWidget(
        PyQuestApp(
          servicesFactory: (_) async => services,
          systemLocalesReader: () => List<Locale>.unmodifiable(osLocales),
          minSplash: Duration.zero,
        ),
      );
      await pumpFor(tester, const Duration(milliseconds: 300));
      expect(_localeOf(tester), const Locale('vi'));

      await tester.runAsync(() => services.settings.setLocalePreference(LocalePreference.en));
      await pumpFor(tester, const Duration(milliseconds: 100));
      expect(_localeOf(tester), const Locale('en'));

      await tester.runAsync(services.resetAllProgress);
      await pumpFor(tester, const Duration(milliseconds: 150));
      expect(services.settings.localePreference, LocalePreference.system);
      expect(services.settings.localeResolution.languageCode, 'vi');
      expect(services.settings.lang, PqLang.vi);
      expect(_localeOf(tester), const Locale('vi'));
      expect(services.settings.raw(SettingsService.localePreferenceKey), isNull);
      final Map<String, String>? resetRows =
          await tester.runAsync(() => SettingsRepository(services.db).all());
      expect(resetRows?[SettingsService.localePreferenceKey], isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      services.dispose();
      services.settings.dispose();
    });

    testWidgets('persisted override survives app and service recreation against the real database',
        (WidgetTester tester) async {
      final Directory directory = await Directory.systemTemp.createTemp('pyquest-locale-recreate-');
      addTearDown(() {
        if (directory.existsSync()) directory.deleteSync(recursive: true);
      });
      final String firstDatabasePath = p.join(directory.path, 'first.db');
      final String recreatedDatabasePath = p.join(directory.path, 'recreated.db');
      Future<AppServices> createServices(String databasePath) async {
        final AppServices? services = await tester.runAsync(() => AppServices.create(
              bundle: rootBundle,
              databaseFactory: databaseFactoryFfiNoIsolate,
              databasePath: databasePath,
              audioEnabled: false,
              startSessionTimer: false,
            ));
        return services!;
      }

      final List<Locale> osLocales = <Locale>[const Locale('vi', 'VN')];
      final AppServices first = await createServices(firstDatabasePath);
      await tester.pumpWidget(
        PyQuestApp(
          servicesFactory: (_) async => first,
          systemLocalesReader: () => List<Locale>.unmodifiable(osLocales),
          minSplash: Duration.zero,
        ),
      );
      await pumpFor(tester, const Duration(milliseconds: 300));
      await tester.runAsync(() => first.settings.setLocalePreference(LocalePreference.en));
      await pumpFor(tester, const Duration(milliseconds: 100));
      expect(_localeOf(tester), const Locale('en'));
      final Map<String, String>? persistedRows =
          await tester.runAsync(() => SettingsRepository(first.db).all());
      expect(persistedRows?[SettingsService.localePreferenceKey], 'en');

      await tester.pumpWidget(const SizedBox.shrink());
      first.dispose();
      first.settings.dispose();
      // Snapshot the committed SQLite file after its write, then construct a fresh service/app
      // against that disk state. The second path avoids sqflite's per-path singleton cache.
      File(firstDatabasePath).copySync(recreatedDatabasePath);

      final AppServices recreated = await createServices(recreatedDatabasePath);
      await tester.pumpWidget(
        PyQuestApp(
          servicesFactory: (_) async => recreated,
          systemLocalesReader: () => List<Locale>.unmodifiable(osLocales),
          minSplash: Duration.zero,
        ),
      );
      await pumpFor(tester, const Duration(milliseconds: 300));
      expect(recreated.settings.localePreference, LocalePreference.en);
      expect(recreated.settings.lang, PqLang.en);
      expect(_localeOf(tester), const Locale('en'));

      await tester.runAsync(() => recreated.settings.setLocalePreference(LocalePreference.system));
      await pumpFor(tester, const Duration(milliseconds: 100));
      expect(_localeOf(tester), const Locale('vi'));
      expect(recreated.settings.lang, PqLang.vi);

      await tester.pumpWidget(const SizedBox.shrink());
      recreated.dispose();
      recreated.settings.dispose();
    });

    testWidgets('localized framework control semantics update on a live modal route',
        (WidgetTester tester) async {
      final List<Locale> osLocales = <Locale>[const Locale('vi', 'VN')];
      final AppServices services = await _openServices(tester);
      await tester.pumpWidget(
        PyQuestApp(
          servicesFactory: (_) async => services,
          systemLocalesReader: () => List<Locale>.unmodifiable(osLocales),
          minSplash: Duration.zero,
        ),
      );
      await pumpFor(tester, const Duration(milliseconds: 300));
      final SemanticsHandle semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);

      unawaited(showDialog<void>(
        context: tester.element(find.byType(Navigator).first),
        builder: (BuildContext context) => const AlertDialog(
          title: Text('Locale semantics'),
          actions: <Widget>[CloseButton()],
        ),
      ));
      await pumpFor(tester, const Duration(milliseconds: 200));
      final Finder closeControl = find.byType(CloseButton);
      expect(closeControl, findsOneWidget);
      expect(tester.getSemantics(closeControl).label, 'Đóng');

      osLocales
        ..clear()
        ..add(const Locale('en', 'US'));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpFor(tester, const Duration(milliseconds: 200));
      final Finder closeControlEn = find.byType(CloseButton);
      expect(closeControlEn, findsOneWidget);
      expect(tester.getSemantics(closeControlEn).label, 'Close');

      await tester.tap(closeControlEn);
      await pumpFor(tester, const Duration(milliseconds: 200));
      await tester.pumpWidget(const SizedBox.shrink());
      services.dispose();
      services.settings.dispose();
    });

    testWidgets('switching locale keeps the route and the text being typed',
        (WidgetTester tester) async {
      tester.platformDispatcher.localesTestValue = <Locale>[const Locale('vi', 'VN')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final AppServices services = await _openServices(tester);

      await tester.pumpWidget(
          PyQuestApp(servicesFactory: (_) async => services, minSplash: Duration.zero));
      await pumpFor(tester, const Duration(milliseconds: 600));

      final NavigatorState navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
      final TextEditingController typed = TextEditingController();
      addTearDown(typed.dispose);
      navigator.push<dynamic>(MaterialPageRoute<dynamic>(
        builder: (_) => Scaffold(body: TextField(controller: typed)),
      ));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'print("hi")');
      expect(typed.text, 'print("hi")');

      tester.platformDispatcher.localesTestValue = <Locale>[const Locale('en', 'US')];
      await pumpFor(tester, const Duration(milliseconds: 300));

      // Same Navigator object, same route, same in-flight input: a locale switch is a
      // rebuild, not a restart.
      expect(tester.state<NavigatorState>(find.byType(Navigator).first), same(navigator));
      expect(find.byType(TextField), findsOneWidget);
      expect(typed.text, 'print("hi")');
      expect(Localizations.localeOf(tester.element(find.byType(TextField))), const Locale('en'));
      expect(_materialOf(tester).cancelButtonLabel, 'Cancel');
    });

    test('generated foundation covers both supported languages', () {
      final List<String> supported =
          AppLocalizations.supportedLocales.map((Locale l) => l.languageCode).toList();
      expect(supported, contains('vi'));
      expect(supported, contains('en'));
    });
  });
}

Locale _localeOf(WidgetTester tester) =>
    Localizations.localeOf(tester.element(find.byType(Navigator).first));

MaterialLocalizations _materialOf(WidgetTester tester) =>
    MaterialLocalizations.of(tester.element(find.byType(Navigator).first));

Future<AppServices> _openServices(WidgetTester tester) async {
  final AppServices? services = await tester.runAsync(() => AppServices.create(
        bundle: rootBundle,
        databaseFactory: databaseFactoryFfiNoIsolate,
        databasePath: inMemoryDatabasePath,
        audioEnabled: false,
        startSessionTimer: false,
      ));
  return services!;
}

class _Fixture {
  _Fixture(this.database) : repository = SettingsRepository(database);

  final AppDatabase database;
  final SettingsRepository repository;

  SettingsService service() => SettingsService(repository);

  Future<void> close() => database.close();
}

Future<_Fixture> _openFixture(Map<String, String> rows) async {
  final AppDatabase database = await AppDatabase.open(
    factory: databaseFactoryFfiNoIsolate,
    path: inMemoryDatabasePath,
  );
  final _Fixture fixture = _Fixture(database);
  for (final MapEntry<String, String> row in rows.entries) {
    await fixture.repository.put(row.key, row.value);
  }
  return fixture;
}
