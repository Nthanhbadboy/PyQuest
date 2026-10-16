import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/modules/tutor/gemini_live_voice.dart';

import 'test_helpers.dart';

class _Line {
  const _Line(this.text, this.fromUser);
  final String text;
  final bool fromUser;
}

/// Drives a voice session the way a device's socket does: server messages in,
/// transcripts and speaker bytes out. No microphone, no network, no key.
///
/// The case that matters here is the one the tutor failed on devices: a message
/// that carries a full answer must also reach the speaker, and the microphone
/// must not answer the tutor's own voice.
void main() {
  late FakePcmOutput output;
  late GeminiLiveVoice voice;
  late List<String> statuses;
  late List<String> errors;
  late List<_Line> transcript;

  setUp(() {
    output = FakePcmOutput();
    statuses = <String>[];
    errors = <String>[];
    transcript = <_Line>[];
    voice = GeminiLiveVoice(
      audioOutput: output,
      onStatus: (String status) => statuses.add(status),
      onTranscript: (String text, {required bool fromUser}) => transcript.add(_Line(text, fromUser)),
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

  test('a spoken answer is handed to the speaker, not only to the chat', () async {
    await voice.pump.prepare();
    voice.handleServerMessageForTest(audioMessage(voiceAudio(2)));

    expect(voice.pump.pendingBytes, 2 * kVoiceSliceBytes);
    expect(transcript, isEmpty);
  });

  test('the tutor answer appears once, when its turn is complete', () async {
    await voice.pump.prepare();
    voice.handleServerMessageForTest(message(<String, Object?>{
      'outputTranscription': <String, String>{'text': 'Vì print nằm'},
    }));
    voice.handleServerMessageForTest(message(<String, Object?>{
      'outputTranscription': <String, String>{'text': 'Vì print nằm trong vòng lặp.'},
      'turnComplete': true,
    }));

    final answers = transcript.where((_Line line) => !line.fromUser).toList();
    expect(answers, hasLength(1), reason: 'a growing partial must not become two bubbles');
    expect(answers.single.text, 'Vì print nằm trong vòng lặp.');
  });

  test("the child's line grows in place instead of duplicating", () async {
    await voice.pump.prepare();
    for (final partial in <String>['vì', 'vì sao', 'vì sao 3']) {
      voice.handleServerMessageForTest(message(<String, Object?>{
        'inputTranscription': <String, String>{'text': partial},
      }));
    }
    final asked = transcript.where((_Line line) => line.fromUser).map((_Line line) => line.text).toList();
    expect(asked, <String>['vì', 'vì sao', 'vì sao 3']);
  });

  test('an interruption clears the speech that has not been played', () async {
    await voice.pump.prepare();
    voice.handleServerMessageForTest(audioMessage(voiceAudio(6)));
    expect(voice.pump.pendingBytes, greaterThan(0));

    voice.handleServerMessageForTest(message(<String, Object?>{'interrupted': true}));
    expect(voice.pump.pendingBytes, 0);
  });

  test('a server error is shown without ever leaking the key', () async {
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

  test('the tutor speaks, then listens again — the microphone is not left open', () async {
    await voice.pump.prepare();
    voice.handleServerMessageForTest(audioMessage(voiceAudio(2).toList(), extra: <String, Object?>{'turnComplete': true}));
    expect(voice.isSpeakingAloud, isFalse);

    await voice.pump.pumpOnce();
    expect(voice.isSpeakingAloud, isTrue, reason: 'audio reached the device');
    expect(statuses.last, contains('đang nói'));

    // The pump's lead + tail (about half a second) has to pass in real time.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await voice.pump.pumpOnce();

    expect(voice.isSpeakingAloud, isFalse);
    expect(statuses.last, contains('Đang nghe bé nói'));
    expect(voice.resumeListeningAt.isAfter(DateTime.now()), isTrue,
        reason: 'the tail of the tutor’s own voice must not open a new turn');
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

  const builtKey = String.fromEnvironment('GEMINI_API_KEY');

  test('a development build without a key says so instead of pretending', () async {
    await voice.startListening(characterName: 'Kai', language: 'vi');
    expect(voice.isRecording, isFalse);
    expect(errors, hasLength(1));
    expect(errors.single, contains('GEMINI_API_KEY'));
    expect(errors.join(), isNot(contains('AIza')));
  }, skip: builtKey.trim().isEmpty ? false : 'this build was compiled with a Gemini key');
}
