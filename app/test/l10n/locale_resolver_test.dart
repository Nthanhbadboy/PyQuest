import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/core/localization/locale_preference.dart';

void main() {
  group('LocaleResolver', () {
    test('resolves regional system tags in OS order and canonicalizes the match', () {
      final LocaleResolution vi = LocaleResolver.resolve(
        preference: LocalePreference.system,
        systemLocales: <String>['fr-FR', 'vi-vn', 'en-GB'],
      );
      expect(vi.languageCode, 'vi');
      expect(vi.preference, LocalePreference.system);
      expect(vi.matchedSystemTag, 'vi-VN');
      expect(vi.usedEnglishFallback, isFalse);

      final LocaleResolution en = LocaleResolver.resolve(
        preference: LocalePreference.system,
        systemLocales: <String>['EN-gb', 'vi-VN'],
      );
      expect(en.languageCode, 'en');
      expect(en.matchedSystemTag, 'en-GB');
      expect(en.usedEnglishFallback, isFalse);
    });

    test('explicit choices override OS locales and carry no system match', () {
      for (final LocalePreference preference in <LocalePreference>[
        LocalePreference.vi,
        LocalePreference.en,
      ]) {
        final LocaleResolution result = LocaleResolver.resolve(
          preference: preference,
          systemLocales: <String>['en-GB', 'vi-VN'],
        );
        expect(result.languageCode, preference.storageValue);
        expect(result.preference, preference);
        expect(result.matchedSystemTag, isNull);
        expect(result.usedEnglishFallback, isFalse);
      }
    });

    test('unsupported, empty, and malformed system tags fall back to English', () {
      final LocaleResolution result = LocaleResolver.resolve(
        preference: LocalePreference.system,
        systemLocales: <String>['', 'en_US', 'en-a', 'fr-FR', '12-BAD', 'vi--VN'],
      );
      expect(result.languageCode, 'en');
      expect(result.preference, LocalePreference.system);
      expect(result.matchedSystemTag, isNull);
      expect(result.usedEnglishFallback, isTrue);
    });

    test('a system preference remains distinct from its current resolution', () {
      final LocaleResolution before = LocaleResolver.resolve(
        preference: LocalePreference.system,
        systemLocales: <String>['vi-VN'],
      );
      final LocaleResolution after = LocaleResolver.resolve(
        preference: LocalePreference.system,
        systemLocales: <String>['fr-FR'],
      );
      expect(before.languageCode, 'vi');
      expect(after.languageCode, 'en');
      expect(after.usedEnglishFallback, isTrue);
      expect(before.preference, LocalePreference.system);
      expect(after.preference, LocalePreference.system);
    });
  });
}
