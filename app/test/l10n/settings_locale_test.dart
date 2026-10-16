import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/core/localization/locale_preference.dart';
import 'package:pyquest/core/settings_service.dart';
import 'package:pyquest/data/database/app_database.dart';
import 'package:pyquest/data/repositories/state_repositories.dart';
import 'package:pyquest/shared/l10n/pq_l10n.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('SettingsService locale preference migration', () {
    test('migrates raw legacy VI once, keeps the legacy row, and reloads idempotently', () async {
      final _Fixture fixture = await _openFixture(<String, String>{'ui_lang': 'vi'});
      addTearDown(fixture.close);
      final SettingsService settings = fixture.service();
      addTearDown(settings.dispose);

      await settings.load(systemLocales: <String>['en-GB']);
      expect(settings.localePreference, LocalePreference.vi);
      expect(settings.lang, PqLang.vi);
      expect(settings.raw(SettingsService.localePreferenceKey), 'vi');
      expect(settings.raw(SettingsService.legacyLanguageKey), 'vi');
      expect(settings.localePreferenceSaved, isTrue);
      expect(settings.localePreferenceSaveError, isNull);

      await settings.load(systemLocales: <String>['en-GB']);
      expect(settings.localePreference, LocalePreference.vi);
      expect(settings.lang, PqLang.vi);
      expect((await fixture.repository.all())[SettingsService.localePreferenceKey], 'vi');
      expect((await fixture.repository.all())[SettingsService.legacyLanguageKey], 'vi');
    });

    test('migrates raw legacy EN as an explicit preference', () async {
      final _Fixture fixture = await _openFixture(<String, String>{'ui_lang': 'en'});
      addTearDown(fixture.close);
      final SettingsService settings = fixture.service();
      addTearDown(settings.dispose);

      await settings.load(systemLocales: <String>['vi-VN']);
      expect(settings.localePreference, LocalePreference.en);
      expect(settings.lang, PqLang.en);
      expect(settings.raw(SettingsService.localePreferenceKey), 'en');
      expect(settings.raw(SettingsService.legacyLanguageKey), 'en');
    });

    test('a valid new system choice wins over legacy VI and OS changes never persist resolution',
        () async {
      final _Fixture fixture = await _openFixture(<String, String>{
        SettingsService.localePreferenceKey: 'system',
        SettingsService.legacyLanguageKey: 'vi',
      });
      addTearDown(fixture.close);
      final SettingsService settings = fixture.service();
      addTearDown(settings.dispose);

      await settings.load(systemLocales: <String>['vi-VN']);
      expect(settings.localePreference, LocalePreference.system);
      expect(settings.localeResolution.languageCode, 'vi');
      expect(settings.localeResolution.matchedSystemTag, 'vi-VN');

      settings.updateSystemLocales(<String>['fr-FR']);
      expect(settings.localePreference, LocalePreference.system);
      expect(settings.lang, PqLang.en);
      expect(settings.localeResolution.usedEnglishFallback, isTrue);
      expect(settings.raw(SettingsService.localePreferenceKey), 'system');
      expect((await fixture.repository.all())[SettingsService.localePreferenceKey], 'system');
    });

    test('valid new English preference wins over legacy VI', () async {
      final _Fixture fixture = await _openFixture(<String, String>{
        SettingsService.localePreferenceKey: 'en',
        SettingsService.legacyLanguageKey: 'vi',
      });
      addTearDown(fixture.close);
      final SettingsService settings = fixture.service();
      addTearDown(settings.dispose);

      await settings.load(systemLocales: <String>['vi-VN']);
      expect(settings.localePreference, LocalePreference.en);
      expect(settings.lang, PqLang.en);
      expect(settings.raw(SettingsService.localePreferenceKey), 'en');
      expect(settings.raw(SettingsService.legacyLanguageKey), 'vi');
    });

    test('legacy PqLang adapter remains unchanged until the root supplies OS locales', () async {
      final _Fixture fixture = await _openFixture(<String, String>{});
      addTearDown(fixture.close);
      final SettingsService settings = fixture.service();
      addTearDown(settings.dispose);

      await settings.load();
      expect(settings.localePreference, LocalePreference.system);
      expect(settings.localeResolution.languageCode, 'en');
      expect(settings.localeResolution.usedEnglishFallback, isTrue);
      expect(settings.lang, PqLang.vi, reason: 'existing consumers retain the pre-015 adapter default');
      expect(settings.raw(SettingsService.localePreferenceKey), isNull,
          reason: 'adapter fallback must not become a persisted explicit VI choice');
    });

    test('present-invalid new preference wins as system over valid legacy English', () async {
      final _Fixture fixture = await _openFixture(<String, String>{
        SettingsService.localePreferenceKey: 'xx',
        SettingsService.legacyLanguageKey: 'en',
      });
      addTearDown(fixture.close);
      final SettingsService settings = fixture.service();
      addTearDown(settings.dispose);

      await settings.load(systemLocales: <String>['vi-VN']);
      expect(settings.localePreference, LocalePreference.system);
      expect(settings.lang, PqLang.vi);
      expect(settings.raw(SettingsService.localePreferenceKey), 'xx');
      expect(settings.raw(SettingsService.legacyLanguageKey), 'en');
    });

    test('absent or invalid legacy raw values default to system without writing a resolution',
        () async {
      for (final Map<String, String> rows in <Map<String, String>>[
        <String, String>{},
        <String, String>{SettingsService.legacyLanguageKey: 'xx'},
      ]) {
        final _Fixture fixture = await _openFixture(rows);
        final SettingsService settings = fixture.service();
        try {
          await settings.load(systemLocales: <String>['en-GB']);
          expect(settings.localePreference, LocalePreference.system);
          expect(settings.lang, PqLang.en);
          expect(settings.raw(SettingsService.localePreferenceKey), isNull);
          expect(settings.localePreferenceSaved, isFalse);
        } finally {
          settings.dispose();
          await fixture.close();
        }
      }
    });

    test('legacy migration write failure keeps this-session choice and exposes unsaved state',
        () async {
      final _Fixture fixture = await _openFixture(<String, String>{'ui_lang': 'vi'});
      addTearDown(fixture.close);
      await fixture.rejectLocalePreferenceWrites();
      final SettingsService settings = fixture.service();
      addTearDown(settings.dispose);

      await settings.load(systemLocales: <String>['en-GB']);
      expect(settings.localePreference, LocalePreference.vi);
      expect(settings.lang, PqLang.vi);
      expect(settings.localePreferenceSaveError, isNotNull);
      expect(settings.localePreferenceSaved, isFalse);
      expect((await fixture.repository.all())[SettingsService.localePreferenceKey], isNull);
      expect((await fixture.repository.all())[SettingsService.legacyLanguageKey], 'vi');

      final SettingsService restarted = fixture.service();
      addTearDown(restarted.dispose);
      await restarted.load(systemLocales: <String>['en-GB']);
      expect(restarted.localePreference, LocalePreference.vi);
      expect(restarted.localePreferenceSaveError, isNotNull);
    });
  });

  group('SettingsService locale persistence', () {
    test('successful selection persists preference rather than effective locale', () async {
      final _Fixture fixture = await _openFixture(<String, String>{});
      addTearDown(fixture.close);
      final SettingsService settings = fixture.service();
      addTearDown(settings.dispose);

      await settings.load(systemLocales: <String>['vi-VN']);
      expect(settings.localePreference, LocalePreference.system);
      expect(settings.lang, PqLang.vi);
      expect(await settings.setLocalePreference(LocalePreference.en), isTrue);
      expect(settings.lang, PqLang.en);
      expect(await settings.setLocalePreference(LocalePreference.system), isTrue);
      expect(settings.localePreference, LocalePreference.system);
      expect(settings.lang, PqLang.vi);
      expect(settings.raw(SettingsService.localePreferenceKey), 'system');
      expect(settings.localePreferenceSaved, isTrue);

      settings.updateSystemLocales(<String>['fr-FR']);
      expect(settings.lang, PqLang.en);
      expect(settings.raw(SettingsService.localePreferenceKey), 'system');
      expect((await fixture.repository.all())[SettingsService.localePreferenceKey], 'system');
    });

    test('failed selection stays effective in-session but restart reads persisted value', () async {
      final _Fixture fixture = await _openFixture(<String, String>{
        SettingsService.localePreferenceKey: 'en',
      });
      addTearDown(fixture.close);
      final SettingsService settings = fixture.service();
      addTearDown(settings.dispose);
      await settings.load(systemLocales: <String>['fr-FR']);
      await fixture.rejectLocalePreferenceWrites();

      expect(await settings.setLocalePreference(LocalePreference.vi), isFalse);
      expect(settings.localePreference, LocalePreference.vi);
      expect(settings.lang, PqLang.vi);
      expect(settings.localePreferenceSaveError, isNotNull);
      expect(settings.localePreferenceSaved, isFalse);
      await expectLater(settings.setLang(PqLang.vi), throwsA(isA<DatabaseException>()));
      expect(settings.lang, PqLang.vi);
      expect((await fixture.repository.all())[SettingsService.localePreferenceKey], 'en');

      final SettingsService restarted = fixture.service();
      addTearDown(restarted.dispose);
      await restarted.load(systemLocales: <String>['fr-FR']);
      expect(restarted.localePreference, LocalePreference.en);
      expect(restarted.lang, PqLang.en);
      expect(restarted.localePreferenceSaveError, isNull);
    });

    test('read failures are surfaced and do not report a successful load', () async {
      final _Fixture fixture = await _openFixture(<String, String>{});
      addTearDown(fixture.close);
      final SettingsService settings = fixture.service();
      addTearDown(settings.dispose);
      await fixture.database.db.execute('ALTER TABLE settings RENAME TO settings_unavailable');

      await expectLater(settings.load(), throwsA(isA<DatabaseException>()));
      expect(settings.localeLoadError, isA<DatabaseException>());
      expect(settings.localePreferenceSaved, isFalse);
    });

    test('legacy language adapter and unrelated preference setters keep working', () async {
      final _Fixture fixture = await _openFixture(<String, String>{});
      addTearDown(fixture.close);
      final SettingsService settings = fixture.service();
      addTearDown(settings.dispose);
      await settings.load();

      await settings.setLang(PqLang.en);
      expect(settings.lang, PqLang.en);
      expect(settings.localePreference, LocalePreference.en);
      expect(settings.raw(SettingsService.localePreferenceKey), 'en');
      expect(settings.raw(SettingsService.legacyLanguageKey), isNull);

      await settings.setSoundOn(false);
      await settings.setMusicOn(false);
      await settings.setCalmMode(true);
      await settings.setIntroSeen();
      final SettingsService restarted = fixture.service();
      addTearDown(restarted.dispose);
      await restarted.load();
      expect(restarted.lang, PqLang.en);
      expect(restarted.soundOn, isFalse);
      expect(restarted.musicOn, isFalse);
      expect(restarted.calmMode, isTrue);
      expect(restarted.introSeen, isTrue);
    });
  });
}

class _Fixture {
  _Fixture(this.database) : repository = SettingsRepository(database);

  final AppDatabase database;
  final SettingsRepository repository;

  SettingsService service() => SettingsService(repository);

  Future<void> rejectLocalePreferenceWrites() => database.db.execute('''
    CREATE TRIGGER reject_locale_preference
    BEFORE INSERT ON settings
    WHEN NEW.key = '${SettingsService.localePreferenceKey}'
    BEGIN
      SELECT RAISE(ABORT, 'locale preference write rejected');
    END
  ''');

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
