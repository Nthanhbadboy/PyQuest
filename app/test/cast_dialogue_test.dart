import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/modules/main_quest/quest_models.dart';
import 'package:pyquest/shared/characters/cast.dart';
import 'package:pyquest/shared/characters/characters.dart';
import 'package:pyquest/shared/characters/dialogue.dart';
import 'package:pyquest/shared/l10n/pq_l10n.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('cast painters', () {
    test('every character can be painted in every mood without a crash', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      for (final id in CharacterId.values) {
        for (final mood in Mood.values) {
          for (final size in const [Size(140, 140), Size(40, 40)]) {
            final painter = characterPainter(id, t: 0.42, blink: 1, bob: -0.02, mood: mood);
            painter.paint(canvas, size);
            expect(painter.shouldRepaint(characterPainter(id, mood: Mood.happy)), isTrue,
                reason: '${id.name}/$mood must repaint when the mood changes');
          }
        }
      }
      recorder.endRecording().dispose();
    });

    test('the two human-wide moods exist for every character and are distinct', () {
      expect(Mood.values, containsAll([Mood.celebrating, Mood.confused]));
      final celebrating = characterPainter(CharacterId.nova, mood: Mood.celebrating);
      final confused = characterPainter(CharacterId.nova, mood: Mood.confused);
      expect(celebrating.shouldRepaint(confused), isTrue);
    });
  });

  group('dialogue', () {
    test('every cast member has a line for every moment in both languages', () {
      for (final member in CastRegistry.members) {
        for (final moment in DialogueMoment.values) {
          for (final lang in PqLang.values) {
            final line = CastDialogue.line(member.id, moment, lang, seed: 0);
            expect(line, isNotEmpty, reason: '${member.id.name}/$moment/${lang.code} fell back to nothing');
            final variants = CastDialogue.variants(member.id, moment, lang);
            for (final v in variants) {
              expect(v.trim(), isNotEmpty);
            }
          }
        }
      }
    });

    test('lines rotate deterministically and never repeat the same sentence forever', () {
      final first = CastDialogue.line(CharacterId.nova, DialogueMoment.greet, PqLang.vi, seed: 0);
      final again = CastDialogue.line(CharacterId.nova, DialogueMoment.greet, PqLang.vi, seed: 0);
      expect(again, first, reason: 'the same seed must give the same line');
      final second = CastDialogue.line(CharacterId.nova, DialogueMoment.greet, PqLang.vi, seed: 1);
      expect(second, isNot(first), reason: 'a new moment picks the next variant');
    });

    test('a member with no specialised line still speaks through the fallback', () {
      final line = CastDialogue.line(CharacterId.robo, DialogueMoment.quotaEmpty, PqLang.vi);
      expect(line, isNotEmpty);
      expect(line, contains('AI'));
    });
  });

  group('tutor routing', () {
    test('skills route to the character who teaches that topic', () {
      expect(CastRegistry.tutorForSkill('Vòng lặp'), CastRegistry.loop);
      expect(CastRegistry.tutorForSkill('while'), CastRegistry.loop);
      expect(CastRegistry.tutorForSkill('Biến'), CastRegistry.bit);
      expect(CastRegistry.tutorForSkill('Hàm'), CastRegistry.ada);
      expect(CastRegistry.tutorForSkill('Điều kiện if'), CastRegistry.pixel);
      expect(CastRegistry.tutorForSkill('In ra màn hình'), CastRegistry.nova);
      expect(CastRegistry.tutorForSkill('Kỹ năng hoàn toàn mới'), CastRegistry.py,
          reason: 'an unknown skill still gets a tutor');
    });

    test('mini-games have their own host', () {
      expect(CastRegistry.tutorForSkillOrModule('', moduleId: 'robot_maze'), CastRegistry.robo);
      expect(CastRegistry.tutorForSkillOrModule('', moduleId: 'bug_hunter'), CastRegistry.byte);
      expect(CastRegistry.tutorForSkillOrModule('Vòng lặp', moduleId: 'dragon_jump'), CastRegistry.pip);
    });

    test('every lesson in the real curriculum has an available tutor', () async {
      final lessons = MainQuestContent.fromJson(
        jsonDecode(await rootBundle.loadString('assets/data/main_quest_ch1.json')) as Map<String, dynamic>,
      ).lessons;
      expect(lessons, isNotEmpty);
      for (final lesson in lessons) {
        final tutor = CastRegistry.tutorForSkill(lesson.skill);
        // The tutor must already be unlocked when the lesson is played, or there
        // would be a lesson whose helper has not joined the island yet.
        final unlockLesson = tutor.unlockLessonId;
        if (unlockLesson != null) {
          final unlockNumber = lessons.firstWhere((l) => l.id == unlockLesson).number;
          expect(unlockNumber, lessThanOrEqualTo(lesson.number),
              reason: '${lesson.id} (${lesson.skill}) routes to ${tutor.name}, unlocked at $unlockLesson');
        }
      }
    });

    test('roster grows with progress and always keeps the core helpers', () {
      final none = CastRegistry.unlocked(const {});
      expect(none.map((m) => m.id), containsAll([CharacterId.nova, CharacterId.py, CharacterId.robo]));
      expect(none.map((m) => m.id), isNot(contains(CharacterId.lumi)));

      final everything = CastRegistry.unlocked({'mq1_01', 'mq1_03', 'mq1_04', 'mq1_06', 'mq1_08', 'mq1_10'});
      expect(everything.length, CastRegistry.members.length);
    });

    test('every member exposes a persona short enough for a prompt', () {
      for (final member in CastRegistry.members) {
        expect(member.promptPersona.length, lessThan(400));
        expect(member.roleVi, isNotEmpty);
        expect(member.roleEn, isNotEmpty);
        expect(member.colourHex, startsWith('#'));
        expect(member.topics, isNotEmpty);
        expect(CastDialogue.topicLine(member, PqLang.vi), isNotEmpty);
        expect(CastDialogue.topicLine(member, PqLang.en), isNotEmpty);
      }
    });

    test('the topic index covers the whole curriculum map', () {
      expect(CastRegistry.byScope(CastScope.human), isNotEmpty);
      expect(CastRegistry.byScope(CastScope.animal), isNotEmpty);
      expect(CastRegistry.byScope(CastScope.robot), isNotEmpty);
      expect(CastRegistry.byScope(CastScope.fantasy), isNotEmpty);
      for (final topic in TutorTopic.values) {
        expect(CastRegistry.tutorForTopic(topic).topics, contains(topic));
      }
    });
  });
}
