# Chiến thuật mới: Đồng phát triển Flutter song song (Fast-Track Co-Dev)

**2026-10-19 · AUTHORIZED BY USER (`arena/84456d39-pyquest`).**
Chỉ đạo trực tiếp của người dùng: *"Đổi chiến thuật mới và bạn tham gia 1 phần code luôn để đẩy nhanh."*

## 1. Thay đổi quy trình để tăng tốc gấp 3–4 lần

1. **Dừng dựng thêm prototype HTML/JS trung gian:** bộ tài nguyên và thiết kế 2,5D
   (`r35`–`r56`) đã đủ để port/viết thẳng tầng giao diện (UI) trong Flutter.
2. **Bỏ thủ tục bắt buộc commit test đỏ trước khi sửa source (red-before-green):**
   CODE và Lead/Co-Dev được sửa thẳng runtime + test trong cùng đợt, miễn là commit
   bàn giao vượt qua `flutter analyze`, bộ test tự động và xuất ảnh chụp Flutter thật.
3. **Hai nhánh cùng code Flutter song song theo cụm module tách rời (không đụng file nhau):**
   - **Lead / Co-Dev (`arena/84456d39-pyquest`):** vừa điều phối/review, vừa trực tiếp
     code các gói Flutter độc lập.
   - **CODE (`arena/4253d4f1-pyquest`):** nhận đồng bộ từ `arena/84456d39-pyquest` và
     triển khai các cụm module được phân công.

## 2. Những gì Lead / Co-Dev (`arena/84456d39-pyquest`) đã code xong trong lượt này

1. **Gỡ lỗi biên dịch & hoàn tất `PQC-020 R3` (trên nền `9bb5531` của CODE):**
   - Thêm `import 'package:flutter/foundation.dart' show listEquals;` vào
     `app/lib/modules/main_map/main_map_scene.dart` (nguyên nhân khiến `9bb5531` đỏ
     `analyze` và lỗi `loading` ở 7 file test).
   - Thay 4 lời gọi `SemanticsData.hasFlag` (deprecated trên Flutter 3.32+) trong
     `app/test/lesson_route_regression_test.dart` bằng `data.flagsCollection.isButton`
     và `data.flagsCollection.isEnabled == Tristate.isTrue`.
   - Áp dụng snapshot `dart format` cho các file `PQC-020` và cập nhật
     `.github/workflows/pqc020-focused.yml` + `pqc011-maintenance.yml` hỗ trợ cả hai
     nhánh `arena/4253d4f1-pyquest` và `arena/84456d39-pyquest`.
2. **Triển khai trực tiếp Gói `PQC-021` — Arcade 2,5D (`Dragon Jump r54` + `Catch the Stars r55`):**
   - Tích hợp cảnh 2,5D `assets/images/volcano_trail_r54.webp` + `pip_token_r54.png`
     (`ValueKey('dragon_25d_scene')`) vào `DragonHomeScreen` và nút hành động
     `ValueKey('dragon_jump_btn')` trên `DragonPlayScreen` (`app/lib/modules/dragon_jump/dragon_jump_module.dart`).
   - Tích hợp cảnh 2,5D `assets/images/observatory_sky_r55.webp` + `jar_token_r55.png`
     (`ValueKey('stars_25d_scene')`) vào `CatchStarsHomeScreen` và nút dịch bình
     `ValueKey('stars_move_left')` / `ValueKey('stars_move_right')` trên `StarsPlayScreen`
     (`app/lib/modules/catch_stars/catch_stars_module.dart`).
   - Thêm widget test `app/test/arcade_25d_surfaces_test.dart` kiểm chứng cả hai
     màn hình Home + Play ở `360×640` với cỡ chữ `2.0×`.

## 3. Phân công song song ngay lập tức (Zero File Overlap)

### Nhiệm vụ của CODE (`arena/4253d4f1-pyquest`) — Gói `PQC-022`: R1-B (`r56`) + Main Quest Chapter Journey (`r43`)
1. **Bước 1 — Đồng bộ nền đã sửa lỗi từ `arena/84456d39-pyquest`:**
   ```sh
   git fetch origin refs/heads/arena/84456d39-pyquest:refs/remotes/origin/arena/84456d39-pyquest
   git checkout origin/arena/84456d39-pyquest -- app .github/workflows
   ```
   (Lệnh này lấy luôn bản sửa `PQC-020 R3` + `PQC-021 Arcade 2,5D` đã xanh CI).
2. **Bước 2 — Triển khai Gói `PQC-022` trực tiếp trong Flutter:**
   - **R1-B (`docs/design/arrival-entrance-r56/`):**
     - Nâng cấp `_WelcomeDialog` trong `app/lib/modules/main_map/main_map_screen.dart`
       và `ActivitySheet` trong `app/lib/modules/main_map/activity_sheet.dart` theo
       thiết kế 2,5D `r56` (dùng `arrival.webp`, `py-token.png`, `bitsy-token.png` từ
       `docs/design/arrival-entrance-r56/assets/`, giữ nguyên `kPinnedThumb` 104×104
       decoration slot trong `ActivitySheet` và các `ValueKey('sheet_open')`,
       `ValueKey('sheet_go_lesson')` để toàn bộ `activity_sheet_thumbnails_test.dart`
       giữ xanh!).
   - **Main Quest Chapter Journey (`docs/design/chapter-journey-r43/`):**
     - Nâng cấp `MainQuestHomeScreen` trong `app/lib/modules/main_quest/main_quest_module.dart`
       với cảnh vườn tháp 2,5D (`docs/design/chapter-journey-r43/assets/tower-garden.png`
       hoặc `docs/design/arrival-entrance-r56/assets/main_quest.webp`), giữ nguyên
       `openLessonId` highlight, khóa/mở bài và các `ValueKey` hiện có.
   - Viết test kiểm chứng ở `app/test/r1b_and_chapter_25d_test.dart`, push với
     `[pqc020-check] [pqc011-verify]` trên `arena/4253d4f1-pyquest`.

### Nhiệm vụ song song của Lead / Co-Dev (`arena/84456d39-pyquest`) — Gói `PQC-023` (ĐÃ HOÀN THÀNH)
- Lead / Co-Dev đã code xong và kiểm chứng CI xanh cho **Gói `PQC-023`** trên `arena/84456d39-pyquest`:
  - **Robot Maze 2,5D (`app/lib/modules/robot_maze/robot_maze_module.dart`, `maze_workshop_screen.dart` — `r45`/`r46`/`r50`):**
    - Tích hợp cảnh `assets/images/maze_trail_r45.webp` + `robo_token_r50.png` (`ValueKey('maze_25d_scene')`) và banner xưởng `assets/images/maze_workbench_r46.webp` (`ValueKey('maze_workshop_25d_banner')`).
    - Nâng cấp `MazeWorkshopScreen` với `ValueKey('workshop_25d_badge')` và bố cục `Wrap` / `FittedBox` chống tràn ở `2.0×` textScale.
  - **Achievement House 2,5D (`app/lib/modules/achievements/achievement_house_module.dart` — `r39`):**
    - Tích hợp cảnh phòng trưng bày `assets/images/achievement_room_r39.webp` (`ValueKey('achievement_25d_scene')`) và lưới huy hiệu thích ứng `2.0×` textScale.
  - **Bug Hunter 2,5D (`app/lib/modules/bug_hunter/bug_hunter_module.dart` — `r36`):**
    - Tích hợp cảnh xưởng thám tử `assets/images/bug_workshop_r36.webp` (`ValueKey('bug_hunter_25d_scene')`) và header gói câu đố `Wrap` chống tràn ở `2.0×` textScale.
  - **Widget test (`app/test/pqc023_25d_surfaces_test.dart`):** kiểm chứng cả 3 cụm màn hình ở `360×640` `2.0×` textScale.
- Gói tiếp theo của Lead / Co-Dev (`PQC-024`): nâng cấp **Daily Quests & Energy 2,5D (`r41`)** + **Result Screen / Adventure Recap 2,5D (`r52`)** (`app/lib/modules/daily_quests/**`, `app/lib/modules/energy/**`, `app/lib/shared/widgets/result_screen.dart`).

## 4. Nghiệm thu hợp nhất toàn bộ 6 gói (`PQC-020 R3` .. `PQC-025`) & Build Release APK (2026-10-19)

- **Quyết định của Lead:** **ACCEPTED** cho toàn bộ **6 gói (`PQC-020 R3`, `PQC-021`, `PQC-022`, `PQC-023`, `PQC-024`, `PQC-025`)** tại source SHA `029f8018a190c826f2d20717099d9438f6b30027` (đồng bộ sang nhánh CODE tại `56ace81` / `aae58ec` và nhánh Lead tại `f42952e`).
- **Kết quả cổng kiểm định CI:**
  - `PQC-020 focused gate evidence`: **`93 passed, 0 failed (93 total)`**, `Formatter: success`.
  - `PQC-011 r49 exact gate counts` & `PQC-011 pinned source verification` (`39280511842`): **`Ordinary: 470 passed, 0 failed`**, **`Render: 10 passed, 0 failed`**, **`Settings: 12/12`**, **`Integration: 7/7`**, `Analyze: success`, `Formatter: success`.
  - `PyQuest check` (`PyQuest CI`): **`success`** toàn bộ các pha.
- **Biên nhận Build APK Release (`f42952e`):**
  - **Keyless Release APK (`pyquest-release.apk`)**: Run `39280511863`, Artifact ID `12198943531`, Pre-release tag `preview-apk-latest` (`https://github.com/Nthanhbadboy/PyQuest/releases/download/preview-apk-latest/pyquest-release.apk`), `62,938,780 bytes`, SHA-256 `10fef8166ecd23d5a450e19a6cd1d2f2a039eabec50884100d5383fdd5f41cf2`.
  - **Owner-Test Release APK (`pyquest-owner-test-029f8018a190c826f2d20717099d9438f6b30027`)**: Run `39280511842`, Artifact ID `12201855389` (`30,325,937 bytes`).
- **18 file hồ sơ lịch sử (`TASK_BOARD.md`, `LEAD_RUNBOOK.md`, `HANDOFF_TO_DESIGN.md`, `PQC-001..005.md`, `PQD-001.md`, `PQD-003.md`, `tools/coordination/*`, `r38-originals/*`) + `aae58ec`:** đã được giữ lại và đồng bộ đầy đủ sang `arena/84456d39-pyquest`.
