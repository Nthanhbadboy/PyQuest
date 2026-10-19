import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Shared decoded [ui.Image] cache for 2.5D gameplay canvases
/// ([DragonPainter], [StarsPainter], [MazeBoardPainter]).
class SpriteCache {
  SpriteCache._();

  static final Map<String, ui.Image> _images = <String, ui.Image>{};
  static final Map<String, Future<ui.Image?>> _pending =
      <String, Future<ui.Image?>>{};

  /// Notifies canvas painters whenever a new 2.5D sprite finishes decoding.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static const List<String> kAll25dSprites = <String>[
    'assets/images/volcano_trail_r54.webp',
    'assets/images/pip_token_r54.png',
    'assets/images/basalt_token_r54.png',
    'assets/images/beetle_token_r54.png',
    'assets/images/observatory_sky_r55.webp',
    'assets/images/jar_token_r55.png',
    'assets/images/star_token_r55.png',
    'assets/images/meteor_token_r55.png',
    'assets/images/garden_stage_r50.webp',
    'assets/images/hedge_token_r50.png',
    'assets/images/robo_token_r50.png',
    'assets/images/py_token_r56.png',
    'assets/images/bitsy_token_r56.png',
    'assets/images/maze_trail_r45.webp',
    'assets/images/main_quest_r56.webp',
  ];

  /// Returns the decoded [ui.Image] if ready; otherwise triggers async load
  /// and returns null for the current frame.
  static ui.Image? get(String asset) {
    final ui.Image? cached = _images[asset];
    if (cached != null) return cached;
    unawaited(load(asset));
    return null;
  }

  static Future<ui.Image?> load(String asset) {
    final ui.Image? existing = _images[asset];
    if (existing != null) return Future<ui.Image?>.value(existing);
    return _pending.putIfAbsent(asset, () async {
      try {
        final ByteData data = await rootBundle.load(asset);
        final ui.Codec codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
        );
        final ui.FrameInfo frame = await codec.getNextFrame();
        _images[asset] = frame.image;
        revision.value++;
        return frame.image;
      } catch (_) {
        return null;
      }
    });
  }

  static Future<void> preloadAll() async {
    await Future.wait(kAll25dSprites.map(load));
  }
}
