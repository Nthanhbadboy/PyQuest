import 'dart:convert';
import 'dart:typed_data';

/// The wire format of a Gemini Live audio session, with no sockets and no
/// plugins in it, so every rule of the protocol can be unit tested.
///
/// Shapes follow the Gemini Developer API endpoint the tutor connects to
/// (`/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent`):
///
/// * `setup` opens the session and asks for audio answers plus both
///   transcriptions, so the chat can show what was said;
/// * microphone frames go out as `realtimeInput.audio` blobs (16 kHz PCM);
/// * the model answers with `serverContent.modelTurn` parts whose
///   `inlineData.data` is 24 kHz PCM 16-bit mono;
/// * `serverContent.turnComplete` closes a turn and `interrupted` tells the
///   client to drop what it is playing.
///
/// Kept separate from [GeminiLiveVoice] because a wrong field name here is
/// exactly the kind of failure that leaves the tutor mute while the text
/// transcript keeps working.
class GeminiLiveWire {
  const GeminiLiveWire._();

  /// Sample rate the API expects for microphone frames.
  static const int inputSampleRate = 16000;

  /// Sample rate the API answers with (PCM 16-bit mono).
  static const int outputSampleRate = 24000;

  /// Mime type of a microphone frame. Same string the official SDKs use.
  static const String inputMimeType = 'audio/pcm;rate=16000';

  static Map<String, Object?> _audioBlob(Uint8List pcm) => <String, Object?>{
        'mimeType': inputMimeType,
        'data': base64Encode(pcm),
      };

  /// The one and only setup message of a session.
  ///
  /// `responseModalities: [AUDIO]` is what makes the tutor speak; without
  /// `outputAudioTranscription` the spoken answer never reaches the chat
  /// bubbles.
  static String setup({
    required String model,
    required String persona,
    required String languageCode,
    required String voiceName,
  }) =>
      jsonEncode(<String, Object?>{
        'setup': <String, Object?>{
          'model': model.startsWith('models/') ? model : 'models/$model',
          'generationConfig': <String, Object?>{
            'responseModalities': <String>['AUDIO'],
            'speechConfig': <String, Object?>{
              'languageCode': languageCode,
              'voiceConfig': <String, Object?>{
                'prebuiltVoiceConfig': <String, Object?>{'voiceName': voiceName},
              },
            },
          },
          'systemInstruction': <String, Object?>{
            'parts': <Object?>[<String, Object?>{'text': persona}],
          },
          'inputAudioTranscription': <String, Object?>{},
          'outputAudioTranscription': <String, Object?>{},
        },
      });

  /// A turn based on text instead of microphones — used to make the tutor
  /// greet the child as soon as the session is open.
  static String clientTextTurn(String text) => jsonEncode(<String, Object?>{
        'clientContent': <String, Object?>{
          'turns': <Object?>[
            <String, Object?>{
              'role': 'user',
              'parts': <Object?>[<String, Object?>{'text': text}],
            },
          ],
          'turnComplete': true,
        },
      });

  /// One microphone frame. `realtimeInput` is the low-latency path: the server
  /// decides when the child stopped talking (voice activity detection), so the
  /// client never has to mark the end of an utterance.
  static String micAudio(Uint8List pcm) => jsonEncode(<String, Object?>{
        'realtimeInput': <String, Object?>{'audio': _audioBlob(pcm)},
      });

  /// Same frame, for a session that will not send more audio (tap Stop).
  static String audioStreamEnd() => jsonEncode(<String, Object?>{
        'realtimeInput': <String, Object?>{'audioStreamEnd': true},
      });

  /// Decodes one server message into the handful of facts the tutor acts on.
  ///
  /// Unknown fields are ignored rather than trusted: a message that carries
  /// nothing we use must not look like a turn.
  static GeminiLiveEvent decode(Object? raw) {
    final Object? decoded;
    if (raw is String) {
      decoded = jsonDecode(raw);
    } else if (raw is List<int>) {
      decoded = jsonDecode(utf8.decode(raw));
    } else if (raw is Map) {
      decoded = raw;
    } else {
      return const GeminiLiveEvent(unreadable: true);
    }
    if (decoded is! Map) return const GeminiLiveEvent(unreadable: true);
    final message = decoded.cast<String, dynamic>();

    if (_first(message, const ['setupComplete', 'setup_complete']) != null) {
      return const GeminiLiveEvent(setupComplete: true);
    }

    final error = message['error'];
    if (error != null) {
      final text = error is Map
          ? (error['message']?.toString() ?? jsonEncode(error))
          : error.toString();
      return GeminiLiveEvent(errorText: redactSecrets(text));
    }

    final goAway = _first(message, const ['goAway', 'go_away']);
    if (goAway != null) {
      final Object? raw = goAway is Map
          ? (goAway['timeLeftBeforeClose'] ?? goAway['time_left_before_close'])
          : goAway;
      final seconds = raw is int ? raw : int.tryParse('$raw');
      return GeminiLiveEvent(goAwaySeconds: seconds ?? 0);
    }

    final serverContent = _first(message, const ['serverContent', 'server_content']);
    if (serverContent is! Map) return const GeminiLiveEvent(ignored: true);
    final content = serverContent.cast<String, dynamic>();

    Uint8List? audio;
    final modelTurnText = StringBuffer();

    final modelTurn = _first(content, const ['modelTurn', 'model_turn']);
    final parts = modelTurn is Map ? (modelTurn['parts'] as Object?) : null;
    if (parts is List) {
      for (final part in parts) {
        if (part is! Map) continue;
        final inline = part['inlineData'] ?? part['inline_data'];
        final data = inline is Map ? inline['data'] : null;
        if (data is String && data.isNotEmpty) {
          final pcm = base64Decode(data);
          audio = audio == null ? pcm : Uint8List.fromList(<int>[...audio, ...pcm]);
        }
        final text = part['text'];
        if (text is String) modelTurnText.write(text);
      }
    }

    String? transcribed(List<String> keys) {
      final node = _first(content, keys);
      if (node is! Map) return null;
      final text = node['text'];
      if (text is! String || text.trim().isEmpty) return null;
      return text.trim();
    }

    final mergedAssistant = <String>[
          modelTurnText.toString().trim(),
          transcribed(const ['outputTranscription', 'output_transcription']) ?? '',
        ].where((String text) => text.isNotEmpty).join(' ').trim();

    return GeminiLiveEvent(
      audio: audio,
      userText: transcribed(const ['inputTranscription', 'input_transcription']),
      assistantText: mergedAssistant.isEmpty ? null : mergedAssistant,
      turnComplete: _isTrue(_first(content, const ['turnComplete', 'turn_complete'])),
      interrupted: _isTrue(_first(content, const ['interrupted'])),
      waitingForInput: _isTrue(_first(content, const ['waitingForInput', 'waiting_for_input'])),
    );
  }

  /// Never let a whole server message into a log: the WebSocket URL that shows
  /// up in connection errors carries the API key.
  static final RegExp _keyParam = RegExp('key=[A-Za-z0-9_\\-]+');
  static final RegExp _googleKey = RegExp('AIza[A-Za-z0-9_\\-]{10,}');

  static String redactSecrets(String text) =>
      text.replaceAll(_keyParam, 'key=•').replaceAll(_googleKey, 'AIza•');

  static Object? _first(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null) return value;
    }
    return null;
  }

  static bool _isTrue(Object? value) => value == true || value == 'true';

  /// Merges one transcription chunk into the text of the current turn.
  ///
  /// The API may resend the whole utterance each time or only the new words,
  /// and it may revise a partial. Both shapes end up as exactly one clean line
  /// in the chat instead of a duplicated half-sentence.
  static String mergeTranscript(String current, String chunk) {
    final said = current.trim();
    final next = chunk.trim();
    if (next.isEmpty) return said;
    if (said.isEmpty) return next;
    if (next.startsWith(said)) return next;
    if (said.endsWith(next)) return said;
    return '$said $next';
  }

  /// Lower-cases [text] and turns everything that is not a letter or a digit
  /// into a single space, so two transcriptions of the same words compare equal
  /// whatever punctuation each one happened to get.
  static String normalizeWords(String text) {
    final b = StringBuffer();
    for (final rune in text.toLowerCase().runes) {
      b.write(_isWordChar(rune) ? String.fromCharCode(rune) : ' ');
    }
    return b.toString().replaceAll(RegExp(' +'), ' ').trim();
  }

  /// True for the characters a spoken word is made of.
  ///
  /// Letters are kept by code point rather than by a Unicode property escape,
  /// because Vietnamese diacritics have to survive for the comparison to mean
  /// anything, and punctuation ranges are excluded so that an em dash or curly
  /// quotes never look like a word.
  static bool _isWordChar(int rune) {
    if (rune >= 0x30 && rune <= 0x39) return true; // 0-9
    if (rune >= 0x41 && rune <= 0x5a) return true; // A-Z
    if (rune >= 0x61 && rune <= 0x7a) return true; // a-z
    if (rune < 0xA1) return false; // ASCII punctuation, space, NBSP
    if (rune >= 0x2000 && rune <= 0x206F) return false; // general punctuation: — “ ” …
    if (rune >= 0x2E00 && rune <= 0x2E7F) return false; // supplemental punctuation
    if (rune >= 0x3000 && rune <= 0x303F) return false; // CJK punctuation
    if (rune >= 0xFE30 && rune <= 0xFE4F) return false; // CJK presentation forms
    if (rune >= 0xFF00 && rune <= 0xFF65) return false; // full-width punctuation
    return true; // Latin-1.1, Greek, Cyrillic, Vietnamese and other letters
  }

  /// True when [heard] is almost certainly the tutor's own voice arriving again
  /// through the microphone instead of the child speaking.
  ///
  /// Android only runs acoustic echo cancellation on the voice-communication
  /// capture path, and even then a phone can hear its own loudspeaker. The
  /// model then transcribes its own greeting as the child's words, which is how
  /// «Chào bạn!» came back labelled as the learner. Only short utterances that
  /// are made of what the tutor just said count as echo, so a child who
  /// repeats a word after the tutor is still heard.
  static bool looksLikeEcho({required String heard, required String spoken}) {
    final heardWords = normalizeWords(heard).split(' ').where((String w) => w.isNotEmpty).toList();
    if (heardWords.isEmpty || heardWords.length > maxEchoWords) return false;
    final spokenWords = normalizeWords(spoken).split(' ').where((String w) => w.isNotEmpty).toSet();
    if (spokenWords.isEmpty) return false;
    final repeated = heardWords.where(spokenWords.contains).length;
    return repeated / heardWords.length >= _echoOverlap;
  }

  /// How long an utterance may be and still plausibly be a playback echo.
  static const int maxEchoWords = 8;

  /// How much of it must have been said by the tutor already.
  static const double _echoOverlap = 0.6;

  /// The child-facing instruction that opens a conversation.
  static String greetingPrompt({required String characterName, required String language}) =>
      'Start a friendly voice conversation with the child now. Briefly greet them, '
      'introduce yourself as $characterName, and ask one simple question about what '
      'they are learning. Speak aloud in ${language == 'vi' ? 'Vietnamese' : 'English'}.';

  static String persona({required String characterName, required String language}) =>
      'You are $characterName, a friendly and expressive character in PyQuest, a '
      'Python-learning game for children. Speak naturally and warmly in Vietnamese '
      'when the child uses Vietnamese, or English when the child uses English. Keep '
      'each answer short, encouraging, age-appropriate, and related to learning. '
      'Never ask for personal information. Do not claim to see the child. '
      'Respond with spoken audio.${language == 'vi' ? ' Trả lời bằng tiếng Việt.' : ''}';

  /// Voice names are fixed per character so Kai and Lumi stay recognisable.
  static String voiceFor(String characterName) => characterName == 'Kai' ? 'Puck' : 'Aoede';

  static String languageCode(String language) => language == 'vi' ? 'vi-VN' : 'en-US';
}

/// Everything the tutor reacts to in one server message.
class GeminiLiveEvent {
  const GeminiLiveEvent({
    this.setupComplete = false,
    this.audio,
    this.userText,
    this.assistantText,
    this.turnComplete = false,
    this.interrupted = false,
    this.waitingForInput = false,
    this.goAwaySeconds,
    this.errorText,
    this.ignored = false,
    this.unreadable = false,
  });

  final bool setupComplete;

  /// PCM 16-bit mono 24 kHz, already concatenated when a message carried two
  /// audio parts.
  final Uint8List? audio;

  /// What the child was heard saying (input transcription).
  final String? userText;

  /// What the tutor said (output transcription and/or text parts).
  final String? assistantText;

  final bool turnComplete;
  final bool interrupted;

  /// The model paused because it expects the child to continue.
  final bool waitingForInput;

  /// The API is about to close this session.
  final int? goAwaySeconds;

  /// Redacted server error, safe to show and to log.
  final String? errorText;

  final bool ignored;
  final bool unreadable;

  bool get hasAudio => audio != null && audio!.isNotEmpty;
  int get audioBytes => audio?.length ?? 0;

  /// A one-line description for diagnostics: counts and flags only, never the
  /// child's words and never a credential.
  String describe() {
    final bits = <String>[];
    if (setupComplete) bits.add('setupComplete');
    if (hasAudio) bits.add('audio=${audioBytes}B');
    if (userText != null) bits.add('userText=${userText!.length}ch');
    if (assistantText != null) bits.add('aiText=${assistantText!.length}ch');
    if (turnComplete) bits.add('turnComplete');
    if (interrupted) bits.add('interrupted');
    if (waitingForInput) bits.add('waitingForInput');
    if (goAwaySeconds != null) bits.add('goAway=${goAwaySeconds}s');
    if (errorText != null) bits.add('error');
    if (unreadable) bits.add('unreadable');
    if (bits.isEmpty) bits.add(ignored ? 'ignored' : 'other');
    return bits.join(' ');
  }
}
