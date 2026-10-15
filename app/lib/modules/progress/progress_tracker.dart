import '../../core/clock.dart';
import '../../core/events.dart';
import '../../data/repositories/progress_repository.dart';

/// Persists progress from [StandardEvent]s: levels, lessons, skills and
/// idempotent claims (bugs fixed, exercises, loops, visits, creations).
class ProgressTracker implements GameEventListener {
  ProgressTracker(this._repo, this._clock);

  final ProgressRepository _repo;
  final Clock _clock;

  @override
  Future<void> onEvent(StandardEvent event, EventOutcome outcome) async {
    final now = _clock.now();
    switch (event.type) {
      case EventTypes.levelCompleted:
        final levelId = event.get<String>('level_id')!;
        final stars = event.get<int>('stars') ?? 1;
        final score = event.get<int>('score') ?? 0;
        final saved = await _repo.saveLevelResult(
          gameId: event.sourceId,
          levelId: levelId,
          stars: stars,
          score: score,
          at: now,
        );
        outcome.firstCompletion = saved.firstCompletion;
        outcome.previousStars = saved.previous?.stars ?? 0;
        outcome.bestStars = saved.current.stars;
        outcome.bestScore = saved.current.highScore;
        outcome.newHighScore = saved.newHighScore;
        final next = event.get<String>('next_level_id');
        if (next != null) {
          await _repo.unlockLevel(event.sourceId, next, now);
        }
      case EventTypes.lessonCompleted:
        final lessonId = event.get<String>('lesson_id')!;
        final first = await _repo.completeLesson(lessonId, event.get<int>('score') ?? 0, now);
        outcome.firstCompletion = first;
        final skills = (event.data['skills'] as List?)?.cast<String>() ?? const <String>[];
        for (final skill in skills) {
          await _repo.learnSkill(skill, now);
        }
      case EventTypes.exerciseSolved:
        final id = event.get<String>('exercise_id')!;
        final skills = (event.data['skills'] as List?)?.cast<String>() ?? const <String>[];
        await _repo.claimOnce('exercise:$id', now);
        if (skills.contains('conditions')) await _repo.claimOnce('cond_ex:$id', now);
        if (skills.contains('loops')) await _repo.claimOnce('loop:$id', now);
      case EventTypes.loopUsed:
        await _repo.claimOnce('loop:${event.get<String>('key')}', now);
      case EventTypes.chapterCompleted:
        await _repo.claimOnce('chapter:${event.get<String>('chapter_id')}', now);
      case EventTypes.bugFixed:
        final first = await _repo.claimOnce('bug:${event.get<String>('puzzle_id')}:${event.get<int>('bug_index')}', now);
        outcome.firstCompletion = first;
      case EventTypes.customGameVerified:
        await _repo.claimOnce('custom:${event.sourceId}:${event.get<int>('custom_id')}', now);
      case EventTypes.activityOpened:
        await _repo.claimOnce('visited:${event.get<String>('activity_id')}', now);
      case EventTypes.itemCollected:
        await _repo.claimOnce('item:${event.sourceId}:${event.get<String>('item_id')}', now);
    }
  }
}
