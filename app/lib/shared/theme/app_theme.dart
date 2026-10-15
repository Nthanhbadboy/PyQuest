import 'package:flutter/material.dart';

import 'palette.dart';

abstract final class PQFonts {
  static const display = 'Baloo2';
  static const body = 'Nunito';
  static const code = 'JetBrainsMono';
}

/// Text styles used across the app. Sizes are generous for young readers.
abstract final class PQText {
  static const hero = TextStyle(
      fontFamily: PQFonts.display, fontSize: 40, fontWeight: FontWeight.w800, color: PQColors.ink, height: 1.05);
  static const h1 = TextStyle(
      fontFamily: PQFonts.display, fontSize: 30, fontWeight: FontWeight.w800, color: PQColors.ink, height: 1.1);
  static const h2 = TextStyle(
      fontFamily: PQFonts.display, fontSize: 24, fontWeight: FontWeight.w800, color: PQColors.ink, height: 1.15);
  static const h3 = TextStyle(
      fontFamily: PQFonts.display, fontSize: 20, fontWeight: FontWeight.w700, color: PQColors.ink, height: 1.2);
  static const body = TextStyle(
      fontFamily: PQFonts.body, fontSize: 17, fontWeight: FontWeight.w500, color: PQColors.inkSoft, height: 1.4);
  static const bodyStrong = TextStyle(
      fontFamily: PQFonts.body, fontSize: 17, fontWeight: FontWeight.w700, color: PQColors.ink, height: 1.4);
  static const small = TextStyle(
      fontFamily: PQFonts.body, fontSize: 15, fontWeight: FontWeight.w700, color: PQColors.inkSoft, height: 1.3);
  static const label = TextStyle(
      fontFamily: PQFonts.body, fontSize: 17, fontWeight: FontWeight.w800, color: PQColors.ink, height: 1.2);
  static const button = TextStyle(
      fontFamily: PQFonts.display, fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1);
  static const number = TextStyle(
      fontFamily: PQFonts.display, fontSize: 22, fontWeight: FontWeight.w800, color: PQColors.ink, height: 1.0);
  static const code = TextStyle(
      fontFamily: PQFonts.code, fontSize: 16, fontWeight: FontWeight.w500, color: PQColors.codeText, height: 1.5);
}

ThemeData buildPyQuestTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: PQColors.pyBlue,
    brightness: Brightness.light,
  ).copyWith(
    primary: PQColors.pyBlue,
    secondary: PQColors.sun,
    surface: PQColors.parchment,
    onSurface: PQColors.ink,
    error: PQColors.danger,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: PQFonts.body,
    scaffoldBackgroundColor: PQColors.parchment,
    splashFactory: InkSparkle.splashFactory,
    textTheme: const TextTheme(
      displayLarge: PQText.hero,
      headlineMedium: PQText.h1,
      headlineSmall: PQText.h2,
      titleLarge: PQText.h3,
      titleMedium: PQText.label,
      bodyLarge: PQText.bodyStrong,
      bodyMedium: PQText.body,
      bodySmall: PQText.small,
      labelLarge: PQText.label,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: PQColors.pyYellow,
      selectionColor: Color(0x665AAEF2),
      selectionHandleColor: PQColors.pyYellow,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
}
