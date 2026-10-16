import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/modules/tutor/gemini_live_voice.dart';
import 'package:pyquest/modules/tutor/tutor_transcript.dart';
import 'package:pyquest/shared/characters/characters.dart';
import 'package:record/record.dart';

import 'test_helpers.dart';

/// Drives a voice session the way a device's socket does: server messages in,
/// transcripts and speaker bytes out. No microphone, no network, no key.
///
/// The two cases that matter here are the ones the tutor failed on real
/// devices: an answer that reaches the chat must also reach the speaker, and
/// the tutor's own voice must never come back as the child's sentence.
void main() {
  late FakePcmOutput output;
  late GeminiLiveVoice voice;
  late List<TutorVoiceStatus> statuses;
  late List<String> errors;
  late List<VoiceUtterance> utterances;
  late TutorTranscript chat;

  setUp(() {
    output = FakePcmOutput();
    statuses = <TutorVoiceStatus>[];
    errors = <String>[];
    utterances = <VoiceUtterance>[];
    chat = TutorTranscript();
    voice = GeminiLiveVoice(
      audioOutput: output,
      onStatus: (TutorVoiceStatus status) => statuses.add(status),
      onTranscript: (VoiceUtterance utterance) {
        utterances.add(utterance);
        chat.say(
          utterance.text,
          role: utterance.role,
          character: utterance.role.isAssistant ? CharacterId.kai : null,
          isFinal: utterance.isFinal,
          interrupted: utterance.interrupted,
          spoken: true,
        );
      },
      onError: (String message) => errors.add(message),
    );
  });

  Map<String, Object?> message(Map<String, Object?> serverContent) => <String, Object?>{
        'serverContent': serverContent,
      };

  Map<String, Object?> audioMessage(List<int> bytes, {Map<String, Object?> extra = const {}}) => message(<String, Object?>{
        'modelTurn': <String, Object?>{
          'role': 'model',
          'parts': <Object?>[
            <String, Object?>{
              'inlineData': <String, Object?>{'mimeType': 'audio/pcm;rate=24000', 'data': base64Encode(bytes)},
            },
          ],
        },
        ...extra,
      });

  Map<String, Object?> spoken(String text, {bool done = false}) => message(<String, Object?>{
        'outputTranscription': <String, String>{'text': text},
        if (done) 'turnComplete': true,
      });

  Map<String, Object?> heard(String text) => message(<String, Object?>{
        'inputTranscription': <String, String>{'text': text},
      });

  List<String> linesOf(TutorSpeakerRole role) =>
      utterances.where((VoiceUtterance u) => u.role == role).map((VoiceUtterance u) => u.text).toList();

  group('audio and text', () {
    test('a spoken answer is handed to the speaker, not only to the chat', () async {
      await voice.pump.prepare();
      voice.handleServerMessageForTest(audioMessage(voiceAudio(2)));

      expect(voice.pump.pendingBytes, 2 * kVoiceSliceBytes);
      expect(utterances, isEmpty, reason: 'audio alone is not a transcript line');
    });

    test('the tutor answer is one line, from greeting to final text', () async {
      await voice.pump.prepare();
      voice.handleServerMessageForTest(spoken('Chào'));
      voice.handleServerMessageForTest(spoken('Chào em, mình là Kai'));
      voice.handleServerMessageForTest(spoken('Chào em, mình là Kai. Hôm nay ta học print nhé?', done: true));

      expect(
        utterances.where((VoiceUtterance u) => u.role.isAssistant && !u.isFinal).length,
        2,
        reason: 'the child sees the answer as it arrives',
      );
      expect(utterances.last.isFinal, isTrue);
      expect(chat.lines.where((TutorLine line) => line.role.isAssistant), hasLength(1),
          reason: 'a growing partial must not become two bubbles');
      expect(chat.lines.single.text, 'Chào em, mình là Kai. Hôm nay ta học print nhé?');
    });

    test("the child's line grows in place instead of duplicating", () async {
      await voice.pump.prepare();
      for (final partial in <String>['vì', 'vì sao', 'vì sao 3']) {
        voice.handleServerMessageForTest(heard(partial));
      }
      expect(linesOf(TutorSpeakerRole.child), <String>['vì', 'vì sao', 'vì sao 3']);
      expect(chat.lines, hasLength(1), reason: 'one utterance, one bubble');
    });

    test('both speakers stay visible and separate in one turn', () async {
      await voice.pump.prepare();
      voice.handleServerMessageForTest(heard('vì sao 3'));
      voice.handleServerMessageForTest(spoken('Vì print nằm'));
      voice.handleServerMessageForTest(spoken('Vì print nằm trong vòng lặp.', done: true));

      expect(chat.lines.map((TutorLine line) => line.role).toList(),
          <TutorSpeakerRole>[TutorSpeakerRole.child, TutorSpeakerRole.assistant]);
      expect(chat.lines.last.character, CharacterId.kai);
      expect(chat.lines.first.text, 'vì sao 3');
    });
  });

  group('the tutor must not hear itself', () {
    test('the microphone is captured on the echo-cancelling voice path', () {
      final live = GeminiLiveVoice.recorderConfig();
      expect(live.encoder, AudioEncoder.pcm16bits);
      expect(live.sampleRate, 16000);
      expect(live.numChannels, 1);
      expect(live.echoCancel, isTrue);
      // The part that actually cancels the echo on Android: the platform only
      // runs acoustic echo cancellation on the voice-communication path, and
      // the default mic source silently ignores the flag above.
      expect(live.androidConfig.audioSource, AndroidAudioSource.voiceCommunication);
    });

    test('the tutor’s own greeting is not shown as the child speaking', () async {
      await voice.pump.prepare();
      voice.handleServerMessageForTest(audioMessage(
        voiceAudio(4).toList(),
        extra: <String, Object?>{'outputTranscription': <String, String>{'text': 'Chào bạn! Mình là Kai.'}, 'turnComplete': true},
      ));
      expect(chat.lines.where((TutorLine line) => line.role.isAssistant), hasLength(1));

      // The phone's speaker plays that greeting and the microphone picks it up.
      voice.handleServerMessageForTest(heard('Chào bạn! Mình là Kai.'));

      expect(chat.lines.where((TutorLine line) => line.role.isChild), isEmpty,
          reason: 'the tutor’s own voice must never become the learner’s line');
      expect(voice.echoDropped, 1);
      expect(utterances.where((VoiceUtterance u) => u.role.isChild), isEmpty);
    });

    test('what the child really says is still shown after the answer played out', () async {
      await voice.pump.prepare();
      voice.handleServerMessageForTest(audioMessage(
        voiceAudio(2).toList(),
        extra: <String, Object?>{'outputTranscription': <String, String>{'text': 'Chào bạn! Mình là Kai.'}, 'turnComplete': true},
      ));
      await voice.pump.pumpOnce();
      // The turn plays out and the echo window passes.
      await Future<void>.delayed(const Duration(milliseconds: 800));
      await voice.pump.pumpOnce();
      await Future<void>.delayed(const Duration(milliseconds: 1300));

      expect(voice.echoSuspect, isFalse, reason: 'the tutor is quiet by now');
      voice.handleServerMessageForTest(heard('Chào bạn'));
      expect(chat.lines.where((TutorLine line) => line.role.isChild), hasLength(1),
          reason: 'a child who answers with the same words is still heard');
    });

    test('an interruption clears the speech that has not been played but keeps the sentence', () async {
      await voice.pump.prepare();
      voice.handleServerMessageForTest(spoken('print nằm trong'));
      voice.handleServerMessageForTest(audioMessage(voiceAudio(6).toList()));
      expect(voice.pump.pendingBytes, greaterThan(0));

      voice.handleServerMessageForTest(message(<String, Object?>{'interrupted': true}));
      expect(voice.pump.pendingBytes, 0, reason: 'unplayed audio is dropped');
      expect(utterances.last.isFinal, isTrue);
      expect(utterances.last.interrupted, isTrue);
      expect(chat.lines.single.text, 'print nằm trong');
      expect(chat.lines.single.interrupted, isTrue,
          reason: 'the UI must say the answer was cut short, not hide it');
    });
  });

  group('session state', () {
    test('the tutor speaks, then listens again — the microphone is not left open', () async {
      await voice.pump.prepare();
      voice.handleServerMessageForTest(audioMessage(voiceAudio(2).toList(), extra: <String, Object?>{'turnComplete': true}));
      expect(voice.phase, VoicePhase.off);

      await voice.pump.pumpOnce();
      expect(voice.isSpeakingAloud, isTrue, reason: 'audio reached the device');
      expect(voice.phase, VoicePhase.speaking);
      expect(statuses.last.phase, VoicePhase.speaking);
      expect(statuses.last.message, contains('đang nói'));

      // The pump's lead + tail (about half a second) has to pass in real time.
      await Future<void>.delayed(const Duration(milliseconds: 700));
      await voice.pump.pumpOnce();

      expect(voice.isSpeakingAloud, isFalse);
      expect(voice.phase, VoicePhase.listening, reason: 'no status string says so, the phase does');
      expect(statuses.last.message, contains('Đang nghe bé nói'));
      expect(voice.resumeListeningAt.isAfter(DateTime.now()), isTrue,
          reason: 'the tail of the tutor’s own voice must not open a new turn');
    });

    test('a session that is about to close leaves a readable conversation', () async {
      await voice.pump.prepare();
      voice.handleServerMessageForTest(spoken('Câu trả lời đang'));
      voice.handleServerMessageForTest(heard('còn đang hỏi'));
      expect(chat.openIndexOf(TutorSpeakerRole.child), isNotNull,
          reason: 'the child is still being heard when the goodbye arrives');
      expect(chat.openIndexOf(TutorSpeakerRole.assistant), isNull,
          reason: 'at most one line can be open — the newest one');

      voice.handleServerMessageForTest(<String, Object?>{
        'goAway': <String, Object?>{'timeLeftBeforeClose': '3s'},
      });

      expect(chat.lines, hasLength(2), reason: 'nothing the child saw may vanish, and nothing is duplicated');
      expect(chat.lines.every((TutorLine line) => line.isFinal), isTrue,
          reason: 'a transcript of an ending session must not stay "partial"');
      expect(statuses.last.phase, VoicePhase.closing);
    });

    test('microphone gate: silent tutor only', () {
      final now = DateTime.now();
      final past = now.subtract(const Duration(seconds: 1));
      final future = now.add(const Duration(seconds: 1));

      expect(GeminiLiveVoice.microphoneGateOpen(tutorSpeaking: false, resumeListeningAt: past, now: now), isTrue);
      expect(GeminiLiveVoice.microphoneGateOpen(tutorSpeaking: true, resumeListeningAt: past, now: now), isFalse);
      expect(GeminiLiveVoice.microphoneGateOpen(tutorSpeaking: false, resumeListeningAt: future, now: now), isFalse);
      expect(GeminiLiveVoice.microphoneGateOpen(tutorSpeaking: false, resumeListeningAt: now, now: now), isTrue);
    });

    test('a server error is shown without ever leaking the key', () {
      voice.handleServerMessageForTest(<String, Object?>{
        'error': <String, Object?>{
          'code': 400,
          'message': 'bad credential for wss://generativelanguage.googleapis.com/ws?key=AIzaSECRETleakysecret12345',
        },
      });

      expect(errors, hasLength(1));
      expect(errors.single, isNot(contains('AIzaSECRETleakysecret')));
      expect(errors.single, contains('Gemini Live'));
    });
  });

  const builtKey = String.fromEnvironment('GEMINI_API_KEY');

  test('a development build without a key says so instead of pretending', () async {
    await voice.startListening(characterName: 'Kai', language: 'vi');
    expect(voice.isRecording, isFalse);
    expect(voice.phase, VoicePhase.off);
    expect(errors, hasLength(1));
    expect(errors.single, contains('GEMINI_API_KEY'));
    expect(errors.join(), isNot(contains('AIza')));
  }, skip: builtKey.trim().isEmpty ? false : 'this build was compiled with a Gemini key');
}
