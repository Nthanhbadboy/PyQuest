import 'dart:async';

import 'package:flutter/widgets.dart';

import 'clock.dart';

/// Gentle break reminders after 30 / 45 / 60 minutes of continuous play.
/// Never blocks the game; leaving the app for 10+ minutes starts a new session.
class SessionService extends ChangeNotifier with WidgetsBindingObserver {
  SessionService(this._clock, this._thresholdMinutes);

  final Clock _clock;
  final List<int> _thresholdMinutes;
  final Set<int> _shown = {};
  Duration _active = Duration.zero;
  DateTime? _resumedAt;
  DateTime? _pausedAt;
  Timer? _timer;

  /// Minutes of the reminder waiting to be shown (null when none).
  int? pendingReminder;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _resumedAt = _clock.now();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _check());
  }

  Duration get activeTime {
    final r = _resumedAt;
    return r == null ? _active : _active + _clock.now().difference(r);
  }

  void _check() {
    final minutes = activeTime.inMinutes;
    for (final t in _thresholdMinutes) {
      if (minutes >= t && !_shown.contains(t)) {
        _shown.add(t);
        pendingReminder = t;
        notifyListeners();
        return;
      }
    }
  }

  void consumeReminder() => pendingReminder = null;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final now = _clock.now();
    if (state == AppLifecycleState.resumed) {
      final p = _pausedAt;
      if (p != null && now.difference(p) >= const Duration(minutes: 10)) {
        _active = Duration.zero;
        _shown.clear();
      }
      _pausedAt = null;
      _resumedAt ??= now;
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      final r = _resumedAt;
      if (r != null) _active += now.difference(r);
      _resumedAt = null;
      _pausedAt ??= now;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
