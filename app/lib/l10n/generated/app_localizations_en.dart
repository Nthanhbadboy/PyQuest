// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PyQuest';

  @override
  String foundationGreeting(String name) {
    return 'Hello $name!';
  }

  @override
  String get foundationFollowsDevice =>
      'This build follows your device language.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSystem => 'Follow device';

  @override
  String get settingsLanguageVi => 'Tiếng Việt';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String settingsLanguageEffective(String language) {
    return 'Currently using: $language';
  }

  @override
  String get settingsLanguageFallback =>
      'Your device language is not supported yet. PyQuest is using English.';

  @override
  String get settingsLanguageScope =>
      'Settings and system controls update now. Some other content is still being translated.';

  @override
  String get settingsLanguageSaving => 'Saving your choice…';

  @override
  String get settingsLanguageSaveError =>
      'Your choice could not be saved. It still applies for now; next time, PyQuest may use your previously saved choice.';

  @override
  String get settingsLanguageRetry => 'Retry saving';

  @override
  String get settingsSound => 'Sound effects';

  @override
  String get settingsMusic => 'Music';

  @override
  String get settingsCalm => 'Calm mode (less motion)';

  @override
  String get settingsAboutPython => 'About PyQuest Python';

  @override
  String get settingsResetProgress => 'Reset all progress';

  @override
  String get settingsFooter =>
      'PyQuest 0.1 · Starter Island. Progress is saved on this device.';

  @override
  String get settingsParentTitle => 'For parents';

  @override
  String get settingsParentWarning =>
      'This deletes progress, badges and custom mazes, and resets settings on this device. To continue, enter the answer:';

  @override
  String settingsParentQuestion(int a, int b) {
    return '$a × $b = ?';
  }

  @override
  String get settingsParentAnswer => 'Answer';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsDelete => 'Delete';

  @override
  String get settingsPythonTitle => 'PyQuest Python (simulated)';

  @override
  String get settingsPythonIntro =>
      'Your code runs on a small Python implementation made for PyQuest, on this device and without a network connection. It supports the basics, but it is NOT full Python.';

  @override
  String get settingsPythonSupportedTitle => 'You can use';

  @override
  String get settingsPythonLimitsTitle => 'Limits';

  @override
  String get settingsPythonSupportedValues =>
      'print(), variables, integers, decimal numbers, strings, True/False, None';

  @override
  String get settingsPythonSupportedOperators =>
      'Arithmetic + - * / // % **, comparisons == != < > <= >=, and/or/not';

  @override
  String get settingsPythonSupportedFlow =>
      'if / elif / else, while, for ... in range(...), break, continue';

  @override
  String get settingsPythonSupportedLists =>
      'Lists: [1, 2, 3], ds[0], ds.append(), len(), in';

  @override
  String get settingsPythonSupportedFunctions =>
      'Functions: def, return, default arguments';

  @override
  String settingsPythonSupportedFString(String example) {
    return 'Simple f-strings, for example: $example';
  }

  @override
  String get settingsPythonSupportedBuiltins =>
      'Built-ins: len, range, str, int, float, bool, abs, round, min, max, sum, list, sorted, type';

  @override
  String get settingsPythonLimitFeatures =>
      'No import, files, networking, input(), class, dictionary, tuple, slicing [a:b], try/except or lambda.';

  @override
  String get settingsPythonLimitSteps =>
      'Up to 100,000 execution steps — endless loops are stopped safely.';

  @override
  String get settingsPythonLimitDepthOutput =>
      'Up to 50 nested function calls and 10,000 output characters.';

  @override
  String get settingsPythonLimitIntegers =>
      'Integers are limited to about ±9 quintillion (standard Python integers have no fixed size limit).';

  @override
  String get settingsPythonLimitOutputTiming =>
      'Output appears after the program finishes, not line by line in real time.';

  @override
  String get settingsPythonLimitNames =>
      'Variable names cannot shadow print, len or range, to help avoid confusing errors.';
}
