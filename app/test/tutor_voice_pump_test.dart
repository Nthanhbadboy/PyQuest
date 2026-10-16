import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/modules/tutor/live_audio_output.dart';

import 'test_helpers.dart';

const int _slice = kVoiceSliceBytes;

Uint8List audio(int slices) => voiceAudio(slices);

void main() {
  late FakePcmOutput output;
  late PcmTurnPump pump;
  late List<String> events;
  late List<String> failures;
  late Duration clock;

  /// A pump driven by a virtual clock: tests decide when time passes, so
  /// pacing and the "has the turn finished playing" rule are deterministic.
  void build({
    Duration lead = const Duration(milliseconds: 180),
    Duration tail = const Duration(milliseconds: 320),
  }) {
    clock = Duration.zero;
    events = <String>[];
    failures = <String>[];
    output = FakePcmOutput();
    pump = PcmTurnPump(
      output: output,
      lead: lead,
      tail: tail,
      // Short so that a deliberately hung write is abandoned quickly.
      writeTimeout: const Duration(milliseconds: 20),
      elapsed: () => clock,
      sleep: (Duration d) async {
        clock += d;
      },
      onSpeakStarted: () => events.add('started'),
      onSpeakFinished: () => events.add('finished'),
      onFailure: (String message) => failures.add(message),
    );
  }

  void advance(int ms) => clock += Duration(milliseconds: ms);

  Future<void> playTurn(int slices) async {
    pump.push(audio(slices));
    pump.endTurn();
    for (var i = 0; i < 24 && pump.isSpeaking; i++) {
      await pump.pumpOnce();
      advance(40);
    }
    await pump.pumpOnce();
  }

  setUp(() {
    build();
  });

  test('a whole spoken turn reaches the device and reports its boundaries', () async {
    await pump.prepare();
    expect(pump.isSpeaking, isFalse);

    pump.push(audio(3));
    expect(pump.isSpeaking, isTrue);
    await pump.pumpOnce();

    expect(output.writtenBytes, 3 * _slice);
    expect(events, <String>['started']);

    pump.endTurn();
    advance(500); // longer than lead + tail
    await pump.pumpOnce();

    expect(events, <String>['started', 'finished']);
    expect(pump.isSpeaking, isFalse);
  });

  test('turn 2 still plays after the device left its playing state', () async {
    // The failure on devices: the greeting plays, the player ends up stopped,
    // and every later answer was handed to a stopped player (which drops it).
    await pump.prepare();
    await playTurn(2);
    final firstTurnBytes = output.audioBytesWritten;
    expect(firstTurnBytes, greaterThan(0));

    output.streaming = false; // e.g. an underrun or a stopPlayer() in between
    final before = output.audioBytesWritten;
    await playTurn(2);

    expect(output.restarts, greaterThan(0), reason: 'the pump must restart the stream');
    expect(output.droppedByDevice, 0, reason: 'audio must never be fed to a stopped device');
    expect(output.audioBytesWritten - before, greaterThan(0), reason: 'the second answer must be audible');
    expect(events.where((String e) => e == 'started').length, 2);
    expect(events.where((String e) => e == 'finished').length, 2);
  });

  test('a write that never returns cannot silence the rest of the session', () async {
    await pump.prepare();

    // Turn 1: the device stops asking for food, so every feed hangs.
    output.hangWrites = true;
    pump.push(audio(3));
    pump.endTurn();
    await pump.pumpOnce();

    expect(pump.slicesDropped, greaterThan(0), reason: 'a hung slice must be abandoned, not awaited forever');
    expect(output.writtenBytes, 0);

    // Turn 2: the device is healthy again — the pump must still play it.
    output.hangWrites = false;
    final before = output.audioBytesWritten;
    pump.push(audio(2));
    pump.endTurn();
    await pump.pumpOnce();

    expect(output.audioBytesWritten - before, 2 * _slice);
    expect(pump.pendingBytes, 0);
  });

  test('a device that cannot be restarted keeps the audio and says so', () async {
    await pump.prepare();
    output.streaming = false;
    output.restartWorks = false;

    pump.push(audio(2));
    pump.endTurn();
    // Three attempts: the pump warns the child only once a fault repeats, so
    // one hiccup never interrupts a lesson.
    for (var i = 0; i < 3; i++) {
      await pump.pumpOnce();
    }

    expect(output.droppedByDevice, 0, reason: 'the pump must not feed a device that is not playing');
    expect(pump.pendingBytes, 2 * _slice, reason: 'nothing is thrown away while the speaker is down');
    expect(failures, isNotEmpty, reason: 'a mute tutor must not look like a working one');

    // The speaker comes back: the audio that waited is played instead of lost.
    output.streaming = true;
    output.restartWorks = true;
    advance(500);
    await pump.pumpOnce();
    expect(output.audioBytesWritten, 2 * _slice);
  });

  test('interruption drops what was not fed and keeps the session usable', () async {
    await pump.prepare();
    pump.push(audio(10));
    await pump.pumpOnce();
    final fedBefore = pump.bytesFed;
    expect(fedBefore, greaterThan(0));

    pump.interrupt();
    expect(pump.pendingBytes, 0);
    expect(pump.isSpeaking, isFalse);
    expect(events, contains('finished'), reason: 'the tutor must start listening again');

    await pump.pumpOnce(); // performs the flush
    expect(output.stopCalls, 1);
    expect(output.streaming, isFalse);

    pump.push(audio(2));
    pump.endTurn();
    advance(600);
    final before = output.audioBytesWritten;
    await pump.pumpOnce();
    expect(output.audioBytesWritten - before, 2 * _slice, reason: 'the next answer still plays');
  });

  test('after repeated failed starts the audio is handed over anyway', () async {
    await pump.prepare();
    output.streaming = false;
    output.restartWorks = false;
    pump.push(audio(1));
    pump.endTurn();
    for (var i = 0; i < 6; i++) {
      await pump.pumpOnce();
      advance(10);
    }
    expect(output.droppedByDevice, greaterThan(0),
        reason: 'a device that never confirms its state must still be offered the audio');
    expect(pump.pendingBytes, 0);
  });

  test('the stream is kept alive with silence between turns', () async {
    await pump.prepare();
    await playTurn(1);
    output.written.clear();

    advance(60);
    await pump.pumpOnce();
    expect(output.written, isNotEmpty, reason: 'idle feeding keeps the device in its playing state');
    expect(voiceIsSilence(output.written.last), isTrue);
    expect(pump.isSpeaking, isFalse);
  });

  test('audio is fed on a real-time budget, never dumped at the device', () async {
    await pump.prepare();
    final leadBytes = pump.lead.inMicroseconds * 24000 * 2 ~/ 1000000;

    pump.push(audio(200)); // several seconds of speech in one burst
    await pump.pumpOnce();
    expect(pump.bytesFed, lessThanOrEqualTo(leadBytes + _slice));
    expect(pump.pendingBytes, greaterThan(0), reason: 'the rest waits its turn');

    final before = pump.bytesFed;
    advance(100); // ~4800 bytes of playback
    await pump.pumpOnce();
    expect(pump.bytesFed, greaterThan(before));
    expect(pump.bytesFed - before, lessThanOrEqualTo(100 * 48 + _slice));
  });

  test('pushed chunks stay even so the PCM sink accepts them', () async {
    await pump.prepare();
    pump.push(Uint8List.fromList(List<int>.filled(_slice + 1, 0x7F)));
    expect(pump.pendingBytes, _slice);
    pump.endTurn();
    await pump.pumpOnce();
    expect(output.written.every((Uint8List slice) => slice.length.isEven), isTrue);
  });

  test('a dead device never holds the conversation hostage', () async {
    await pump.prepare();
    output.streaming = false;
    output.restartWorks = false;

    pump.push(audio(2));
    pump.endTurn();
    for (var i = 0; i < 6 && pump.isSpeaking; i++) {
      await pump.pumpOnce();
      advance(1000);
    }

    expect(pump.isSpeaking, isFalse);
    expect(pump.pendingBytes, 0);
    expect(events, contains('finished'), reason: 'the tutor must open the microphone again');
    expect(failures, isNotEmpty);
  });

  test('stop() releases the device and no further audio is accepted', () async {
    await pump.prepare();
    pump.push(audio(2));
    await pump.stop();
    expect(output.stopCalls, 1);
    final fed = pump.bytesFed;
    pump.push(audio(4));
    await pump.pumpOnce();
    expect(pump.bytesFed, fed);
    expect(pump.pendingBytes, 0);
  });
}
