import 'dart:async';
import 'dart:io';
import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pyquest/app/app_scope.dart';
import 'package:pyquest/app/app_services.dart';
import 'package:pyquest/app/pyquest_app.dart';
import 'package:pyquest/app/settings_sheet.dart';
import 'package:pyquest/core/localization/locale_preference.dart';
import 'package:pyquest/core/settings_service.dart';
import 'package:pyquest/data/database/app_database.dart';
import 'package:pyquest/data/repositories/state_repositories.dart';
import 'package:pyquest/l10n/generated/app_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  setUpAll(loadAppFonts);

  for (final _RootLocaleCase localeCase in _rootLocaleCases) {
    testWidgets(
      'real Settings sheet follows ${localeCase.name} without storing the resolved language',
      (WidgetTester tester) async {
        tester.platformDispatcher.localesTestValue = <Locale>[localeCase.systemLocale];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        final AppServices services = await _openServices(tester);
        await _mountPyQuest(tester, services);

        expect(_rootLocale(tester), localeCase.effectiveLocale);
        expect(_rootMaterial(tester).cancelButtonLabel, localeCase.cancelLabel);
        expect(services.settings.localePreference, LocalePreference.system);
        expect(services.settings.localePreferenceSaved, isFalse);
        expect(services.settings.localePreferenceSaveError, isNull);
        expect(services.settings.raw(SettingsService.localePreferenceKey), isNull);

        await _openSettings(tester);
        _expectSettingsBaseCopy(tester, localeCase.effectiveLocale.languageCode);
        _expectOneSelectedRadio(tester, LocalePreference.system);
        expect(find.text(localeCase.activeLine), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('language_saving')), findsNothing);
        expect(find.byKey(const ValueKey<String>('language_save_error')), findsNothing);
        expect(find.byKey(const ValueKey<String>('language_retry')), findsNothing);
        expect(
          find.byKey(const ValueKey<String>('language_fallback')),
          localeCase.fallback ? findsOneWidget : findsNothing,
        );
        if (localeCase.fallback) {
          expect(find.text(localeCase.fallbackCopy), findsOneWidget);
          expect(find.text('English'), findsOneWidget);
        } else {
          expect(find.byKey(const ValueKey<String>('language_fallback')), findsNothing);
        }

        expect(services.settings.raw(SettingsService.localePreferenceKey), isNull);
        expect(
          (await _settingsRows(tester, services))[SettingsService.localePreferenceKey],
          isNull,
        );
        expect(tester.takeException(), isNull);
      },
      semanticsEnabled: true,
    );
  }

  testWidgets('UI choices apply immediately and preserve the open route, toggles, and progress',
      (WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = <Locale>[const Locale('vi', 'VN')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final AppServices services = await _openServices(tester);
    await tester.runAsync(() async {
      await services.settings.setSoundOn(false);
      await services.settings.setMusicOn(true);
      await services.settings.setCalmMode(true);
      await services.db.db.insert('progress', <String, Object?>{
        'lesson_id': 'settings-locale-preserve-fixture',
        'best_score': 3,
        'completed_at': 1,
      });
    });
    await _mountPyQuest(tester, services);

    final NavigatorState navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    await _openSettings(tester);
    _expectOneSelectedRadio(tester, LocalePreference.system);
    _expectToggle(tester, 'toggle_sound', 'Âm thanh hiệu ứng', isToggled: false);
    _expectToggle(tester, 'toggle_music', 'Nhạc nền', isToggled: true);
    _expectToggle(tester, 'toggle_calm', 'Chế độ êm dịu (ít chuyển động)', isToggled: true);

    await _chooseLocale(tester, LocalePreference.en);
    _expectSettingsBaseCopy(tester, 'en');
    expect(_rootLocale(tester), const Locale('en'));
    expect(_rootMaterial(tester).cancelButtonLabel, 'Cancel');
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Currently using: English'), findsOneWidget);
    _expectOneSelectedRadio(tester, LocalePreference.en);
    expect(find.byKey(const ValueKey<String>('settings_language_panel')), findsOneWidget);
    expect(tester.state<NavigatorState>(find.byType(Navigator).first), same(navigator));

    await _chooseLocale(tester, LocalePreference.vi);
    _expectSettingsBaseCopy(tester, 'vi');
    expect(_rootLocale(tester), const Locale('vi'));
    expect(find.text('Đang dùng: Tiếng Việt'), findsOneWidget);
    _expectOneSelectedRadio(tester, LocalePreference.vi);

    await _chooseLocale(tester, LocalePreference.system);
    expect(_rootLocale(tester), const Locale('vi'));
    expect(find.text('Đang dùng: Tiếng Việt'), findsOneWidget);
    _expectOneSelectedRadio(tester, LocalePreference.system);
    expect(services.settings.raw(SettingsService.localePreferenceKey), 'system');
    expect(
      (await _settingsRows(tester, services))[SettingsService.localePreferenceKey],
      'system',
    );
    expect(services.settings.soundOn, isFalse);
    expect(services.settings.musicOn, isTrue);
    expect(services.settings.calmMode, isTrue);
    expect(
      await tester.runAsync(() => services.db.db.query(
            'progress',
            where: 'lesson_id = ?',
            whereArgs: <Object?>['settings-locale-preserve-fixture'],
          )),
      hasLength(1),
    );
    _expectToggle(tester, 'toggle_sound', 'Âm thanh hiệu ứng', isToggled: false);
    _expectToggle(tester, 'toggle_music', 'Nhạc nền', isToggled: true);
    _expectToggle(tester, 'toggle_calm', 'Chế độ êm dịu (ít chuyển động)', isToggled: true);
    expect(tester.takeException(), isNull);
  }, semanticsEnabled: true);

  testWidgets('a failed locale write stays selected and Retry reflects the real database result',
      (WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = <Locale>[const Locale('vi', 'VN')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final AppServices services = await _openServices(tester);
    await tester.runAsync(() => services.settings.setLocalePreference(LocalePreference.en));
    await tester.runAsync(() => services.db.db.execute('''
      CREATE TRIGGER reject_settings_locale
      BEFORE INSERT ON settings
      WHEN NEW.key = '${SettingsService.localePreferenceKey}'
      BEGIN
        SELECT RAISE(ABORT, 'locale write rejected for test');
      END
    '''));
    await _mountPyQuest(tester, services);
    expect(_rootLocale(tester), const Locale('en'));
    await _openSettings(tester);

    await _chooseLocale(tester, LocalePreference.vi);
    await pumpFor(tester, const Duration(milliseconds: 250));
    expect(_rootLocale(tester), const Locale('vi'));
    expect(_rootMaterial(tester).cancelButtonLabel, 'Huỷ');
    expect(services.settings.localePreference, LocalePreference.vi);
    expect(services.settings.localePreferenceSaveError, isNotNull);
    expect(find.text(_viSaveFailure), findsOneWidget);
    expect(find.text('Thử lưu lại'), findsOneWidget);
    _expectOneSelectedRadio(tester, LocalePreference.vi);
    expect(
      (await _settingsRows(tester, services))[SettingsService.localePreferenceKey],
      'en',
    );

    await tester.runAsync(() => services.db.db.execute('DROP TRIGGER reject_settings_locale'));
    await _tapVisible(tester, find.byKey(const ValueKey<String>('language_retry')));
    await pumpFor(tester, const Duration(milliseconds: 350));
    expect(_rootLocale(tester), const Locale('vi'));
    expect(services.settings.localePreferenceSaved, isTrue);
    expect(services.settings.localePreferenceSaveError, isNull);
    expect(find.byKey(const ValueKey<String>('language_save_error')), findsNothing);
    expect(find.byKey(const ValueKey<String>('language_retry')), findsNothing);
    expect(
      (await _settingsRows(tester, services))[SettingsService.localePreferenceKey],
      'vi',
    );

    await tester.pageBack();
    await pumpFor(tester, const Duration(milliseconds: 250));
    await _openSettings(tester);
    _expectOneSelectedRadio(tester, LocalePreference.vi);
    expect(find.byKey(const ValueKey<String>('language_save_error')), findsNothing);
    expect(tester.takeException(), isNull);
  }, semanticsEnabled: true);

  testWidgets('the real Settings chooser persists EN across an AppServices and PyQuestApp restart',
      (WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = <Locale>[const Locale('vi', 'VN')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final Directory directory = await tester.runAsync(
        () => Directory.systemTemp.createTemp('pyquest-settings-restart-')) as Directory;
    AppServices? firstServices;
    AppServices? secondServices;
    AppServices? thirdServices;
    addTearDown(() async {
      try {
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        try {
          if (thirdServices != null) await _disposeServices(tester, thirdServices);
        } finally {
          try {
            if (secondServices != null) await _disposeServices(tester, secondServices);
          } finally {
            try {
              if (firstServices != null) await _disposeServices(tester, firstServices);
            } finally {
              await tester.runAsync(() async {
                if (await directory.exists()) await directory.delete(recursive: true);
              });
            }
          }
        }
      }
    });

    final String databasePath = p.join(directory.path, AppDatabase.fileName);
    firstServices = await _createServices(tester, databasePath: databasePath);
    final AppServices first = firstServices;
    await _mountPyQuest(tester, first);
    await _openSettings(tester);
    await _chooseLocale(tester, LocalePreference.en);
    expect(_rootLocale(tester), const Locale('en'));
    expect(
      (await _settingsRows(tester, first))[SettingsService.localePreferenceKey],
      'en',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await _disposeServices(tester, first);
    firstServices = null;

    secondServices = await _createServices(tester, databasePath: databasePath);
    final AppServices second = secondServices;
    expect(second, isNot(same(first)));
    expect(second.db, isNot(same(first.db)));
    expect(second.settings, isNot(same(first.settings)));
    await _mountPyQuest(tester, second);
    expect(_rootLocale(tester), const Locale('en'));
    await _openSettings(tester);
    _expectOneSelectedRadio(tester, LocalePreference.en);
    expect(find.text('Currently using: English'), findsOneWidget);

    await _chooseLocale(tester, LocalePreference.system);
    expect(_rootLocale(tester), const Locale('vi'));
    expect(second.settings.localePreference, LocalePreference.system);
    expect(
      (await _settingsRows(tester, second))[SettingsService.localePreferenceKey],
      'system',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await _disposeServices(tester, second);
    secondServices = null;
    thirdServices = await _createServices(tester, databasePath: databasePath);
    final AppServices third = thirdServices;
    await _mountPyQuest(tester, third);
    expect(_rootLocale(tester), const Locale('vi'));
    await _openSettings(tester);
    _expectOneSelectedRadio(tester, LocalePreference.system);
    expect(find.text('Đang dùng: Tiếng Việt'), findsOneWidget);
    expect(
      (await _settingsRows(tester, third))[SettingsService.localePreferenceKey],
      'system',
      reason: 'the stored preference survives recreation as literal system, not its resolved VI locale',
    );
    expect(tester.takeException(), isNull);
  }, semanticsEnabled: true);

  testWidgets('overlapping UI saves keep the latest request authoritative and survive sheet disposal',
      (WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = <Locale>[const Locale('vi', 'VN')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final Directory directory = await tester.runAsync(
        () => Directory.systemTemp.createTemp('pyquest-settings-race-')) as Directory;
    final String databasePath = p.join(directory.path, AppDatabase.fileName);
    final AppServices services = await _createServices(tester, databasePath: databasePath);
    _LockedWriteDatabase? lock;
    addTearDown(() async {
      try {
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        try {
          if (lock != null) await _releaseWriteLock(tester, lock);
        } finally {
          try {
            await _disposeServices(tester, services);
          } finally {
            await tester.runAsync(() async {
              if (await directory.exists()) await directory.delete(recursive: true);
            });
          }
        }
      }
    });

    services.settings.updateSystemLocales(<String>['vi-VN']);
    await tester.runAsync(() => services.db.db.execute('''
      CREATE TRIGGER reject_first_locale_request
      BEFORE INSERT ON settings
      WHEN NEW.key = '${SettingsService.localePreferenceKey}' AND NEW.value = 'en'
      BEGIN
        SELECT RAISE(ABORT, 'stale locale write rejected');
      END
    '''));
    await tester.pumpWidget(_settingsComponentHost(services));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('settings_component_open')));
    await pumpFor(tester, const Duration(milliseconds: 300));

    lock = await _holdWriteLock(tester, databasePath);
    await _chooseLocale(tester, LocalePreference.en);
    expect(_rootLocale(tester), const Locale('en'));
    expect(find.text('Saving your choice…'), findsOneWidget);
    await _chooseLocale(tester, LocalePreference.vi);
    expect(_rootLocale(tester), const Locale('vi'));
    expect(find.text('Đang lưu lựa chọn…'), findsOneWidget);
    _expectOneSelectedRadio(tester, LocalePreference.vi);

    await _releaseWriteLock(tester, lock);
    lock = null;
    await pumpFor(tester, const Duration(milliseconds: 300));
    final Map<String, String> afterRace = await _settingsRows(tester, services);
    expect(afterRace[SettingsService.localePreferenceKey], 'vi');
    expect(services.settings.localePreference, LocalePreference.vi);
    expect(services.settings.localePreferenceSaveError, isNull,
        reason: 'the late failure from the older EN request must not own current status');
    expect(find.byKey(const ValueKey<String>('language_saving')), findsNothing);
    expect(find.byKey(const ValueKey<String>('language_save_error')), findsNothing);
    expect(find.text('Đang dùng: Tiếng Việt'), findsOneWidget);

    // Start one more deliberately pending request, pop the sheet before its Future settles, then
    // let the injected write failure arrive. The unmounted panel must not call setState afterward.
    lock = await _holdWriteLock(tester, databasePath);
    await _chooseLocale(tester, LocalePreference.en);
    expect(find.text('Saving your choice…'), findsOneWidget);
    await tester.pageBack();
    await pumpFor(tester, const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey<String>('settings_language_panel')), findsNothing);
    await _releaseWriteLock(tester, lock);
    lock = null;
    await _settingsRows(tester, services);
    await pumpFor(tester, const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey<String>('settings_component_open')));
    await pumpFor(tester, const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey<String>('language_save_error')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('language_retry')), findsOneWidget);
    expect(find.text('Your choice could not be saved. It still applies for now; next time, PyQuest may use your previously saved choice.'), findsOneWidget);
  }, semanticsEnabled: true);

  testWidgets('Python information and parent gate localize live without losing the gate input',
      (WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = <Locale>[const Locale('vi', 'VN')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final AppServices services = await _openServices(tester);
    await tester.runAsync(() => services.db.db.insert('progress', <String, Object?>{
      'lesson_id': 'parent-gate-preserve-fixture',
      'best_score': 2,
      'completed_at': 1,
    }));
    await _mountPyQuest(tester, services);
    await _openSettings(tester);

    await _tapVisible(tester, find.byKey(const ValueKey<String>('settings_about_python')));
    await pumpFor(tester, const Duration(milliseconds: 300));
    _expectPythonCopy(tester, 'vi');

    tester.platformDispatcher.localesTestValue = <Locale>[const Locale('en', 'US')];
    await pumpFor(tester, const Duration(milliseconds: 350));
    expect(_rootLocale(tester), const Locale('en'));
    expect(services.settings.localePreference, LocalePreference.system);
    expect(find.text('Currently using: English'), findsOneWidget);
    _expectPythonCopy(tester, 'en');
    await tester.ensureVisible(find.text(_pythonEnCopy.last));
    await tester.pump();
    expect(tester.takeException(), isNull);
    final Finder pythonContents = find.byKey(const ValueKey<String>('python_info_sheet'));
    expect(
      find.descendant(of: pythonContents, matching: find.textContaining(_fStringLiteral)),
      findsOneWidget,
      reason: 'the example code is intentionally a Vietnamese Python literal in both locales',
    );
    for (final String viOnly in _pythonViCopy.where(
      (String text) => text != _fStringLiteral && !_pythonEnCopy.contains(text),
    )) {
      expect(find.descendant(of: pythonContents, matching: find.text(viOnly)), findsNothing);
    }
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await pumpFor(tester, const Duration(milliseconds: 250));
    await _tapVisible(tester, find.byKey(const ValueKey<String>('settings_reset_progress')));
    await pumpFor(tester, const Duration(milliseconds: 250));
    _expectParentCopy(tester, 'en');
    await tester.enterText(find.byKey(const ValueKey<String>('parent_gate_field')), '0');
    await _tapVisible(tester, find.text('Delete'));
    await pumpFor(tester, const Duration(milliseconds: 250));
    expect(find.byKey(const ValueKey<String>('parent_gate_field')), findsNothing);
    expect(find.byKey(const ValueKey<String>('settings_language_panel')), findsOneWidget);
    expect(
      await tester.runAsync(() => services.db.db.query(
            'progress',
            where: 'lesson_id = ?',
            whereArgs: <Object?>['parent-gate-preserve-fixture'],
          )),
      hasLength(1),
      reason: 'a wrong answer must not reset progress',
    );

    await _tapVisible(tester, find.byKey(const ValueKey<String>('settings_reset_progress')));
    await pumpFor(tester, const Duration(milliseconds: 250));
    final String question = tester.widget<Text>(
      find.byKey(const ValueKey<String>('settings_parent_question')),
    ).data!;
    final RegExpMatch match = RegExp(r'(\d+)\s*×\s*(\d+)').firstMatch(question)!;
    final String answer = '${int.parse(match[1]!) * int.parse(match[2]!)}';
    await tester.enterText(find.byKey(const ValueKey<String>('parent_gate_field')), answer);

    tester.platformDispatcher.localesTestValue = <Locale>[const Locale('vi', 'VN')];
    await pumpFor(tester, const Duration(milliseconds: 350));
    expect(_rootLocale(tester), const Locale('vi'));
    expect(services.settings.localePreference, LocalePreference.system);
    _expectParentCopy(tester, 'vi');
    expect(
      tester.widget<TextField>(find.byKey(const ValueKey<String>('parent_gate_field'))).controller?.text,
      answer,
      reason: 'changing the OS locale rebuilds the open parent dialog without dropping input',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey<String>('settings_parent_question'))).data,
      question,
      reason: 'the same multiplication operands survive the localized dialog rebuild',
    );

    await _tapVisible(tester, find.text('Xoá'));
    await pumpFor(tester, const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey<String>('parent_gate_field')), findsNothing);
    expect(find.byKey(const ValueKey<String>('settings_language_panel')), findsNothing);
    expect(
      await tester.runAsync(() => services.db.db.query(
            'progress',
            where: 'lesson_id = ?',
            whereArgs: <Object?>['parent-gate-preserve-fixture'],
          )),
      isEmpty,
      reason: 'a correct answer must call the existing reset flow',
    );
    expect(tester.takeException(), isNull);
  });

  for (final _ViewportCase viewportCase in _viewportCases) {
    testWidgets(
      'Settings fits ${viewportCase.name} at text scale ${viewportCase.textScale}',
      (WidgetTester tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = viewportCase.logicalSize;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = viewportCase.textScale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final AppServices services = await _openServices(tester);
        await tester.runAsync(() => services.settings.load(systemLocales: <String>['vi-VN']));
        if (viewportCase.locale.isExplicit) {
          await tester.runAsync(() => services.settings.setLocalePreference(viewportCase.locale));
        }
        await tester.pumpWidget(_settingsComponentHost(services));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey<String>('settings_component_open')));
        await pumpFor(tester, const Duration(milliseconds: 300));

        expect(find.byKey(const ValueKey<String>('settings_language_panel')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('language_system')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('language_vi')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('language_en')), findsOneWidget);
        _expectOneSelectedRadio(tester, viewportCase.locale);
        await tester.ensureVisible(find.byKey(const ValueKey<String>('settings_about_python')));
        await tester.pump();
        expect(find.byKey(const ValueKey<String>('settings_about_python')), findsOneWidget);
        await tester.ensureVisible(find.byKey(const ValueKey<String>('settings_reset_progress')));
        await tester.pump();
        expect(find.byKey(const ValueKey<String>('settings_reset_progress')), findsOneWidget);
        await tester.ensureVisible(find.byKey(const ValueKey<String>('settings_footer')));
        await tester.pump();
        final Rect footerRect = tester.getRect(find.byKey(const ValueKey<String>('settings_footer')));
        expect(footerRect.top, greaterThanOrEqualTo(0));
        expect(footerRect.bottom, lessThanOrEqualTo(viewportCase.logicalSize.height));
        expect(tester.takeException(), isNull);
      },
      semanticsEnabled: true,
    );
  }

  testWidgets('uncapped scale 2.0 keeps radio choices and Retry reachable on a short screen',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final AppServices services = await _openServices(tester);
    await tester.runAsync(() => services.settings.setLocalePreference(LocalePreference.en));
    await tester.runAsync(() => services.db.db.execute('''
      CREATE TRIGGER reject_locale_scale
      BEFORE INSERT ON settings
      WHEN NEW.key = '${SettingsService.localePreferenceKey}'
      BEGIN
        SELECT RAISE(ABORT, 'scale retry fixture');
      END
    '''));
    await tester.runAsync(() => services.db.db.execute('''
      CREATE TRIGGER reject_locale_scale_update
      BEFORE UPDATE ON settings
      WHEN NEW.key = '${SettingsService.localePreferenceKey}'
      BEGIN
        SELECT RAISE(ABORT, 'scale retry fixture');
      END
    '''));
    await tester.pumpWidget(_settingsComponentHost(services));
    await tester.pump();
    expect(MediaQuery.textScalerOf(tester.element(find.byKey(const ValueKey<String>('settings_component_open')))).scale(1), 2.0);
    await tester.tap(find.byKey(const ValueKey<String>('settings_component_open')));
    await pumpFor(tester, const Duration(milliseconds: 300));
    await _tapVisible(tester, find.byKey(const ValueKey<String>('language_vi')));
    await pumpFor(tester, const Duration(milliseconds: 350));
    _expectOneSelectedRadio(tester, LocalePreference.vi);
    await tester.ensureVisible(find.byKey(const ValueKey<String>('language_retry')));
    await tester.pump();

    expect(find.byKey(const ValueKey<String>('language_system')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('language_vi')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('language_en')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('language_retry')), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, semanticsEnabled: true);
}

const List<_RootLocaleCase> _rootLocaleCases = <_RootLocaleCase>[
  _RootLocaleCase(
    name: 'Vietnamese system locale',
    systemLocale: Locale('vi', 'VN'),
    effectiveLocale: Locale('vi'),
    cancelLabel: 'Huỷ',
    activeLine: 'Đang dùng: Tiếng Việt',
  ),
  _RootLocaleCase(
    name: 'unsupported system locale',
    systemLocale: Locale('fr', 'FR'),
    effectiveLocale: Locale('en'),
    cancelLabel: 'Cancel',
    activeLine: 'Currently using: English',
    fallback: true,
    fallbackCopy: 'Your device language is not supported yet. PyQuest is using English.',
  ),
];

const String _fStringLiteral = 'f"Xin chào {ten}"';
const String _viSaveFailure =
    'Chưa lưu được lựa chọn. Ngôn ngữ vẫn được dùng trong lần mở này; lần mở sau có thể trở về lựa chọn đã lưu trước đó.';

const List<String> _pythonViCopy = <String>[
  'PyQuest Python (mô phỏng)',
  'Code của bạn chạy trên một phiên bản Python thu nhỏ được viết riêng cho PyQuest, ngay trên máy, không cần mạng. Nó giống Python thật ở những phần cơ bản nhưng KHÔNG phải Python đầy đủ.',
  'Bạn có thể dùng',
  'print(), biến, số nguyên, số thập phân, chuỗi chữ, True/False, None',
  'Phép tính + - * / // % ** và so sánh == != < > <= >=, and/or/not',
  'if / elif / else, while, for ... in range(...), break, continue',
  'Danh sách: [1, 2, 3], ds[0], ds.append(), len(), in',
  'Hàm: def, return, tham số mặc định',
  'f-string đơn giản, ví dụ: f"Xin chào {ten}"',
  'Lệnh có sẵn: len, range, str, int, float, bool, abs, round, min, max, sum, list, sorted, type',
  'Giới hạn',
  'Không có import, file, mạng, input(), class, dictionary, tuple, cắt chuỗi [a:b], try/except, lambda.',
  'Tối đa 100.000 bước chạy — vòng lặp vô tận sẽ được dừng an toàn.',
  'Hàm gọi lồng nhau tối đa 50 tầng; in ra tối đa 10.000 ký tự.',
  'Số nguyên giới hạn khoảng ±9 tỉ tỉ (Python thật không giới hạn).',
  'Kết quả hiện ra sau khi chương trình chạy xong, không hiện từng dòng theo thời gian thực.',
  'Không cho đặt tên biến trùng print, len, range để tránh lỗi khó hiểu.',
];

const List<String> _pythonEnCopy = <String>[
  'PyQuest Python (simulated)',
  'Your code runs on a small Python implementation made for PyQuest, on this device and without a network connection. It supports the basics, but it is NOT full Python.',
  'You can use',
  'print(), variables, integers, decimal numbers, strings, True/False, None',
  'Arithmetic + - * / // % **, comparisons == != < > <= >=, and/or/not',
  'if / elif / else, while, for ... in range(...), break, continue',
  'Lists: [1, 2, 3], ds[0], ds.append(), len(), in',
  'Functions: def, return, default arguments',
  'Simple f-strings, for example: f"Xin chào {ten}"',
  'Built-ins: len, range, str, int, float, bool, abs, round, min, max, sum, list, sorted, type',
  'Limits',
  'No import, files, networking, input(), class, dictionary, tuple, slicing [a:b], try/except or lambda.',
  'Up to 100,000 execution steps — endless loops are stopped safely.',
  'Up to 50 nested function calls and 10,000 output characters.',
  'Integers are limited to about ±9 quintillion (standard Python integers have no fixed size limit).',
  'Output appears after the program finishes, not line by line in real time.',
  'Variable names cannot shadow print, len or range, to help avoid confusing errors.',
];

const List<String> _parentViCopy = <String>[
  'Dành cho bố mẹ',
  'Thao tác này xoá tiến trình, huy hiệu, mê cung tự tạo và đặt lại cài đặt trên thiết bị này. Để tiếp tục, hãy nhập kết quả:',
  'Kết quả',
  'Huỷ',
  'Xoá',
];

const List<String> _parentEnCopy = <String>[
  'For parents',
  'This deletes progress, badges and custom mazes, and resets settings on this device. To continue, enter the answer:',
  'Answer',
  'Cancel',
  'Delete',
];

class _RootLocaleCase {
  const _RootLocaleCase({
    required this.name,
    required this.systemLocale,
    required this.effectiveLocale,
    required this.cancelLabel,
    required this.activeLine,
    this.fallback = false,
    this.fallbackCopy = '',
  });

  final String name;
  final Locale systemLocale;
  final Locale effectiveLocale;
  final String cancelLabel;
  final String activeLine;
  final bool fallback;
  final String fallbackCopy;
}

class _ViewportCase {
  const _ViewportCase(this.name, this.logicalSize, this.textScale, this.locale);

  final String name;
  final Size logicalSize;
  final double textScale;
  final LocalePreference locale;
}

const List<_ViewportCase> _viewportCases = <_ViewportCase>[
  _ViewportCase('360x640 VI', Size(360, 640), 1.0, LocalePreference.vi),
  _ViewportCase('360x640 EN', Size(360, 640), 1.0, LocalePreference.en),
  _ViewportCase('390x844 VI', Size(390, 844), 1.0, LocalePreference.vi),
  _ViewportCase('390x844 EN', Size(390, 844), 1.0, LocalePreference.en),
];

Future<AppServices> _createServices(WidgetTester tester, {String? databasePath}) async {
  final AppServices? services = await tester.runAsync(() => AppServices.create(
        bundle: rootBundle,
        databaseFactory: databaseFactoryFfiNoIsolate,
        databasePath: databasePath ?? inMemoryDatabasePath,
        audioEnabled: false,
        startSessionTimer: false,
      ));
  return services as AppServices;
}

Future<AppServices> _openServices(WidgetTester tester) async {
  final AppServices services = await _createServices(tester);
  addTearDown(() async {
    try {
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      await _disposeServices(tester, services);
    }
  });
  return services;
}

Future<void> _disposeServices(WidgetTester tester, AppServices services) async {
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

Future<void> _mountPyQuest(WidgetTester tester, AppServices services) async {
  await tester.pumpWidget(
    PyQuestApp(servicesFactory: (_) async => services, minSplash: Duration.zero),
  );
  await pumpFor(tester, const Duration(milliseconds: 600));
}

Future<void> _openSettings(WidgetTester tester) async {
  final Finder button = find.byKey(const ValueKey<String>('settings_button')).first;
  await tester.ensureVisible(button);
  await tester.pump();
  // Match the working root-navigation tap used by the existing render suite.
  await tester.tap(button, warnIfMissed: false);
  await pumpFor(tester, const Duration(milliseconds: 900));
  expect(find.byKey(const ValueKey<String>('settings_language_panel')), findsOneWidget);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

Future<void> _chooseLocale(WidgetTester tester, LocalePreference preference) async {
  await _tapVisible(tester, find.byKey(ValueKey<String>('language_${preference.storageValue}')));
  await pumpFor(tester, const Duration(milliseconds: 250));
}

Future<_LockedWriteDatabase> _holdWriteLock(WidgetTester tester, String path) async {
  final Database lockDatabase = await tester.runAsync(
        () => databaseFactoryFfiNoIsolate.openDatabase(
          path,
          options: OpenDatabaseOptions(singleInstance: false),
        ),
      ) as Database;
  final Completer<void> acquired = Completer<void>();
  final Completer<void> release = Completer<void>();
  final Future<void> transaction = lockDatabase.transaction<void>((Transaction txn) async {
    await txn.update(
      'settings',
      <String, Object?>{'value': '1'},
      where: 'key = ?',
      whereArgs: <Object?>['schema_version'],
    );
    acquired.complete();
    await release.future;
  });
  await tester.runAsync(() => acquired.future);
  return _LockedWriteDatabase(lockDatabase, release, transaction);
}

Future<void> _releaseWriteLock(WidgetTester tester, _LockedWriteDatabase lock) async {
  if (!lock.release.isCompleted) lock.release.complete();
  await tester.runAsync(() async {
    await lock.transaction;
    await lock.database.close();
  });
}

class _LockedWriteDatabase {
  const _LockedWriteDatabase(this.database, this.release, this.transaction);

  final Database database;
  final Completer<void> release;
  final Future<void> transaction;
}

Future<Map<String, String>> _settingsRows(WidgetTester tester, AppServices services) async {
  final Map<String, String>? rows = await tester.runAsync(
    () => SettingsRepository(services.db).all(),
  );
  return rows ?? <String, String>{};
}

Locale _rootLocale(WidgetTester tester) =>
    Localizations.localeOf(tester.element(find.byType(Navigator).first));

MaterialLocalizations _rootMaterial(WidgetTester tester) =>
    MaterialLocalizations.of(tester.element(find.byType(Navigator).first));

void _expectOneSelectedRadio(WidgetTester tester, LocalePreference expected) {
  final Map<LocalePreference, bool> checked = <LocalePreference, bool>{};
  for (final LocalePreference preference in LocalePreference.values) {
    final data = tester
        .getSemantics(find.byKey(ValueKey<String>('language_${preference.storageValue}')))
        .getSemanticsData();
    expect(data.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
    expect(data.flagsCollection.isChecked, isNot(CheckedState.none));
    checked[preference] = data.flagsCollection.isChecked == CheckedState.isTrue;
  }
  expect(checked.values.where((bool value) => value), hasLength(1));
  expect(checked[expected], isTrue);
}

void _expectToggle(
  WidgetTester tester,
  String key,
  String label, {
  required bool isToggled,
}) {
  final data = tester.getSemantics(find.byKey(ValueKey<String>(key))).getSemanticsData();
  expect(data.label, label);
  expect(data.flagsCollection.isToggled, isNot(Tristate.none));
  expect(data.flagsCollection.isToggled == Tristate.isTrue, isToggled);
}

const List<String> _settingsViCopy = <String>[
  'Cài đặt',
  'Ngôn ngữ',
  'Theo hệ thống',
  'Tiếng Việt',
  'English',
  'Cài đặt và giao diện hệ thống đổi ngôn ngữ ngay. Một số nội dung khác đang được bổ sung bản dịch.',
  'Âm thanh hiệu ứng',
  'Nhạc nền',
  'Chế độ êm dịu (ít chuyển động)',
  'Về PyQuest Python',
  'Xoá toàn bộ tiến trình',
  'PyQuest 0.1 · Đảo Khởi Đầu. Tiến trình được lưu trên thiết bị này.',
];

const List<String> _settingsEnCopy = <String>[
  'Settings',
  'Language',
  'Follow device',
  'Tiếng Việt',
  'English',
  'Settings and system controls update now. Some other content is still being translated.',
  'Sound effects',
  'Music',
  'Calm mode (less motion)',
  'About PyQuest Python',
  'Reset all progress',
  'PyQuest 0.1 · Starter Island. Progress is saved on this device.',
];

void _expectSettingsBaseCopy(WidgetTester tester, String locale) {
  final List<String> expected = locale == 'vi' ? _settingsViCopy : _settingsEnCopy;
  for (final String copy in expected) {
    expect(find.text(copy), findsOneWidget, reason: 'Missing $locale Settings copy: $copy');
  }
}

void _expectPythonCopy(WidgetTester tester, String locale) {
  final List<String> expected = locale == 'vi' ? _pythonViCopy : _pythonEnCopy;
  for (final String copy in expected) {
    expect(find.text(copy), findsOneWidget, reason: 'Missing $locale Python info copy: $copy');
  }
}

void _expectParentCopy(WidgetTester tester, String locale) {
  final List<String> expected = locale == 'vi' ? _parentViCopy : _parentEnCopy;
  for (final String copy in expected) {
    expect(find.text(copy), findsOneWidget, reason: 'Missing $locale parent-gate copy: $copy');
  }
}

Widget _settingsComponentHost(AppServices services) => AppScope(
      services: services,
      child: AnimatedBuilder(
        animation: services.settings,
        builder: (BuildContext context, Widget? _) => MaterialApp(
          locale: Locale(services.settings.localeResolution.languageCode),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => Center(
                child: TextButton(
                  key: const ValueKey<String>('settings_component_open'),
                  onPressed: () => showSettingsSheet(context),
                  child: const Text('Open settings'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
