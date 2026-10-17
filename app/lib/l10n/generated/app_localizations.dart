import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// Name handed to the OS task switcher and to the localization foundation.
  ///
  /// In en, this message translates to:
  /// **'PyQuest'**
  String get appTitle;

  /// Typed-placeholder greeting used to prove the generated delegate resolves per locale.
  ///
  /// In en, this message translates to:
  /// **'Hello {name}!'**
  String foundationGreeting(String name);

  /// Shown while the app is following the OS language list.
  ///
  /// In en, this message translates to:
  /// **'This build follows your device language.'**
  String get foundationFollowsDevice;

  /// PQC-016 Settings surface; settingsTitle
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// PQC-016 Settings surface; settingsLanguageTitle
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// PQC-016 Settings surface; settingsLanguageSystem
  ///
  /// In en, this message translates to:
  /// **'Follow device'**
  String get settingsLanguageSystem;

  /// PQC-016 Settings surface; settingsLanguageVi
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get settingsLanguageVi;

  /// PQC-016 Settings surface; settingsLanguageEn
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// PQC-016 Settings surface; settingsLanguageEffective
  ///
  /// In en, this message translates to:
  /// **'Currently using: {language}'**
  String settingsLanguageEffective(String language);

  /// PQC-016 Settings surface; settingsLanguageFallback
  ///
  /// In en, this message translates to:
  /// **'Your device language is not supported yet. PyQuest is using English.'**
  String get settingsLanguageFallback;

  /// PQC-016 Settings surface; settingsLanguageScope
  ///
  /// In en, this message translates to:
  /// **'Settings and system controls update now. Some other content is still being translated.'**
  String get settingsLanguageScope;

  /// PQC-016 Settings surface; settingsLanguageSaving
  ///
  /// In en, this message translates to:
  /// **'Saving your choice…'**
  String get settingsLanguageSaving;

  /// PQC-016 Settings surface; settingsLanguageSaveError
  ///
  /// In en, this message translates to:
  /// **'Your choice could not be saved. It still applies for now; next time, PyQuest may use your previously saved choice.'**
  String get settingsLanguageSaveError;

  /// PQC-016 Settings surface; settingsLanguageRetry
  ///
  /// In en, this message translates to:
  /// **'Retry saving'**
  String get settingsLanguageRetry;

  /// PQC-016 Settings surface; settingsSound
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get settingsSound;

  /// PQC-016 Settings surface; settingsMusic
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get settingsMusic;

  /// PQC-016 Settings surface; settingsCalm
  ///
  /// In en, this message translates to:
  /// **'Calm mode (less motion)'**
  String get settingsCalm;

  /// PQC-016 Settings surface; settingsAboutPython
  ///
  /// In en, this message translates to:
  /// **'About PyQuest Python'**
  String get settingsAboutPython;

  /// PQC-016 Settings surface; settingsResetProgress
  ///
  /// In en, this message translates to:
  /// **'Reset all progress'**
  String get settingsResetProgress;

  /// PQC-016 Settings surface; settingsFooter
  ///
  /// In en, this message translates to:
  /// **'PyQuest 0.1 · Starter Island. Progress is saved on this device.'**
  String get settingsFooter;

  /// PQC-016 Settings surface; settingsParentTitle
  ///
  /// In en, this message translates to:
  /// **'For parents'**
  String get settingsParentTitle;

  /// PQC-016 Settings surface; settingsParentWarning
  ///
  /// In en, this message translates to:
  /// **'This deletes progress, badges and custom mazes, and resets settings on this device. To continue, enter the answer:'**
  String get settingsParentWarning;

  /// PQC-016 Settings surface; settingsParentQuestion
  ///
  /// In en, this message translates to:
  /// **'{a} × {b} = ?'**
  String settingsParentQuestion(int a, int b);

  /// PQC-016 Settings surface; settingsParentAnswer
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get settingsParentAnswer;

  /// PQC-016 Settings surface; settingsCancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancel;

  /// PQC-016 Settings surface; settingsDelete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settingsDelete;

  /// PQC-016 Settings surface; settingsPythonTitle
  ///
  /// In en, this message translates to:
  /// **'PyQuest Python (simulated)'**
  String get settingsPythonTitle;

  /// PQC-016 Settings surface; settingsPythonIntro
  ///
  /// In en, this message translates to:
  /// **'Your code runs on a small Python implementation made for PyQuest, on this device and without a network connection. It supports the basics, but it is NOT full Python.'**
  String get settingsPythonIntro;

  /// PQC-016 Settings surface; settingsPythonSupportedTitle
  ///
  /// In en, this message translates to:
  /// **'You can use'**
  String get settingsPythonSupportedTitle;

  /// PQC-016 Settings surface; settingsPythonLimitsTitle
  ///
  /// In en, this message translates to:
  /// **'Limits'**
  String get settingsPythonLimitsTitle;

  /// PQC-016 Settings surface; settingsPythonSupportedValues
  ///
  /// In en, this message translates to:
  /// **'print(), variables, integers, decimal numbers, strings, True/False, None'**
  String get settingsPythonSupportedValues;

  /// PQC-016 Settings surface; settingsPythonSupportedOperators
  ///
  /// In en, this message translates to:
  /// **'Arithmetic + - * / // % **, comparisons == != < > <= >=, and/or/not'**
  String get settingsPythonSupportedOperators;

  /// PQC-016 Settings surface; settingsPythonSupportedFlow
  ///
  /// In en, this message translates to:
  /// **'if / elif / else, while, for ... in range(...), break, continue'**
  String get settingsPythonSupportedFlow;

  /// PQC-016 Settings surface; settingsPythonSupportedLists
  ///
  /// In en, this message translates to:
  /// **'Lists: [1, 2, 3], ds[0], ds.append(), len(), in'**
  String get settingsPythonSupportedLists;

  /// PQC-016 Settings surface; settingsPythonSupportedFunctions
  ///
  /// In en, this message translates to:
  /// **'Functions: def, return, default arguments'**
  String get settingsPythonSupportedFunctions;

  /// PQC-016 Settings surface; settingsPythonSupportedFString
  ///
  /// In en, this message translates to:
  /// **'Simple f-strings, for example: {example}'**
  String settingsPythonSupportedFString(String example);

  /// PQC-016 Settings surface; settingsPythonSupportedBuiltins
  ///
  /// In en, this message translates to:
  /// **'Built-ins: len, range, str, int, float, bool, abs, round, min, max, sum, list, sorted, type'**
  String get settingsPythonSupportedBuiltins;

  /// PQC-016 Settings surface; settingsPythonLimitFeatures
  ///
  /// In en, this message translates to:
  /// **'No import, files, networking, input(), class, dictionary, tuple, slicing [a:b], try/except or lambda.'**
  String get settingsPythonLimitFeatures;

  /// PQC-016 Settings surface; settingsPythonLimitSteps
  ///
  /// In en, this message translates to:
  /// **'Up to 100,000 execution steps — endless loops are stopped safely.'**
  String get settingsPythonLimitSteps;

  /// PQC-016 Settings surface; settingsPythonLimitDepthOutput
  ///
  /// In en, this message translates to:
  /// **'Up to 50 nested function calls and 10,000 output characters.'**
  String get settingsPythonLimitDepthOutput;

  /// PQC-016 Settings surface; settingsPythonLimitIntegers
  ///
  /// In en, this message translates to:
  /// **'Integers are limited to about ±9 quintillion (standard Python integers have no fixed size limit).'**
  String get settingsPythonLimitIntegers;

  /// PQC-016 Settings surface; settingsPythonLimitOutputTiming
  ///
  /// In en, this message translates to:
  /// **'Output appears after the program finishes, not line by line in real time.'**
  String get settingsPythonLimitOutputTiming;

  /// PQC-016 Settings surface; settingsPythonLimitNames
  ///
  /// In en, this message translates to:
  /// **'Variable names cannot shadow print, len or range, to help avoid confusing errors.'**
  String get settingsPythonLimitNames;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
