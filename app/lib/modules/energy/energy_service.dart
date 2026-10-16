import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../core/clock.dart';
import '../../core/config/game_config.dart';
import '../../core/events.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/state_repositories.dart';

/// Energy: regenerates over time (also while the app is closed), never
/// locks the map, completed lessons, the Achievement House or Creator Mode.
/// There are no ads and no purchases in this build.
class EnergyService extends ChangeNotifier implements GameEventListener {
  EnergyService({
    required EnergyRepository repo,
    required ProgressRepository progress,
    required GameConfig config,
    required Clock clock,
  })  : _repo = repo,
        _progress = progress,
        _config = config,
        _clock = clock;

  final EnergyRepository _repo;
  final ProgressRepository _progress;
  final GameConfig _config;
  final Clock _clock;

  int _current = 0;
  int _max = 20;
  DateTime _lastRegenAt = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _timer;

  int get current => _current;
  int get max => _max;
  bool get isFull => _current >= _max;
  Duration get regenInterval => _config.energyRegenInterval;

  /// Time until the next unit, or null when full.
  Duration? get timeToNext {
    if (isFull) return null;
    final next = _lastRegenAt.add(regenInterval);
    final left = next.difference(_clock.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// Time until completely full, or null when already full.
  Duration? get timeToFull {
    final next = timeToNext;
    if (next == null) return null;
    return next + regenInterval * (_max - _current - 1);
  }

  Future<void> init() async {
    final row = await _repo.load();
    final now = _clock.now();
    if (row == null) {
      _max = _config.energyMaxInitial;
      _current = _max;
      _lastRegenAt = now;
      await _save();
    } else {
      _current = row.current;
      _max = row.max;
      _lastRegenAt = DateTime.fromMillisecondsSinceEpoch(row.lastRegenAt);
      if (_applyRegen(now)) await _save();
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => refresh());
  }

  /// Applies regeneration that happened since the last check.
  Future<void> refresh() async {
    if (_applyRegen(_clock.now())) {
      notifyListeners();
      await _save();
    }
  }

  bool _applyRegen(DateTime now) {
    if (now.isBefore(_lastRegenAt)) {
      // Device clock moved backwards: restart the timer, never go negative.
      _lastRegenAt = now;
      return true;
    }
    if (_current >= _max) {
      // While full the regen clock is paused.
      _lastRegenAt = now;
      return false;
    }
    final intervalMs = regenInterval.inMilliseconds;
    final units = now.difference(_lastRegenAt).inMilliseconds ~/ intervalMs;
    if (units <= 0) return false;
    _current = math.min(_max, _current + units);
    _lastRegenAt = _current >= _max ? now : _lastRegenAt.add(Duration(milliseconds: intervalMs * units));
    return true;
  }

  bool canAfford(int amount) => amount <= 0 || _current >= amount;

  /// Spends energy if possible. Returns false (and changes nothing) otherwise.
  Future<bool> spend(int amount) async {
    if (amount <= 0) return true;
    _applyRegen(_clock.now());
    if (_current < amount) {
      notifyListeners();
      return false;
    }
    if (_current >= _max) _lastRegenAt = _clock.now();
    _current -= amount;
    notifyListeners();
    await _save();
    return true;
  }

  Future<void> _save() => _repo.save(EnergyRow(_current, _max, _lastRegenAt.millisecondsSinceEpoch));

  @override
  Future<void> onEvent(StandardEvent event, EventOutcome outcome) async {
    if (event.type != EventTypes.chapterCompleted) return;
    final chapter = event.get<String>('chapter_id');
    final bonus = _config.energyMilestoneBonus['chapter:$chapter'];
    if (chapter == null || bonus == null || bonus <= 0) return;
    if (!await _progress.claimOnce('energy_max:chapter:$chapter', _clock.now())) return;
    final newMax = math.min(_config.energyMaxCap, _max + bonus);
    if (newMax == _max) return;
    _applyRegen(_clock.now());
    final wasFull = _current >= _max;
    _max = newMax;
    if (wasFull) _lastRegenAt = _clock.now();
    await _save();
    notifyListeners();
    outcome.notices.add(RewardNotice(
      kind: RewardKind.energy,
      id: 'energy_max_$chapter',
      title: 'Bình năng lượng lớn hơn!',
      description: 'Năng lượng tối đa của bạn tăng lên $_max.',
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
