import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Single SQLite database for all gameplay state (no JSON files for state).
///
/// Schema changes go through [_migrations]; the current version is stored in
/// `settings.schema_version` and the file is backed up before migrating.
/// SQL is kept to features available in Android 7's SQLite 3.9 (no UPSERT).
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const int schemaVersion = 1;
  static const String fileName = 'pyquest.db';

  /// Opens (and migrates) the on-device database.
  static Future<AppDatabase> open({DatabaseFactory? factory, String? path}) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), fileName);
    final isMemory = dbPath == inMemoryDatabasePath;
    final db = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        singleInstance: !isMemory,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
    final appDb = AppDatabase._(db);
    await appDb._migrate(isMemory ? null : dbPath);
    return appDb;
  }

  Future<void> close() => db.close();

  Future<int> _currentVersion() async {
    await db.execute('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    final rows = await db.query('settings', where: 'key = ?', whereArgs: ['schema_version']);
    if (rows.isEmpty) return 0;
    return int.tryParse(rows.first['value'] as String) ?? 0;
  }

  Future<void> _migrate(String? filePath) async {
    final from = await _currentVersion();
    if (from >= schemaVersion) return;
    if (from > 0 && filePath != null) {
      final file = File(filePath);
      if (await file.exists()) {
        await file.copy('$filePath.v$from.bak');
      }
    }
    await db.transaction((txn) async {
      for (var v = from + 1; v <= schemaVersion; v++) {
        for (final sql in _migrations[v]!) {
          await txn.execute(sql);
        }
      }
      await txn.execute(
        'INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)',
        ['schema_version', '$schemaVersion'],
      );
    });
  }

  static const Map<int, List<String>> _migrations = {
    1: [
      '''CREATE TABLE IF NOT EXISTS progress (
           id INTEGER PRIMARY KEY AUTOINCREMENT,
           lesson_id TEXT NOT NULL UNIQUE,
           best_score INTEGER NOT NULL DEFAULT 0,
           completed_at INTEGER NOT NULL)''',
      '''CREATE TABLE IF NOT EXISTS skills (
           skill_id TEXT PRIMARY KEY,
           learned_at INTEGER NOT NULL)''',
      '''CREATE TABLE IF NOT EXISTS reward_claims (
           reward_key TEXT PRIMARY KEY,
           awarded_at INTEGER NOT NULL)''',
      '''CREATE TABLE IF NOT EXISTS game_results (
           id INTEGER PRIMARY KEY AUTOINCREMENT,
           game_id TEXT NOT NULL,
           level_id TEXT NOT NULL,
           stars INTEGER NOT NULL,
           high_score INTEGER NOT NULL,
           plays INTEGER NOT NULL DEFAULT 1,
           completed_at INTEGER NOT NULL,
           UNIQUE (game_id, level_id))''',
      '''CREATE TABLE IF NOT EXISTS unlocked_levels (
           game_id TEXT NOT NULL,
           level_id TEXT NOT NULL,
           unlocked_at INTEGER NOT NULL,
           PRIMARY KEY (game_id, level_id))''',
      '''CREATE TABLE IF NOT EXISTS energy_state (
           id INTEGER PRIMARY KEY CHECK (id = 1),
           current_energy INTEGER NOT NULL,
           max_energy INTEGER NOT NULL,
           last_regen_at INTEGER NOT NULL)''',
      '''CREATE TABLE IF NOT EXISTS daily_quests (
           local_day TEXT NOT NULL,
           quest_id TEXT NOT NULL,
           progress INTEGER NOT NULL DEFAULT 0,
           completed INTEGER NOT NULL DEFAULT 0,
           rewarded INTEGER NOT NULL DEFAULT 0,
           PRIMARY KEY (local_day, quest_id))''',
      '''CREATE TABLE IF NOT EXISTS achievements (
           achievement_id TEXT PRIMARY KEY,
           unlocked_at INTEGER NOT NULL,
           seen INTEGER NOT NULL DEFAULT 0)''',
      '''CREATE TABLE IF NOT EXISTS game_store (
           game_id TEXT NOT NULL,
           key TEXT NOT NULL,
           value TEXT NOT NULL,
           PRIMARY KEY (game_id, key))''',
      '''CREATE TABLE IF NOT EXISTS custom_levels (
           id INTEGER PRIMARY KEY AUTOINCREMENT,
           game_id TEXT NOT NULL,
           name TEXT NOT NULL,
           data TEXT NOT NULL,
           verified INTEGER NOT NULL DEFAULT 0,
           created_at INTEGER NOT NULL,
           updated_at INTEGER NOT NULL)''',
    ],
  };
}
