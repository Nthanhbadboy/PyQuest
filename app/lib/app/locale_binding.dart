import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/localization/locale_preference.dart';
import '../core/settings_service.dart';

/// Reads the ordered OS locale list. Defaults to the platform dispatcher; tests inject a list.
typedef SystemLocalesReader = List<Locale> Function();

/// App-root bridge between the OS locale list and the PQC-014 preference service.
///
/// This adapter has exactly two jobs:
///
/// * push the ordered OS locale list into [SettingsService] as **session input**, so a
///   `system` preference resolves against the real device list while an explicit choice
///   keeps winning. Nothing here persists a resolved language (PQC-014 contract).
/// * expose the effective [locale] for `MaterialApp.locale`.
///
/// It never calls the tutor/voice layer itself: those callers read
/// `SettingsService.lang`, which follows the same resolution, so cast dialogue and the
/// live tutor voice follow the device language through this one path.
class AppLocaleBinding extends ChangeNotifier {
  AppLocaleBinding({
    required this.settings,
    SystemLocalesReader? systemLocales,
  }) : _readSystemLocales = systemLocales ?? _platformLocales {
    settings.addListener(_onSettingsChanged);
  }

  /// Reads the list through the binding, so a test host that overrides
  /// `platformDispatcher` (or a future platform channel) is honoured too.
  static List<Locale> _platformLocales() => WidgetsBinding.instance.platformDispatcher.locales;

  final SettingsService settings;
  final SystemLocalesReader _readSystemLocales;

  List<Locale> _systemLocales = const <Locale>[];

  /// The OS list last pushed into [settings]; empty until [syncSystemLocales] runs.
  List<Locale> get systemLocales => _systemLocales;

  /// Ordered BCP-47 tags handed to the settings service, e.g. `['vi-VN', 'en-US']`.
  List<String> get systemLocaleTags =>
      _systemLocales.map((Locale locale) => locale.toLanguageTag()).toList(growable: false);

  /// Effective locale for the app.
  ///
  /// `system` follows the OS list; an explicit preference wins; an unsupported list falls
  /// back to English. The framework resolves its own delegate by language code, so the
  /// resolved code alone is handed over.
  Locale get locale => Locale(settings.localeResolution.languageCode);

  /// Locale used **before** settings exist: the OS list only, no stored preference yet.
  static Locale bootstrapLocale(Iterable<Locale> systemLocales) => Locale(
        LocaleResolver.resolve(
          preference: LocalePreference.system,
          systemLocales: systemLocales.map((Locale locale) => locale.toLanguageTag()),
        ).languageCode,
      );

  /// Re-reads the OS list and pushes it into [settings].
  ///
  /// Called once at boot and again whenever the OS list changes (also on resume). For an
  /// explicit preference the resolver is unchanged, and the preference row is never
  /// written, so a device that reports `fr-FR` cannot overwrite a Vietnamese choice.
  void syncSystemLocales() {
    _systemLocales = List<Locale>.unmodifiable(_readSystemLocales());
    settings.updateSystemLocales(systemLocaleTags);
    notifyListeners();
  }

  @override
  void dispose() {
    settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() => notifyListeners();
}
