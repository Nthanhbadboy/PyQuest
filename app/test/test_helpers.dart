import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/core/clock.dart';
import 'package:pyquest/modules/tutor/live_audio_output.dart';

class FakeClock extends Clock {
  FakeClock(this.current);
  DateTime current;
  @override
  DateTime now() => current;
  void advance(Duration d) => current = current.add(d);
}

Future<void> loadAppFonts() async {
  const fonts = {
    'Baloo2': ['Baloo2-SemiBold.ttf', 'Baloo2-Bold.ttf', 'Baloo2-ExtraBold.ttf'],
    'Nunito': ['Nunito-Medium.ttf', 'Nunito-Bold.ttf', 'Nunito-ExtraBold.ttf', 'Nunito-Black.ttf'],
    'JetBrainsMono': ['JetBrainsMono-Medium.ttf', 'JetBrainsMono-Bold.ttf'],
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key);
    for (final f in entry.value) {
      loader.addFont(rootBundle.load('assets/fonts/$f'));
    }
    await loader.load();
  }
}

/// Pumps frames for [d] without waiting for (endless) idle animations to settle.
Future<void> pumpFor(WidgetTester tester, Duration d, {Duration step = const Duration(milliseconds: 50)}) async {
  var elapsed = Duration.zero;
  while (elapsed < d) {
    await tester.pump(step);
    elapsed += step;
  }
}

Future<void> tapAndSettle(WidgetTester tester, Finder f, {Duration wait = const Duration(milliseconds: 900)}) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await pumpFor(tester, wait);
}


/// One 20 ms slice at 24 kHz, 16-bit mono — the tutor's answer format.
const int kVoiceSliceBytes = 960;

/// PCM bytes that are recognisably not silence.
Uint8List voiceAudio(int slices) => Uint8List.fromList(List<int>.filled(kVoiceSliceBytes * slices, 0x7F));

bool voiceIsSilence(Uint8List bytes) => bytes.every((int byte) => byte == 0);

/// A stand-in speaker that behaves the way `flutter_sound`'s live PCM stream
/// behaves on a device, including the two traps that made the tutor mute after
/// its greeting:
///
/// * a `write` may never complete, because the device stopped sending the
///   `needSomeFood` callback the plugin waits for;
/// * writes issued while the player is not playing are dropped silently — no
///   error, no sound, and the text transcript keeps looking healthy.
class FakePcmOutput implements PcmAudioOutput {
  FakePcmOutput({this.streaming = true});

  /// False mimics `PlayerState.isStopped`: data is accepted and discarded.
  bool streaming;

  /// True mimics a feed whose native `needSomeFood` callback never arrives.
  bool hangWrites = false;

  /// False mimics a player that cannot be restarted.
  bool restartWorks = true;

  int openCalls = 0;
  int stopCalls = 0;
  int releaseCalls = 0;
  int restarts = 0;
  int droppedByDevice = 0;

  final List<Uint8List> written = <Uint8List>[];

  int get writtenBytes => written.fold(0, (int sum, Uint8List slice) => sum + slice.length);

  int get audioBytesWritten => written
      .where((Uint8List slice) => slice.any((int byte) => byte != 0))
      .fold(0, (int sum, Uint8List slice) => sum + slice.length);

  @override
  Future<void> open() async {
    openCalls++;
  }

  @override
  bool get isStreaming => streaming;

  @override
  Future<bool> ensureStreaming() async {
    if (streaming) return true;
    if (!restartWorks) return false;
    streaming = true;
    restarts++;
    return true;
  }

  @override
  Future<void> write(Uint8List pcm) async {
    if (hangWrites) await Completer<void>().future;
    if (!streaming) {
      droppedByDevice += pcm.length;
      return;
    }
    written.add(pcm);
  }

  @override
  Future<void> stopStreaming() async {
    stopCalls++;
    streaming = false;
  }

  @override
  Future<void> release() async {
    releaseCalls++;
  }
}
