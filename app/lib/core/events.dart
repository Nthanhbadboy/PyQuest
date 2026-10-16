import 'dart:async';

import 'package:flutter/foundation.dart';

/// Shared event format every activity sends (TECHNICAL_ARCHITECTURE §2.5).
/// Games never call the progress/achievement/quest systems directly.
class StandardEvent {
  StandardEvent({
    required this.type,
    required this.sourceId,
    this.data = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String type;
  final String sourceId;
  final Map<String, Object?> data;
  final DateTime timestamp;

  T? get<T>(String key) {
    final v = data[key];
    return v is T ? v : null;
  }

  @override
  String toString() => 'StandardEvent($type from $sourceId $data)';
}

abstract final class EventTypes {
  /// A level was won (stars >= 1). data: level_id, stars, score, next_level_id?
  static const levelCompleted = 'level_completed';

  /// A level attempt failed. data: level_id, fails
  static const levelFailed = 'level_failed';

  /// A lesson was finished. data: lesson_id, chapter_id, skills (`List<String>`), score
  static const lessonCompleted = 'lesson_completed';

  /// An exercise was solved. data: exercise_id, skills (`List<String>`)
  static const exerciseSolved = 'exercise_solved';

  /// data: chapter_id
  static const chapterCompleted = 'chapter_completed';

  /// data: puzzle_id, bug_index
  static const bugFixed = 'bug_fixed';

  /// Child code was executed. data: success (bool), context (String), recovered_from_limit (bool)
  static const codeRun = 'code_run';

  /// A loop construct solved something. data: key
  static const loopUsed = 'loop_used';

  /// Creator Mode test run. data: success
  static const creatorTestRun = 'creator_test_run';

  /// A self-made level was proven solvable. data: custom_id
  static const customGameVerified = 'custom_game_verified';

  /// data: activity_id
  static const activityOpened = 'activity_opened';

  /// Something collectible was obtained. data: item_id
  static const itemCollected = 'item_collected';
}

enum RewardKind { badge, quest, energy, unlock, item }

/// Something to celebrate on a result screen.
class RewardNotice {
  const RewardNotice({required this.kind, required this.id, required this.title, required this.description});
  final RewardKind kind;
  final String id;
  final String title;
  final String description;
}

class EventOutcome {
  final List<RewardNotice> notices = [];
  bool firstCompletion = false;
  int previousStars = 0;
  int bestStars = 0;
  int bestScore = 0;
  bool newHighScore = false;
}

abstract interface class GameEventListener {
  Future<void> onEvent(StandardEvent event, EventOutcome outcome);
}

/// Simple in-process event bus. Listeners run in registration order:
/// progress tracker → energy → daily quests → achievements.
class GameEventHub {
  final List<GameEventListener> _listeners = [];
  final StreamController<StandardEvent> _controller = StreamController<StandardEvent>.broadcast();

  /// Bumped after every processed event so screens can refresh saved data.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  Stream<StandardEvent> get stream => _controller.stream;

  void register(GameEventListener listener) => _listeners.add(listener);

  Future<EventOutcome> emit(StandardEvent event) async {
    final outcome = EventOutcome();
    for (final listener in _listeners) {
      await listener.onEvent(event, outcome);
    }
    revision.value++;
    _controller.add(event);
    return outcome;
  }

  void dispose() {
    _controller.close();
    revision.dispose();
  }
}
