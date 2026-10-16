import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'gemini_live_wire.dart';
import 'live_audio_output.dart';

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

  /// Hard limit for "the tutor is still speaking" before the session is torn
  /// down anyway. A stuck speaker must never freeze a lesson.
  static const Duration _stopGrace = Duration(seconds: 8);

  /// Fallback for the opening greeting: if nothing ever plays, the microphone
  /// must still be handed to the child.
  static const Duration _greetingGuard = Duration(seconds: 12);

  final void Function(String status) onStatus;
  final void Function(String text, {required bool fromUser}) onTranscript;
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
  String _characterName = 'Kai';

  bool _recording = false;
  bool _closing = false;
  bool _tutorSpeaking = false;
  bool _stopAfterResponse = false;
  bool _disposed = false;
  DateTime _resumeListeningAt = DateTime.fromMillisecondsSinceEpoch(0);
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

  bool get isRecording => _recording;

  @visibleForTesting
  PcmTurnPump get pump => _pump;

  /// Feeds one raw server message into the session, exactly as the socket would
  /// hand it over. Tests use this to drive the event order a device sees
  /// without a network, a microphone or an API key.
  @visibleForTesting
  void handleServerMessageForTest(Object? message) => _handleServerMessage(message);

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

  Future<void> startListening({required String characterName, required String language}) async {
    if (_disposed || _recording || _channel != null) return;
    if (_apiKey.trim().isEmpty) {
      onError('Thiếu GEMINI_API_KEY. Hãy build thử nghiệm với --dart-define=GEMINI_API_KEY=...');
      return;
    }
    _characterName = characterName;
    _closing = false;
    try {
      debugPrint('[PyQuestVoice] startListening character=$characterName language=$language model=$_model');
      onStatus('Đang kết nối Gemini Live…');
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
          onError('Kết nối voice lỗi: ${GeminiLiveWire.redactSecrets('$error')}');
        },
        onDone: () {
          if (!_setupComplete.isCompleted) {
            _setupComplete.completeError(StateError('Gemini Live đã đóng kết nối trước khi setup hoàn tất.'));
          }
          if (!_disposed && _recording) {
            _recording = false;
            onStatus('Đã ngắt kết nối');
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
      _outputText = '';
      _turnUserText = '';
      _stopTimeout?.cancel();
      _stopAfterResponse = false;
      _tutorSpeaking = false;

      final stream = await _recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: GeminiLiveWire.inputSampleRate,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ));
      _recording = true;
      debugPrint('[PyQuestVoice] microphone stream started: PCM16 mono ${GeminiLiveWire.inputSampleRate}Hz');
      onStatus('Đang trò chuyện… Hãy nói tự nhiên, không cần nhấn giữ micro');
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
        onError('Không đọc được micro: $error');
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
      onError('Không thể bắt đầu voice: ${GeminiLiveWire.redactSecrets('$error')}');
      onStatus('Voice chưa kết nối');
      await _pump.stop();
      await _closeSocket();
    }
  }

  Future<void> stopListening() async {
    if (!_recording) return;
    debugPrint('[PyQuestVoice] stop requested micChunks=$_micChunkCount blockedChunks=$_micBlockedCount serverAudioChunks=$_serverAudioChunks');
    _recording = false;
    _stopAfterResponse = true;
    onStatus('Đang chờ $_characterName nói nốt…');
    await _stopRecorder();
    try {
      _channel?.sink.add(GeminiLiveWire.audioStreamEnd());
      debugPrint('[PyQuestVoice] sent audioStreamEnd');
    } catch (error) {
      onError('Không gửi được đoạn âm thanh: $error');
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
    debugPrint('[PyQuestVoice] session closing events=$_serverEvents audioChunks=$_serverAudioChunks audioBytes=$_serverAudioBytes errors=$_errors');
    onStatus('Đã dừng trò chuyện');
    await _pump.stop();
    await _closeSocket();
  }

  void _onSpeakStarted() {
    _openEarTimer?.cancel();
    _openEarTimer = null;
    _tutorSpeaking = true;
    _resumeListeningAt = DateTime.fromMillisecondsSinceEpoch(0);
    if (!_disposed) onStatus('$_characterName đang nói…');
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
    _resumeListeningAt = DateTime.now().add(_listenAgainGuard);
    debugPrint('[PyQuestVoice] microphone reopened ($reason)');
    if (_disposed || _stopAfterResponse) return;
    onStatus('Đang nghe bé nói…');
  }

  void _onPlaybackFailure(String message) {
    if (_disposed) return;
    onError(message);
  }

  void _handleServerMessage(dynamic raw) {
    final GeminiLiveEvent event;
    try {
      event = GeminiLiveWire.decode(raw);
    } on Object catch (error) {
      debugPrint('[PyQuestVoice] server message parse ERROR: ${GeminiLiveWire.redactSecrets('$error')}');
      onError('Không đọc được phản hồi Gemini Live.');
      return;
    }
    _serverEvents++;
    debugPrint('[PyQuestVoice] recv #$_serverEvents ${event.describe()}');

    if (event.setupComplete) {
      if (!_setupComplete.isCompleted) _setupComplete.complete();
      return;
    }
    if (event.errorText != null) {
      _errors++;
      debugPrint('[PyQuestVoice] server ERROR #$_errors ${event.errorText}');
      onError('Gemini Live: ${event.errorText}');
      return;
    }
    if (event.goAwaySeconds != null) {
      debugPrint('[PyQuestVoice] server goAway in ${event.goAwaySeconds}s');
      onStatus('Phiên trò chuyện sắp kết thúc…');
      return;
    }

    final userText = event.userText;
    if (userText != null && userText.isNotEmpty) {
      // One cumulative line per utterance, so a partial revision updates the
      // child's bubble instead of adding a second one.
      _turnUserText = GeminiLiveWire.mergeTranscript(_turnUserText, userText);
      onTranscript(_turnUserText, fromUser: true);
    }

    final assistantText = event.assistantText;
    if (assistantText != null && assistantText.isNotEmpty) {
      _outputText = GeminiLiveWire.mergeTranscript(_outputText, assistantText);
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
      debugPrint('[PyQuestVoice] server interrupted=true; queued audio dropped');
      _outputText = '';
      _turnUserText = '';
      _turnAudioBytes = 0;
      _pump.interrupt();
    }

    if (event.turnComplete) {
      debugPrint('[PyQuestVoice] server turnComplete audioBytes=$_turnAudioBytes pumpFed=${_pump.bytesFed} pumpDropped=${_pump.slicesDropped}');
      if (event.audioBytes == 0 && _turnAudioBytes == 0) {
        // Worth a line on the child's screen: a text-only turn is what makes
        // the tutor look mute, and it is the server's choice, not the player's.
        debugPrint('[PyQuestVoice] turnComplete without audio for this turn '
            '(text=${_outputText.trim().length}ch)');
        if (_outputText.trim().isNotEmpty) {
          onStatus('$_characterName chỉ trả lời bằng chữ cho câu này…');
        }
      }
      _turnAudioBytes = 0;
      if (_outputText.trim().isNotEmpty) {
        onTranscript(_outputText.trim(), fromUser: false);
        _outputText = '';
      }
      _turnUserText = '';
      // The turn is only over once the audio has actually played out; the pump
      // tells us (or the stop grace timer does).
      _pump.endTurn();
    }
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
