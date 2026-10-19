import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/pyquest_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFFFFF5DE),
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(
    PyQuestApp(
      systemLocalesReader: () {
        final List<Locale> os =
            WidgetsBinding.instance.platformDispatcher.locales;
        if (os.any((Locale l) => l.languageCode == 'vi')) return os;
        return <Locale>[const Locale('vi'), ...os];
      },
    ),
  );
}
