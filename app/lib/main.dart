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
  runApp(const PyQuestApp());
}
