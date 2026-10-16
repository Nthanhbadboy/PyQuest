import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/app/app_services.dart';
import 'package:pyquest/core/events.dart';
import 'package:pyquest/data/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_helpers.dart';

Future<AppServices> makeServices(FakeClock clock, {String? path}) => AppServices.create(
      bundle: rootBundle,
      databaseFactory: databaseFactoryFfiNoIsolate,
      databasePath: path ?? inMemoryDatabasePath,
      clock: clock,
      audioEnabled: false,
      startSessionTimer: false,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('energy regenerates over time, caps at max and never goes negative', () async {
    final clock = FakeClock(DateTime(2026, 10, 15, 9));
    final s = await makeServices(clock);
    expect(s.energy.current, 20);
    expect(s.energy.isFull, isTrue);
    expect(await s.energy.spend(2), isTrue);
    expect(s.energy.current, 18);
    expect(s.energy.timeToNext, const Duration(minutes: 10));
    clock.advance(const Duration(minutes: 25));
    await s.energy.refresh();
    expect(s.energy.current, 20, reason: 'two units regenerated, capped at max');
    expect(await s.energy.spend(20), isTrue);
    expect(await s.energy.spend(1), isFalse);
    expect(s.energy.current, 0);
    clock.advance(const Duration(minutes: 10));
    await s.energy.refresh();
    expect(s.energy.current, 1);
    // Clock moved backwards: no negative regen, no crash.
    clock.advance(const Duration(hours: -3));
    await s.energy.refresh();
    expect(s.energy.current, 1);
    s.dispose();
    await s.db.close();
  });

  test('level results keep the best score/stars and rewards are idempotent', () async {
    final clock = FakeClock(DateTime(2026, 10, 15, 9));
    final s = await makeServices(clock);
    final first = await s.events.emit(StandardEvent(
      type: EventTypes.levelCompleted,
      sourceId: 'robot_maze',
      data: {'level_id': 'rm_01', 'stars': 2, 'score': 70, 'next_level_id': 'rm_02'},
    ));
    expect(first.firstCompletion, isTrue);
    expect(first.notices.map((n) => n.id), contains('first_steps'));
    final again = await s.events.emit(StandardEvent(
      type: EventTypes.levelCompleted,
      sourceId: 'robot_maze',
      data: {'level_id': 'rm_01', 'stars': 1, 'score': 40},
    ));
    expect(again.firstCompletion, isFalse);
    expect(again.notices.where((n) => n.id == 'first_steps'), isEmpty, reason: 'badges are awarded once');
    final record = await s.progress.levelRecord('robot_maze', 'rm_01');
    expect(record!.stars, 2);
    expect(record.highScore, 70);
    expect(record.plays, 2);
    expect(await s.progress.unlockedLevels('robot_maze'), contains('rm_02'));
    expect(await s.progress.claimOnce('test:key', clock.now()), isTrue);
    expect(await s.progress.claimOnce('test:key', clock.now()), isFalse);
    s.dispose();
    await s.db.close();
  });

  test('lessons, badges and the chapter milestone', () async {
    final clock = FakeClock(DateTime(2026, 10, 15, 21)); // 9 pm → secret Night Owl
    final s = await makeServices(clock);
    final o = await s.events.emit(StandardEvent(
      type: EventTypes.lessonCompleted,
      sourceId: 'main_quest',
      timestamp: clock.now(),
      data: {'lesson_id': 'mq1_01', 'chapter_id': 'code_apprentice', 'skills': ['py:print()'], 'score': 100},
    ));
    final ids = o.notices.map((n) => n.id).toList();
    expect(ids, containsAll(['first_line', 'night_owl']));
    expect(await s.progress.learnedSkills(), contains('py:print()'));
    final chapter = await s.events.emit(StandardEvent(
      type: EventTypes.chapterCompleted,
      sourceId: 'main_quest',
      data: {'chapter_id': 'code_apprentice'},
    ));
    expect(chapter.notices.map((n) => n.id), containsAll(['code_apprentice', 'energy_max_code_apprentice']));
    expect(s.energy.max, 25);
    final twice = await s.events.emit(StandardEvent(
      type: EventTypes.chapterCompleted,
      sourceId: 'main_quest',
      data: {'chapter_id': 'code_apprentice'},
    ));
    expect(twice.notices, isEmpty);
    expect(s.energy.max, 25, reason: 'milestone bonus is granted once');
    s.dispose();
    await s.db.close();
  });

  test('daily quests: three per day, progress, stamp, reset at local midnight', () async {
    final clock = FakeClock(DateTime(2026, 10, 15, 10));
    final s = await makeServices(clock);
    expect(s.quests.quests, hasLength(3));
    final codeQuest = s.quests.quests.any((q) => q.def.id == 'code_runs_3' || q.def.id == 'lesson_1');
    expect(codeQuest, isTrue, reason: 'one learning quest per day');
    for (var i = 0; i < 3; i++) {
      await s.events.emit(StandardEvent(type: EventTypes.codeRun, sourceId: 'test', data: {'success': true, 'context': 'lesson'}));
    }
    await s.events.emit(StandardEvent(
      type: EventTypes.lessonCompleted,
      sourceId: 'main_quest',
      data: {'lesson_id': 'mq1_01', 'chapter_id': 'code_apprentice', 'skills': <String>[], 'score': 100},
    ));
    final learn = s.quests.quests.firstWhere((q) => q.def.category.name == 'learn');
    expect(learn.completed, isTrue);
    expect(await s.quests.claimStamp(learn.def.id), isTrue);
    expect(await s.quests.claimStamp(learn.def.id), isFalse);
    expect(s.quests.totalStamps, 1);
    clock.advance(const Duration(days: 1));
    await s.quests.ensureToday();
    expect(s.quests.quests.every((q) => !q.completed), isTrue);
    s.dispose();
    await s.db.close();
  });

  test('progress survives closing and reopening the database file', () async {
    final dir = await Directory.systemTemp.createTemp('pyquest_test');
    final path = '${dir.path}/${AppDatabase.fileName}';
    final clock = FakeClock(DateTime(2026, 10, 15, 10));
    final a = await makeServices(clock, path: path);
    await a.energy.spend(3);
    await a.events.emit(StandardEvent(
      type: EventTypes.levelCompleted,
      sourceId: 'robot_maze',
      data: {'level_id': 'rm_01', 'stars': 3, 'score': 100},
    ));
    await a.store.addInt('dragon_jump', 'coins', 42);
    await a.settings.setMusicOn(false);
    a.dispose();
    await a.db.close();

    final b = await makeServices(clock, path: path);
    expect(b.energy.current, 17);
    expect((await b.progress.levelRecord('robot_maze', 'rm_01'))!.stars, 3);
    expect(await b.store.getInt('dragon_jump', 'coins'), 42);
    expect(b.settings.musicOn, isFalse);
    expect(b.achievements.isUnlocked('first_steps'), isTrue);
    b.dispose();
    await b.db.close();
    await dir.delete(recursive: true);
  });
}
