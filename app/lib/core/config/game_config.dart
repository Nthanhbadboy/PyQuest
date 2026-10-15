import 'dart:convert';

import 'package:flutter/services.dart';

import '../../python_runtime/python_runtime.dart';

/// Gameplay numbers live in assets/config/game_config.json, never in code.
class GameConfig {
  GameConfig(this.raw);

  final Map<String, dynamic> raw;

  static const String assetPath = 'assets/config/game_config.json';

  static Future<GameConfig> load(AssetBundle bundle) async {
    final text = await bundle.loadString(assetPath);
    return GameConfig(jsonDecode(text) as Map<String, dynamic>);
  }

  Map<String, dynamic> section(String name) => (raw[name] as Map<String, dynamic>?) ?? const {};

  int _int(String sectionName, String key, int fallback) => (section(sectionName)[key] as num?)?.toInt() ?? fallback;

  // Energy -----------------------------------------------------------------
  int get energyMaxInitial => _int('energy', 'max_initial', 20);
  int get energyMaxCap => _int('energy', 'max_cap', 40);
  Duration get energyRegenInterval => Duration(minutes: _int('energy', 'regen_minutes_per_unit', 10));
  Map<String, int> get energyMilestoneBonus => {
        for (final e in ((section('energy')['milestone_bonus'] as Map<String, dynamic>?) ?? const {}).entries)
          e.key: (e.value as num).toInt(),
      };

  int cost(String key) => _int('energy_costs', key, 0);

  // Session ----------------------------------------------------------------
  List<int> get sessionReminderMinutes =>
      ((raw['session_reminders_minutes'] as List?) ?? const [30, 45, 60]).map((e) => (e as num).toInt()).toList();

  // Hints ------------------------------------------------------------------
  int get lightHintAfterFails => _int('hints', 'light_after_fails', 2);
  int get strongHintAfterFails => _int('hints', 'strong_after_fails', 3);
  int get suggestPracticeAfterFails => _int('hints', 'suggest_practice_after_fails', 4);

  // Python -----------------------------------------------------------------
  RuntimeLimits get pythonLimits => RuntimeLimits.fromJson(section('python_runtime'));

  // Per game ---------------------------------------------------------------
  int gameInt(String game, String key, int fallback) => _int(game, key, fallback);

  double gameDouble(String game, String key, double fallback) =>
      (section(game)[key] as num?)?.toDouble() ?? fallback;

  List<int> gameIntList(String game, String key, List<int> fallback) =>
      ((section(game)[key] as List?)?.map((e) => (e as num).toInt()).toList()) ?? fallback;
}
