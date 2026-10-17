// PQC-015 — app localization foundation.
//
// Output of `flutter gen-l10n` for the configuration in app/l10n.yaml
// (arb-dir lib/l10n, template app_en.arb, output-dir lib/l10n/generated). It is
// committed so a clean checkout analyzes and tests without a generator step; run
// `flutter gen-l10n` to refresh it after editing the ARB files.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;

/// Callers look localized strings up with `AppLocalizations.of(context)`.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations);

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// The locales with an ARB bundle — `vi` and `en` only (PQC-015 scope).
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('vi')];

  /// Name handed to the OS task switcher and to the localization foundation.
  String get appTitle;

  /// Typed-placeholder greeting: proves the delegate resolves per locale.
  String foundationGreeting(String name);

  /// Shown while the app is following the OS language list.
  String get foundationFollowsDevice;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));

  @override
  bool isSupported(Locale locale) => supportedLocales
      .map((Locale supported) => supported.languageCode)
      .contains(locale.languageCode);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }
  throw FlutterError(
    'AppLocalizations.delegate failed to load an unsupported locale "$locale". '
    'Supported locales are: ${AppLocalizations.supportedLocales.join(', ')}.',
  );
}

class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PyQuest';

  @override
  String foundationGreeting(String name) => 'Hello $name!';

  @override
  String get foundationFollowsDevice => 'This build follows your device language.';
}

class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'PyQuest';

  @override
  String foundationGreeting(String name) => 'Xin chào $name!';

  @override
  String get foundationFollowsDevice => 'Bản này theo ngôn ngữ của thiết bị.';
}
