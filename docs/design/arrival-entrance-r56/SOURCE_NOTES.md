# Source notes r56 — trích nguồn, không phải bằng chứng runtime

Pin CODE `5c97577c32c27d36f33c09bf3af2fa01ad0111f5` (PQC020 chưa ACCEPTED). Dòng giữ số nguồn; khoảng trắng cuối dòng bỏ khi trích.

## `app/lib/modules/main_map/activity_sheet.dart` · 17–31

```dart
17:
18:   @override
19:   Widget build(BuildContext context) {
20:     final def = module.def;
21:     return SingleChildScrollView(
22:       padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
23:       child: Column(
24:         crossAxisAlignment: CrossAxisAlignment.stretch,
25:         children: [
26:           Row(
27:             crossAxisAlignment: CrossAxisAlignment.start,
28:             children: [
29:               Container(
30:                 width: 104,
31:                 height: 104,
```

## `app/lib/modules/main_map/activity_sheet.dart` · 77–145

```dart
77:               ),
78:             )
79:           else
80:             PQPanel(
81:               child: Column(
82:                 crossAxisAlignment: CrossAxisAlignment.start,
83:                 children: [
84:                   Row(
85:                     children: [
86:                       Text('Tiến trình', style: PQText.h3),
87:                       const Spacer(),
88:                       if (status.stars != null) ...[
89:                         const StarIcon(size: 22),
90:                         const SizedBox(width: 4),
91:                         Text('${status.stars}', style: PQText.number.copyWith(fontSize: 20)),
92:                       ],
93:                     ],
94:                   ),
95:                   const SizedBox(height: 4),
96:                   Text(status.progressLabel, style: PQText.bodyStrong),
97:                   for (final line in status.detailLines)
98:                     Padding(
99:                       padding: const EdgeInsets.only(top: 2),
100:                       child: Text(line, style: PQText.body.copyWith(fontSize: 15.5)),
101:                     ),
102:                 ],
103:               ),
104:             ),
105:           const SizedBox(height: 18),
106:           if (status.locked && status.unlockLessonId != null)
107:             ChunkyButton(
108:               key: const ValueKey('sheet_go_lesson'),
109:               label: 'Đi tới bài học',
110:               icon: Icons.school_rounded,
111:               tone: PQTone.py,
112:               expand: true,
113:               onPressed: () => Navigator.of(context).pop('lesson:${status.unlockLessonId}'),
114:             )
115:           else if (!status.locked)
116:             ChunkyButton(
117:               key: const ValueKey('sheet_open'),
118:               label: 'Vào ${def.name}',
119:               icon: Icons.play_arrow_rounded,
120:               tone: def.tone,
121:               expand: true,
122:               onPressed: () => Navigator.of(context).pop('open'),
123:             ),
124:           const SizedBox(height: 10),
125:           ChunkyButton(
126:             label: 'Để sau',
127:             tone: PQTone.parchment,
128:             expand: true,
129:             onPressed: () => Navigator.of(context).pop(),
130:           ),
131:         ],
132:       ),
133:     );
134:   }
135: }
```

## `app/lib/modules/main_map/main_map_screen.dart` · 120–130

```dart
120:   Future<void> _showIntro() async {
121:     if (!mounted) return;
122:     await showDialog<void>(
123:       context: context,
124:       barrierDismissible: false,
125:       barrierColor: PQColors.ink.withValues(alpha: 0.55),
126:       builder: (BuildContext context) => const _WelcomeDialog(),
127:     );
128:     if (mounted) await _services?.settings.setIntroSeen();
129:   }
130:
```

## `app/lib/modules/main_map/main_map_screen.dart` · 131–184

```dart
131:   Future<void> _openPlace(ActivityModule module) async {
132:     final AppServices? services = _services;
133:     final MainMapPlaceState? place = _placeStatuses?.places[module.def.id];
134:     if (!mounted ||
135:         services == null ||
136:         _routeBusy ||
137:         place?.status == null ||
138:         place?.phase != MainMapPlacePhase.ready)
139:       return;
140:
141:     final double villageOffset = _villageScroll.hasClients
142:         ? _villageScroll.offset
143:         : 0;
144:     final double directoryOffset = _directoryScroll.hasClients
145:         ? _directoryScroll.offset
146:         : 0;
147:     setState(() => _routeBusy = true);
148:     services.audio.play(Sfx.pop);
149:     bool enteredActivity = false;
150:     try {
151:       final String? action = await showPQSheet<String>(
152:         context,
153:         builder: (BuildContext context) =>
154:             ActivitySheet(module: module, status: place!.status!),
155:       );
156:       if (!mounted || action == null) return;
157:       if (action == 'open') {
158:         enteredActivity = true;
159:         await openActivity(context, module);
160:       } else if (action.startsWith('lesson:')) {
161:         final ActivityModule? main = activityById('main_quest');
162:         if (main is MainQuestModule) {
163:           enteredActivity = true;
164:           await openActivity(context, main, lessonId: action.substring(7));
165:         }
166:       }
167:     } finally {
168:       if (mounted) {
169:         final bool shouldRefresh = enteredActivity || _refreshPending;
170:         _refreshPending = false;
171:         setState(() => _routeBusy = false);
172:         if (shouldRefresh) await _placeStatuses?.refresh();
173:         if (mounted) {
174:           WidgetsBinding.instance.addPostFrameCallback((_) {
175:             if (!mounted) return;
176:             _restoreScrollOffset(_villageScroll, villageOffset);
177:             _restoreScrollOffset(_directoryScroll, directoryOffset);
178:             _placeFocus[module.def.id]?.requestFocus();
179:           });
180:         }
181:       }
182:     }
183:   }
184:
```

## `app/lib/modules/main_map/main_map_screen.dart` · 410–446

```dart
410: Future<void> openActivity(
411:   BuildContext context,
412:   ActivityModule module, {
413:   String? lessonId,
414: }) async {
415:   final AppServices s = AppScope.of(context);
416:   final outcome = await s.events.emit(
417:     StandardEvent(
418:       type: EventTypes.activityOpened,
419:       sourceId: 'main_map',
420:       data: <String, Object?>{'activity_id': module.def.id},
421:     ),
422:   );
423:   if (!context.mounted) return;
424:   s.audio.play(Sfx.whoosh);
425:   WidgetBuilder page = module.buildHome;
426:   if (lessonId != null && module is MainQuestModule) {
427:     final MainQuestModule main = module;
428:     page = (BuildContext context) =>
429:         main.buildHome(context, openLessonId: lessonId);
430:   }
431:   final NavigatorState navigator = Navigator.of(context);
432:   final route = navigator.push<void>(
433:     CloudRoute<void>(builder: page, calm: s.settings.calmMode),
434:   );
435:   if (outcome.notices.isNotEmpty) {
436:     unawaited(
437:       Future<void>.delayed(const Duration(milliseconds: 900), () {
438:         if (navigator.mounted)
439:           showRewardToasts(navigator.context, outcome.notices);
440:       }),
441:     );
442:   }
443:   await route;
444:   if (context.mounted) s.audio.music(MusicTrack.island);
445: }
446:
```

## `app/lib/modules/main_map/main_map_screen.dart` · 457–481

```dart
457:   static const _pages = [
458:     (
459:       CharacterId.robo,
460:       'Chào mừng tới Đảo Khởi Đầu!',
461:       'Mình là Robo. Mỗi địa điểm trên đảo là một trò chơi hoặc một chặng phiêu lưu riêng. Chạm vào một nơi để khám phá nhé!',
462:     ),
463:     (
464:       CharacterId.py,
465:       'Học Python ở Tháp Python',
466:       'Tớ là thầy Py. Ở Tháp Python bạn sẽ học viết code thật từng bước. Nhiều trò chơi khác trên đảo không cần biết Python đâu!',
467:     ),
468:     (
469:       CharacterId.pip,
470:       'Năng lượng và nghỉ ngơi',
471:       'Chơi màn mới và học bài mới dùng một chút năng lượng. Năng lượng tự hồi theo thời gian. Không có quảng cáo, không có mua bán!',
472:     ),
473:   ];
474:
475:   @override
476:   Widget build(BuildContext context) {
477:     final (character, title, body) = _pages[_page];
478:     final last = _page == _pages.length - 1;
479:     return Dialog(
480:       backgroundColor: Colors.transparent,
481:       insetPadding: const EdgeInsets.all(20),
```

## `app/lib/modules/main_quest/main_quest_module.dart` · 28–55

```dart
28:     labelAnchor: Offset(0.514, 0.275),
29:     thumbnail: 'assets/images/thumb_tower.webp',
30:     tone: PQTone.py,
31:     needsPython: true,
32:   );
33:
34:   @override
35:   Future<ActivityStatus> status(AppServices services) async {
36:     final done = await services.progress.completedLessons();
37:     final lessons = services.mainQuest.lessons;
38:     final count = lessons.where((l) => done.contains(l.id)).length;
39:     final next = lessons.where((l) => !done.contains(l.id)).firstOrNull;
40:     return ActivityStatus(
41:       progressLabel: '$count/${lessons.length} bài',
42:       recommended: count == 0,
43:       detailLines: [
44:         'Chặng ${services.mainQuest.chapterNumber}: ${services.mainQuest.chapterTitle}',
45:         if (next != null) 'Bài tiếp theo: ${next.title}' else 'Đã hoàn thành Chặng ${services.mainQuest.chapterNumber}!',
46:       ],
47:     );
48:   }
49:
50:   @override
51:   Widget buildHome(BuildContext context, {String? openLessonId}) => MainQuestHomeScreen(openLessonId: openLessonId);
52: }
53:
54: class MainQuestHomeScreen extends StatefulWidget {
55:   const MainQuestHomeScreen({super.key, this.openLessonId});
```

## `app/lib/modules/main_quest/main_quest_module.dart` · 80–119

```dart
80:   @override
81:   void dispose() {
82:     _services?.events.revision.removeListener(_load);
83:     _scroll.dispose();
84:     super.dispose();
85:   }
86:
87:   Future<void> _load() async {
88:     final done = await _services!.progress.completedLessons();
89:     if (!mounted) return;
90:     setState(() => _done = done);
91:     if (!_scrolledToTarget && widget.openLessonId != null) {
92:       _scrolledToTarget = true;
93:       final i = _services!.mainQuest.lessons.indexWhere((l) => l.id == widget.openLessonId);
94:       WidgetsBinding.instance.addPostFrameCallback((_) {
95:         if (_scroll.hasClients && i > 1) {
96:           _scroll.animateTo((i - 1) * 96.0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
97:         }
98:       });
99:     }
100:   }
101:
102:   bool _unlocked(List<Lesson> lessons, int i) => i == 0 || _done.contains(lessons[i - 1].id);
103:
104:   Future<void> _open(Lesson lesson) async {
105:     final s = AppScope.of(context);
106:     final cost = _done.contains(lesson.id)
107:         ? s.config.cost('main_quest_review')
108:         : (lesson.isChallenge ? s.config.cost('chapter_challenge_first') : s.config.cost('main_quest_lesson_first'));
109:     if (!await spendEnergy(context, cost)) return;
110:     if (!mounted) return;
111:     await Navigator.of(context).push(CloudRoute<void>(builder: (_) => LessonScreen(lesson: lesson), calm: s.settings.calmMode));
112:   }
113:
114:   @override
115:   Widget build(BuildContext context) {
116:     final s = AppScope.of(context);
117:     final content = s.mainQuest;
118:     final lessons = content.lessons;
119:     final count = lessons.where((l) => _done.contains(l.id)).length;
```

## `app/lib/core/settings_service.dart` · 17–39

```dart
17:   bool _systemLocaleInputProvided = false;
18:   LocalePreference _localePreference = LocalePreference.system;
19:   LocaleResolution _localeResolution = LocaleResolver.resolve(preference: LocalePreference.system);
20:   Object? _localeLoadError;
21:   Object? _localePreferenceSaveError;
22:   bool _loaded = false;
23:   int _localePreferenceRequest = 0;
24:   Future<void> _localePreferenceWriteTail = Future<void>.value();
25:
26:   /// Loads raw settings and migrates a valid legacy language without deleting it.
27:   ///
28:   /// OS locales are supplied by the caller; this service does not read platform APIs.
29:   Future<void> load({Iterable<String>? systemLocales}) async {
30:     // A reload/reset on the existing service must not erase the OS session input. A caller
31:     // can still explicitly replace it with an empty list to select the English fallback.
32:     if (systemLocales != null) {
33:       _systemLocaleInputProvided = true;
34:       _systemLocales = List<String>.unmodifiable(systemLocales);
35:     }
36:     _loaded = false;
37:     _localeLoadError = null;
38:     late final Map<String, String> loadedValues;
39:     try {
```
