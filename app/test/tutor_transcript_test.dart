import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/modules/tutor/tutor_models.dart';
import 'package:pyquest/modules/tutor/tutor_transcript.dart';
import 'package:pyquest/shared/characters/characters.dart';

/// The role model behind the tutor chat.
///
/// These are the rules that used to live in a `"Bé: " text prefix` and a
/// `startsWith` guess — the reason one mis-heard utterance could relabel the
/// tutor's own greeting as the child's speech.
void main() {
  group('speaker roles', () {
    test('every line carries its own role', () {
      final chat = TutorTranscript();
      chat.say('Chào bạn!', role: TutorSpeakerRole.assistant, character: CharacterId.nova);
      chat.say('Vì sao print in hai dòng?', role: TutorSpeakerRole.child);

      expect(chat.length, 2);
      expect(chat.lines[0].role, TutorSpeakerRole.assistant);
      expect(chat.lines[0].character, CharacterId.nova);
      expect(chat.lines[1].role, TutorSpeakerRole.child);
      expect(chat.lines[1].isChild, isTrue);
    });

    test('the tutor never speaks as the child, whatever the words are', () {
      final chat = TutorTranscript();
      // The exact sentence the tutor said, coming back from the microphone.
      chat.say('Chào bạn!', role: TutorSpeakerRole.assistant, character: CharacterId.kai);
      chat.say('Chào bạn!', role: TutorSpeakerRole.child, spoken: true);

      expect(chat.length, 2, reason: 'identical text is still two different turns');
      expect(chat.lines[0].role, TutorSpeakerRole.assistant);
      expect(chat.lines[1].role, TutorSpeakerRole.child);
      expect(chat.lines[0].character, CharacterId.kai);
    });
  });

  group('live partials', () {
    test('a growing partial updates its own bubble only', () {
      final chat = TutorTranscript();
      chat.say('print', role: TutorSpeakerRole.assistant, isFinal: false);
      chat.say('print nằm trong', role: TutorSpeakerRole.assistant, isFinal: false);
      chat.say('print nằm trong vòng lặp.', role: TutorSpeakerRole.assistant, isFinal: true);

      expect(chat.length, 1);
      expect(chat.lines.single.text, 'print nằm trong vòng lặp.');
      expect(chat.lines.single.isFinal, isTrue);
    });

    test('interleaved speakers each keep one line per utterance', () {
      final chat = TutorTranscript();
      chat.say('vì', role: TutorSpeakerRole.child, isFinal: false);
      chat.say('vì sao 3', role: TutorSpeakerRole.child, isFinal: false);
      chat.say('Chào em', role: TutorSpeakerRole.assistant, character: CharacterId.kai, isFinal: false);
      chat.say('Chào em, mình là Kai', role: TutorSpeakerRole.assistant, isFinal: false);

      expect(chat.length, 2, reason: 'two utterances, not four bubbles');
      expect(chat.lines[0].role, TutorSpeakerRole.child);
      expect(chat.lines[0].text, 'vì sao 3');
      expect(chat.lines[1].role, TutorSpeakerRole.assistant);
      expect(chat.lines[1].text, 'Chào em, mình là Kai');
      expect(chat.lines[1].character, CharacterId.kai);
      expect(chat.openIndexOf(TutorSpeakerRole.child), isNull,
          reason: 'the tutor starting to answer closes the child’s utterance');
      expect(chat.openIndexOf(TutorSpeakerRole.assistant), 1);
    });

    test('the next question never overwrites the answer before it', () {
      final chat = TutorTranscript();
      chat.say('Chào em, mình là Kai', role: TutorSpeakerRole.assistant, isFinal: false);
      chat.say('print in ra gì?', role: TutorSpeakerRole.child, isFinal: false);
      chat.say('In ra một dòng.', role: TutorSpeakerRole.assistant, isFinal: true);

      expect(chat.length, 3);
      expect(chat.lines.map((TutorLine line) => line.text).toList(),
          <String>['Chào em, mình là Kai', 'print in ra gì?', 'In ra một dòng.']);
    });

    test('a new turn from one speaker closes the other one’s unfinished line', () {
      final chat = TutorTranscript();
      chat.say('Câu trả lời đang', role: TutorSpeakerRole.assistant, isFinal: false);
      chat.say('còn đây là câu hỏi', role: TutorSpeakerRole.child, isFinal: true);

      expect(chat.length, 2);
      expect(chat.lines[0].isFinal, isTrue, reason: 'it stays on screen as what was said');
      expect(chat.openIndexOf(TutorSpeakerRole.assistant), isNull);
    });

    test('empty text never creates a bubble', () {
      final chat = TutorTranscript();
      expect(chat.say('   ', role: TutorSpeakerRole.child), -1);
      expect(chat.say('chưa có gì', role: TutorSpeakerRole.child), 0);
      expect(chat.say('', role: TutorSpeakerRole.child), 0);
      expect(chat.length, 1);
      expect(chat.lines.single.text, 'chưa có gì');
    });
  });

  group('turn state', () {
    test('an interrupted answer is marked, not deleted', () {
      final chat = TutorTranscript();
      chat.say('Em hãy xem dòng', role: TutorSpeakerRole.assistant, character: CharacterId.kai, isFinal: false);
      // What the live session emits when the child cut in: the sentence so far,
      // closed and labelled as cut short.
      chat.say(
        'Em hãy xem dòng',
        role: TutorSpeakerRole.assistant,
        character: CharacterId.kai,
        isFinal: true,
        interrupted: true,
      );

      expect(chat.length, 1);
      expect(chat.lines.single.text, 'Em hãy xem dòng');
      expect(chat.lines.single.isFinal, isTrue);
      expect(chat.lines.single.interrupted, isTrue);
    });

    test('sealing leaves the text alone', () {
      final chat = TutorTranscript();
      chat.say('một', role: TutorSpeakerRole.child);
      chat.say('hai', role: TutorSpeakerRole.assistant, isFinal: false);
      expect(chat.sealOpen(), 1, reason: 'only the newest utterance can still be open');
      expect(chat.lines.map((TutorLine line) => line.text).toList(), <String>['một', 'hai']);
      expect(chat.lines.every((TutorLine line) => line.isFinal), isTrue);
      expect(chat.sealOpen(), 0);
    });

    test('typed and spoken lines share the model but stay distinguishable', () {
      final chat = TutorTranscript();
      chat.say('Câu này gõ bằng bàn phím', role: TutorSpeakerRole.child);
      chat.say('Câu này nói bằng micro', role: TutorSpeakerRole.child, spoken: true);

      expect(chat.lines[0].spoken, isFalse);
      expect(chat.lines[1].spoken, isTrue);
    });

    test('answer metadata survives a partial revision', () {
      final chat = TutorTranscript();
      chat.say(
        'Gợi ý',
        role: TutorSpeakerRole.assistant,
        character: CharacterId.ada,
        source: TutorSource.offline,
        hintLevel: TutorHintLevel.pointing,
        failKind: TutorFailKind.timeout,
        isFinal: false,
      );
      chat.say('Gợi ý nhỏ: xem lại vòng lặp', role: TutorSpeakerRole.assistant, isFinal: true);

      final line = chat.lines.single;
      expect(line.character, CharacterId.ada);
      expect(line.source, TutorSource.offline);
      expect(line.hintLevel, TutorHintLevel.pointing);
      expect(line.failKind, TutorFailKind.timeout);
    });
  });

  test('the list is bounded, oldest first dropped', () {
    final chat = TutorTranscript(limit: 4);
    for (var i = 0; i < 10; i++) {
      chat.say('câu $i', role: TutorSpeakerRole.child);
    }
    expect(chat.length, 4);
    expect(chat.lines.first.text, 'câu 6');
    expect(chat.lines.last.text, 'câu 9');
  });
}
