import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

    testWidgets('system preference follows the ordered OS list and never persists it',
        (WidgetTester tester) async {
      final _Fixture fixture = await tester.runAsync(() => _openFixture(const <String, String>{}))
          as _Fixture;
      addTearDown(() async {
        await tester.runAsync(fixture.close);
      });
      final SettingsService settings = fixture.service();
      addTearDown(settings.dispose);
      await tester.runAsync(settings.load);

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
      final Map<String, String>? rows = await tester.runAsync(fixture.repository.all);
      expect(rows?[SettingsService.localePreferenceKey], isNull);
    });

    testWidgets('an unsupported OS list falls back to English without writing a preference',
        (WidgetTester tester) async {
      final _Fixture fixture = await tester.runAsync(() => _openFixture(const <String, String>{}))
          as _Fixture;
      addTearDown(() async {
        await tester.runAsync(fixture.close);
      });
      final SettingsService settings = fixture.service();
      addTearDown(settings.dispose);
      await tester.runAsync(settings.load);

      final AppLocaleBinding binding = AppLocaleBinding(
        settings: settings,
        systemLocales: () => const <Locale>[Locale('fr', 'FR'), Locale('de')],
      );
      addTearDown(binding.dispose);
      binding.syncSystemLocales();

      expect(binding.locale, const Locale('en'));
      expect(settings.localeResolution.usedEnglishFallback, isTrue);
      expect(settings.lang, PqLang.en);
      final Map<String, String>? rows = await tester.runAsync(fixture.repository.all);
      expect(rows?[SettingsService.localePreferenceKey], isNull);
    });

    testWidgets('an explicit preference keeps winning while the OS list changes',
        (WidgetTester tester) async {
      final _Fixture fixture = await tester.runAsync(() => _openFixture(const <String, String>{}))
          as _Fixture;
      addTearDown(() async {
        await tester.runAsync(fixture.close);
      });
      final SettingsService settings = fixture.service();
      addTearDown(settings.dispose);
      await tester.runAsync(settings.load);

      final List<Locale> osList = <Locale>[const Locale('vi', 'VN')];
      final AppLocaleBinding binding =
          AppLocaleBinding(settings: settings, systemLocales: () => osList);
      addTearDown(binding.dispose);
      binding.syncSystemLocales();
      expect(
        await tester.runAsync(() => settings.setLocalePreference(LocalePreference.en)),
        isTrue,
      );
      expect(binding.locale, const Locale('en'));

      osList
        ..clear()
        ..add(const Locale('vi', 'VN'));
      binding.syncSystemLocales();
      expect(binding.locale, const Locale('en'));
      expect(settings.lang, PqLang.en);

      // Back to `system`: the OS list applies again, still without a new write.
      expect(
        await tester.runAsync(() => settings.setLocalePreference(LocalePreference.system)),
        isTrue,
      );
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

    for (final _FreshRootCase localeCase in _nonVietnameseFreshRootCases) {
      testWidgets(
        'fresh splash and loaded root resolve ${localeCase.name} without persisting the system locale',
        (WidgetTester tester) async {
          await _verifyFreshRootCase(tester, localeCase);
        },
      );
    }

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
      final Map<String, String>? systemRows =
          await tester.runAsync(() => SettingsRepository(services.db).all());
      expect(systemRows?[SettingsService.localePreferenceKey], isNull);

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
    });

    testWidgets('persisted override survives a recreated service and localization root',
        (WidgetTester tester) async {
      final Directory directory = await tester.runAsync(
          () => Directory.systemTemp.createTemp('pyquest-locale-recreate-')) as Directory;
      AppDatabase? database;
      SettingsService? original;
      SettingsService? recreated;
      AppLocaleBinding? binding;
      addTearDown(() async {
        try {
          await tester.pumpWidget(const SizedBox.shrink());
        } finally {
          try {
            binding?.dispose();
          } finally {
            try {
              original?.dispose();
            } finally {
              try {
                recreated?.dispose();
              } finally {
                try {
                  if (database != null) await tester.runAsync(database.close);
                } finally {
                  await tester.runAsync(() async {
                    if (await directory.exists()) await directory.delete(recursive: true);
                  });
                }
              }
            }
          }
        }
      });

      final AppDatabase openedDatabase = await tester.runAsync(() => AppDatabase.open(
            factory: databaseFactoryFfiNoIsolate,
            path: p.join(directory.path, 'pyquest.db'),
          )) as AppDatabase;
      database = openedDatabase;
      final _Fixture fixture = _Fixture(openedDatabase);
      original = fixture.service();
      await tester.runAsync(original.load);
      expect(
        await tester.runAsync(() => original!.setLocalePreference(LocalePreference.en)),
        isTrue,
      );
      expect(original.raw(SettingsService.localePreferenceKey), 'en');

      // Recreate the service against the real SQLite database; it must read the persisted
      // explicit choice rather than relying on the first service's in-memory state.
      recreated = fixture.service();
      expect(recreated, isNot(same(original)));
      await tester.runAsync(recreated.load);
      expect(recreated.localePreference, LocalePreference.en);

      final List<Locale> osLocales = <Locale>[const Locale('vi', 'VN')];
      binding = AppLocaleBinding(
        settings: recreated,
        systemLocales: () => List<Locale>.unmodifiable(osLocales),
      )..syncSystemLocales();
      await tester.pumpWidget(_localizedHost(binding));
      await pumpFor(tester, const Duration(milliseconds: 100));
      expect(_localeOf(tester), const Locale('en'));
      expect(_materialOf(tester).cancelButtonLabel, 'Cancel');

      expect(
        await tester.runAsync(() => recreated!.setLocalePreference(LocalePreference.system)),
        isTrue,
      );
      binding.syncSystemLocales();
      await pumpFor(tester, const Duration(milliseconds: 100));
      expect(_localeOf(tester), const Locale('vi'));
      expect(_materialOf(tester).cancelButtonLabel, 'Huỷ');
      expect(recreated.raw(SettingsService.localePreferenceKey), 'system');
      final Map<String, String>? persisted =
          await tester.runAsync(fixture.repository.all);
      expect(persisted?[SettingsService.localePreferenceKey], 'system');

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('persisted locale survives a fresh PyQuestApp and AppServices recreation',
        (WidgetTester tester) async {
      tester.platformDispatcher.localesTestValue = <Locale>[const Locale('vi', 'VN')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      final Directory directory = await tester.runAsync(
          () => Directory.systemTemp.createTemp('pyquest-app-restart-locale-')) as Directory;
      AppServices? firstServices;
      AppServices? secondServices;
      addTearDown(() async {
        try {
          await tester.pumpWidget(const SizedBox.shrink());
        } finally {
          try {
            if (secondServices != null) {
              await _disposeAndCloseServices(tester, secondServices);
            }
          } finally {
            try {
              if (firstServices != null) {
                await _disposeAndCloseServices(tester, firstServices);
              }
            } finally {
              await tester.runAsync(() async {
                if (await directory.exists()) await directory.delete(recursive: true);
              });
            }
          }
        }
      });

      final String databasePath = p.join(directory.path, AppDatabase.fileName);
      firstServices = await _createFileBackedServices(tester, databasePath);
      final AppServices first = firstServices;
      await tester.pumpWidget(
        PyQuestApp(servicesFactory: (_) async => first, minSplash: Duration.zero),
      );
      await pumpFor(tester, const Duration(milliseconds: 600));
      expect(_localeOf(tester), const Locale('vi'));
      expect(_materialOf(tester).cancelButtonLabel, 'Huỷ');
      expect(first.settings.raw(SettingsService.localePreferenceKey), isNull);
      final Map<String, String>? firstRows = await tester.runAsync(
          () => SettingsRepository(first.db).all());
      expect(firstRows?[SettingsService.localePreferenceKey], isNull);

      expect(
        await tester.runAsync(() => first.settings.setLocalePreference(LocalePreference.en)),
        isTrue,
      );
      await pumpFor(tester, const Duration(milliseconds: 150));
      expect(_localeOf(tester), const Locale('en'));
      expect(_materialOf(tester).cancelButtonLabel, 'Cancel');
      expect(first.settings.raw(SettingsService.localePreferenceKey), 'en');
      final Map<String, String>? englishRows = await tester.runAsync(
          () => SettingsRepository(first.db).all());
      expect(englishRows?[SettingsService.localePreferenceKey], 'en');

      // A real app restart: unmount, dispose every service, and close DB#1 before
      // AppServices.create opens the same file into a distinct DB#2 connection.
      await tester.pumpWidget(const SizedBox.shrink());
      await _disposeAndCloseServices(tester, first);
      firstServices = null;

      secondServices = await _createFileBackedServices(tester, databasePath);
      final AppServices second = secondServices;
      expect(second, isNot(same(first)));
      expect(second.db, isNot(same(first.db)));
      expect(second.settings, isNot(same(first.settings)));
      await tester.pumpWidget(
        PyQuestApp(servicesFactory: (_) async => second, minSplash: Duration.zero),
      );
      await pumpFor(tester, const Duration(milliseconds: 600));

      // Persisted EN wins over the fresh OS=VI input on the new app and service graph.
      expect(_localeOf(tester), const Locale('en'));
      expect(_materialOf(tester).cancelButtonLabel, 'Cancel');
      expect(second.settings.localePreference, LocalePreference.en);
      expect(second.settings.raw(SettingsService.localePreferenceKey), 'en');
      final Map<String, String>? reopenedRows = await tester.runAsync(
          () => SettingsRepository(second.db).all());
      expect(reopenedRows?[SettingsService.localePreferenceKey], 'en');

      expect(
        await tester.runAsync(() => second.settings.setLocalePreference(LocalePreference.system)),
        isTrue,
      );
      await pumpFor(tester, const Duration(milliseconds: 150));
      expect(_localeOf(tester), const Locale('vi'));
      expect(_materialOf(tester).cancelButtonLabel, 'Huỷ');
      expect(second.settings.localePreference, LocalePreference.system);
      expect(second.settings.raw(SettingsService.localePreferenceKey), 'system');
      final Map<String, String>? systemRows = await tester.runAsync(
          () => SettingsRepository(second.db).all());
      expect(systemRows?[SettingsService.localePreferenceKey], 'system');
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

    test('Flutter-generated localization output is committed and reproducible', () {
      final String appDirectory = Directory.current.path;
      final String repositoryRoot = File(p.join(appDirectory, 'pubspec.yaml')).existsSync()
          ? Directory(appDirectory).parent.path
          : appDirectory;
      final ProcessResult diff = Process.runSync(
        'git',
        <String>['diff', '--exit-code', '--', 'app/lib/l10n/generated'],
        workingDirectory: repositoryRoot,
      );
      expect(diff.exitCode, 0, reason: '${diff.stdout}${diff.stderr}');
      final ProcessResult status = Process.runSync(
        'git',
        <String>['status', '--porcelain', '--untracked-files=all', '--', 'app/lib/l10n/generated'],
        workingDirectory: repositoryRoot,
      );
      expect(status.exitCode, 0, reason: '${status.stderr}');
      expect(status.stdout, isEmpty, reason: 'gen-l10n must not create uncommitted output');

      final List<String> generatedFiles =
          Directory('lib/l10n/generated').listSync().whereType<File>().map((File f) => f.uri.pathSegments.last).toList()
            ..sort();
      expect(generatedFiles, <String>[
        'app_localizations.dart',
        'app_localizations_en.dart',
        'app_localizations_vi.dart',
      ]);
    });

    test('generated foundation covers both supported languages', () {
      final List<String> supported =
          AppLocalizations.supportedLocales.map((Locale l) => l.languageCode).toList();
      expect(supported, contains('vi'));
      expect(supported, contains('en'));
    });
  });
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
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) =>
                Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
        ),
      ),
    );

Locale _localeOf(WidgetTester tester) =>
    Localizations.localeOf(tester.element(find.byType(Navigator).first));

MaterialLocalizations _materialOf(WidgetTester tester) =>
    MaterialLocalizations.of(tester.element(find.byType(Navigator).first));

const List<_FreshRootCase> _nonVietnameseFreshRootCases = <_FreshRootCase>[
  _FreshRootCase(
    name: 'English en-US',
    systemLocale: Locale('en', 'US'),
    expectedLocale: Locale('en'),
    cancelLabel: 'Cancel',
    closeLabel: 'Close',
    greeting: 'Hello Pip!',
  ),
  _FreshRootCase(
    name: 'unsupported French fr-FR',
    systemLocale: Locale('fr', 'FR'),
    expectedLocale: Locale('en'),
    cancelLabel: 'Cancel',
    closeLabel: 'Close',
    greeting: 'Hello Pip!',
    expectsEnglishFallback: true,
  ),
];

Future<void> _verifyFreshRootCase(WidgetTester tester, _FreshRootCase localeCase) async {
  tester.platformDispatcher.localesTestValue = <Locale>[localeCase.systemLocale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  Directory? directory;
  AppServices? services;
  final Completer<AppServices> pendingServices = Completer<AppServices>();
  addTearDown(() async {
    try {
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      try {
        if (services != null) await _disposeAndCloseServices(tester, services);
      } finally {
        if (directory != null) {
          await tester.runAsync(() async {
            if (await directory.exists()) await directory.delete(recursive: true);
          });
        }
      }
    }
  });

  directory = await tester.runAsync(
      () => Directory.systemTemp.createTemp('pyquest-fresh-root-locale-')) as Directory;
  await tester.pumpWidget(
    PyQuestApp(
      servicesFactory: (_) => pendingServices.future,
      minSplash: Duration.zero,
    ),
  );
  await tester.pump();
  _expectFreshRootLocalization(tester, localeCase);

  final AppServices openedServices = await _createFileBackedServices(
    tester,
    p.join(directory.path, AppDatabase.fileName),
  );
  services = openedServices;
  pendingServices.complete(openedServices);
  await pumpFor(tester, const Duration(milliseconds: 600));
  _expectFreshRootLocalization(tester, localeCase);

  expect(openedServices.settings.localePreference, LocalePreference.system);
  expect(openedServices.settings.raw(SettingsService.localePreferenceKey), isNull);
  expect(openedServices.settings.localeResolution.usedEnglishFallback,
      localeCase.expectsEnglishFallback);
  final Map<String, String>? rows = await tester.runAsync(
      () => SettingsRepository(openedServices.db).all());
  expect(rows?[SettingsService.localePreferenceKey], isNull);
}

void _expectFreshRootLocalization(WidgetTester tester, _FreshRootCase localeCase) {
  expect(_localeOf(tester), localeCase.expectedLocale);
  expect(_materialOf(tester).cancelButtonLabel, localeCase.cancelLabel);
  expect(_materialOf(tester).closeButtonLabel, localeCase.closeLabel);
  final AppLocalizations? l10n = AppLocalizations.of(
    tester.element(find.byType(Navigator).first),
  );
  expect(l10n, isNotNull);
  expect(l10n!.localeName, localeCase.expectedLocale.languageCode);
  expect(l10n.foundationGreeting('Pip'), localeCase.greeting);
}

Future<AppServices> _createFileBackedServices(
  WidgetTester tester,
  String databasePath,
) async {
  final AppServices? services = await tester.runAsync(() => AppServices.create(
        bundle: rootBundle,
        databaseFactory: databaseFactoryFfiNoIsolate,
        databasePath: databasePath,
        audioEnabled: false,
        startSessionTimer: false,
      ));
  return services as AppServices;
}

Future<void> _disposeAndCloseServices(WidgetTester tester, AppServices services) async {
  try {
    services.dispose();
  } finally {
    try {
      services.settings.dispose();
    } finally {
      await tester.runAsync(services.db.close);
    }
  }
}

class _FreshRootCase {
  const _FreshRootCase({
    required this.name,
    required this.systemLocale,
    required this.expectedLocale,
    required this.cancelLabel,
    required this.closeLabel,
    required this.greeting,
    this.expectsEnglishFallback = false,
  });

  final String name;
  final Locale systemLocale;
  final Locale expectedLocale;
  final String cancelLabel;
  final String closeLabel;
  final String greeting;
  final bool expectsEnglishFallback;
}

Future<AppServices> _openServices(WidgetTester tester) async {
  final AppServices? services = await tester.runAsync(() => AppServices.create(
        bundle: rootBundle,
        databaseFactory: databaseFactoryFfiNoIsolate,
        databasePath: inMemoryDatabasePath,
        audioEnabled: false,
        startSessionTimer: false,
      ));
  final AppServices opened = services!;
  addTearDown(() async {
    try {
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      try {
        opened.dispose();
      } finally {
        try {
          opened.settings.dispose();
        } finally {
          await tester.runAsync(opened.db.close);
        }
      }
    }
  });
  return opened;
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
