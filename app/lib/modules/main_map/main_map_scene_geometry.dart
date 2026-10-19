import 'dart:math' as math;

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

/// One resolved village-label box plus the offset the layout had to declare to keep
/// it from covering a neighbour (`Offset.zero` means it sits exactly on its anchor).
typedef VillageMarkerPlacement = ({Rect rect, Offset declaredOffset});

/// Shared placement contract for the six village labels: production uses it in
/// `_VillageMarkerLayout`, and the rendered geometry tests recompute the same boxes
/// from the real child sizes. One contract, two consumers — a model test can no
/// longer pass while the painted boxes collide (that was finding A).
///
/// Rules, in order:
/// 1. centre each REAL content box on `villageMarkerCenter(id, sceneSize)`, clamped
///    into the scene, so nothing is clipped, ellipsised, font-shrunk or `scaleDown`ed;
/// 2. top-down sweep: a label is pushed down only past labels that actually share its
///    horizontal range, by the minimum distance that clears them plus [gap];
/// 3. if anything then hangs off the bottom, a bottom-up sweep pulls labels back in
///    and re-applies the separation from below, still on the y axis only;
/// 4. whatever y-shift the sweeps needed is reported as `declaredOffset` — the offset
///    is data the tests can see, not a silent fudge.
///
/// x never changes after step 1, so anchor-to-landmark identity is preserved and no
/// label is reassigned to another house. When a viewport genuinely cannot host the
/// content (labels taller than the art allows), the leftover overlap is left in place
/// for the tests to report instead of being hidden by shrinking the labels.
Map<String, VillageMarkerPlacement> villageMarkerPlacements({
  required Size sceneSize,
  required Map<String, Size> childSizes,
  required List<String> order,
  double gap = 4,
}) {
  double clampStart(double start, double maxStart) =>
      maxStart <= 0
      ? maxStart / 2
      : start.clamp(0.0, maxStart).toDouble();
  Size sizeOf(String id) => childSizes[id]!;

  final Map<String, double> left = <String, double>{};
  final Map<String, double> top = <String, double>{};
  for (final String id in order) {
    final Size size = sizeOf(id);
    final Offset center = villageMarkerCenter(id, sceneSize);
    left[id] = clampStart(
      center.dx - size.width / 2,
      sceneSize.width - size.width,
    );
    top[id] = clampStart(
      center.dy - size.height / 2,
      sceneSize.height - size.height,
    );
  }
  final Map<String, double> baseTop = Map<String, double>.of(top);

  bool sharesX(String a, String b) =>
      left[a]! < left[b]! + sizeOf(b).width &&
      left[b]! < left[a]! + sizeOf(a).width;
  int byTop(String a, String b) {
    final int byPosition = top[a]!.compareTo(top[b]!);
    return byPosition != 0
        ? byPosition
        : order.indexOf(a).compareTo(order.indexOf(b));
  }

  for (int sweep = 0; sweep <= order.length; sweep++) {
    bool moved = false;
    final List<String> descending = order.toList()..sort(byTop);
    for (int i = 0; i < descending.length; i++) {
      final String current = descending[i];
      for (final String previous in descending.take(i)) {
        if (!sharesX(previous, current)) continue;
        final double need =
            top[previous]! + sizeOf(previous).height + gap;
        if (top[current]! < need) {
          top[current] = need;
          moved = true;
        }
      }
    }
    double overflow = 0;
    for (final String id in order) {
      overflow = math.max(
        overflow,
        top[id]! + sizeOf(id).height - sceneSize.height,
      );
    }
    if (overflow > 0) {
      final List<String> fromBottom = order.toList()
        ..sort((String a, String b) {
          final int byBottom =
              (top[b]! + sizeOf(b).height).compareTo(
                top[a]! + sizeOf(a).height,
              );
          return byBottom != 0
              ? byBottom
              : order.indexOf(b).compareTo(order.indexOf(a));
        });
      for (int i = 0; i < fromBottom.length; i++) {
        final String current = fromBottom[i];
        if (top[current]! + sizeOf(current).height > sceneSize.height) {
          top[current] = math.max(
            0.0,
            sceneSize.height - sizeOf(current).height,
          );
          moved = true;
        }
        for (final String below in fromBottom.take(i)) {
          if (!sharesX(current, below)) continue;
          final double need =
              top[below]! - sizeOf(current).height - gap;
          if (top[current]! > need) {
            top[current] = math.max(0.0, need);
            moved = true;
          }
        }
      }
    }
    if (!moved) break;
  }

  return <String, VillageMarkerPlacement>{
    for (final String id in order)
      id: (
        rect: Rect.fromLTWH(
          left[id]!,
          top[id]!,
          sizeOf(id).width,
          sizeOf(id).height,
        ),
        declaredOffset: Offset(0, top[id]! - baseTop[id]!),
      ),
  };
}

/// The visible marker footprint, used by geometry MODEL tests (helper rectangles with
/// an assumed height; the rendered box proof lives in `main_map_scene_test.dart`).
Rect villageMarkerTargetRect(
  String activityId,
  Size sceneSize, {
  double height = kVillageMinimumTargetSize,
}) {
  final Offset center = villageMarkerCenter(activityId, sceneSize);
  final double width = sceneSize.width * kVillageMarkerWidthFraction;
  return Rect.fromCenter(center: center, width: width, height: height);
}
