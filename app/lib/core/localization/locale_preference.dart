/// A stored UI-language choice. `system` is a preference, never an effective locale.
abstract final class LocaleSupport {
  static const List<String> languageCodes = <String>['vi', 'en'];
  static const String fallbackLanguageCode = 'en';

  static bool supports(String languageCode) => languageCodes.contains(languageCode);
}

enum LocalePreference {
  system('system'),
  vi('vi'),
  en('en');

  const LocalePreference(this.storageValue);

  final String storageValue;

  bool get isExplicit => this != system;

  static LocalePreference? fromStoredValue(String? value) {
    for (final LocalePreference preference in values) {
      if (preference.storageValue == value) return preference;
    }
    return null;
  }
}

/// The result of resolving a preference against an ordered OS locale list.
class LocaleResolution {
  const LocaleResolution({
    required this.preference,
    required this.languageCode,
    required this.matchedSystemTag,
    required this.usedEnglishFallback,
  });

  final LocalePreference preference;

  /// Supported language selected for this session (`vi` or `en`).
  final String languageCode;

  /// Canonicalized regional tag that matched when the preference is `system`.
  final String? matchedSystemTag;

  /// True only when system mode found no supported locale and selected English.
  final bool usedEnglishFallback;

  bool get isSystemMatch => preference == LocalePreference.system && matchedSystemTag != null;
}

/// Pure locale resolver. Inputs are supplied by a caller; this class never reads device APIs.
class LocaleResolver {
  const LocaleResolver._();

  static LocaleResolution resolve({
    required LocalePreference preference,
    Iterable<String> systemLocales = const <String>[],
  }) {
    if (preference == LocalePreference.vi || preference == LocalePreference.en) {
      return LocaleResolution(
        preference: preference,
        languageCode: preference.storageValue,
        matchedSystemTag: null,
        usedEnglishFallback: false,
      );
    }

    for (final String candidate in systemLocales) {
      final String? canonical = _canonicalizeBcp47(candidate);
      if (canonical == null) continue;
      final String language = canonical.split('-').first;
      if (LocaleSupport.supports(language)) {
        return LocaleResolution(
          preference: preference,
          languageCode: language,
          matchedSystemTag: canonical,
          usedEnglishFallback: false,
        );
      }
    }

    return const LocaleResolution(
      preference: LocalePreference.system,
      languageCode: LocaleSupport.fallbackLanguageCode,
      matchedSystemTag: null,
      usedEnglishFallback: true,
    );
  }

  /// Returns a normalized BCP-47 tag, or null for malformed tags.
  static String? _canonicalizeBcp47(String value) {
    if (value.isEmpty || value != value.trim()) return null;
    final List<String> subtags = value.split('-');
    if (!RegExp(r'^[A-Za-z]{2,8}$').hasMatch(subtags.first) ||
        subtags.skip(1).any((String part) =>
            part.isEmpty || part.length > 8 || !RegExp(r'^[A-Za-z0-9]+$').hasMatch(part))) {
      return null;
    }

    int index = 1;
    final String language = subtags.first;
    // Optional extlang subtags (only after 2–3 character primary language subtags).
    if (language.length <= 3) {
      int count = 0;
      while (index < subtags.length && count < 3 &&
          RegExp(r'^[A-Za-z]{3}$').hasMatch(subtags[index])) {
        index++;
        count++;
      }
    }
    // Optional script, region, and variant subtags in their BCP-47 positions.
    int? scriptIndex;
    int? regionIndex;
    if (index < subtags.length && RegExp(r'^[A-Za-z]{4}$').hasMatch(subtags[index])) {
      scriptIndex = index++;
    }
    if (index < subtags.length &&
        (RegExp(r'^[A-Za-z]{2}$').hasMatch(subtags[index]) ||
            RegExp(r'^\d{3}$').hasMatch(subtags[index]))) {
      regionIndex = index++;
    }
    while (index < subtags.length &&
        (RegExp(r'^[A-Za-z0-9]{5,8}$').hasMatch(subtags[index]) ||
            RegExp(r'^\d[A-Za-z0-9]{3}$').hasMatch(subtags[index]))) {
      index++;
    }
    // Extensions have a unique alphanumeric singleton and one or more 2–8 character values.
    final Set<String> extensions = <String>{};
    while (index < subtags.length && RegExp(r'^[0-9A-WY-Za-wy-z]$').hasMatch(subtags[index])) {
      final String singleton = subtags[index].toLowerCase();
      if (!extensions.add(singleton)) return null;
      index++;
      final int start = index;
      while (index < subtags.length && RegExp(r'^[A-Za-z0-9]{2,8}$').hasMatch(subtags[index])) {
        index++;
      }
      if (index == start) return null;
    }
    // Private-use is optional and, unlike extension payloads, permits one-character subtags.
    if (index < subtags.length && subtags[index].toLowerCase() == 'x') {
      index++;
      final int start = index;
      while (index < subtags.length && RegExp(r'^[A-Za-z0-9]{1,8}$').hasMatch(subtags[index])) {
        index++;
      }
      if (index == start) return null;
    }
    if (index != subtags.length) return null;

    final List<String> canonical = <String>[subtags.first.toLowerCase()];
    for (int partIndex = 1; partIndex < subtags.length; partIndex++) {
      final String part = subtags[partIndex];
      if (partIndex == scriptIndex) {
        canonical.add('${part[0].toUpperCase()}${part.substring(1).toLowerCase()}');
      } else if (partIndex == regionIndex) {
        canonical.add(part.toUpperCase());
      } else {
        canonical.add(part.toLowerCase());
      }
    }
    return canonical.join('-');
  }
}
