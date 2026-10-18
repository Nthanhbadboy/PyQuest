import 'package:flutter/foundation.dart';

import '../../app/activity.dart';

enum MainMapPlacePhase { loading, ready, error }

@immutable
class MainMapPlaceState {
  const MainMapPlaceState.loading()
      : phase = MainMapPlacePhase.loading,
        status = null,
        error = null;

  const MainMapPlaceState.ready(ActivityStatus value)
      : phase = MainMapPlacePhase.ready,
        status = value,
        error = null;

  const MainMapPlaceState.error(this.error)
      : phase = MainMapPlacePhase.error,
        status = null;

  final MainMapPlacePhase phase;
  final ActivityStatus? status;
  final Object? error;
}

typedef MainMapStatusLoader = Future<ActivityStatus> Function();

/// Loads the six activity statuses independently and ignores stale completions.
/// Each loader owns only status reads; retry never emits activity-open events.
class MainMapSceneStatusController extends ChangeNotifier {
  MainMapSceneStatusController(Map<String, MainMapStatusLoader> loaders)
      : _loaders = Map<String, MainMapStatusLoader>.unmodifiable(loaders),
        _places = <String, MainMapPlaceState>{
          for (final String id in loaders.keys) id: const MainMapPlaceState.loading(),
        },
        _attempts = <String, int>{for (final String id in loaders.keys) id: 0};

  final Map<String, MainMapStatusLoader> _loaders;
  final Map<String, MainMapPlaceState> _places;
  final Map<String, int> _attempts;
  bool _disposed = false;

  Map<String, MainMapPlaceState> get places => Map<String, MainMapPlaceState>.unmodifiable(_places);

  Future<void> refresh() async {
    if (_disposed) return;
    for (final String id in _loaders.keys) {
      _attempts[id] = _attempts[id]! + 1;
      _places[id] = const MainMapPlaceState.loading();
    }
    notifyListeners();
    await Future.wait<void>(_loaders.keys.map(_load));
  }

  Future<void> retry(String id) async {
    if (_disposed || !_loaders.containsKey(id)) return;
    _attempts[id] = _attempts[id]! + 1;
    _places[id] = const MainMapPlaceState.loading();
    notifyListeners();
    await _load(id);
  }

  Future<void> _load(String id) async {
    final int attempt = _attempts[id]!;
    try {
      final ActivityStatus status = await _loaders[id]!();
      if (_isCurrent(id, attempt)) {
        _places[id] = MainMapPlaceState.ready(status);
        notifyListeners();
      }
    } catch (error) {
      if (_isCurrent(id, attempt)) {
        _places[id] = MainMapPlaceState.error(error);
        notifyListeners();
      }
    }
  }

  bool _isCurrent(String id, int attempt) => !_disposed && _attempts[id] == attempt;

  @override
  void dispose() {
    _disposed = true;
    for (final String id in _attempts.keys) {
      _attempts[id] = _attempts[id]! + 1;
    }
    super.dispose();
  }
}
