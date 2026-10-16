import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Experimental push-to-talk Gemini Live client for development builds.
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
  final AudioPlayer _player = AudioPlayer();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSubscription;
  StreamSubscription<Uint8List>? _micSubscription;
  Completer<void> _setupComplete = Completer<void>();
  final List<int> _responsePcm = <int>[];
  String _outputText = '';
  bool _recording = false;
  bool _disposed = false;

  bool get isRecording => _recording;

  Future<void> startListening({required String characterName, required String language}) async {
    if (_disposed || _recording) return;
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
      await _setupComplete.future.timeout(const Duration(seconds: 12));
      if (!await _recorder.hasPermission()) {
        throw StateError('Chưa được cấp quyền micro cho PyQuest.');
      }
      _responsePcm.clear();
      _outputText = '';
      final stream = await _recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ));
      _recording = true;
      onStatus('Đang nghe… Nhấn Dừng để Kai/Lumi trả lời');
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
    onStatus('Đang xử lý câu nói…');
    await _stopRecorder();
    try {
      _channel?.sink.add(jsonEncode(<String, Object>{
        'realtimeInput': <String, Object>{'audioStreamEnd': true},
      }));
    } catch (error) {
      onError('Không gửi được đoạn âm thanh: $error');
    }
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
          if (data is String) _responsePcm.addAll(base64Decode(data));
          final text = part is Map ? part['text'] : null;
          if (text is String) _outputText += text;
        }
      }
      if (serverContent?['turnComplete'] == true) {
        if (_outputText.trim().isNotEmpty) {
          onTranscript(_outputText.trim(), fromUser: false);
          _outputText = '';
        }
        unawaited(_playResponse());
      }
      if (serverContent?['interrupted'] == true) _responsePcm.clear();
    } catch (error) {
      onError('Không đọc được phản hồi Gemini Live: $error');
    }
  }

  Future<void> _playResponse() async {
    if (_responsePcm.isEmpty || _disposed) {
      onStatus('Đã xong lượt nói');
      await _closeSocket();
      return;
    }
    try {
      final bytes = _wavBytes(Uint8List.fromList(_responsePcm), sampleRate: 24000);
      _responsePcm.clear();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/pyquest_gemini_reply.wav');
      await file.writeAsBytes(bytes, flush: true);
      await _player.stop();
      await _player.play(DeviceFileSource(file.path));
      onStatus('Kai/Lumi đang nói…');
      await _player.onPlayerComplete.first.timeout(const Duration(seconds: 60));
      onStatus('Đã xong lượt nói');
      await _closeSocket();
    } catch (error) {
      onError('Không phát được giọng nói: $error');
    }
  }

  Uint8List _wavBytes(Uint8List pcm, {required int sampleRate}) {
    final header = ByteData(44);
    void ascii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        header.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    header.setUint32(4, 36 + pcm.length, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    header.setUint32(40, pcm.length, Endian.little);
    return Uint8List.fromList(<int>[...header.buffer.asUint8List(), ...pcm]);
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
    await _stopRecorder();
    await _closeSocket();
    await _player.dispose();
    await _recorder.dispose();
  }
}
