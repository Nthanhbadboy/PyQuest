// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'PyQuest';

  @override
  String foundationGreeting(String name) {
    return 'Xin chào $name!';
  }

  @override
  String get foundationFollowsDevice => 'Bản này theo ngôn ngữ của thiết bị.';
}
