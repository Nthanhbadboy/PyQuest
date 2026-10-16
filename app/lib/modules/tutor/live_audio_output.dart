import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';

import 'gemini_live_wire.dart';

/// The tutor's speaker, behind the smallest contract that the turn logic needs,
/// so the whole playback lifecycle can be tested without a device.
abstract interface class PcmAudioOutput {
  /// Acquires the device for this session. Safe to call twice.
  Future<void> open();

  /// True when the device is actually consuming fed bytes.
  bool get isStreaming;

  /// Makes sure the stream is running and reports whether it accepts data.
  ///
  /// Must never wait for playback to finish: a live stream only "finishes"
  /// when it is stopped, and flutter_sound's start future is exactly that.
  Future<bool> ensureStreaming();

  /// Hands one PCM slice to the device. May hang or throw — the pump bounds and
  /// catches it, because a wedged write must not silence the next turn.
  Future<void> write(Uint8List pcm);

  Future<void> stopStreaming();

  Future<void> release();
}

/// [PcmAudioOutput] on top of `flutter_sound`'s live PCM stream player.
///
/// Two behaviours of that plugin are the reason this wrapper exists, and both
/// bit the tutor on real devices:
///
/// * `startPlayerFromStream()` returns a future that only completes when
///   playback ENDS, and it stops the player internally first — so awaiting it,
///   or letting its errors go unobserved, loses the speaker in silence;
/// * `feedUint8FromStream()` waits for a native `needSomeFood` callback, and
///   `stopPlayer()` drops that callback instead of completing it. An awaited
///   feed can therefore hang forever, and any feed issued while the player
///   state is `isStopped` is dropped without an error at all.
class FlutterSoundPcmOutput implements PcmAudioOutput {
  FlutterSoundPcmOutput({FlutterSoundPlayer? player, this.onDiagnostic})
      : _player = player ?? FlutterSoundPlayer();

  final FlutterSoundPlayer _player;
  final void Function(String message)? onDiagnostic;

  static const int _bufferBytes = 16384; // ~340 ms at 24 kHz mono 16-bit
  static const Duration _startPollEvery = Duration(milliseconds: 40);
  static const int _startPolls = 25; // ~1 s: enough for a cold AudioTrack
  static const Duration _nativeBudget = Duration(milliseconds: 700);

  bool _opened = false;
  Future<bool>? _starting;

  @override
  bool get isStreaming => _player.isPlaying;

  @override
  Future<void> open() async {
    if (_opened) return;
    _opened = true;
    try {
      await _player.openPlayer().timeout(_nativeBudget, onTimeout: () {
        _diagnose('openPlayer timed out');
        return _player;
      });
    } on Object catch (error) {
      _opened = false;
      _diagnose('openPlayer failed: $error');
      rethrow;
    }
  }

  @override
  Future<bool> ensureStreaming() {
    if (_player.isPlaying) return SynchronousFuture<bool>(true);
    final pending = _starting;
    if (pending != null) return pending;
    final future = _start();
    _starting = future;
    return future.whenComplete(() => _starting = null);
  }

  Future<bool> _start() async {
    await open();
    // Deliberately not awaited (see the class comment) — but never unobserved
    // either, because a silent failure here used to mean "no audio at all".
    unawaited(
      _player
          .startPlayerFromStream(
            codec: Codec.pcm16,
            interleaved: true,
            numChannels: 1,
            sampleRate: GeminiLiveWire.outputSampleRate,
            bufferSize: _bufferBytes,
          )
          .catchError((Object error) {
            _diagnose('startPlayerFromStream failed: $error');
          }),
    );
    for (var i = 0; i < _startPolls; i++) {
      await Future<void>.delayed(_startPollEvery);
      if (_player.isPlaying) {
        _diagnose('audio stream playing');
        return true;
      }
    }
    _diagnose('audio stream never reached isPlaying (${_player.playerState})');
    return false;
  }

  @override
  Future<void> write(Uint8List pcm) async {
    await _player.feedUint8FromStream(pcm);
  }

  @override
  Future<void> stopStreaming() async {
    try {
      await _player.stopPlayer().timeout(_nativeBudget, onTimeout: () {
        _diagnose('stopPlayer timed out');
      });
    } on Object catch (error) {
      _diagnose('stopPlayer failed: $error');
    }
  }

  @override
  Future<void> release() async {
    await stopStreaming();
    if (!_opened) return;
    _opened = false;
    try {
      await _player.closePlayer().timeout(_nativeBudget, onTimeout: () {
        _diagnose('closePlayer timed out');
      });
    } on Object catch (error) {
      _diagnose('closePlayer failed: $error');
    }
  }

  void _diagnose(String message) => debugPrint('[PyQuestVoice] audio: $message');
}

/// Plays a model turn as it arrives, on a real-time budget.
///
/// Gemini answers much faster than a speaker can play. The code this replaces
/// fed every chunk as fast as the socket delivered it and awaited each feed
/// inside ONE long-lived future chain; the first `stopPlayer()` of a session
/// wedged that chain, so the greeting was cut short and every later turn was
/// silent while the text transcript kept working. Here:
///
/// * the stream is opened once per session and kept alive with silence, which
///   stops the device from leaving its playing state between turns;
/// * audio is fed on a budget ("what the device could have played by now, plus
///   a short lead"), so the native buffer is never overflown;
/// * no write is chained: a slice that hangs is abandoned after [writeTimeout]
///   and the next turn is tried anyway;
/// * [interrupt] forgets only what has not been fed yet.
class PcmTurnPump {
  PcmTurnPump({
    required this.output,
    this.sampleRate = GeminiLiveWire.outputSampleRate,
    this.tick = const Duration(milliseconds: 20),
    this.lead = const Duration(milliseconds: 180),
    this.tail = const Duration(milliseconds: 320),
    this.writeTimeout = const Duration(milliseconds: 500),
    this.onSpeakStarted,
    this.onSpeakFinished,
    this.onFailure,
    this.onDiagnostic,
    @visibleForTesting Duration Function()? elapsed,
    @visibleForTesting Future<void> Function(Duration)? sleep,
  })  : _bytesPerSecond = sampleRate * 2,
        _elapsed = elapsed ?? _wallClock,
        _sleep = sleep ?? Future<void>.delayed;

  /// A burst may fill the lead in a few ticks instead of one slice per tick.
  static const int _maxSlicesPerTick = 8;

  /// Never feeds less than this, or the device starves between two chunks.
  static const int _minSliceBytes = 2;

  final PcmAudioOutput output;
  final int sampleRate;
  final Duration tick;
  final Duration lead;
  final Duration tail;
  final Duration writeTimeout;

  /// Fired when the first bytes of a turn reached the device.
  final VoidCallback? onSpeakStarted;

  /// Fired when a turn has been fully handed to the device and had time to play
  /// out. The tutor listens again only now, so its own voice through the
  /// speaker cannot interrupt itself.
  final VoidCallback? onSpeakFinished;

  /// Playback broke in a way worth telling the child about (never a payload).
  final void Function(String message)? onFailure;
  final void Function(String message)? onDiagnostic;

  final int _bytesPerSecond;
  final Duration Function() _elapsed;
  final Future<void> Function(Duration) _sleep;

  static final Stopwatch _sharedWatch = Stopwatch()..start();
  static Duration _wallClock() => _sharedWatch.elapsed;

  final List<Uint8List> _parts = <Uint8List>[];
  int _partOffset = 0;
  int _pendingBytes = 0;

  late final Uint8List _silence = Uint8List(sliceBytes);

  bool _running = false;
  bool _stopped = true;
  bool _turnOpen = false;
  bool _draining = false;
  bool _flushRequested = false;
  bool _speaking = false;

  Duration _reference = Duration.zero;
  int _fedBytes = 0;
  Duration _lastAudioAt = Duration.zero;

  int _slicesFed = 0;
  int _slicesDropped = 0;
  int _failures = 0;

  /// Bytes handed to the device so far (diagnostics only).
  int get bytesFed => _fedBytes;
  int get slicesFed => _slicesFed;
  int get slicesDropped => _slicesDropped;
  int get pendingBytes => _pendingBytes;

  /// True from the first fed byte of a turn until its audio has played out.
  bool get isSpeaking => _turnOpen || _draining || _pendingBytes > 0;

  /// Size of one feed: a single [tick] of audio.
  int get sliceBytes {
    final bytes = tick.inMicroseconds * _bytesPerSecond ~/ 1000000;
    return bytes.isEven ? bytes : bytes + 1;
  }

  /// Starts the pump loop. Idempotent: one stream per session.
  Future<void> start() async {
    await prepare();
    unawaited(_loop());
  }

  /// Acquires the device and opens the pump's bookkeeping without running the
  /// loop. Tests use this together with [pumpOnce] so pacing and turn
  /// transitions are driven by a virtual clock instead of wall time.
  Future<void> prepare() async {
    if (_running) return;
    _running = true;
    _stopped = false;
    _reference = _elapsed();
    _lastAudioAt = _reference;
    _fedBytes = 0;
    await output.open();
  }

  /// One pump step: feed what the device could have played by now.
  @visibleForTesting
  Future<void> pumpOnce() => _pumpOnce();

  /// Adds one PCM chunk of the current turn.
  void push(Uint8List pcm) {
    if (pcm.isEmpty || _stopped) return;
    // 16-bit mono frames must stay even or the PCM sink rejects the slice.
    final aligned = pcm.length.isEven ? pcm : Uint8List.sublistView(pcm, 0, pcm.length - 1);
    if (aligned.isEmpty) return;
    _parts.add(aligned);
    _pendingBytes += aligned.length;
    _turnOpen = true;
    _draining = false;
  }

  /// The turn's audio is all here: play it out, then report the turn as spoken
  /// so the session can listen again (or close after the last one).
  void endTurn() {
    if (!_turnOpen && _pendingBytes == 0) return;
    _turnOpen = false;
    _draining = true;
  }

  /// The child interrupted the tutor: forget what was not fed yet and make the
  /// device stop the current speech.
  void interrupt() {
    _clearQueue();
    _turnOpen = false;
    _flushRequested = true;
    _draining = false;
    _speaking = false;
    onSpeakFinished?.call();
    onDiagnostic?.call('interrupted: queued audio dropped');
  }

  /// Stops the loop and the device.
  Future<void> stop() async {
    _stopped = true;
    _running = false;
    _clearQueue();
    _turnOpen = false;
    _draining = false;
    _speaking = false;
    await output.stopStreaming();
  }

  void _clearQueue() {
    _parts.clear();
    _partOffset = 0;
    _pendingBytes = 0;
  }

  /// How many bytes the device could still take without overflowing: what it
  /// should have played by now, plus the lead, minus what was fed already.
  int get _budgetBytes {
    final played = (_elapsed() - _reference).inMicroseconds * _bytesPerSecond ~/ 1000000;
    final leadBytes = lead.inMicroseconds * _bytesPerSecond ~/ 1000000;
    final allowed = played + leadBytes - _fedBytes;
    if (allowed < _minSliceBytes) return 0;
    return allowed.isEven ? allowed : allowed - 1;
  }

  Future<void> _loop() async {
    while (!_stopped) {
      try {
        await _pumpOnce();
      } on Object catch (error) {
        _noteFailure('pump error: $error');
      }
      if (_stopped) return;
      await _sleep(tick);
    }
  }

  Future<void> _pumpOnce() async {
    if (_stopped) return;
    if (_flushRequested) {
      _flushRequested = false;
      await output.stopStreaming();
      if (_stopped) return;
      _reference = _elapsed();
      _fedBytes = 0;
      return;
    }

    if (_pendingBytes == 0) {
      // Idle: keep the stream fed with silence. Without this the device drops
      // out of its playing state after the first turn and then silently
      // discards every byte the next turn brings.
      if (_budgetBytes >= sliceBytes && await output.ensureStreaming()) {
        await _write(_silence, isAudio: false);
      }
      _maybeFinishTurn();
      return;
    }

    if (!await output.ensureStreaming()) {
      _noteFailure('audio output unavailable');
      _maybeGiveUpOnTurn();
      return;
    }
    final slice = sliceBytes;
    for (var i = 0; i < _maxSlicesPerTick && _pendingBytes > 0; i++) {
      final budget = _budgetBytes;
      final amount = budget < slice ? budget : slice;
      if (amount < _minSliceBytes) break;
      await _write(_take(amount), isAudio: true);
    }
    _maybeFinishTurn();
  }

  /// A turn whose device stays unavailable is declared over after a while.
  ///
  /// Dropping the audio is the lesser evil: the tutor must open the microphone
  /// again instead of sitting mute with the child waiting for an answer that
  /// can never be played.
  void _maybeGiveUpOnTurn() {
    if (!_draining && !_turnOpen) return;
    if (_elapsed() - _lastAudioAt < lead + tail + const Duration(seconds: 4)) return;
    onDiagnostic?.call('turn dropped: audio device unavailable');
    _clearQueue();
    _turnOpen = false;
    _draining = false;
    _speaking = false;
    onSpeakFinished?.call();
  }

  void _maybeFinishTurn() {
    if (!_draining || _pendingBytes > 0) return;
    if (_elapsed() - _lastAudioAt < lead + tail) return;
    _draining = false;
    _speaking = false;
    onSpeakFinished?.call();
  }

  Future<void> _write(Uint8List data, {required bool isAudio}) async {
    if (_stopped || data.isEmpty) return;
    var abandoned = false;
    // The catchError first keeps an error that arrives AFTER the timeout from
    // becoming an unhandled async error, which would kill the isolate.
    final fed = output.write(data).catchError((Object error) {
      abandoned = true;
      _noteFailure('feed failed: $error');
    });
    await fed.timeout(writeTimeout, onTimeout: () {
      abandoned = true;
    });
    if (abandoned) {
      // Dropping a wedged slice is always better than stalling the session:
      // flutter_sound completes a feed only when the device asks for more.
      _slicesDropped++;
      onDiagnostic?.call('dropped ${data.length}B slice: device not accepting data');
      return;
    }
    _slicesFed++;
    _fedBytes += data.length;
    if (isAudio) {
      _lastAudioAt = _elapsed();
      if (!_speaking) {
        _speaking = true;
        onSpeakStarted?.call();
      }
    }
  }

  Uint8List _take(int maxBytes) {
    while (_parts.isNotEmpty) {
      final first = _parts.first;
      final available = first.length - _partOffset;
      if (available <= 0) {
        _parts.removeAt(0);
        _partOffset = 0;
        continue;
      }
      if (available <= maxBytes) {
        _parts.removeAt(0);
        final slice = _partOffset == 0 ? first : Uint8List.sublistView(first, _partOffset);
        _partOffset = 0;
        _pendingBytes -= slice.length;
        return slice;
      }
      final slice = Uint8List.sublistView(first, _partOffset, _partOffset + maxBytes);
      _partOffset += maxBytes;
      _pendingBytes -= maxBytes;
      return slice;
    }
    return Uint8List(0);
  }

  void _noteFailure(String message) {
    _failures++;
    onDiagnostic?.call(message);
    if (_failures == 3 || _failures % 25 == 0) {
      onFailure?.call('Trợ lý không phát được âm thanh ($message)');
    }
  }
}
