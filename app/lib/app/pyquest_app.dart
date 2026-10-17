import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/generated/app_localizations.dart';
import '../modules/main_map/main_map_screen.dart';
import '../shared/characters/characters.dart';
import '../shared/theme/app_theme.dart';
import '../shared/theme/palette.dart';
import '../shared/widgets/chunky_button.dart';
import 'app_scope.dart';
import 'app_services.dart';
import 'locale_binding.dart';

typedef ServicesFactory = Future<AppServices> Function(AssetBundle bundle);

class PyQuestApp extends StatefulWidget {
  const PyQuestApp({
    super.key,
    this.servicesFactory,
    this.systemLocalesReader,
    this.minSplash = const Duration(milliseconds: 900),
  });

  final ServicesFactory? servicesFactory;
  final SystemLocalesReader? systemLocalesReader;
  final Duration minSplash;

  @override
  State<PyQuestApp> createState() => _PyQuestAppState();
}

class _PyQuestAppState extends State<PyQuestApp> with WidgetsBindingObserver {
  /// Framework + generated delegates, shared by the splash and the loaded app so a
  /// framework string never silently falls back while the preference is still unknown.
  static const List<LocalizationsDelegate<dynamic>> _delegates = <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  AppServices? _services;
  AppLocaleBinding? _localeBinding;
  Object? _error;
  List<Locale> _systemLocales = const <Locale>[];

  List<Locale> get _readSystemLocales =>
      widget.systemLocalesReader?.call() ?? WidgetsBinding.instance.platformDispatcher.locales;

  @override
  void initState() {
    super.initState();
    _systemLocales = _readSystemLocales;
    WidgetsBinding.instance.addObserver(this);
    _boot();
  }

  /// The OS list changed while we run (or the app resumed with a new one): re-push it.
  /// An explicit preference is untouched — the resolver keeps it — and nothing is written.
  @override
  void didChangeLocales(List<Locale>? locales) {
    super.didChangeLocales(locales);
    _systemLocales = locales ?? _readSystemLocales;
    _localeBinding?.syncSystemLocales();
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) return;

    // Locale change callbacks may be delivered while the app is backgrounded (or missed by
    // a platform). Re-read on resume rather than trusting the last callback payload.
    _systemLocales = _readSystemLocales;
    _localeBinding?.syncSystemLocales();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _localeBinding?.dispose();
    _localeBinding = null;
    super.dispose();
  }

  Future<void> _boot() async {
    setState(() => _error = null);
    try {
      final factory = widget.servicesFactory ?? (bundle) => AppServices.create(bundle: bundle);
      final results = await Future.wait([
        factory(rootBundle),
        Future<void>.delayed(widget.minSplash),
      ]);
      final AppServices services = results.first as AppServices;
      if (!mounted) return;
      // Before this point no OS list reached the settings service, so its `lang` still
      // followed the legacy row; pushing the real list here is what makes cast dialogue
      // and the live tutor voice follow the device language.
      final AppLocaleBinding binding = AppLocaleBinding(
        settings: services.settings,
        systemLocales: widget.systemLocalesReader,
      )..syncSystemLocales();
      setState(() {
        _services = services;
        _localeBinding?.dispose();
        _localeBinding = binding;
      });
    } catch (e, st) {
      debugPrint('PyQuest failed to start: $e\n$st');
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = buildPyQuestTheme();
    final s = _services;
    final List<Locale> supportedLocales = AppLocalizations.supportedLocales;
    if (s == null) {
      // Splash: the OS list only, but the delegates are already here.
      return MaterialApp(
        title: 'PyQuest',
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: AppLocaleBinding.bootstrapLocale(_systemLocales),
        supportedLocales: supportedLocales,
        localizationsDelegates: _delegates,
        home: SplashScreen(error: _error, onRetry: _boot),
      );
    }
    final AppLocaleBinding binding = _localeBinding!;
    return AppScope(
      services: s,
      child: AnimatedBuilder(
        animation: binding,
        builder: (BuildContext context, Widget? _) => MaterialApp(
          title: 'PyQuest',
          debugShowCheckedModeBanner: false,
          theme: theme,
          locale: binding.locale,
          supportedLocales: supportedLocales,
          localizationsDelegates: _delegates,
          // Respect the system text size, but cap it so game layouts stay intact.
          builder: (context, child) =>
              MediaQuery.withClampedTextScaling(maxScaleFactor: 1.2, child: child!),
          home: const MainMapScreen(),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8ED8F8), Color(0xFFBFEAF5), PQColors.parchment],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CharacterView(id: CharacterId.robo, size: 110),
                    CharacterView(id: CharacterId.py, size: 140),
                    CharacterView(id: CharacterId.pip, size: 110),
                  ],
                ),
                const SizedBox(height: 8),
                const PyQuestLogo(size: 64),
                const SizedBox(height: 4),
                Text('Build Your Game. Rule Your World.', style: PQText.bodyStrong.copyWith(color: PQColors.inkSoft)),
                const SizedBox(height: 28),
                if (widget.error == null)
                  AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < 3; i++)
                          Transform.translate(
                            offset: Offset(0, -8 * math.max(0, math.sin((_c.value - i * 0.15) * 2 * math.pi))),
                            child: Container(
                              width: 14,
                              height: 14,
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                color: [PQColors.pyBlue, PQColors.sun, PQColors.coral][i],
                                shape: BoxShape.circle,
                                border: Border.all(color: PQColors.ink, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        Text('Ối! Đảo chưa mở được.', style: PQText.h3),
                        const SizedBox(height: 6),
                        Text('Hãy thử lại nhé. Nếu vẫn lỗi, hãy khởi động lại ứng dụng.', textAlign: TextAlign.center, style: PQText.body),
                        const SizedBox(height: 12),
                        ChunkyButton(label: 'Thử lại', tone: PQTone.sun, onPressed: widget.onRetry),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chunky two-colour wordmark: "Py" in Python blue, "Quest" in sun yellow.
class PyQuestLogo extends StatelessWidget {
  const PyQuestLogo({super.key, this.size = 56});
  final double size;

  @override
  Widget build(BuildContext context) {
    TextStyle base(Color c) => TextStyle(fontFamily: PQFonts.display, fontWeight: FontWeight.w800, fontSize: size, height: 1.0, color: c);
    Widget word(String text, Color fill) => Stack(
          children: [
            Text(text,
                style: TextStyle(
                  fontFamily: PQFonts.display,
                  fontWeight: FontWeight.w800,
                  fontSize: size,
                  height: 1.0,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = size * 0.14
                    ..strokeJoin = StrokeJoin.round
                    ..color = PQColors.ink,
                )),
            Text(text, style: base(fill)),
          ],
        );
    return Transform.rotate(
      angle: -0.03,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [word('Py', PQColors.pyBlue), word('Quest', PQColors.sun)],
      ),
    );
  }
}
