// PQC-020 R3: file này là MODEL test — nó kiểm công thức projection và các hình chữ
// nhật mà helper tự sinh với chiều cao giả định (48/96). Nó KHÔNG chứng minh hộp thật
// của nút trên màn hình: đúng vì đó là lỗ hổng mà finding A rơi qua, nơi `Align` đặt
// nhãn theo khoảng trống còn lại nên "Núi Lửa" đè "Tháp Python" dù mọi phép tính model
// đều xanh. Bằng chứng RenderBox thật nằm ở `main_map_scene_test.dart` (R3-GEOM).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/app/activity_registry.dart';
import 'package:pyquest/modules/main_map/main_map_scene_geometry.dart';

void main() {
  group('R1-A W01 geometry model (helper rectangles, not RenderBox)', () {
    test('anchors cover exactly the six existing registry IDs', () {
      expect(
        kVillageMarkerAnchors.keys.toSet(),
        activityRegistry.map((module) => module.def.id).toSet(),
      );
      expect(activityRegistry, hasLength(6));
    });

    test(
      'scene retains the complete asset aspect ratio at both target widths',
      () {
        for (final double width in <double>[360, 390]) {
          final double height = villageSceneHeight(width);
          expect(height / width, closeTo(1844 / 853, 1e-9));
          expect(height, greaterThan(640));
        }
      },
    );

    test(
      'model: six helper target rectangles fit inside the scrollable art',
      () {
        for (final double width in <double>[360, 390]) {
          final Size scene = Size(width, villageSceneHeight(width));
          for (final String id in kVillageMarkerAnchors.keys) {
            final Rect target = villageMarkerTargetRect(id, scene);
            expect(
              target.width,
              greaterThanOrEqualTo(kVillageMinimumTargetSize),
            );
            expect(
              target.height,
              greaterThanOrEqualTo(kVillageMinimumTargetSize),
            );
            expect(
              target.left,
              greaterThanOrEqualTo(0),
              reason: '$id left edge',
            );
            expect(target.top, greaterThanOrEqualTo(0), reason: '$id top edge');
            expect(
              target.right,
              lessThanOrEqualTo(scene.width),
              reason: '$id right edge',
            );
            expect(
              target.bottom,
              lessThanOrEqualTo(scene.height),
              reason: '$id bottom edge',
            );
          }
        }
      },
    );

    test('model: helper rectangles do not overlap at 360 or 390 px', () {
      for (final double width in <double>[360, 390]) {
        final Size scene = Size(width, villageSceneHeight(width));
        final List<String> ids = kVillageMarkerAnchors.keys.toList(
          growable: false,
        );
        for (int i = 0; i < ids.length; i++) {
          for (int j = i + 1; j < ids.length; j++) {
            expect(
              villageMarkerTargetRect(
                ids[i],
                scene,
                height: 96,
              ).overlaps(villageMarkerTargetRect(ids[j], scene, height: 96)),
              isFalse,
              reason: '${ids[i]} overlaps ${ids[j]} at width $width',
            );
          }
        }
      }
    });
  });
}
