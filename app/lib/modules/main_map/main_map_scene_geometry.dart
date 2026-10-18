import 'package:flutter/widgets.dart';

/// Geometry for the selected R1-A W01 static scene (853 × 1844 source pixels).
const Size kVillageSceneImageSize = Size(853, 1844);
const double kVillageMarkerWidthFraction = 0.32;
const double kVillageMinimumTargetSize = 48;

/// Registry IDs paired with their normalized DESIGN r53 visual anchors.
/// Anchors describe label centers, not collision rectangles in the artwork.
const Map<String, Offset> kVillageMarkerAnchors = <String, Offset>{
  'main_quest': Offset(0.48, 0.29),
  'robot_maze': Offset(0.23, 0.445),
  'dragon_jump': Offset(0.82, 0.33),
  'catch_stars': Offset(0.80, 0.515),
  'bug_hunter': Offset(0.22, 0.64),
  'achievement_house': Offset(0.80, 0.68),
};

/// Returns the image's full, uncropped height when it is displayed at [width].
double villageSceneHeight(double width) =>
    width * kVillageSceneImageSize.height / kVillageSceneImageSize.width;

/// Projects a normalized DESIGN anchor into the displayed scene rectangle.
Offset villageMarkerCenter(String activityId, Size sceneSize) {
  final Offset anchor = kVillageMarkerAnchors[activityId]!;
  return Offset(anchor.dx * sceneSize.width, anchor.dy * sceneSize.height);
}

/// The visible marker footprint, used by geometry tests (not inferred from art bounds).
Rect villageMarkerTargetRect(
  String activityId,
  Size sceneSize, {
  double height = kVillageMinimumTargetSize,
}) {
  final Offset center = villageMarkerCenter(activityId, sceneSize);
  final double width = sceneSize.width * kVillageMarkerWidthFraction;
  return Rect.fromCenter(center: center, width: width, height: height);
}
