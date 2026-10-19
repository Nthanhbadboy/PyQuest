# Custom report117450223454 @a9bcdcf

| phase key | exit |
|---|---|
| flutter_version | 0 |
| pub_get | 0 |
| l10n_evidence_tests | 0 |
| l10n_evidence | 0 |
| analyze | 0 |
| settings_test | 0 |
| ordinary_tests | 0 |
| render_tests | 0 |
| l10n_evidence_publish | 0 |

| workflow step | outcome |
|---|---|
| Flutter version | success |
| Dependencies | success |
| Localization evidence tests | success |
| Localization evidence collection | success |
| Flutter analyze | success |
| Focused Settings test | success |
| Ordinary tests | success |
| Render tests | success |
| Evidence publication | success |
| Preview publication | success |

### settings_test.txt
```
00:00 +0: loading /home/runner/work/PyQuest/PyQuest/app/test/l10n/settings_sheet_localization_test.dart
00:00 +0: (setUpAll)
00:00 +0: real Settings sheet follows Vietnamese system locale without storing the resolved language
00:01 +1: real Settings sheet follows unsupported system locale without storing the resolved language
00:01 +2: UI choices apply immediately and preserve the open route, toggles, and progress
00:02 +3: a failed locale write stays selected and Retry reflects the real database result
00:02 +4: the real Settings chooser persists EN across an AppServices and PyQuestApp restart
00:03 +5: overlapping UI saves keep the latest request authoritative and survive sheet disposal
00:03 +6: Python information and parent gate localize live without losing the gate input
00:04 +7: Settings fits 360x640 VI at text scale 1.0
00:05 +8: Settings fits 360x640 EN at text scale 1.0
00:05 +9: Settings fits 390x844 VI at text scale 1.0
00:05 +10: Settings fits 390x844 EN at text scale 1.0
00:05 +11: uncapped scale 2.0 keeps radio choices and Retry reachable on a short screen
00:05 +12: (tearDownAll)
00:05 +12: All tests passed!

```

---

### flutter_version.txt
```
Flutter 3.47.7 • channel stable • https://github.com/flutter/flutter.git
Framework • revision abaf9c5237 (9 days ago) • 2026-10-08 09:51:21 -0700
Engine • hash d8a2d6c768c334d53e16277f837970ffa1e2de81 (revision deb287481e) (10 days ago) • 2026-10-07 17:09:12.000Z
Tools • Dart 3.13.5 • DevTools 2.60.0

```

---

### pub_get.txt
```
Resolving dependencies...
Downloading packages...
  code_assets 1.2.1 (2.1.0 available)
+ flutter_sound 9.30.0
+ flutter_sound_platform_interface 9.30.0 (10.3.8 available)
+ flutter_sound_web 9.30.0 (10.3.8 available)
  hooks 2.0.2 (2.2.0 available)
+ logger 2.8.0
  material_color_utilities 0.13.0 (0.13.1 available)
  meta 1.18.3 (1.19.0 available)
  native_toolchain_c 0.19.2 (0.19.5 available)
  objective_c 9.5.0 (9.6.2 available)
+ record 6.2.1 (7.1.2 available)
+ record_android 1.5.2 (2.2.0 available)
+ record_ios 1.2.1 (2.1.1 available)
+ record_linux 1.3.1 (2.1.3 available)
+ record_macos 1.2.2 (2.1.1 available)
+ record_platform_interface 1.6.0 (2.1.0 available)
  record_use 0.6.0 (1.1.1 available)
+ record_web 1.3.0 (2.1.3 available)
+ record_windows 1.0.7 (2.3.0 available)
  sqlite3 3.5.2 (3.7.1 available)
  test_api 0.7.12 (0.7.15 available)
  vector_math 2.4.0 (2.4.3 available)
  vm_service 15.3.0 (15.4.0 available)
+ web_socket 1.0.1
+ web_socket_channel 3.0.3
Changed 14 dependencies!
21 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.

```

---

### l10n_evidence_tests.txt
```
test_collect_captures_every_file_and_compares_twice_to_head (__main__.EvidenceChannelTests.test_collect_captures_every_file_and_compares_twice_to_head) ... ok
test_detects_untracked_name_and_byte_drift (__main__.EvidenceChannelTests.test_detects_untracked_name_and_byte_drift) ... ok
test_failed_generators_are_not_reported_as_success (__main__.EvidenceChannelTests.test_failed_generators_are_not_reported_as_success) ... ok
test_preexisting_untracked_output_is_recorded_before_safe_cleanup (__main__.EvidenceChannelTests.test_preexisting_untracked_output_is_recorded_before_safe_cleanup) ... ok
test_publish_failure_propagates (__main__.EvidenceChannelTests.test_publish_failure_propagates) ... ok
test_rejects_oversize_envelope_instead_of_truncating (__main__.EvidenceChannelTests.test_rejects_oversize_envelope_instead_of_truncating) ... ok
test_rejects_unsafe_paths_and_symlinks (__main__.EvidenceChannelTests.test_rejects_unsafe_paths_and_symlinks) ... ok
test_round_trip_preserves_sources_and_hashes (__main__.EvidenceChannelTests.test_round_trip_preserves_sources_and_hashes) ... ok

----------------------------------------------------------------------
Ran 8 tests in 0.008s

OK

```

---

### l10n_evidence_collect.txt
```
collected localization evidence: PASS -> ../l10n_evidence.json

```

---

### analyze.txt
```
Analyzing app...
No issues found! (ran in 11.5s)

```

---

### test.txt
```
00:00 +0: loading /home/runner/work/PyQuest/PyQuest/app/test/journey_widget_test.dart
00:00 +0: /home/runner/work/PyQuest/PyQuest/app/test/tutor_voice_pump_test.dart: a whole spoken turn reaches the device and reports its boundaries
00:00 +1: /home/runner/work/PyQuest/PyQuest/app/test/journey_widget_test.dart: (setUpAll)
00:00 +1: /home/runner/work/PyQuest/PyQuest/app/test/tutor_voice_pump_test.dart: turn 2 still plays after the device left its playing state
00:00 +2: /home/runner/work/PyQuest/PyQuest/app/test/journey_widget_test.dart: new player: map → Robot Maze level 1 solved → result → progress saved
00:00 +3: /home/runner/work/PyQuest/PyQuest/app/test/journey_widget_test.dart: new player: map → Robot Maze level 1 solved → result → progress saved
00:00 +4: /home/runner/work/PyQuest/PyQuest/app/test/journey_widget_test.dart: new player: map → Robot Maze level 1 solv

... [trimmed] ...

/home/runner/work/PyQuest/PyQuest/app/test/activity_sheet_thumbnails_test.dart: route thật của sheet (showPQSheet) — CTA phải cuộn tới được và trả đúng nhánh Bug Hunter khoá: CTA "đi tới bài học" dùng lesson id THẬT từ data
00:41 +400: /home/runner/work/PyQuest/PyQuest/app/test/activity_sheet_thumbnails_test.dart: vùng chạm của landmark trên đảo (toán hitBox, không cần pump) mọi hitBox còn >= 48px ở 360x640 sau phép cover của map
00:41 +401: /home/runner/work/PyQuest/PyQuest/app/test/activity_sheet_thumbnails_test.dart: ngân sách + cache của bộ thumbnail (precache qua ImageProvider thật) sáu key Asset resolve + decode từng cái một, rồi mới nhìn cache
PQC-009 imageCache precache: entries=6 bytes=1990656 (cache của engine trên máy CI, không phải RAM/GPU thiết bị)
00:41 +402: /home/runner/work/PyQuest/PyQuest/app/test/activity_sheet_thumbnails_test.dart: kích thước chạm đo từ RenderBox thật (characterization cho PQC-008) ChunkyButton.small = mặt 44 + depth 4 theo chiều dọc; textScale 2 không làm nhỏ hơn
00:41 +403: /home/runner/work/PyQuest/PyQuest/app/test/activity_sheet_thumbnails_test.dart: kích thước chạm đo từ RenderBox thật (characterization cho PQC-008) RoundIconButton(size:44) là trường hợp khác: rộng 44, depth cộng theo chiều dọc
00:41 +404: /home/runner/work/PyQuest/PyQuest/app/test/activity_sheet_thumbnails_test.dart: bằng chứng tiêu cực bytes hỏng bị phát hiện, không im lặng vẽ ô trống
00:41 +405: /home/runner/work/PyQuest/PyQuest/app/test/activity_sheet_thumbnails_test.dart: bằng chứng tiêu cực asset thumbnail thật không được có bytes ngắn bất thường
00:41 +406: /home/runner/work/PyQuest/PyQuest/app/test/activity_sheet_thumbnails_test.dart: (tearDownAll)
00:41 +406: All tests passed!

```

---

### render.txt
```
00:00 +0: loading /home/runner/work/PyQuest/PyQuest/app/test/render/render_screens_test.dart
00:00 +0: (setUpAll)
00:00 +0: render A: first launch
00:02 +1: render B: robot maze
00:05 +2: render C: lesson flow
00:07 +3: render D: arcade games
00:09 +4: render E: house, bugs, sheets, playground
00:11 +5: render F: small phone 360x640
00:12 +6: render G: cast gallery
00:12 +7: render H: tutor panel, offline build
00:13 +8: render I: tutor panel with an AI answer (static preview provider)
00:14 +9: render J: activity sheet before-set (six + locked)
PQC-009 imageCache khi mở lần lượt sáu sheet (cache của engine trên máy CI, KHÔNG phải RAM/GPU thiết bị): j00=7entries/11501568B -> j01=7entries/11501568B -> j02=7entries/11501568B -> j03=7entries/11501568B -> j04=7entries/11501568B -> j05=7entries/11501568B
00:18 +10: (tearDownAll)
00:18 +10: All tests passed!

```

---

### l10n_evidence_publish.txt
```
published localization evidence check for a9bcdcf8e3203ee17b1a5de0b9ebff6a0e8dd32d: PASS

```

---

### previews.txt
```
a00_welcome.png 2 chunk(s)
a01_map_new_player.png 4 chunk(s)
a02_sheet_locked.png 2 chunk(s)
b00_map_progress.png 4 chunk(s)
b01_sheet_maze.png 2 chunk(s)
b02_maze_home.png 2 chunk(s)
b03_maze_program_python.png 2 chunk(s)
b04_maze_result.png 2 chunk(s)
b05_maze_fail.png 2 chunk(s)
b06_workshop.png 2 chunk(s)
b07_workshop_code.png 2 chunk(s)
b08_workshop_verified.png 2 chunk(s)
board-mq1_01_s2-b1-code-highlight-390x844-font1.0-en.png 1 chunk(s)
board-mq1_01_s2-b1-code-highlight-390x844-font1.0-vi.png 1 chunk(s)
board-mq1_01_s2-b1-code-highlight-390x844-font2.0-en.png 2 chunk(s)
board-mq1_01_s2-b1-code-highlight-390x844-font2.0-vi.png 2 chunk(s)
board-mq1_01_s2-b2-quote-tokens-390x844-font1.0-en.png 1 chunk(s)
board-mq1_01_s2-b2-quote-tokens-390x844-font1.0-vi.png 1 chunk(s)
board-mq1_01_s2-b2-quote-tokens-390x844-font2.0-en.png 2 chunk(s)
board-mq1_01_s2-b2-quote-token

... [trimmed] ...

ape-wait-390x844-font1.0-en.png 1 chunk(s)
board-mq1_03_s2-b4-shape-wait-390x844-font1.0-vi.png 1 chunk(s)
board-mq1_03_s2-b4-shape-wait-390x844-font2.0-en.png 2 chunk(s)
board-mq1_03_s2-b4-shape-wait-390x844-font2.0-vi.png 2 chunk(s)
c00_tower_new.png 2 chunk(s)
c01_lesson_story.png 1 chunk(s)
c02_lesson_example.png 2 chunk(s)
c03_lesson_choice_wrong.png 2 chunk(s)
c04_lesson_fill_correct.png 2 chunk(s)
c05_lesson_code_error.png 2 chunk(s)
c06_lesson_code_ok.png 2 chunk(s)
c07_lesson_complete.png 2 chunk(s)
d00_dragon_home.png 2 chunk(s)
d01_dragon_shop.png 3 chunk(s)
d02_dragon_play.png 1 chunk(s)
d03_dragon_result.png 2 chunk(s)
d04_stars_home.png 2 chunk(s)
d05_star_atlas.png 1 chunk(s)
d06_stars_play.png 1 chunk(s)
e00_energy_sheet.png 2 chunk(s)
e01_daily_quests.png 2 chunk(s)
e02_settings.png 2 chunk(s)
e03_house_badges.png 2 chunk(s)
e04_house_wall.png 1 chunk(s)
e05_bug_home.png 2 chunk(s)
e06_bug_puzzle_run.png 2 chunk(s)
e07_bug_fix_picker.png 2 chunk(s)
e08_playground.png 2 chunk(s)
f00_small_map.png 3 chunk(s)
f01_small_maze.png 2 chunk(s)
f02_small_lesson.png 2 chunk(s)
f03_small_dragon_home.png 2 chunk(s)
g00_cast_gallery.png 2 chunk(s)
h00_tutor_offline_open.png 2 chunk(s)
h01_tutor_offline_answer.png 2 chunk(s)
h02_tutor_hint_ladder.png 2 chunk(s)
i00_tutor_ai_answer.png 2 chunk(s)
i01_lesson_with_tutor_button.png 1 chunk(s)
j00_sheet_main_quest.png 2 chunk(s)
j01_sheet_robot_maze.png 2 chunk(s)
j02_sheet_dragon_jump.png 2 chunk(s)
j03_sheet_catch_stars.png 2 chunk(s)
j04_sheet_bug_hunter.png 2 chunk(s)
j05_sheet_achievement_house.png 2 chunk(s)
j06_sheet_bug_hunter_locked.png 2 chunk(s)
j07_small_sheet_robot_maze.png 2 chunk(s)
j08_small_sheet_bug_hunter_locked.png 2 chunk(s)

```
