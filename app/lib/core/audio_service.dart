import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import 'settings_service.dart';

enum Sfx { tap, pop, success, fail, star, coin, jump, hit, step, unlock, whoosh, sparkle, bug, bonk, splash }

enum MusicTrack { island, arcade, calm }

/// Sound effects + looping music. All audio is generated in-house
/// (see tool/generate_audio.py). Failures never crash the game; when the
/// platform has no audio (widget tests) the service silently does nothing.
class AudioService with WidgetsBindingObserver {
  AudioService(this._settings, {this.enabled = true});

  final SettingsService _settings;
  final bool enabled;

  final Map<Sfx, _SfxChannel> _channels = {};
  AudioPlayer? _music;
  MusicTrack? _wantedTrack;
  MusicTrack? _loadedTrack;
  bool _ready = false;
  bool _paused = false;

  static const Map<Sfx, int> _voices = {Sfx.coin: 3, Sfx.sparkle: 3, Sfx.step: 2, Sfx.tap: 2, Sfx.pop: 2};

  static String _sfxAsset(Sfx s) => 'audio/sfx_${s.name}.wav';
  static String _musicAsset(MusicTrack t) => 'audio/music_${t.name}.ogg';

  Future<void> init() async {
    if (!enabled) return;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
      );
      for (final s in Sfx.values) {
        final channel = _SfxChannel(_sfxAsset(s), _voices[s] ?? 1);
        await channel.init();
        _channels[s] = channel;
      }
      _music = AudioPlayer();
      await _music!.setReleaseMode(ReleaseMode.loop);
      _ready = true;
      WidgetsBinding.instance.addObserver(this);
      _settings.addListener(_onSettingsChanged);
    } catch (e) {
      debugPrint('Audio unavailable: $e');
      _ready = false;
    }
  }

  void play(Sfx sfx, {double volume = 1.0}) {
    if (!_ready || !_settings.soundOn || _paused) return;
    final channel = _channels[sfx];
    if (channel == null) return;
    unawaited(channel.play(volume).catchError((Object e) => debugPrint('sfx failed: $e')));
  }

  /// Selects the background track for the current screen.
  void music(MusicTrack track) {
    _wantedTrack = track;
    unawaited(_syncMusic());
  }

  Future<void> _syncMusic() async {
    final player = _music;
    if (!_ready || player == null) return;
    try {
      if (!_settings.musicOn || _paused || _wantedTrack == null) {
        await player.pause();
        return;
      }
      final volume = _wantedTrack == MusicTrack.calm ? 0.35 : 0.45;
      if (_loadedTrack != _wantedTrack) {
        _loadedTrack = _wantedTrack;
        await player.stop();
        await player.setVolume(volume);
        await player.play(AssetSource(_musicAsset(_wantedTrack!)));
      } else {
        await player.setVolume(volume);
        await player.resume();
      }
    } catch (e) {
      debugPrint('music failed: $e');
    }
  }

  void _onSettingsChanged() => unawaited(_syncMusic());

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _paused = state != AppLifecycleState.resumed;
    unawaited(_syncMusic());
  }
}

class _SfxChannel {
  _SfxChannel(this.asset, this.voices);

  final String asset;
  final int voices;
  final List<AudioPlayer> _players = [];
  int _next = 0;

  Future<void> init() async {
    for (var i = 0; i < voices; i++) {
      final p = AudioPlayer();
      await p.setPlayerMode(PlayerMode.lowLatency);
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setSource(AssetSource(asset));
      _players.add(p);
    }
  }

  Future<void> play(double volume) async {
    if (_players.isEmpty) return;
    final p = _players[_next];
    _next = (_next + 1) % _players.length;
    await p.stop();
    await p.setVolume(volume);
    await p.resume();
  }
}
