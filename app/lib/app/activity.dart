import 'package:flutter/widgets.dart';

import '../shared/characters/characters.dart';
import '../shared/theme/palette.dart';
import 'app_services.dart';

/// Static description of a place on the Main Map.
class ActivityDef {
  const ActivityDef({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.host,
    required this.hitBox,
    required this.labelAnchor,
    required this.thumbnail,
    required this.tone,
    required this.needsPython,
    this.hasCreatorMode = false,
  });

  final String id;
  final String name;
  final String tagline;
  final String description;
  final CharacterId host;

  /// Tappable landmark area, normalised to the map image (0..1).
  final Rect hitBox;

  /// Where the name plate hangs, normalised to the map image.
  final Offset labelAnchor;
  final String thumbnail;
  final PQTone tone;
  final bool needsPython;
  final bool hasCreatorMode;
}

/// Live state of an activity, computed from saved progress.
class ActivityStatus {
  const ActivityStatus({
    required this.progressLabel,
    this.stars,
    this.locked = false,
    this.lockReason,
    this.unlockLessonId,
    this.recommended = false,
    this.detailLines = const [],
  });

  final String progressLabel;
  final int? stars;
  final bool locked;
  final String? lockReason;

  /// Main Quest lesson that opens this activity (for the "go to lesson" button).
  final String? unlockLessonId;

  /// Pulses on the map to guide new players.
  final bool recommended;
  final List<String> detailLines;
}

/// Every game / branch plugs into the island through this interface. Adding
/// a new game = a new module folder + one entry in the activity registry;
/// the platform (map, energy, events, achievements) stays untouched.
abstract class ActivityModule {
  ActivityDef get def;

  Future<ActivityStatus> status(AppServices services);

  /// The activity's own home screen (its loop, rules and progress).
  Widget buildHome(BuildContext context);
}
