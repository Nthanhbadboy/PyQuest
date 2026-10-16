import 'package:flutter/foundation.dart';

import '../data/repositories/state_repositories.dart';
import '../shared/l10n/pq_l10n.dart';
import 'localization/locale_preference.dart';

/// Player preferences, persisted in the `settings` table.
class SettingsService extends ChangeNotifier {
  SettingsService(this._repo);

  static const String localePreferenceKey = 'ui_locale_preference';
  static const String legacyLanguageKey = 'ui_lang';

  final SettingsRepository _repo;
  Map<String, String> _values = <String, String>{};
  List<String> _systemLocales = <String>[];
  LocalePreference _localePreference = LocalePreference.system;
  LocaleResolution _localeResolution = LocaleResolver.resolve(preference: LocalePreference.system);
  Object? _localeLoadError;
  Object? _localePreferenceSaveError;
  bool _loaded = false;

  /// Loads raw settings and migrates a valid legacy language without deleting it.
  ///
  /// OS locales are supplied by the caller; this service does not read platform APIs.
  Future<void> load({Iterable<String> systemLocales = const <String>[]}) async {
    _systemLocales = List<String>.unmodifiable(systemLocales);
    _loaded = false;
    _localeLoadError = null;
    late final Map<String, String> loadedValues;
    try {
      loadedValues = await _repo.all();
    } catch (error) {
      _localeLoadError = error;
      notifyListeners();
      rethrow;
    }

    _values = loadedValues;
    _localeLoadError = null;
    _localePreferenceSaveError = null;
    _loaded = true;

    if (_values.containsKey(localePreferenceKey)) {
      _localePreference = LocalePreference.fromStoredValue(_values[localePreferenceKey]) ??
          LocalePreference.system;
    } else {
      final String? legacy = _values[legacyLanguageKey];
      final LocalePreference? legacyPreference = LocalePreference.fromStoredValue(legacy);
      if (legacyPreference?.isExplicit ?? false) {
        _localePreference = legacyPreference!;
        try {
          await _repo.put(localePreferenceKey, _localePreference.storageValue);
          _values[localePreferenceKey] = _localePreference.storageValue;
        } catch (error) {
          // Keep the legacy choice for this session, but expose that migration was not saved.
          _localePreferenceSaveError = error;
        }
      } else {
        _localePreference = LocalePreference.system;
      }
    }

    _refreshResolution();
    notifyListeners();
  }

  bool _bool(String key, bool fallback) {
    final String? value = _values[key];
    return value == null ? fallback : value == '1';
  }

  Future<void> _set(String key, String value) async {
    _values[key] = value;
    notifyListeners();
    await _repo.put(key, value);
  }

  bool get soundOn => _bool('sound_on', true);
  bool get musicOn => _bool('music_on', true);

  /// Fewer moving decorations and shorter celebrations.
  bool get calmMode => _bool('calm_mode', false);
  bool get introSeen => _bool('intro_seen', false);

  Future<void> setSoundOn(bool value) => _set('sound_on', value ? '1' : '0');
  Future<void> setMusicOn(bool value) => _set('music_on', value ? '1' : '0');
  Future<void> setCalmMode(bool value) => _set('calm_mode', value ? '1' : '0');
  Future<void> setIntroSeen() => _set('intro_seen', '1');

  LocalePreference get localePreference => _localePreference;
  LocaleResolution get localeResolution => _localeResolution;
  Object? get localeLoadError => _localeLoadError;
  Object? get localePreferenceSaveError => _localePreferenceSaveError;

  /// Whether the current choice is present on disk, not merely effective in memory.
  bool get localePreferenceSaved =>
      _loaded && _localePreferenceSaveError == null &&
      _values[localePreferenceKey] == _localePreference.storageValue;

  /// Effective language for the existing cast/tutor adapter. In system mode this may be English
  /// fallback, but the stored preference remains `system`.
  PqLang get lang => PqLang.fromCode(_localeResolution.languageCode);
  PqStrings get strings => PqStrings.of(lang);

  /// Change OS locale input for this session. This never writes the preference.
  void updateSystemLocales(Iterable<String> systemLocales) {
    _systemLocales = List<String>.unmodifiable(systemLocales);
    _refreshResolution();
    notifyListeners();
  }

  /// Select a locale for this session immediately and persist the preference key. A failed write
  /// leaves the session selection active while exposing the failure and leaving stored values
  /// unchanged, so a newly loaded service observes the actual persisted preference.
  Future<bool> setLocalePreference(LocalePreference preference) async {
    _localePreference = preference;
    _localePreferenceSaveError = null;
    _refreshResolution();
    notifyListeners();

    try {
      await _repo.put(localePreferenceKey, preference.storageValue);
      _values[localePreferenceKey] = preference.storageValue;
      notifyListeners();
      return true;
    } catch (error) {
      _localePreferenceSaveError = error;
      notifyListeners();
      return false;
    }
  }

  /// Compatibility adapter for existing cast/tutor callers. Choosing a language is explicit.
  Future<void> setLang(PqLang value) async {
    final LocalePreference preference =
        value == PqLang.en ? LocalePreference.en : LocalePreference.vi;
    await setLocalePreference(preference);
  }

  void _refreshResolution() {
    _localeResolution = LocaleResolver.resolve(
      preference: _localePreference,
      systemLocales: _systemLocales,
    );
  }

  String? raw(String key) => _values[key];
  Future<void> setRaw(String key, String value) => _set(key, value);
}
