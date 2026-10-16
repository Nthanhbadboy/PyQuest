import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'gemini_live_wire.dart';
import 'live_audio_output.dart';
import 'tutor_transcript.dart';

/// Where the live voice conversation is, in the session's own words.
///
/// The panel used to read this out of the human-readable status string
/// (`status.contains('đang nói')`), which meant a wording change could make
/// the app claim the tutor was speaking when it was not.
enum VoicePhase {
  /// No session: the text tutor answers.
  off,

  /// Socket, microphone permission and speaker are being acquired.
  connecting,

  /// Microphone open, waiting for the child.
  listening,

  /// The tutor's own audio is being played.
  speaking,

  /// The last turn is being played out before the session closes.
  closing;

  bool get isLive => this == VoicePhase.listening || this == VoicePhase.speaking;
}

/// One status update of a voice session: a phase for the UI logic and a
/// sentence for the child.
class TutorVoiceStatus {
  const TutorVoiceStatus(this.phase, this.message);

  final VoicePhase phase;
  final String message;

  @override
  String toString() => '${phase.name}: $message';
}

/// One utterance produced by a live session, already tagged with who said it.
class VoiceUtterance {
  const VoiceUtterance({
    required this.role,
    required this.text,
    this.isFinal = true,
    this.interrupted = false,
    this.seals = false,
  });

  /// "No more revisions are coming": the conversation display must close
  /// whatever it still shows as being spoken. Emitted when a session ends
  /// without a turnComplete — the alternative, re-sending the text, would add
  /// a second bubble for a sentence that is already on screen.
  const VoiceUtterance.sealed()
      : role = TutorSpeakerRole.assistant,
        text = '',
        isFinal = true,
        interrupted = false,
        seals = true;

  final TutorSpeakerRole role;
  final String text;

  /// False while a transcription can still be revised by the server.
  final bool isFinal;

  /// The assistant stopped mid-sentence because the child interrupted it.
  final bool interrupted;

  /// True only for [VoiceUtterance.sealed].
  final bool seals;

  @override
  String toString() => seals ? 'seal-open-lines' : '${role.name}(${isFinal ? 'final' : 'partial'}): $text';
}

/// Experimental hands-free Gemini Live conversation for development builds.
///
/// Supply the key only through --dart-define=GEMINI_API_KEY=... . This is
/// intentionally a development shortcut: dart-defines are embedded in the
/// APK and must be replaced by short-lived tokens/server mediation before
/// any public release.
///
/// The socket protocol lives in [GeminiLiveWire] and the speaker lifecycle in
/// [PcmTurnPump]; this class only glues microphone frames, server events and
/// the turn-taking of a conversation together.
class GeminiLiveVoice {
  GeminiLiveVoice({
    required this.onStatus,
    required this.onTranscript,
    required this.onError,
    @visibleForTesting PcmAudioOutput? audioOutput,
  }) : _output = audioOutput ?? FlutterSoundPcmOutput();

  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = 'gemini-3.1-flash-live-preview';

  /// How long the microphone stays closed after the tutor stopped talking, so
  /// the tail of its voice is not heard as a new question.
  static const Duration _listenAgainGuard = Duration(milliseconds: 220);

  /// How long after the tutor's voice a short transcription is still treated as
  /// playback echo instead of as the child speaking.
  static const Duration _echoGrace = Duration(milliseconds: 1200);

  /// Hard limit for "the tutor is still speaking" before the session is torn
  /// down anyway. A stuck speaker must never freeze a lesson.
  static const Duration _stopGrace = Duration(seconds: 8);

  /// Fallback for the opening greeting: if nothing ever plays, the microphone
  /// must still be handed to the child.
  static const Duration _greetingGuard = Duration(seconds: 12);

  final void Function(TutorVoiceStatus status) onStatus;
  final void Function(VoiceUtterance utterance) onTranscript;
  final void Function(String message) onError;

  /// Created on first use: constructing it talks to the platform plugin, and a
  /// lesson that never opens the microphone must not pay for that.
  late final AudioRecorder _recorder = AudioRecorder();
  final PcmAudioOutput _output;

  late final PcmTurnPump _pump = PcmTurnPump(
    output: _output,
    onSpeakStarted: _onSpeakStarted,
    onSpeakFinished: _onSpeakFinished,
    onFailure: _onPlaybackFailure,
    onDiagnostic: (message) => debugPrint('[PyQuestVoice] pump: $message'),
  );

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSubscription;
  StreamSubscription<Uint8List>? _micSubscription;
  Completer<void> _setupComplete = Completer<void>();
  String _outputText = '';
  String _turnUserText = '';
  String _lastSpokenText = '';
  String _characterName = 'Kai';

  bool _recording = false;
  bool _closing = false;
  bool _tutorSpeaking = false;
  bool _stopAfterResponse = false;
  bool _disposed = false;
  DateTime _resumeListeningAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _echoUntil = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _stopTimeout;
  Timer? _openEarTimer;

  // Diagnostics only: counts and sizes, never the child's words.
  int _micChunkCount = 0;
  int _micByteCount = 0;
  int _micBlockedCount = 0;
  int _serverAudioChunks = 0;
  int _serverAudioBytes = 0;
  int _turnAudioBytes = 0;
  int _serverEvents = 0;
  int _errors = 0;
  int _echoDropped = 0;

  bool get isRecording => _recording;

  /// The session's own view of what is happening, so the UI never has to guess
  /// from a sentence.
  /// Kept as a field rather than derived, because a derived phase is a guess
  /// and a guessed phase is how a UI starts claiming the tutor is speaking.
  VoicePhase get phase => _disposed ? VoicePhase.off : _phase;
  VoicePhase _phase = VoicePhase.off;

  @visibleForTesting
  PcmTurnPump get pump => _pump;

  /// Feeds one raw server message into the session, exactly as the socket would
  /// hand it over. Tests use this to drive the event order a device sees
  /// without a network, a microphone or an API key.
  @visibleForTesting
  void handleServerMessageForTest(Object? message) => _handleServerMessage(message);

  /// The recorder settings of a voice turn.
  ///
  /// `echoCancel` alone is not enough on Android: the platform only runs
  /// acoustic echo cancellation on the voice-communication capture path, so a
  /// phone with the default mic source records the tutor's own greeting and the
  /// model hears it as the child's speech. That is the second half of the
  /// "the tutor is mute / talks to itself" failure, and it needs no permission
  /// the app does not already have.
  @visibleForTesting
  static RecordConfig recorderConfig() => const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: GeminiLiveWire.inputSampleRate,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
        androidConfig: AndroidRecordConfig(audioSource: AndroidAudioSource.voiceCommunication),
      );

  /// The half-duplex rule on its own, so the timing can be tested without a
  /// microphone: frames are forwarded only while the tutor is silent and the
  /// guard against its own voice tail has passed.
  @visibleForTesting
  static bool microphoneGateOpen({
    required bool tutorSpeaking,
    required DateTime resumeListeningAt,
    required DateTime now,
  }) =>
      !tutorSpeaking && !now.isBefore(resumeListeningAt);

  bool get _forwardsMicrophoneAudio =>
      _recording &&
      _channel != null &&
      microphoneGateOpen(
        tutorSpeaking: _tutorSpeaking,
        resumeListeningAt: _resumeListeningAt,
        now: DateTime.now(),
      );

  /// True while the tutor's own voice is playing (or has just finished and the
  /// microphone is still guarded).
  @visibleForTesting
  bool get isSpeakingAloud => _tutorSpeaking;

  @visibleForTesting
  DateTime get resumeListeningAt => _resumeListeningAt;

  /// True while a short transcription is plausibly the tutor's own voice coming
  /// back through the microphone.
  @visibleForTesting
  bool get echoSuspect =>
      _tutorSpeaking || DateTime.now().isBefore(_echoUntil) || _pump.isSpeaking;

  /// How many utterances were dropped as echo. Diagnostics only: the child's
  /// words are never counted, kept or printed anywhere.
  @visibleForTesting
  int get echoDropped => _echoDropped;

  Future<void> startListening({required String characterName, required String language}) async {
    if (_disposed || _recording || _channel != null) return;
    if (_apiKey.trim().isEmpty) {
      onError('Thiếu GEMINI_API_KEY. Hãy build thử nghiệm với --dart-define=GEMINI_API_KEY=...');
      _status(VoicePhase.off, 'Voice chưa kết nối');
      return;
    }
    _characterName = characterName;
    _closing = false;
    try {
      debugPrint('[PyQuestVoice] startListening character=$characterName language=$language model=$_model');
      _status(VoicePhase.connecting, 'Đang kết nối Gemini Live…');
      // WebSocketChannel.connect only accepts ws:// or wss:// URIs.
      // Uri.https() creates an https:// URI and fails before the Live session
      // can be established.
      final uri = Uri(
        scheme: 'wss',
        host: 'generativelanguage.googleapis.com',
        path: '/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent',
        queryParameters: <String, String>{'key': _apiKey},
      );
      _setupComplete = Completer<void>();
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _socketSubscription = channel.stream.listen(
        _handleServerMessage,
        onError: (Object error) {
          if (!_setupComplete.isCompleted) _setupComplete.completeError(error);
          _fail('Kết nối voice lỗi: ${GeminiLiveWire.redactSecrets('$error')}');
        },
        onDone: () {
          if (!_setupComplete.isCompleted) {
            _setupComplete.completeError(StateError('Gemini Live đã đóng kết nối trước khi setup hoàn tất.'));
          }
          if (!_disposed && _recording) {
            _recording = false;
            _status(VoicePhase.off, 'Đã ngắt kết nối');
          }
        },
      );
      _channel!.sink.add(GeminiLiveWire.setup(
        model: _model,
        persona: GeminiLiveWire.persona(characterName: characterName, language: language),
        languageCode: GeminiLiveWire.languageCode(language),
        voiceName: GeminiLiveWire.voiceFor(characterName),
      ));
      await _setupComplete.future.timeout(const Duration(seconds: 25));
      debugPrint('[PyQuestVoice] setupComplete received');

      final hasMicPermission = await _recorder.hasPermission();
      debugPrint('[PyQuestVoice] microphone permission=$hasMicPermission');
      if (!hasMicPermission) {
        throw StateError('Chưa được cấp quyền micro cho PyQuest.');
      }

      // The speaker is opened once for the whole session and then kept alive by
      // the pump. Starting/stopping it per turn is what used to mute every
      // answer after the greeting.
      await _pump.start();
      debugPrint('[PyQuestVoice] playback pump started');

      _micChunkCount = 0;
      _micByteCount = 0;
      _micBlockedCount = 0;
      _serverAudioChunks = 0;
      _serverAudioBytes = 0;
      _serverEvents = 0;
      _errors = 0;
      _echoDropped = 0;
      _outputText = '';
      _turnUserText = '';
      _lastSpokenText = '';
      _stopTimeout?.cancel();
      _stopAfterResponse = false;
      _tutorSpeaking = false;

      final stream = await _recorder.startStream(recorderConfig());
      _recording = true;
      debugPrint('[PyQuestVoice] microphone stream started: PCM16 mono ${GeminiLiveWire.inputSampleRate}Hz');
      _status(VoicePhase.listening, 'Đang trò chuyện… Hãy nói tự nhiên, không cần nhấn giữ micro');
      _micSubscription = stream.listen((chunk) {
        if (!_recording || _channel == null) return;
        _micChunkCount++;
        _micByteCount += chunk.length;
        if (_micChunkCount == 1 || _micChunkCount % 50 == 0) {
          debugPrint('[PyQuestVoice] mic chunks=$_micChunkCount bytes=$_micByteCount latestChunkBytes=${chunk.length}');
        }
        // Half-duplex: while the tutor talks, its own voice comes back through
        // the microphone. Forwarding that makes the model interrupt itself and
        // cut its answer short, which is exactly the "greeting only" symptom.
        if (!_forwardsMicrophoneAudio) {
          _micBlockedCount++;
          return;
        }
        _channel!.sink.add(GeminiLiveWire.micAudio(chunk));
      }, onError: (Object error) {
        debugPrint('[PyQuestVoice] microphone stream ERROR: $error');
        _fail('Không đọc được micro: $error');
      }, onDone: () {
        debugPrint('[PyQuestVoice] microphone stream done chunks=$_micChunkCount bytes=$_micByteCount');
      });

      // Prompt the tutor to open the conversation as soon as the session is ready.
      _channel!.sink.add(GeminiLiveWire.clientTextTurn(
        GeminiLiveWire.greetingPrompt(characterName: characterName, language: language),
      ));
      // The greeting is spoken before the child is heard. Keeping the
      // microphone closed until that first answer has played out is what stops
      // a noise (or the tutor's own voice) from interrupting the greeting.
      _tutorSpeaking = true;
      _openEarTimer?.cancel();
      _openEarTimer = Timer(_greetingGuard, () => _openEarForChild('chờ câu chào quá lâu'));
      debugPrint('[PyQuestVoice] sent greeting turn (clientContent, text parts=1); microphone closed until it has been spoken');
    } catch (error, stackTrace) {
      debugPrint('[PyQuestVoice] startListening ERROR: ${GeminiLiveWire.redactSecrets('$error')}\n$stackTrace');
      await _stopRecorder();
      _fail('Không thể bắt đầu voice: ${GeminiLiveWire.redactSecrets('$error')}');
      _status(VoicePhase.off, 'Voice chưa kết nối');
      await _pump.stop();
      await _closeSocket();
    }
  }

  Future<void> stopListening() async {
    if (!_recording) return;
    debugPrint('[PyQuestVoice] stop requested micChunks=$_micChunkCount blockedChunks=$_micBlockedCount serverAudioChunks=$_serverAudioChunks');
    _recording = false;
    _stopAfterResponse = true;
    _status(VoicePhase.closing, 'Đang chờ $_characterName nói nốt…');
    await _stopRecorder();
    try {
      _channel?.sink.add(GeminiLiveWire.audioStreamEnd());
      debugPrint('[PyQuestVoice] sent audioStreamEnd');
    } catch (error) {
      _fail('Không gửi được đoạn âm thanh: $error');
    }

    // The tutor should finish its current turn; never leave the UI waiting
    // forever if no turnComplete (or no playback) ever arrives.
    _stopTimeout?.cancel();
    _stopTimeout = Timer(_stopGrace, () {
      if (_disposed || !_stopAfterResponse) return;
      debugPrint('[PyQuestVoice] stop grace expired without a finished turn');
      unawaited(_finishStop());
    });
    if (!_pump.isSpeaking) unawaited(_finishStop());
  }

  Future<void> _finishStop() async {
    if (_disposed || _closing) return;
    _closing = true;
    _stopTimeout?.cancel();
    _stopTimeout = null;
    _openEarTimer?.cancel();
    _openEarTimer = null;
    _stopAfterResponse = false;
    debugPrint('[PyQuestVoice] session closing events=$_serverEvents audioChunks=$_serverAudioChunks '
        'audioBytes=$_serverAudioBytes errors=$_errors echoDropped=$_echoDropped');
    _sealOpenTranscripts();
    _status(VoicePhase.off, 'Đã dừng trò chuyện');
    await _pump.stop();
    await _closeSocket();
  }

  /// A session that ends mid-sentence must leave a readable conversation
  /// behind, not a bubble that is still "partial" forever.
  void _sealOpenTranscripts() {
    final pending = _turnUserText.trim().isNotEmpty || _outputText.trim().isNotEmpty;
    _turnUserText = '';
    _outputText = '';
    if (pending) onTranscript(const VoiceUtterance.sealed());
  }

  void _onSpeakStarted() {
    _openEarTimer?.cancel();
    _openEarTimer = null;
    _tutorSpeaking = true;
    _resumeListeningAt = DateTime.fromMillisecondsSinceEpoch(0);
    if (!_disposed) _status(VoicePhase.speaking, '$_characterName đang nói…');
    debugPrint('[PyQuestVoice] playback started bytes=$_turnAudioBytes');
  }

  void _onSpeakFinished() {
    _openEarForChild('turn played out');
    if (_disposed || _stopAfterResponse) {
      unawaited(_finishStop());
    }
  }

  /// Hands the conversation back to the child.
  void _openEarForChild(String reason) {
    _openEarTimer?.cancel();
    _openEarTimer = null;
    if (!_tutorSpeaking) return;
    _tutorSpeaking = false;
    final now = DateTime.now();
    _resumeListeningAt = now.add(_listenAgainGuard);
    // The audio that was already buffered keeps playing for a moment after the
    // pump is done with it, and the room carries it back into the microphone.
    _echoUntil = now.add(_echoGrace);
    debugPrint('[PyQuestVoice] microphone reopened ($reason)');
    if (_disposed || _stopAfterResponse) return;
    _status(VoicePhase.listening, 'Đang nghe bé nói…');
  }

  void _onPlaybackFailure(String message) {
    if (_disposed) return;
    onError(message);
  }

  void _status(VoicePhase phase, String message) {
    _phase = phase;
    onStatus(TutorVoiceStatus(phase, message));
  }

  void _fail(String message) {
    _errors++;
    onError(message);
  }

  void _handleServerMessage(dynamic raw) {
    final GeminiLiveEvent event;
    try {
      event = GeminiLiveWire.decode(raw);
    } on Object catch (error) {
      debugPrint('[PyQuestVoice] server message parse ERROR: ${GeminiLiveWire.redactSecrets('$error')}');
      _fail('Không đọc được phản hồi Gemini Live.');
      return;
    }
    _serverEvents++;
    debugPrint('[PyQuestVoice] recv #$_serverEvents ${event.describe()}');

    if (event.setupComplete) {
      if (!_setupComplete.isCompleted) _setupComplete.complete();
      return;
    }
    if (event.errorText != null) {
      debugPrint('[PyQuestVoice] server ERROR #$_errors ${event.errorText}');
      _fail('Gemini Live: ${event.errorText}');
      return;
    }
    if (event.goAwaySeconds != null) {
      debugPrint('[PyQuestVoice] server goAway in ${event.goAwaySeconds}s');
      // Whatever was still being transcribed becomes a finished line: the
      // socket is closing, so no turnComplete will ever seal it.
      _sealOpenTranscripts();
      _status(VoicePhase.closing, 'Phiên trò chuyện sắp kết thúc…');
      return;
    }

    final userText = event.userText;
    if (userText != null && userText.isNotEmpty) {
      _heardFromMicrophone(userText);
    }

    final assistantText = event.assistantText;
    if (assistantText != null && assistantText.isNotEmpty) {
      _outputText = GeminiLiveWire.mergeTranscript(_outputText, assistantText);
      // Shown while it arrives: an answer that only appears on turnComplete
      // disappears altogether when the turn is interrupted, and then the
      // tutor's own words are the only line left in the chat — labelled as the
      // child's. When this very message ends the turn, the final emission below
      // is the one that counts.
      if (!event.turnComplete && !event.interrupted) {
        onTranscript(VoiceUtterance(
          role: TutorSpeakerRole.assistant,
          text: _outputText.trim(),
          isFinal: false,
        ));
      }
    }

    if (event.hasAudio) {
      _serverAudioChunks++;
      _serverAudioBytes += event.audioBytes;
      _turnAudioBytes += event.audioBytes;
      if (_serverAudioChunks == 1 || _serverAudioChunks % 10 == 0) {
        debugPrint('[PyQuestVoice] server audio chunks=$_serverAudioChunks bytes=$_serverAudioBytes queued=${_pump.pendingBytes}');
      }
      _pump.push(event.audio!);
    }

    if (event.interrupted) {
      // The child cut in. Keep what the tutor had already said — it was heard,
      // so it must stay in the conversation, marked as cut short.
      debugPrint('[PyQuestVoice] server interrupted=true; queued audio dropped, assistant text kept');
      _pump.interrupt();
      _finishAssistantTurn(interrupted: true);
      _turnUserText = '';
      _openEarForChild('bị ngắt lời');
      return;
    }

    if (event.turnComplete) {
      debugPrint('[PyQuestVoice] server turnComplete audioBytes=$_turnAudioBytes pumpFed=${_pump.bytesFed} pumpDropped=${_pump.slicesDropped}');
      if (event.audioBytes == 0 && _turnAudioBytes == 0 && _outputText.trim().isNotEmpty) {
        // Worth a line on the child's screen: a text-only turn is what makes
        // the tutor look mute, and it is the server's choice, not the player's.
        debugPrint('[PyQuestVoice] turnComplete without audio for this turn (text=${_outputText.length}ch)');
        _status(VoicePhase.listening, '$_characterName chỉ trả lời bằng chữ cho câu này…');
      }
      _turnAudioBytes = 0;
      _finishAssistantTurn();
      _turnUserText = '';
      // The turn is only over once the audio has actually played out; the pump
      // tells us (or the stop grace timer does).
      _pump.endTurn();
    }
  }

  /// One utterance the microphone produced, after the playback-echo filter.
  ///
  /// Returns nothing and changes nothing when the words are the tutor's own: a
  /// tutor greeting must never become the learner's line.
  void _heardFromMicrophone(String heard) {
    final candidate = GeminiLiveWire.mergeTranscript(_turnUserText, heard);
    final tutorSaid = _lastSpokenText.isNotEmpty ? _lastSpokenText : _outputText;
    if (echoSuspect && GeminiLiveWire.looksLikeEcho(heard: candidate, spoken: tutorSaid)) {
      _echoDropped++;
      _turnUserText = '';
      debugPrint('[PyQuestVoice] dropped a ${candidate.split(' ').length}-word transcription as '
          'playback echo (count=$_echoDropped) — not shown as the child’s line');
      return;
    }
    _turnUserText = candidate;
    onTranscript(VoiceUtterance(
      role: TutorSpeakerRole.child,
      text: candidate.trim(),
      isFinal: false,
    ));
  }

  /// Ends the assistant's turn: the text it produced becomes one final line.
  void _finishAssistantTurn({bool interrupted = false}) {
    final said = _outputText.trim();
    _turnAudioBytes = 0;
    _outputText = '';
    if (said.isEmpty) return;
    _lastSpokenText = said;
    onTranscript(VoiceUtterance(
      role: TutorSpeakerRole.assistant,
      text: said,
      interrupted: interrupted,
    ));
  }

  Future<void> _stopRecorder() async {
    debugPrint('[PyQuestVoice] stopping recorder; chunks=$_micChunkCount bytes=$_micByteCount');
    await _micSubscription?.cancel();
    _micSubscription = null;
    try {
      if (await _recorder.isRecording()) await _recorder.stop();
    } catch (_) {}
  }

  Future<void> _closeSocket() async {
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    try {
      await _channel?.sink.close();
    } catch (error) {
      debugPrint('[PyQuestVoice] socket close ERROR: $error');
    }
    _channel = null;
    debugPrint('[PyQuestVoice] socket closed');
  }

  Future<void> dispose() async {
    _disposed = true;
    _recording = false;
    _stopTimeout?.cancel();
    _stopTimeout = null;
    _openEarTimer?.cancel();
    _openEarTimer = null;
    await _stopRecorder();
    await _closeSocket();
    await _pump.stop();
    await _output.release();
    try {
      await _recorder.dispose();
    } catch (error) {
      debugPrint('[PyQuestVoice] recorder dispose failed: $error');
    }
  }
}
