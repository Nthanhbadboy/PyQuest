import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Experimental hands-free Gemini Live conversation for development builds.
///
/// Supply the key only through --dart-define=GEMINI_API_KEY=... . This is
/// intentionally a development shortcut: dart-defines are embedded in the
/// APK and must be replaced by short-lived tokens/server mediation before
/// any public release.
class GeminiLiveVoice {
  GeminiLiveVoice({
    required this.onStatus,
    required this.onTranscript,
    required this.onError,
  });

  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = 'gemini-3.1-flash-live-preview';

  final void Function(String status) onStatus;
  final void Function(String text, {required bool fromUser}) onTranscript;
  final void Function(String message) onError;

  final AudioRecorder _recorder = AudioRecorder();
  final FlutterSoundPlayer _streamPlayer = FlutterSoundPlayer();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSubscription;
  StreamSubscription<Uint8List>? _micSubscription;
  Completer<void> _setupComplete = Completer<void>();
  Future<void> _audioQueue = Future<void>.value();
  bool _playerOpened = false;
  bool _streamStarted = false;
  int _turnPcmBytes = 0;
  DateTime? _turnAudioStartedAt;
  int _audioTurn = 0;
  String _outputText = '';
  bool _recording = false;
  bool _stopAfterResponse = false;
  Timer? _stopTimeout;
  bool _disposed = false;

  bool get isRecording => _recording;

  Future<void> startListening({required String characterName, required String language}) async {
    if (_disposed || _recording || _channel != null) return;
    if (_apiKey.trim().isEmpty) {
      onError('Thiếu GEMINI_API_KEY. Hãy build thử nghiệm với --dart-define=GEMINI_API_KEY=...');
      return;
    }
    try {
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
          onError('Kết nối voice lỗi: $error');
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
      final persona = 'You are $characterName, a friendly and expressive character in PyQuest, a Python-learning game for children. '
          'Speak naturally and warmly in Vietnamese when the child uses Vietnamese, or English when the child uses English. '
          'Keep each answer short, encouraging, age-appropriate, and related to learning. Never ask for personal information. '
          'Do not claim to see the child. Respond with spoken audio.';
      _channel!.sink.add(jsonEncode(<String, Object>{
        'setup': <String, Object>{
          'model': 'models/$_model',
          'generationConfig': <String, Object>{
            'responseModalities': <String>['AUDIO'],
            'speechConfig': <String, Object>{
              'languageCode': language == 'vi' ? 'vi-VN' : 'en-US',
              'voiceConfig': <String, Object>{
                'prebuiltVoiceConfig': <String, Object>{'voiceName': characterName == 'Kai' ? 'Puck' : 'Aoede'},
              },
            },
          },
          'systemInstruction': <String, Object>{'parts': <Object>[<String, String>{'text': persona}]},
          'inputAudioTranscription': <String, Object>{},
          'outputAudioTranscription': <String, Object>{},
        },
      }));
      await _setupComplete.future.timeout(const Duration(seconds: 25));
      if (!await _recorder.hasPermission()) {
        throw StateError('Chưa được cấp quyền micro cho PyQuest.');
      }
      await _streamPlayer.openPlayer();
      _playerOpened = true;
      _outputText = '';
      _stopTimeout?.cancel();
      _stopAfterResponse = false;
      final stream = await _recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ));
      _recording = true;
      onStatus('Đang trò chuyện… Hãy nói tự nhiên, không cần nhấn giữ micro');
      _micSubscription = stream.listen((chunk) {
        if (!_recording || _channel == null) return;
        _channel!.sink.add(jsonEncode(<String, Object>{
          'realtimeInput': <String, Object>{
            'audio': <String, String>{
              'mimeType': 'audio/pcm;rate=16000',
              'data': base64Encode(chunk),
            },
          },
        }));
      }, onError: (Object error) => onError('Không đọc được micro: $error'));
      // Prompt the tutor to open the conversation as soon as the session is ready.
      _channel!.sink.add(jsonEncode(<String, Object>{
        'clientContent': <String, Object>{
          'turns': <Object>[
            <String, Object>{
              'role': 'user',
              'parts': <Object>[
                <String, String>{
                  'text': 'Start a friendly voice conversation with the child now. Briefly greet them, introduce yourself as $characterName, and ask one simple question about what they are learning. Speak aloud in ${language == 'vi' ? 'Vietnamese' : 'English'}.',
                },
              ],
            },
          ],
          'turnComplete': true,
        },
      }));
    } catch (error) {
      await _stopRecorder();
      onError('Không thể bắt đầu voice: $error');
      onStatus('Voice chưa kết nối');
      await _closeSocket();
    }
  }

  Future<void> stopListening() async {
    if (!_recording) return;
    _recording = false;
    _stopAfterResponse = true;
    onStatus('Đang chờ Kai/Lumi nói nốt…');
    await _stopRecorder();
    try {
      _channel?.sink.add(jsonEncode(<String, Object>{
        'realtimeInput': <String, Object>{'audioStreamEnd': true},
      }));
    } catch (error) {
      onError('Không gửi được đoạn âm thanh: $error');
    }

    // Gemini should finish its current turn after audioStreamEnd. Never leave
    // the UI waiting forever if the server does not send turnComplete.
    _stopTimeout?.cancel();
    _stopTimeout = Timer(const Duration(seconds: 8), () {
      if (_disposed || !_stopAfterResponse || _channel == null) return;
      _stopAfterResponse = false;
      _streamStarted = false;
      _turnPcmBytes = 0;
      _turnAudioStartedAt = null;
      onStatus('Đã dừng trò chuyện');
      unawaited(_streamPlayer.stopPlayer());
      unawaited(_closeSocket());
    });
  }

  void _handleServerMessage(dynamic raw) {
    try {
      final message = jsonDecode(raw is String ? raw : utf8.decode(raw as List<int>)) as Map<String, dynamic>;
      if (message.containsKey('setupComplete')) {
        if (!_setupComplete.isCompleted) _setupComplete.complete();
        return;
      }
      if (message['error'] != null) {
        onError('Gemini Live: ${message['error']}');
        return;
      }
      final inputText = message['serverContent']?['inputTranscription']?['text'];
      if (inputText is String && inputText.trim().isNotEmpty) {
        onTranscript(inputText.trim(), fromUser: true);
      }
      final serverContent = message['serverContent'];
      final outputText = serverContent?['outputTranscription']?['text'];
      if (outputText is String && outputText.isNotEmpty) _outputText += outputText;
      final parts = serverContent?['modelTurn']?['parts'];
      if (parts is List) {
        for (final part in parts) {
          final inlineData = part is Map ? part['inlineData'] : null;
          final data = inlineData is Map ? inlineData['data'] : null;
          if (data is String) {
            final pcm = Uint8List.fromList(base64Decode(data));
            _audioQueue = _audioQueue.then((_) => _feedPcm(pcm));
          }
          final text = part is Map ? part['text'] : null;
          if (text is String) _outputText += text;
        }
      }
      if (serverContent?['turnComplete'] == true) {
        if (_outputText.trim().isNotEmpty) {
          onTranscript(_outputText.trim(), fromUser: false);
          _outputText = '';
        }
        unawaited(_finishAudioTurn());
      }
      if (serverContent?['interrupted'] == true) {
        _audioTurn++;
        _turnPcmBytes = 0;
        _turnAudioStartedAt = null;
        _streamStarted = false;
        unawaited(_streamPlayer.stopPlayer());
      }
    } catch (error) {
      onError('Không đọc được phản hồi Gemini Live: $error');
    }
  }

  Future<void> _feedPcm(Uint8List pcm) async {
    if (_disposed || pcm.isEmpty || !_playerOpened) return;
    if (!_streamStarted) {
      _streamStarted = true;
      _turnPcmBytes = 0;
      _turnAudioStartedAt = DateTime.now();
      final turn = _audioTurn;
      // Flutter Sound starts a native PCM stream; unlike the previous WAV path,
      // each Gemini chunk is sent to the speaker as soon as it arrives.
      unawaited(_streamPlayer.startPlayerFromStream(
        codec: Codec.pcm16,
        interleaved: true,
        numChannels: 1,
        sampleRate: 24000,
        bufferSize: 4096,
      ));
      // Give the platform audio sink a moment to initialize before the first
      // packet. Keep this delay short so it does not reintroduce turn buffering.
      await Future<void>.delayed(const Duration(milliseconds: 60));
      if (_disposed || turn != _audioTurn) return;
      onStatus('Kai/Lumi đang nói…');
    }
    if (_disposed) return;
    // Gemini PCM chunks are 16-bit mono. Keep an even byte count for the PCM sink.
    final usableLength = pcm.length.isEven ? pcm.length : pcm.length - 1;
    if (usableLength <= 0) return;
    await _streamPlayer.feedUint8FromStream(
      usableLength == pcm.length ? pcm : Uint8List.sublistView(pcm, 0, usableLength),
    );
    _turnPcmBytes += usableLength;
  }

  Future<void> _finishAudioTurn() async {
    final turn = _audioTurn;
    try {
      await _audioQueue;
      if (_disposed || turn != _audioTurn) return;
      if (_turnPcmBytes > 0 && _turnAudioStartedAt != null && _streamStarted) {
        // Let the native stream play the remaining samples instead of cutting
        // the tail off when Gemini signals turnComplete.
        final total = Duration(
          microseconds: (_turnPcmBytes * 1000000 / (24000 * 2)).round(),
        );
        final elapsed = DateTime.now().difference(_turnAudioStartedAt!);
        final remaining = total - elapsed + const Duration(milliseconds: 220);
        if (remaining > Duration.zero) await Future<void>.delayed(remaining);
        if (_disposed || turn != _audioTurn) return;
        await _streamPlayer.stopPlayer();
      }
      _streamStarted = false;
      _turnPcmBytes = 0;
      _turnAudioStartedAt = null;
      if (_stopAfterResponse) {
        _stopTimeout?.cancel();
        _stopTimeout = null;
        _stopAfterResponse = false;
        onStatus('Đã dừng trò chuyện');
        await _closeSocket();
      } else {
        onStatus('Đang nghe bé nói…');
      }
    } catch (error) {
      onError('Không phát được luồng giọng nói: $error');
      _streamStarted = false;
    }
  }

  Future<void> _stopRecorder() async {
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
    } catch (_) {}
    _channel = null;
  }

  Future<void> dispose() async {
    _disposed = true;
    _recording = false;
    _stopTimeout?.cancel();
    _stopTimeout = null;
    await _stopRecorder();
    await _closeSocket();
    if (_playerOpened) {
      await _streamPlayer.stopPlayer();
      await _streamPlayer.closePlayer();
      _playerOpened = false;
    }
    await _recorder.dispose();
  }
}
