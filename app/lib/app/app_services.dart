import 'dart:async';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../core/audio_service.dart';
import '../core/clock.dart';
import '../core/config/game_config.dart';
import '../core/events.dart';
import '../core/session_service.dart';
import '../core/settings_service.dart';
import '../data/database/app_database.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/state_repositories.dart';
import '../modules/achievements/achievement_engine.dart';
import '../modules/bug_hunter/bug_models.dart';
import '../modules/daily_quests/daily_quest_service.dart';
import '../modules/energy/energy_service.dart';
import '../modules/main_quest/quest_models.dart';
import '../modules/progress/progress_tracker.dart';
import '../modules/robot_maze/maze_models.dart';
import '../python_runtime/simulated_runtime.dart';

/// Composition root: creates every service once and wires the event bus.
class AppServices {
  AppServices._({
    required this.config,
    required this.clock,
    required this.db,
    required this.progress,
    required this.settings,
    required this.audio,
    required this.energy,
    required this.achievements,
    required this.quests,
    required this.events,
    required this.store,
    required this.customLevels,
    required this.python,
    required this.session,
    required this.robotMaze,
    required this.mainQuest,
    required this.bugHunter,
  });

  final GameConfig config;
  final Clock clock;
  final AppDatabase db;
  final ProgressRepository progress;
  final SettingsService settings;
  final AudioService audio;
  final EnergyService energy;
  final AchievementEngine achievements;
  final DailyQuestService quests;
  final GameEventHub events;
  final GameStore store;
  final CustomLevelRepository customLevels;
  final SimulatedPythonRuntime python;
  final SessionService session;
  final RobotMazeContent robotMaze;
  final MainQuestContent mainQuest;
  final BugHunterContent bugHunter;

  static Future<AppServices> create({
    required AssetBundle bundle,
    DatabaseFactory? databaseFactory,
    String? databasePath,
    Clock clock = const Clock(),
    bool audioEnabled = true,
    bool startSessionTimer = true,
  }) async {
    final config = await GameConfig.load(bundle);
    final db = await AppDatabase.open(factory: databaseFactory, path: databasePath);
    final progress = ProgressRepository(db);
    final settings = SettingsService(SettingsRepository(db));
    await settings.load();
    final audio = AudioService(settings, enabled: audioEnabled);
    // Audio loads in the background so the island opens without waiting.
    unawaited(audio.init());
    final energy = EnergyService(repo: EnergyRepository(db), progress: progress, config: config, clock: clock);
    await energy.init();
    final customLevels = CustomLevelRepository(db);
    final achievements = AchievementEngine(
      db: db,
      repo: AchievementRepository(db),
      progress: progress,
      customLevels: customLevels,
      clock: clock,
    );
    await achievements.init();
    final mainQuest = await MainQuestContent.load(bundle);
    final bugHunter = await BugHunterContent.load(bundle);
    final quests = DailyQuestService(
      DailyQuestRepository(db),
      clock,
      isBugHunterUnlocked: () async => (await progress.completedLessons()).contains(bugHunter.unlockLessonId),
    );
    final events = GameEventHub()
      ..register(ProgressTracker(progress, clock))
      ..register(energy)
      ..register(quests)
      ..register(achievements);
    await quests.ensureToday();
    final session = SessionService(clock, config.sessionReminderMinutes);
    if (startSessionTimer) session.start();
    return AppServices._(
      config: config,
      clock: clock,
      db: db,
      progress: progress,
      settings: settings,
      audio: audio,
      energy: energy,
      achievements: achievements,
      quests: quests,
      events: events,
      store: GameStore(db),
      customLevels: customLevels,
      python: SimulatedPythonRuntime(limits: config.pythonLimits),
      session: session,
      robotMaze: await RobotMazeContent.load(bundle),
      mainQuest: mainQuest,
      bugHunter: bugHunter,
    );
  }

  /// Wipes all progress (parent-gated in Settings) by recreating tables.
  Future<void> resetAllProgress() async {
    final sql = db.db;
    await sql.transaction((txn) async {
      for (final table in const [
        'progress',
        'skills',
        'reward_claims',
        'game_results',
        'unlocked_levels',
        'energy_state',
        'daily_quests',
        'achievements',
        'game_store',
        'custom_levels',
      ]) {
        await txn.delete(table);
      }
      await txn.delete('settings', where: "key <> 'schema_version'");
    });
    await settings.load();
    await energy.init();
    await achievements.init();
    await quests.ensureToday(force: true);
    events.revision.value++;
  }

  /// Stops timers (used by tests and when the app shuts down).
  void dispose() {
    energy.dispose();
    session.dispose();
  }
}
