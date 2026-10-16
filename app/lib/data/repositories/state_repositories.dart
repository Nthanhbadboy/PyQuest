import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';

/// App-wide settings (sound, music, ...), stored as text key/value pairs.
class SettingsRepository {
  SettingsRepository(this._db);
  final AppDatabase _db;

  Future<Map<String, String>> all() async {
    final rows = await _db.db.query('settings');
    return {for (final r in rows) r['key'] as String: r['value'] as String};
  }

  Future<void> put(String key, String value) async {
    await _db.db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

class EnergyRow {
  const EnergyRow(this.current, this.max, this.lastRegenAt);
  final int current;
  final int max;
  final int lastRegenAt;
}

class EnergyRepository {
  EnergyRepository(this._db);
  final AppDatabase _db;

  Future<EnergyRow?> load() async {
    final rows = await _db.db.query('energy_state', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return EnergyRow(r['current_energy'] as int, r['max_energy'] as int, r['last_regen_at'] as int);
  }

  Future<void> save(EnergyRow row) async {
    await _db.db.insert(
      'energy_state',
      {'id': 1, 'current_energy': row.current, 'max_energy': row.max, 'last_regen_at': row.lastRegenAt},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

class AchievementRepository {
  AchievementRepository(this._db);
  final AppDatabase _db;

  Future<Map<String, DateTime>> unlocked() async {
    final rows = await _db.db.query('achievements');
    return {
      for (final r in rows)
        r['achievement_id'] as String: DateTime.fromMillisecondsSinceEpoch(r['unlocked_at'] as int),
    };
  }

  /// Returns true when the achievement was newly unlocked.
  Future<bool> unlock(String id, DateTime at) async {
    return _db.db.transaction((txn) async {
      final rows = await txn.query('achievements', where: 'achievement_id = ?', whereArgs: [id], limit: 1);
      if (rows.isNotEmpty) return false;
      await txn.insert('achievements', {'achievement_id': id, 'unlocked_at': at.millisecondsSinceEpoch, 'seen': 0});
      return true;
    });
  }

  Future<int> unseenCount() async {
    final rows = await _db.db.rawQuery('SELECT COUNT(*) AS c FROM achievements WHERE seen = 0');
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<void> markAllSeen() async {
    await _db.db.update('achievements', {'seen': 1});
  }
}

class DailyQuestRow {
  const DailyQuestRow(this.questId, this.progress, this.completed, this.rewarded);
  final String questId;
  final int progress;
  final bool completed;
  final bool rewarded;
}

class DailyQuestRepository {
  DailyQuestRepository(this._db);
  final AppDatabase _db;

  Future<List<DailyQuestRow>> forDay(String day) async {
    final rows = await _db.db.query('daily_quests', where: 'local_day = ?', whereArgs: [day], orderBy: 'rowid');
    return [
      for (final r in rows)
        DailyQuestRow(r['quest_id'] as String, r['progress'] as int, (r['completed'] as int) == 1,
            (r['rewarded'] as int) == 1),
    ];
  }

  Future<void> createDay(String day, List<String> questIds) async {
    await _db.db.transaction((txn) async {
      for (final id in questIds) {
        await txn.insert('daily_quests', {'local_day': day, 'quest_id': id, 'progress': 0, 'completed': 0, 'rewarded': 0},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<void> update(String day, String questId, {required int progress, required bool completed}) async {
    await _db.db.update('daily_quests', {'progress': progress, 'completed': completed ? 1 : 0},
        where: 'local_day = ? AND quest_id = ?', whereArgs: [day, questId]);
  }

  Future<bool> markRewarded(String day, String questId) async {
    final count = await _db.db.update('daily_quests', {'rewarded': 1},
        where: 'local_day = ? AND quest_id = ? AND completed = 1 AND rewarded = 0', whereArgs: [day, questId]);
    return count > 0;
  }

  Future<int> totalStamps() async {
    final rows = await _db.db.rawQuery('SELECT COUNT(*) AS c FROM daily_quests WHERE rewarded = 1');
    return (rows.first['c'] as int?) ?? 0;
  }
}

/// Private per-game storage (wallets, upgrades, collections...). Each game
/// module only touches its own `gameId` namespace.
class GameStore {
  GameStore(this._db);
  final AppDatabase _db;

  Future<String?> getString(String gameId, String key) async {
    final rows = await _db.db.query('game_store',
        columns: ['value'], where: 'game_id = ? AND key = ?', whereArgs: [gameId, key], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setString(String gameId, String key, String value) async {
    await _db.db.insert('game_store', {'game_id': gameId, 'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> getInt(String gameId, String key, {int fallback = 0}) async {
    final v = await getString(gameId, key);
    return v == null ? fallback : (int.tryParse(v) ?? fallback);
  }

  Future<void> setInt(String gameId, String key, int value) => setString(gameId, key, '$value');

  Future<int> addInt(String gameId, String key, int delta) async {
    return _db.db.transaction((txn) async {
      final rows = await txn.query('game_store',
          columns: ['value'], where: 'game_id = ? AND key = ?', whereArgs: [gameId, key], limit: 1);
      final current = rows.isEmpty ? 0 : (int.tryParse(rows.first['value'] as String) ?? 0);
      final next = current + delta;
      await txn.insert('game_store', {'game_id': gameId, 'key': key, 'value': '$next'},
          conflictAlgorithm: ConflictAlgorithm.replace);
      return next;
    });
  }

  Future<List<String>> getList(String gameId, String key) async {
    final v = await getString(gameId, key);
    if (v == null || v.isEmpty) return [];
    return (jsonDecode(v) as List).cast<String>();
  }

  Future<void> setList(String gameId, String key, List<String> values) => setString(gameId, key, jsonEncode(values));
}

class CustomLevel {
  const CustomLevel({
    required this.id,
    required this.gameId,
    required this.name,
    required this.data,
    required this.verified,
    required this.updatedAt,
  });

  final int id;
  final String gameId;
  final String name;
  final Map<String, dynamic> data;
  final bool verified;
  final DateTime updatedAt;
}

/// Creations made in Creator Mode.
class CustomLevelRepository {
  CustomLevelRepository(this._db);
  final AppDatabase _db;

  Future<List<CustomLevel>> list(String gameId) async {
    final rows = await _db.db.query('custom_levels', where: 'game_id = ?', whereArgs: [gameId], orderBy: 'updated_at DESC');
    return [for (final r in rows) _fromRow(r)];
  }

  Future<int> countVerified() async {
    final rows = await _db.db.rawQuery('SELECT COUNT(*) AS c FROM custom_levels WHERE verified = 1');
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<int> save({
    int? id,
    required String gameId,
    required String name,
    required Map<String, dynamic> data,
    required bool verified,
    required DateTime at,
  }) async {
    final values = {
      'game_id': gameId,
      'name': name,
      'data': jsonEncode(data),
      'verified': verified ? 1 : 0,
      'updated_at': at.millisecondsSinceEpoch,
    };
    if (id == null) {
      return _db.db.insert('custom_levels', {...values, 'created_at': at.millisecondsSinceEpoch});
    }
    await _db.db.update('custom_levels', values, where: 'id = ?', whereArgs: [id]);
    return id;
  }

  Future<void> delete(int id) async {
    await _db.db.delete('custom_levels', where: 'id = ?', whereArgs: [id]);
  }

  CustomLevel _fromRow(Map<String, Object?> r) => CustomLevel(
        id: r['id'] as int,
        gameId: r['game_id'] as String,
        name: r['name'] as String,
        data: jsonDecode(r['data'] as String) as Map<String, dynamic>,
        verified: (r['verified'] as int) == 1,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int),
      );
}
