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

    test(
      'placements: projected centre is kept whenever the real boxes already fit',
      () {
        for (final double width in <double>[360, 390]) {
          final Size scene = Size(width, villageSceneHeight(width));
          for (final double height in <double>[48, 58, 76]) {
            final Map<String, Size> sizes = <String, Size>{
              for (final String id in kVillageMarkerAnchors.keys)
                id: Size(scene.width * kVillageMarkerWidthFraction, height),
            };
            final Map<String, VillageMarkerPlacement> placed =
                villageMarkerPlacements(
                  sceneSize: scene,
                  childSizes: sizes,
                  order: kVillageMarkerAnchors.keys.toList(growable: false),
                );
            for (final String id in sizes.keys) {
              expect(
                placed[id]!.declaredOffset,
                Offset.zero,
                reason: '$id ở $width/$height: không có va chạm nào phải sửa',
              );
              expect(
                (placed[id]!.rect.center - villageMarkerCenter(id, scene))
                    .distance,
                lessThan(1e-6),
                reason: '$id phải có tâm đúng bằng projection ở $width/$height',
              );
            }
          }
        }
      },
    );

    test(
      'placements: tránh va chạm chỉ bằng lệch Y, luôn trong scene, không bao giờ dời nhãn sang nhà khác',
      () {
        for (final double width in <double>[360, 390]) {
          final Size scene = Size(width, villageSceneHeight(width));
          for (double height = 48; height <= 200; height += 8) {
            final Map<String, Size> sizes = <String, Size>{
              for (final String id in kVillageMarkerAnchors.keys)
                id: Size(scene.width * kVillageMarkerWidthFraction, height),
            };
            final List<String> ids = kVillageMarkerAnchors.keys.toList(
              growable: false,
            );
            final Map<String, VillageMarkerPlacement> placed =
                villageMarkerPlacements(
                  sceneSize: scene,
                  childSizes: sizes,
                  order: ids,
                );
            for (final String id in ids) {
              final Rect rect = placed[id]!.rect;
              expect(
                placed[id]!.declaredOffset.dx,
                0,
                reason: 'lệch ngang là đổi nhà, height=$height width=$width',
              );
              // Rect.contains loại trừ cạnh phải/đáy nên nhãn áp sát mép vẫn hợp lệ.
              expect(
                rect.left >= -1e-6 &&
                    rect.top >= -1e-6 &&
                    rect.right <= scene.width + 1e-6 &&
                    rect.bottom <= scene.height + 1e-6,
                isTrue,
                reason: '$id bị đẩy ra ngoài scene ở height=$height',
              );
              expect(
                rect.width,
                greaterThanOrEqualTo(kVillageMinimumTargetSize),
                reason: '$id mất kích thước tối ở height=$height',
              );
            }
            for (int i = 0; i < ids.length; i++) {
              for (int j = i + 1; j < ids.length; j++) {
                expect(
                  placed[ids[i]]!.rect.overlaps(placed[ids[j]]!.rect),
                  isFalse,
                  reason:
                      '${ids[i]} chồng ${ids[j]} ở $width, height=$height — '
                      'đây là vùng thực tế của 1x tới 2x, không được phép đè nhau',
                );
              }
            }
          }
        }
      },
    );
  });
}
