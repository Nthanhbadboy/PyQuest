import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/modules/tutor/gemini_live_wire.dart';

/// The Gemini Live protocol, asserted on the JSON the tutor actually sends and
/// the messages it actually receives.
///
/// These are the checks that were missing while the tutor went mute after its
/// greeting: the answer only becomes audible if the setup asks for AUDIO, the
/// child's speech only reaches the model as `realtimeInput.audio`, and a reply
/// only shows up in the chat if `outputAudioTranscription` is parsed.
void main() {
  group('outgoing messages', () {
    test('setup asks for spoken audio and BOTH transcriptions', () {
      final message = jsonDecode(GeminiLiveWire.setup(
        model: 'gemini-3.1-flash-live-preview',
        persona: 'You are Kai, a friendly tutor',
        languageCode: 'vi-VN',
        voiceName: 'Puck',
      )) as Map<String, dynamic>;

      final setup = message['setup']! as Map<String, dynamic>;
      expect(setup['model'], 'models/gemini-3.1-flash-live-preview');

      final config = setup['generationConfig']! as Map<String, dynamic>;
      expect(config['responseModalities'], <String>['AUDIO']);

      final speech = config['speechConfig']! as Map<String, dynamic>;
      expect(speech['languageCode'], 'vi-VN');
      final voice = (speech['voiceConfig']! as Map<String, dynamic>)['prebuiltVoiceConfig']! as Map<String, dynamic>;
      expect(voice['voiceName'], 'Puck');

      expect(setup['systemInstruction'], isA<Map<String, dynamic>>());
      expect(setup.containsKey('inputAudioTranscription'), isTrue);
      // Without the output transcription the tutor speaks and the chat stays
      // empty — the bug the transcript fix had to restore.
      expect(setup.containsKey('outputAudioTranscription'), isTrue);
    });

    test('a text turn opens the conversation through clientContent', () {
      final message = jsonDecode(GeminiLiveWire.clientTextTurn('Xin chào')) as Map<String, dynamic>;
      final clientContent = message['clientContent']! as Map<String, dynamic>;
      final turns = clientContent['turns']! as List<dynamic>;
      final turn = turns.single as Map<String, dynamic>;
      expect(turn['role'], 'user');
      expect((turn['parts']! as List<dynamic>).single, <String, String>{'text': 'Xin chào'});
      // turnComplete is what makes the model answer right away.
      expect(clientContent['turnComplete'], isTrue);
      expect(message.containsKey('setup'), isFalse);
    });

    test('microphone frames go out as realtimeInput.audio PCM', () {
      final pcm = Uint8List.fromList(<int>[0, 1, 2, 3, 250, 255]);
      final message = jsonDecode(GeminiLiveWire.micAudio(pcm)) as Map<String, dynamic>;
      final realtime = message['realtimeInput']! as Map<String, dynamic>;
      final audio = realtime['audio']! as Map<String, dynamic>;
      expect(audio['mimeType'], GeminiLiveWire.inputMimeType);
      expect(audio['mimeType'], 'audio/pcm;rate=16000');
      expect(base64Decode(audio['data']! as String), pcm);
    });

    test('stopping the microphone ends the audio stream, not the session', () {
      final message = jsonDecode(GeminiLiveWire.audioStreamEnd()) as Map<String, dynamic>;
      final realtime = message['realtimeInput']! as Map<String, dynamic>;
      expect(realtime['audioStreamEnd'], isTrue);
    });

    test('the greeting is spoken aloud in the learner language', () {
      final vietnamese = GeminiLiveWire.greetingPrompt(characterName: 'Kai', language: 'vi');
      expect(vietnamese, contains('Vietnamese'));
      expect(vietnamese, contains('Kai'));
      final english = GeminiLiveWire.greetingPrompt(characterName: 'Lumi', language: 'en');
      expect(english, contains('English'));
      expect(GeminiLiveWire.languageCode('vi'), 'vi-VN');
      expect(GeminiLiveWire.languageCode('en'), 'en-US');
      // Two characters, two voices: the persona must stay distinguishable.
      expect(GeminiLiveWire.voiceFor('Kai'), isNot(GeminiLiveWire.voiceFor('Lumi')));
    });

    test('the API key never survives into an outgoing or logged string', () {
      const secret = 'AIzaTESTsecretTHATMUSTNOTLEAK123';
      final redacted = GeminiLiveWire.redactSecrets('wss://generativelanguage.googleapis.com/ws?key=$secret failed');
      expect(redacted, isNot(contains(secret)));
      expect(redacted, contains('key=•'));
      expect(GeminiLiveWire.redactSecrets('error with $secret'), isNot(contains(secret)));
    });
  });

  group('incoming messages', () {
    Map<String, Object?> audioMessage(List<int> bytes, {bool turnComplete = false, Map<String, Object?> extra = const {}}) =>
        <String, Object?>{
          'serverContent': <String, Object?>{
            'modelTurn': <String, Object?>{
              'role': 'model',
              'parts': <Object?>[
                <String, Object?>{
                  'inlineData': <String, Object?>{'mimeType': 'audio/pcm;rate=24000', 'data': base64Encode(bytes)},
                },
              ],
            },
            if (turnComplete) 'turnComplete': true,
            ...extra,
          },
        };

    test('setupComplete is recognised', () {
      final event = GeminiLiveWire.decode(<String, Object?>{'setupComplete': <String, Object?>{}});
      expect(event.setupComplete, isTrue);
      expect(event.describe(), contains('setupComplete'));
    });

    test('model audio is decoded as PCM and survives a turnComplete in the same message', () {
      final event = GeminiLiveWire.decode(audioMessage(<int>[4, 5, 6, 7], turnComplete: true));
      expect(event.hasAudio, isTrue);
      expect(event.audio, Uint8List.fromList(<int>[4, 5, 6, 7]));
      expect(event.turnComplete, isTrue);
      expect(event.interrupted, isFalse);
    });

    test('several audio parts in one message are played in order', () {
      final event = GeminiLiveWire.decode(<String, Object?>{
        'serverContent': <String, Object?>{
          'modelTurn': <String, Object?>{
            'parts': <Object?>[
              <String, Object?>{
                'inlineData': <String, Object?>{'data': base64Encode(<int>[1, 1])},
              },
              <String, Object?>{
                'inlineData': <String, Object?>{'data': base64Encode(<int>[2, 2])},
              },
            ],
          },
        },
      });
      expect(event.audio, Uint8List.fromList(<int>[1, 1, 2, 2]));
    });

    test('both transcriptions are read, in camelCase and snake_case', () {
      final camel = GeminiLiveWire.decode(<String, Object?>{
        'serverContent': <String, Object?>{
          'inputTranscription': <String, String>{'text': '  vì sao vòng lặp chạy 3 lần  '},
          'outputTranscription': <String, String>{'text': 'Vì print nằm trong vòng lặp.'},
        },
      });
      expect(camel.userText, 'vì sao vòng lặp chạy 3 lần');
      expect(camel.assistantText, 'Vì print nằm trong vòng lặp.');

      final snake = GeminiLiveWire.decode(<String, Object?>{
        'server_content': <String, Object?>{
          'input_transcription': <String, String>{'text': 'why'},
          'output_transcription': <String, String>{'text': 'because'},
          'turn_complete': true,
          'interrupted': true,
          'waiting_for_input': true,
        },
      });
      expect(snake.userText, 'why');
      expect(snake.assistantText, 'because');
      expect(snake.turnComplete, isTrue);
      expect(snake.interrupted, isTrue);
      expect(snake.waitingForInput, isTrue);
    });

    test('model text parts count as the tutor answer when there is no audio', () {
      final event = GeminiLiveWire.decode(<String, Object?>{
        'serverContent': <String, Object?>{
          'modelTurn': <String, Object?>{
            'parts': <Object?>[
              <String, Object?>{'text': 'Thử in ra biến đó xem sao.'},
            ],
          },
          'turnComplete': true,
        },
      });
      expect(event.hasAudio, isFalse);
      expect(event.assistantText, 'Thử in ra biến đó xem sao.');
      expect(event.turnComplete, isTrue);
    });

    test('errors are surfaced but never carry the key', () {
      final event = GeminiLiveWire.decode(<String, Object?>{
        'error': <String, Object?>{
          'code': 400,
          'message': 'Cannot connect to wss://generativelanguage.googleapis.com/ws?key=AIzaLEAKYleaky0000000000',
        },
      });
      expect(event.errorText, isNotNull);
      expect(event.errorText, isNot(contains('AIzaLEAKYleaky')));
      expect(event.errorText, contains('key=•'));
    });

    test('goAway is reported with the time left', () {
      final event = GeminiLiveWire.decode(<String, Object?>{
        'goAway': <String, Object?>{'timeLeftBeforeClose': 45},
      });
      expect(event.goAwaySeconds, 45);
      expect(event.describe(), contains('goAway=45s'));
    });

    test('messages the tutor cannot use are ignored, not mistaken for a turn', () {
      final ignored = GeminiLiveWire.decode(<String, Object?>{
        'usageMetadata': <String, Object?>{'totalTokenCount': 12},
      });
      expect(ignored.ignored, isTrue);
      expect(ignored.turnComplete, isFalse);
      expect(ignored.hasAudio, isFalse);

      final broken = GeminiLiveWire.decode(<String, Object?>{'serverContent': 'not a map'});
      expect(broken.ignored, isTrue);
    });

    test('unreadable payloads throw for the caller to report', () {
      expect(() => GeminiLiveWire.decode('{not json'), throwsFormatException);
    });

    test('diagnostics describe sizes only, never the child’s words', () {
      final event = GeminiLiveWire.decode(<String, Object?>{
        'serverContent': <String, Object?>{
          'inputTranscription': <String, String>{'text': 'bé nói điều bí mật ở nhà'},
          'outputTranscription': <String, String>{'text': 'trợ giảng trả lời bí mật'},
          'turnComplete': true,
        },
      });
      expect(event.describe(), isNot(contains('bí mật')));
      expect(event.describe(), contains('userText='));
      expect(event.describe(), contains('aiText='));
      expect(event.describe(), contains('turnComplete'));
    });
  });

  group('transcript merging', () {
    test('a growing partial replaces the same turn', () {
      var text = '';
      for (final partial in <String>['Chào', 'Chào em', 'Chào em, mình là Kai']) {
        text = GeminiLiveWire.mergeTranscript(text, partial);
      }
      expect(text, 'Chào em, mình là Kai');
    });

    test('new words are appended instead of duplicated', () {
      expect(GeminiLiveWire.mergeTranscript('Vì sao ư?', 'Vì print nằm trong vòng lặp.'),
          'Vì sao ư? Vì print nằm trong vòng lặp.');
      expect(GeminiLiveWire.mergeTranscript('A B C', 'B C'), 'A B C');
      expect(GeminiLiveWire.mergeTranscript('', 'chỉ một'), 'chỉ một');
      expect(GeminiLiveWire.mergeTranscript('đã xong', '   '), 'đã xong');
    });
  });
}
