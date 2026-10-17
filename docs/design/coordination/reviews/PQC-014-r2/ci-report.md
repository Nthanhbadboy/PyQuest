# Custom report 117307744269 @ 4751f11

| phase key | exit |
|---|---|
| pub_get | 0 |
| analyze | 0 |
| test | 0 |
| render | 0 |
### flutter_version.txt
```
Flutter 3.47.7 • channel stable • https://github.com/flutter/flutter.git
Framework • revision abaf9c5237 (8 days ago) • 2026-10-08 09:51:21 -0700
Engine • hash d8a2d6c768c334d53e16277f837970ffa1e2de81 (revision deb287481e) (9 days ago) • 2026-10-07 17:09:12.000Z
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
/home/runner/work/PyQuest/PyQuest/app/l10n.yaml: The argument "synthetic-package" no longer has any effect and should be removed. See http://flutter.dev/to/flutter-gen-deprecation

```

---

### analyze.txt
```
Analyzing app...
No issues found! (ran in 12.5s)

```

---

### test.txt
```
00:00 +0: loading /home/runner/work/PyQuest/PyQuest/app/test/journey_widget_test.dart
00:00 +0: /home/runner/work/PyQuest/PyQuest/app/test/journey_widget_test.dart: (setUpAll)
00:00 +0: /home/runner/work/PyQuest/PyQuest/app/test/journey_widget_test.dart: new player: map → Robot Maze level 1 solved → result → progress saved
00:03 +1: /home/runner/work/PyQuest/PyQuest/app/test/journey_widget_test.dart: Main Quest lesson 1 can be completed with real code
00:05 +2: /home/runner/work/PyQuest/PyQuest/app/test/journey_widget_test.dart: (tearDownAll)
00:05 +2: loading /home/runner/work/PyQuest/PyQuest/app/test/tutor_voice_pump_test.dart
00:06 +2: /home/runner/work/PyQuest/PyQuest/app/test/tutor_voice_pump_test.dart: a whole spoken turn reaches the device and reports its boundaries
00:06 +3: /home/runner/work/PyQuest/PyQuest/app/test/tutor_voice_pump_test.dart: turn 2 still plays after the device left its playing state
00:06 +4: /home/runner/work/PyQuest/PyQuest/app/test/tutor_voice_pump_test.dart: a write that never returns cannot silence the rest of the session
00:06 +5: /home/runner/work/PyQuest/PyQuest/app/test/tutor_voice_pump_test.dart: a device that cannot be restarted keeps the audio and says so
00:06 +6: /home/runner/work/PyQuest/PyQuest/app/test/tutor_voice_pump_test.dart: interruption drops what was not fed and keeps the session usable
00:06 +7: /home/runner/work/PyQuest/PyQuest/app/test/tutor_voice_pump_test.dart: after repeated failed starts the audio is handed over anyway
00:06 +8: /home/runner/work/PyQuest/PyQuest/app/test/tutor_voice_pump_test.dart: the stream is kept alive with silence between turns
00:06

... [trimmed] ...

e] recv #2 userText=22ch
[PyQuestVoice] dropped a 5-word transcription as playback echo (count=1) — not shown as the child’s line
01:04 +370: /home/runner/work/PyQuest/PyQuest/app/test/tutor_voice_session_test.dart: the tutor must not hear itself what the child really says is still shown after the answer played out
[PyQuestVoice] recv #1 audio=1920B aiText=22ch turnComplete
[PyQuestVoice] server audio chunks=1 bytes=1920 queued=0
[PyQuestVoice] server turnComplete audioBytes=1920 pumpFed=0 pumpDropped=0
[PyQuestVoice] playback started bytes=0
[PyQuestVoice] microphone reopened (turn played out)
[PyQuestVoice] recv #2 userText=8ch
01:06 +371: /home/runner/work/PyQuest/PyQuest/app/test/tutor_voice_session_test.dart: the tutor must not hear itself an interruption clears the speech that has not been played but keeps the sentence
[PyQuestVoice] recv #1 aiText=15ch
[PyQuestVoice] recv #2 audio=5760B
[PyQuestVoice] server audio chunks=1 bytes=5760 queued=0
[PyQuestVoice] recv #3 interrupted
[PyQuestVoice] server interrupted=true; queued audio dropped, assistant text kept
[PyQuestVoice] pump: interrupted: queued audio dropped
01:06 +372: /home/runner/work/PyQuest/PyQuest/app/test/tutor_voice_session_test.dart: session state the tutor speaks, then listens again — the microphone is not left open
[PyQuestVoice] recv #1 audio=1920B turnComplete
[PyQuestVoice] server audio chunks=1 bytes=1920 queued=0
[PyQuestVoice] server turnComplete audioBytes=1920 pumpFed=0 pumpDropped=0
[PyQuestVoice] playback started bytes=0
[PyQuestVoice] microphone reopened (turn played out)
01:07 +373: /home/runner/work/PyQuest/PyQuest/app/test/tutor_voice_session_test.dart: session state a session that is about to close leaves a readable conversation
[PyQuestVoice] recv #1 aiText=16ch
[PyQuestVoice] recv #2 userText=12ch
[PyQuestVoice] recv #3 goAway=0s
[PyQuestVoice] server goAway in 0s
01:07 +374: /home/runner/work/PyQuest/PyQuest/app/test/tutor_voice_session_test.dart: session state microphone gate: silent tutor only
01:07 +375: /home/runner/work/PyQuest/PyQuest/app/test/tutor_voice_session_test.dart: session state a server error is shown without ever leaking the key
[PyQuestVoice] recv #1 error
[PyQuestVoice] server ERROR #0 bad credential for wss://generativelanguage.googleapis.com/ws?key=•
01:07 +376: /home/runner/work/PyQuest/PyQuest/app/test/tutor_voice_session_test.dart: a development build without a key says so instead of pretending
01:07 +377: loading /home/runner/work/PyQuest/PyQuest/app/test/services_test.dart
01:08 +377: /home/runner/work/PyQuest/PyQuest/app/test/services_test.dart: energy regenerates over time, caps at max and never goes negative
01:08 +378: /home/runner/work/PyQuest/PyQuest/app/test/services_test.dart: level results keep the best score/stars and rewards are idempotent
01:08 +379: /home/runner/work/PyQuest/PyQuest/app/test/services_test.dart: lessons, badges and the chapter milestone
01:08 +380: /home/runner/work/PyQuest/PyQuest/app/test/services_test.dart: daily quests: three per day, progress, stamp, reset at local midnight
01:08 +381: /home/runner/work/PyQuest/PyQuest/app/test/services_test.dart: progress survives closing and reopening the database file
01:08 +382: All tests passed!

```

---

### render.txt
```
00:00 +0: loading /home/runner/work/PyQuest/PyQuest/app/test/render/render_screens_test.dart
00:00 +0: (setUpAll)
00:00 +0: render A: first launch
00:02 +1: render B: robot maze
00:06 +2: render C: lesson flow
00:08 +3: render D: arcade games
00:11 +4: render E: house, bugs, sheets, playground
00:13 +5: render F: small phone 360x640
00:14 +6: render G: cast gallery
00:14 +7: render H: tutor panel, offline build
00:15 +8: render I: tutor panel with an AI answer (static preview provider)
00:16 +9: render J: activity sheet before-set (six + locked)
PQC-009 imageCache khi mở lần lượt sáu sheet (cache của engine trên máy CI, KHÔNG phải RAM/GPU thiết bị): j00=7entries/11501568B -> j01=7entries/11501568B -> j02=7entries/11501568B -> j03=7entries/11501568B -> j04=7entries/11501568B -> j05=7entries/11501568B
00:21 +10: (tearDownAll)
00:21 +10: All tests passed!

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
board-mq1_01_s2-b2-quote-tokens-390x844-font2.0-vi.png 2 chunk(s)
board-mq1_01_s2-b3-connector-single-output-360x640-font2.0-en.png 2 chunk(s)
board-mq1_01_s2-b3-connector-single-output-360x640-font2.0-vi.png 2 chunk(s)
board-mq1_01_s2-b3-connector-single-output-390x844-font1.0-en.png 1 chunk(s)
board-mq1_01_s2-b3-connector-single-output-390x844-font1.0-vi.png 1 chunk(s)
board-mq1_01_s2-b3-connector-single-output-390x844-font2.0-en.png 2 chunk(s)
board-mq1_01_s2-b3-connector-single-output-390x844-font2.0-vi.png 2 chunk(s)
board-mq1_01_s2-b4-wait-task-360x640-font2.0-en.png 1 chunk(s)
board-mq1_01_s2-b4-wait-task-360x640-font2.0-vi.png 1 chunk(s)
board-mq1_01_s2-b4-wait-task-390x844-font1.0-en.png 1 chunk(s)
board-mq1_01_s2-b4-wait-task-390x844-font1.0-vi.png 1 chunk(s)
board-mq1_01_s2-b4-wait-task-390x844-font2.0-en.png 2 chunk(s)
board-mq1_01_s2-b4-wait-task-390x844-font2.0-vi.png 2 chunk(s)
board-mq1_03_s2-b1-groups-3-4-line-highlight-360x640-font2.0-en.png 2 chunk(s)
board-mq1_03_s2-b1-groups-3-4-line-highlight-360x640-font2.0-vi.png 2 chunk(s)
board-mq1_03_s2-b1-groups-3-4-line-highlight-390x844-font1.0-en.png 1 chunk(s)
board-mq1_03_s2-b1-groups-3-4-line-highlight-390x844-font1.0-vi.png 1 chunk(s)
board-mq1_03_s2-b1-groups-3-4-line-highlight-390x844-font2.0-en.png 2 chunk(s)
board-mq1_03_s2-b1-groups-3-4-line-highlight-390x844-font2.0-vi.png 2 chunk(s)
board-mq1_03_s2-b2-cleared-group-7-first-line-390x844-font1.0-en.png 1 chunk(s)
board-mq1_03_s2-b2-cleared-group-7-first-line-390x844-font1.0-vi.png 1 chunk(s)
board-mq1_03_s2-b2-cleared-group-7-first-line-390x844-font2.0-en.png 2 chunk(s)
board-mq1_03_s2-b2-cleared-group-7-first-line-390x844-font2.0-vi.png 2 chunk(s)
board-mq1_03_s2-b3-whole-run-two-lines-360x640-font2.0-en.png 1 chunk(s)
board-mq1_03_s2-b3-whole-run-two-lines-360x640-font2.0-vi.png 1 chunk(s)
board-mq1_03_s2-b3-whole-run-two-lines-390x844-font1.0-en.png 1 chunk(s)
board-mq1_03_s2-b3-whole-run-two-lines-390x844-font1.0-vi.png 1 chunk(s)
board-mq1_03_s2-b3-whole-run-two-lines-390x844-font2.0-en.png 2 chunk(s)
board-mq1_03_s2-b3-whole-run-two-lines-390x844-font2.0-vi.png 2 chunk(s)
board-mq1_03_s2-b4-shape-wait-390x844-font1.0-en.png 1 chunk(s)
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
