# PQC-020 r2 — bounded static routing check

Chạy trên CODE `arena/4253d4f1-pyquest`, so workflow ở baseSHA `bed783cf9b7a327fe9766e96bd2e3020dc08ff82`
với bản làm việc. Công cụ: evaluator biểu thức Actions tự viết (chỉ `contains`/`!`/`==`/`&&`/`||`/ngoặc,
right-assoc, `||` và `&&` trả *giá trị* operand như Actions), đọc YAML bằng `yaml.safe_load`,
không gọi GitHub API, không chạy workflow. `ci/` không đổi; script này không được thêm vào repo.

sha256 baseline → working:

```
e7fed82d15849b75207dd1db6d56f74c9e7643446e0f09c8062fa379fc23359a  (baseline) pqc020-focused.yml
16b5d2bd007e7aaf0e19d70e49508a8543ccf745743f33e79e81a5159b290111  (working)    pqc020-focused.yml
f5c6106292beeb8122ea2415e4b46fb0270dfb26b32d7a4409b6094769c87ac9  (baseline) pqc011-maintenance.yml
9c726505319840a672c8d2d8be72aa71e3c5b2508342df7aba31931950738b86  (working)    pqc011-maintenance.yml
```

## Kết quả

| case | ref | event | markers | focused job | maintenance job | MAINTENANCE_PHASE |
|---|---|---|---|---|---|---|
| new branch, both 020+verify markers | arena/4253d4f1-pyquest | push | fix(x): real change [pqc020-check] [pqc011-verify] | run | run | verify |
| new branch, verify marker only | arena/4253d4f1-pyquest | push | fix(x): [pqc011-verify] | skip | skip | verify |
| new branch, 020 marker only | arena/4253d4f1-pyquest | push | fix(x): [pqc020-check] | skip | skip | normalize |
| new branch, diag marker mixed in | arena/4253d4f1-pyquest | push | fix(x): [pqc020-check] [pqc011-verify] [pqc011-diag] | skip | skip | diagnose |
| new branch, normalize marker mixed in | arena/4253d4f1-pyquest | push | fix(x): [pqc020-check] [pqc011-verify] [pqc011-normalize] | skip | skip | normalize |
| new branch, apk marker mixed in | arena/4253d4f1-pyquest | push | fix(x): [pqc020-check] [pqc011-verify] [apk] | skip | skip | verify |
| new branch, emulator marker mixed in | arena/4253d4f1-pyquest | push | fix(x): [pqc020-check] [pqc011-verify] [emulator] | skip | skip | verify |
| new branch, skip-ci marker mixed in | arena/4253d4f1-pyquest | push | fix(x): [pqc020-check] [pqc011-verify] [skip ci] | skip | skip | verify |
| new branch, workflow_dispatch | arena/4253d4f1-pyquest | workflow_dispatch | (none) | skip | skip | normalize |
| legacy branch, both markers | arena/0d4fcb38-pyquest | push | fix(x): [pqc020-check] [pqc011-verify] | run | run | verify |
| legacy branch, normalize only | arena/0d4fcb38-pyquest | push | chore(x): [pqc011-normalize] | skip | run | normalize |
| legacy branch, workflow_dispatch | arena/0d4fcb38-pyquest | workflow_dispatch | (none) | skip | run | normalize |
| other arena branch, both markers | arena/someone-else | push | fix(x): [pqc020-check] [pqc011-verify] | skip | skip | verify |
| other branch, workflow_dispatch | arena/someone-else | workflow_dispatch | (none) | skip | skip | normalize |

Check formatting on changed PQC-020 Dart files: ['--output=none --set-exit-if-changed', 'lib/modules/main_map/main_map_screen.dart', 'lib/modules/main_map/main_map_scene.dart', 'lib/modules/main_map/main_map_scene_geometry.dart', 'lib/modules/main_map/main_map_scene_state.dart', 'test/main_map_scene_test.dart', 'test/main_map_scene_geometry_test.dart', 'test/main_map_scene_route_test.dart', 'test/activity_sheet_thumbnails_test.dart', 'test/render/render_screens_test.dart', 'test/journey_widget_test.dart', 'test/lesson_route_regression_test.dart']
Run focused R1-A and existing map-geometry tests: ['--timeout 45s --reporter expanded', 'test/journey_widget_test.dart', 'test/main_map_scene_geometry_test.dart', 'test/main_map_scene_test.dart', 'test/main_map_scene_route_test.dart', 'test/activity_sheet_thumbnails_test.dart', 'test/lesson_route_regression_test.dart']
snapshot appended:    ['app/test/journey_widget_test.dart', 'app/test/lesson_route_regression_test.dart']

STATIC ROUTING CHECK: PASS — legacy clause verbatim, new branch verify-only, lists appended in order.
