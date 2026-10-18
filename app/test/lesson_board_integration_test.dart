import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/app/app_scope.dart';
import 'package:pyquest/app/app_services.dart';
import 'package:pyquest/core/events.dart';
import 'package:pyquest/modules/main_quest/lesson_screen.dart';
import 'package:pyquest/modules/main_quest/quest_models.dart';
import 'package:pyquest/modules/tutor/board/authored_board_repository.dart';
import 'package:pyquest/modules/tutor/board/board_controller.dart';
import 'package:pyquest/modules/tutor/board/board_view.dart';
import 'package:pyquest/shared/l10n/pq_l10n.dart';
import 'package:pyquest/shared/widgets/chunky_button.dart';
import 'package:pyquest/shared/widgets/code_widgets.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_helpers.dart';

final Object _pqc011AssetLoadContextKey = Object();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUpAll(loadAppFonts);

  testWidgets(
    'authored example editor/run and board controls do not grade or progress',
    (WidgetTester tester) async {
      final AppServices services = await _createServices(tester);
      final _TracingAssetBundle assetBundle = _TracingAssetBundle(rootBundle);
      await _preloadAuthoredAssetBytes(tester, bundle: assetBundle);
      final Lesson lesson = services.mainQuest.byId('mq1_01')!;
      await _mountLesson(tester, services, lesson, bundle: assetBundle);

      await _advanceStoryToExample(tester, lesson);
      await _waitForBoard(tester);
      expect(
        find.byKey(const ValueKey<String>('lesson_authored_board_mq1_01_s2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('lesson_board_authored_badge')),
        findsOneWidget,
      );
      expect(find.text('Bảng soạn sẵn'), findsOneWidget);
      expect(find.text('Nova'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('board_scaffold')),
        findsNothing,
      );
      expect(find.text('mq1_01_s2'), findsNothing);

      CodeEditor editor = tester.widget<CodeEditor>(
        find.byKey(const ValueKey<String>('example_code_editor_mq1_01_s2')),
      );
      expect(editor.controller.text, 'print("Xin chào!")');
      final BoardController board = tester
          .widget<BoardView>(find.byType(BoardView))
          .controller;
      expect(board.plan?.characterId, 'nova');
      expect(board.beatCount, 4);

      final int energyBefore = services.energy.current;
      final List<String> events = <String>[];
      final StreamSubscription<StandardEvent> subscription = services
          .events
          .stream
          .listen((StandardEvent event) => events.add(event.type));
      addTearDown(subscription.cancel);

      final Finder next = find.byKey(const ValueKey<String>('board_next'));
      for (int i = 0; i < 3; i++) {
        await tester.ensureVisible(next);
        await tester.pump();
        if (board.canGoNext) {
          await tester.tap(next);
          await tester.pump();
        }
      }
      expect(board.stepId, 'mq1_01_s2');
      expect(board.beatIndex, 3);
      expect(board.isWaitingForLearner, isTrue);
      await tester.ensureVisible(next);
      await tester.pump();
      await tester.tap(next);
      await tester.pump();
      expect(board.beatIndex, 3);
      expect(
        board.isWaitingForLearner,
        isFalse,
        reason:
            'the learner may acknowledge the authored wait beat without advancing the lesson',
      );
      expect(find.text('2/5'), findsOneWidget);
      expect(services.energy.current, energyBefore);
      ChunkyButton continueButton = tester.widget<ChunkyButton>(
        find.byKey(const ValueKey<String>('lesson_continue')),
      );
      expect(
        continueButton.onPressed,
        isNull,
        reason:
            'board controls never call lesson Continue or change the lesson step',
      );
      await tester.tap(find.byKey(const ValueKey<String>('board_replay')));
      await tester.pump();
      expect(board.beatIndex, 0);
      await tester.tap(next);
      await tester.pump();
      expect(board.beatIndex, 1);
      await tester.tap(find.byKey(const ValueKey<String>('board_previous')));
      await tester.pump();
      expect(board.beatIndex, 0);
      expect(board.stepId, 'mq1_01_s2');
      expect(find.text('2/5'), findsOneWidget);
      expect(events, isNot(contains(EventTypes.exerciseSolved)));
      expect(events, isNot(contains(EventTypes.lessonCompleted)));

      for (int i = 0; i < 3; i++) {
        await tester.ensureVisible(next);
        await tester.pump();
        if (board.canGoNext) {
          await tester.tap(next);
          await tester.pump();
        }
      }
      expect(board.beatIndex, 3);
      expect(board.isWaitingForLearner, isTrue);

      editor = tester.widget<CodeEditor>(
        find.byKey(const ValueKey<String>('example_code_editor_mq1_01_s2')),
      );
      editor.controller.value = TextEditingValue(
        text: 'print("Xin chào!")',
        selection: const TextSelection.collapsed(offset: 5),
      );
      await tester.pump();
      expect(board.beatIndex, 3);
      expect(
        board.isWaitingForLearner,
        isTrue,
        reason: 'selection-only changes do not count as learner editing',
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('example_run')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('example_run')));
      await _waitForContinueEnabled(tester);
      expect(find.text('Xin chào!'), findsWidgets);
      expect(board.beatIndex, 3);
      expect(
        board.isWaitingForLearner,
        isFalse,
        reason:
            'running the example acknowledges the wait without changing the beat',
      );
      expect(events, contains(EventTypes.codeRun));
      expect(events, isNot(contains(EventTypes.exerciseSolved)));
      expect(events, isNot(contains(EventTypes.lessonCompleted)));
      continueButton = tester.widget<ChunkyButton>(
        find.byKey(const ValueKey<String>('lesson_continue')),
      );
      expect(
        continueButton.onPressed,
        isNotNull,
        reason: 'running the example keeps its pre-existing Continue behavior',
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('board_replay')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('board_replay')));
      await tester.pump();
      for (int i = 0; i < 3; i++) {
        await tester.ensureVisible(next);
        await tester.pump();
        if (board.canGoNext) {
          await tester.tap(next);
          await tester.pump();
        }
      }
      expect(board.beatIndex, 3);
      expect(board.isWaitingForLearner, isTrue);

      editor.controller.text = 'print("Đã sửa")';
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('board_code_mismatch')),
        findsOneWidget,
      );
      expect(board.beatIndex, 3);
      expect(
        board.isWaitingForLearner,
        isFalse,
        reason: 'a text edit acknowledges wait without advancing the board',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('example_run')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('example_run')));
      await _waitForCondition(
        tester,
        () => find.text('Đã sửa').evaluate().isNotEmpty,
        'edited example output is rendered',
      );
      expect(find.text('Đã sửa'), findsWidgets);
      expect(board.stepId, 'mq1_01_s2');
      expect(board.beatIndex, 3);
      expect(events, isNot(contains(EventTypes.exerciseSolved)));
      expect(events, isNot(contains(EventTypes.lessonCompleted)));

      await _finish(tester, services);
    },
  );

  testWidgets(
    'tutor sheet and locale changes preserve the lesson-owned board/editor state',
    (WidgetTester tester) async {
      final AppServices services = await _createServices(tester);
      final _TracingAssetBundle assetBundle = _TracingAssetBundle(rootBundle);
      await _preloadAuthoredAssetBytes(tester, bundle: assetBundle);
      await tester.runAsync(() => services.settings.setLang(PqLang.vi));
      final Lesson lesson = services.mainQuest.byId('mq1_03')!;
      await _mountLesson(tester, services, lesson, bundle: assetBundle);
      await _advanceStoryToExample(tester, lesson);
      await _waitForBoard(
        tester,
        description: '${lesson.id} / ${services.settings.lang}',
      );

      final BoardView view = tester.widget<BoardView>(find.byType(BoardView));
      final BoardController board = view.controller;
      expect(board.plan?.characterId, 'pixel');
      expect(find.text('Pixel'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('lesson_board_authored_badge')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('board_next')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('board_next')));
      await tester.pump();
      expect(board.beatIndex, 1);
      board.learner.setNote('test-only marker');
      board.learner.addStroke('test-only-stroke');

      final CodeEditor editor = tester.widget<CodeEditor>(
        find.byKey(const ValueKey<String>('example_code_editor_mq1_03_s2')),
      );
      editor.controller.value = TextEditingValue(
        text: 'print(10 + 2)',
        selection: const TextSelection.collapsed(offset: 8),
      );
      editor.focusNode!.requestFocus();
      await tester.pump();
      expect(editor.focusNode!.hasFocus, isTrue);
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('example_run')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('example_run')));
      await _waitForContinueEnabled(tester);
      expect(find.text('12'), findsOneWidget);
      // Bring the editor into view; the caret-specific wait below, not this
      // whole-widget reveal, establishes the scroll baseline.
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('example_code_editor_mq1_03_s2')),
      );
      await tester.pump();
      final ScrollPosition lessonScroll = _lessonScrollPosition(tester);
      final Finder editorField = find.byKey(
        const ValueKey<String>('code_editor_field'),
        skipOffstage: false,
      );
      final Finder editableText = find.descendant(
        of: editorField,
        matching: find.byType(EditableText, skipOffstage: false),
      );
      final Stopwatch tutorTraceClock = Stopwatch()..start();
      ModalRoute<dynamic>? tutorRoute;
      String tutorRouteState() {
        final ModalRoute<dynamic>? route = tutorRoute;
        if (route == null) return 'tutorRoute=not-yet-captured';
        return 'tutorRoute=${route.runtimeType} active=${route.isActive} '
            'current=${route.isCurrent} animation=${route.animation?.status}';
      }

      void traceTutorState(String event) {
        debugPrint(
          '[PQC-011 tutor transition] event=$event '
          'elapsed=${tutorTraceClock.elapsed} '
          '${tutorRouteState()} '
          'focus=${editor.focusNode!.hasFocus} '
          'scroll=${lessonScroll.pixels.toStringAsFixed(2)}',
        );
      }

      void traceFocusChange() => debugPrint(
        '[PQC-011 focus event] elapsed=${tutorTraceClock.elapsed} '
        '${tutorRouteState()} focus=${editor.focusNode!.hasFocus} '
        'scroll=${lessonScroll.pixels.toStringAsFixed(2)}',
      );
      void traceScrollChange() => debugPrint(
        '[PQC-011 scroll event] elapsed=${tutorTraceClock.elapsed} '
        '${tutorRouteState()} focus=${editor.focusNode!.hasFocus} '
        'scroll=${lessonScroll.pixels.toStringAsFixed(2)}',
      );
      void traceCaretSnapshot(String event, [_CaretScrollSnapshot? snapshot]) {
        final _CaretScrollSnapshot sample =
            snapshot ?? _captureCaretScrollSnapshot(tester, editor);
        debugPrint(
          '[PQC-011 caret viewport] event=$event '
          'elapsed=${tutorTraceClock.elapsed} ${tutorRouteState()} $sample',
        );
      }

      editor.focusNode!.addListener(traceFocusChange);
      lessonScroll.addListener(traceScrollChange);
      await tester.ensureVisible(editableText);
      await tester.pump();
      expect(
        editor.focusNode!.hasFocus,
        isTrue,
        reason: 'the existing tutor-state case reaches the baseline focused',
      );
      final _CaretScrollSnapshot caretBaselineBeforeTutor =
          await _waitForCaretScrollToSettle(
            tester,
            editor,
            'before opening Tutor',
          );
      traceTutorState('focused editor settled before opening Tutor');
      traceCaretSnapshot(
        'dynamic baseline before Tutor',
        caretBaselineBeforeTutor,
      );

      await tester.tap(find.byKey(const ValueKey<String>('lesson_tutor')));
      await _waitForCondition(
        tester,
        () => find
            .byKey(const ValueKey<String>('tutor_close'))
            .evaluate()
            .isNotEmpty,
        'tutor sheet opening completes',
      );
      tutorRoute = ModalRoute.of<dynamic>(
        tester.element(
          find.byKey(
            const ValueKey<String>('tutor_close'),
            skipOffstage: false,
          ),
        ),
      );
      expect(tutorRoute, isNotNull);
      await tester.pump(const Duration(milliseconds: 300));
      traceTutorState('Tutor open transition settled, before close tap');
      traceCaretSnapshot('before close tap');
      expect(find.byKey(const ValueKey<String>('tutor_close')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('tutor_close')));
      traceTutorState('immediately after close tap returns');
      traceCaretSnapshot('immediately after close tap');
      await tester.pump();
      traceTutorState('one frame after close tap');
      await _waitForCondition(
        tester,
        () =>
            find
                .byKey(const ValueKey<String>('tutor_close'))
                .evaluate()
                .isEmpty &&
            editor.focusNode!.hasFocus,
        'tutor sheet closes and restores editor focus',
      );
      traceTutorState('Tutor route absent and editor focus restored');
      traceCaretSnapshot('after route closes and focus returns');
      final _CaretScrollSnapshot caretStateAfterTutor =
          await _waitForCaretScrollToSettle(
            tester,
            editor,
            'after first Tutor close',
          );
      traceCaretSnapshot(
        'after first close caret scrolling settles',
        caretStateAfterTutor,
      );

      final BoardController afterTutor = tester
          .widget<BoardView>(find.byType(BoardView))
          .controller;
      expect(identical(afterTutor, board), isTrue);
      expect(board.beatIndex, 1);
      expect(board.learner.note, 'test-only marker');
      expect(board.learner.strokes, <String>['test-only-stroke']);
      expect(editor.controller.text, 'print(10 + 2)');
      expect(
        editor.controller.selection,
        const TextSelection.collapsed(offset: 8),
      );
      expect(editor.focusNode!.hasFocus, isTrue);
      expect(
        find.text('12'),
        findsOneWidget,
        reason: 'the last run result survives the tutor route',
      );
      final double firstCloseScrollDelta =
          caretStateAfterTutor.scrollPixels -
          caretBaselineBeforeTutor.scrollPixels;
      debugPrint(
        '[PQC-011 caret comparison] first close scroll delta='
        '${firstCloseScrollDelta.toStringAsFixed(2)}',
      );
      expect(
        caretStateAfterTutor.scrollPixels,
        closeTo(caretBaselineBeforeTutor.scrollPixels, 0.5),
      );

      await tester.tap(find.byKey(const ValueKey<String>('lesson_tutor')));
      await _waitForCondition(
        tester,
        () => find
            .byKey(const ValueKey<String>('tutor_close'))
            .evaluate()
            .isNotEmpty,
        'tutor sheet opening completes',
      );
      tutorRoute = ModalRoute.of<dynamic>(
        tester.element(
          find.byKey(
            const ValueKey<String>('tutor_close'),
            skipOffstage: false,
          ),
        ),
      );
      expect(tutorRoute, isNotNull);
      await tester.pump(const Duration(milliseconds: 300));
      traceTutorState('reopened Tutor route settled, before close tap');
      traceCaretSnapshot('before second close tap');
      expect(find.byKey(const ValueKey<String>('tutor_close')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('tutor_close')));
      traceTutorState('immediately after second close tap returns');
      traceCaretSnapshot('immediately after second close tap');
      await tester.pump();
      traceTutorState('one frame after second close tap');
      await _waitForCondition(
        tester,
        () =>
            find
                .byKey(const ValueKey<String>('tutor_close'))
                .evaluate()
                .isEmpty &&
            editor.focusNode!.hasFocus,
        'tutor sheet closes and restores editor focus after reopening',
      );
      traceTutorState('Tutor route absent and focus restored after reopening');
      traceCaretSnapshot('after second route closes and focus returns');
      final _CaretScrollSnapshot caretStateAfterReopen =
          await _waitForCaretScrollToSettle(
            tester,
            editor,
            'after second Tutor close',
          );
      traceCaretSnapshot(
        'after second close caret scrolling settles',
        caretStateAfterReopen,
      );
      final double secondCloseScrollDelta =
          caretStateAfterReopen.scrollPixels -
          caretBaselineBeforeTutor.scrollPixels;
      debugPrint(
        '[PQC-011 caret comparison] second close scroll delta='
        '${secondCloseScrollDelta.toStringAsFixed(2)}',
      );
      expect(
        identical(
          tester.widget<BoardView>(find.byType(BoardView)).controller,
          board,
        ),
        isTrue,
      );
      expect(board.beatIndex, 1);
      expect(board.learner.note, 'test-only marker');
      expect(board.learner.strokes, <String>['test-only-stroke']);
      expect(editor.controller.text, 'print(10 + 2)');
      expect(
        editor.controller.selection,
        const TextSelection.collapsed(offset: 8),
      );
      expect(editor.focusNode!.hasFocus, isTrue);
      expect(find.text('12'), findsOneWidget);
      expect(
        caretStateAfterReopen.scrollPixels,
        closeTo(caretBaselineBeforeTutor.scrollPixels, 0.5),
      );
      editor.focusNode!.removeListener(traceFocusChange);
      lessonScroll.removeListener(traceScrollChange);

      await tester.runAsync(() => services.settings.setLang(PqLang.en));
      await _waitForCondition(
        tester,
        () =>
            board.locale == 'en' &&
            find.text('Authored example').evaluate().isNotEmpty,
        'English board labels follow the persisted locale',
      );
      expect(board.locale, 'en');
      expect(board.beatIndex, 1);
      expect(find.text('Authored example'), findsOneWidget);
      expect(find.text('Join them and count'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(board.learner.note, 'test-only marker');
      expect(board.learner.strokes, <String>['test-only-stroke']);
      expect(editor.controller.text, 'print(10 + 2)');
      expect(
        editor.controller.selection,
        const TextSelection.collapsed(offset: 8),
      );

      await tester.runAsync(() => services.settings.setLang(PqLang.vi));
      await _waitForCondition(
        tester,
        () =>
            board.locale == 'vi' &&
            find.text('Bảng soạn sẵn').evaluate().isNotEmpty,
        'Vietnamese board labels follow the persisted locale',
      );
      expect(board.locale, 'vi');
      expect(board.beatIndex, 1);
      expect(find.text('Bảng soạn sẵn'), findsOneWidget);
      expect(find.text('Gộp lại và đếm'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(editor.controller.text, 'print(10 + 2)');
      expect(
        editor.controller.selection,
        const TextSelection.collapsed(offset: 8),
      );

      await _finish(tester, services);
    },
  );

  testWidgets(
    'embedded board controls are hit-testable at both sizes in VI/EN, including 2x text',
    (WidgetTester tester) async {
      final AppServices services = await _createServices(tester);
      final _TracingAssetBundle assetBundle = _TracingAssetBundle(rootBundle);
      await _preloadAuthoredAssetBytes(tester, bundle: assetBundle);
      final List<MapEntry<Size, PqLang>> cases = <MapEntry<Size, PqLang>>[
        MapEntry<Size, PqLang>(const Size(390, 844), PqLang.vi),
        MapEntry<Size, PqLang>(const Size(390, 844), PqLang.en),
        MapEntry<Size, PqLang>(const Size(360, 640), PqLang.vi),
        MapEntry<Size, PqLang>(const Size(360, 640), PqLang.en),
      ];

      for (int index = 0; index < cases.length; index++) {
        if (index > 0) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
        final MapEntry<Size, PqLang> testCase = cases[index];
        await tester.runAsync(() => services.settings.setLang(testCase.value));
        final Lesson lesson = services.mainQuest.byId('mq1_01')!;
        await _mountLesson(
          tester,
          services,
          lesson,
          bundle: assetBundle,
          viewport: testCase.key,
        );
        await _advanceStoryToExample(tester, lesson);
        await _waitForBoard(
          tester,
          description: '${testCase.key} / ${testCase.value}',
        );
        expect(
          find.byKey(const ValueKey<String>('lesson_board_authored_badge')),
          findsOneWidget,
        );
        expect(
          find.text(
            testCase.value == PqLang.vi ? 'Bảng soạn sẵn' : 'Authored example',
          ),
          findsOneWidget,
        );
        expect(find.text('mq1_01_s2'), findsNothing);

        final BoardController board = tester
            .widget<BoardView>(find.byType(BoardView))
            .controller;
        final Finder next = find.byKey(const ValueKey<String>('board_next'));
        await tester.ensureVisible(next);
        await tester.pump();
        await tester.tap(next);
        await tester.pump();
        expect(
          board.beatIndex,
          1,
          reason:
              '${testCase.key}/${testCase.value}: board control accepted a real hit',
        );

        final Finder run = find.byKey(const ValueKey<String>('example_run'));
        await tester.ensureVisible(run);
        await tester.pump();
        await tester.tap(run);
        await _waitForContinueEnabled(tester);
        final Finder continueButton = find.byKey(
          const ValueKey<String>('lesson_continue'),
        );
        await tester.ensureVisible(continueButton);
        await tester.pump();
        await tester.tap(continueButton);
        await _waitForCondition(
          tester,
          () => find.text('3/5').evaluate().isNotEmpty,
          'Continue advances to the next lesson step',
        );
        expect(
          find.text('3/5'),
          findsOneWidget,
          reason:
              '${testCase.key}/${testCase.value}: existing lesson Continue remains reachable',
        );
        expect(tester.takeException(), isNull);
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.runAsync(() => services.settings.setLang(PqLang.vi));
      final Lesson lesson = services.mainQuest.byId('mq1_01')!;
      await _mountLesson(
        tester,
        services,
        lesson,
        viewport: const Size(360, 640),
        textScale: 2,
      );
      await _advanceStoryToExample(tester, lesson);
      await _waitForBoard(tester);
      expect(
        find.byKey(const ValueKey<String>('lesson_board_authored_badge')),
        findsOneWidget,
      );
      expect(find.text('Bảng soạn sẵn'), findsOneWidget);
      final Finder nextAtTwoX = find.byKey(
        const ValueKey<String>('board_next'),
      );
      await tester.ensureVisible(nextAtTwoX);
      await tester.tap(nextAtTwoX);
      await tester.pump();
      expect(
        tester.widget<BoardView>(find.byType(BoardView)).controller.beatIndex,
        1,
      );

      final Finder runAtTwoX = find.byKey(
        const ValueKey<String>('example_run'),
      );
      await tester.ensureVisible(runAtTwoX);
      await tester.pump();
      await tester.tap(runAtTwoX);
      await _waitForContinueEnabled(tester);

      final Finder continueAtTwoX = find.byKey(
        const ValueKey<String>('lesson_continue'),
      );
      await tester.ensureVisible(continueAtTwoX);
      await tester.pump();
      await tester.tap(continueAtTwoX);
      await _waitForCondition(
        tester,
        () => find.text('3/5').evaluate().isNotEmpty,
        'Continue advances at 360x640 with 2x text',
      );
      expect(
        find.text('3/5'),
        findsOneWidget,
        reason:
            'Run enables Continue and both remain reachable at 360x640 with 2x text',
      );
      expect(tester.takeException(), isNull);
      await _finish(tester, services);
    },
  );

  testWidgets(
    'unsupported ExampleStep keeps the existing read-only example UI without a blank board',
    (WidgetTester tester) async {
      final AppServices services = await _createServices(tester);
      final Lesson lesson = services.mainQuest.byId('mq1_02')!;
      await _mountLesson(tester, services, lesson);
      await _advanceStoryToExample(tester, lesson);
      expect(find.byType(BoardView), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('lesson_authored_board_mq1_02_s2')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('example_code_editor_mq1_02_s2')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey<String>('example_run')), findsOneWidget);
      await _finish(tester, services);
    },
  );

  testWidgets(
    'malformed authored assets show labeled fallback without blocking the lesson',
    (WidgetTester tester) async {
      final AppServices services = await _createServices(tester);
      final Lesson lesson = services.mainQuest.byId('mq1_01')!;
      final _CorruptBoardAssetBundle bundle = _CorruptBoardAssetBundle(
        rootBundle,
      );
      await _mountLesson(tester, services, lesson, bundle: bundle);
      await _advanceStoryToExample(tester, lesson);
      for (
        int i = 0;
        i < 30 &&
            find
                .byKey(const ValueKey<String>('board_fallback'))
                .evaluate()
                .isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        find.byKey(const ValueKey<String>('board_fallback')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('lesson_board_authored_badge')),
        findsOneWidget,
      );
      expect(find.text('2/5'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _finish(tester, services);
    },
  );

  testWidgets(
    'late asset completion cannot apply to a step whose board owner was disposed',
    (WidgetTester tester) async {
      final AppServices services = await _createServices(tester);
      final Lesson lesson = services.mainQuest.byId('mq1_01')!;
      final Map<String, ByteData> authoredSources =
          await _preloadAuthoredAssetBytes(tester);
      final _GatedAssetBundle bundle = _GatedAssetBundle(
        rootBundle,
        authoredSources,
      );
      addTearDown(bundle.release);
      await _mountLesson(tester, services, lesson, bundle: bundle);
      await _advanceStoryToExample(tester, lesson);
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('lesson_board_loading')),
        findsOneWidget,
        reason: 'asset load is intentionally held behind the test gate',
      );

      await tester.tap(find.byKey(const ValueKey<String>('example_run')));
      await _waitForContinueEnabled(tester);
      await tester.tap(find.byKey(const ValueKey<String>('lesson_continue')));
      await _waitForCondition(
        tester,
        () => find.text('3/5').evaluate().isNotEmpty,
        'Continue advances before the late asset delivery',
      );
      expect(find.text('3/5'), findsOneWidget);
      expect(find.byType(BoardView), findsNothing);

      expect(
        bundle.deliveredAssetKeys,
        isEmpty,
        reason:
            'the gate keeps both authored asset deliveries pending until after step disposal',
      );
      bundle.release();
      await _waitForAuthoredAssetDelivery(tester, bundle);
      expect(
        find.byKey(const ValueKey<String>('lesson_authored_board_mq1_01_s2')),
        findsNothing,
      );
      expect(find.byType(BoardView), findsNothing);
      expect(tester.takeException(), isNull);
      await _finish(tester, services);
    },
  );

  testWidgets(
    'late asset completion after leaving LessonScreen is ignored safely',
    (WidgetTester tester) async {
      final AppServices services = await _createServices(tester);
      final Map<String, ByteData> authoredSources =
          await _preloadAuthoredAssetBytes(tester);
      final _GatedAssetBundle bundle = _GatedAssetBundle(
        rootBundle,
        authoredSources,
      );
      final Lesson lesson = services.mainQuest.byId('mq1_01')!;
      addTearDown(bundle.release);
      await _mountLesson(tester, services, lesson, bundle: bundle);
      await _advanceStoryToExample(tester, lesson);
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('lesson_board_loading')),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(
        bundle.deliveredAssetKeys,
        isEmpty,
        reason:
            'the gate keeps both authored asset deliveries pending until after unmount',
      );
      bundle.release();
      await _waitForAuthoredAssetDelivery(tester, bundle);
      expect(
        find.byKey(const ValueKey<String>('lesson_authored_board_mq1_01_s2')),
        findsNothing,
      );
      expect(find.byType(BoardView), findsNothing);
      expect(
        tester.takeException(),
        isNull,
        reason:
            'late repository completion must not call setState/apply on a disposed lesson',
      );
      await _finish(tester, services);
    },
  );
}

Future<AppServices> _createServices(WidgetTester tester) async {
  final AppServices? services = await tester.runAsync(
    () => AppServices.create(
      bundle: rootBundle,
      databaseFactory: databaseFactoryFfiNoIsolate,
      databasePath: inMemoryDatabasePath,
      audioEnabled: false,
      startSessionTimer: false,
    ),
  );
  return services!;
}

Future<void> _mountLesson(
  WidgetTester tester,
  AppServices services,
  Lesson lesson, {
  AssetBundle? bundle,
  Size viewport = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = viewport;
  Widget screen = LessonScreen(lesson: lesson);
  if (bundle != null)
    screen = DefaultAssetBundle(bundle: bundle, child: screen);
  await tester.pumpWidget(
    MaterialApp(
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child ?? const SizedBox.shrink(),
      ),
      home: AppScope(services: services, child: screen),
    ),
  );
  // Lesson stories use an intentional repeating character animation, so a
  // settle-until-idle pump can never complete. Readiness is the initial step
  // and its Continue control being present, not animation quiescence.
  await tester.pump();
  await _waitForCondition(
    tester,
    () =>
        find.text('1/${lesson.steps.length}').evaluate().isNotEmpty &&
        find
            .byKey(const ValueKey<String>('lesson_continue'))
            .evaluate()
            .isNotEmpty,
    'initial lesson step and Continue control mount',
  );
}

class _CaretScrollSnapshot {
  const _CaretScrollSnapshot({
    required this.hasFocus,
    required this.selectionOffset,
    required this.scrollPixels,
    required this.viewportDimension,
    required this.caretRect,
    required this.viewportRect,
    required this.visibleViewportRect,
    required this.paddedViewportRect,
    required this.viewInsets,
    required this.scrollPadding,
  });

  final bool hasFocus;
  final int selectionOffset;
  final double scrollPixels;
  final double viewportDimension;
  final Rect caretRect;
  final Rect viewportRect;
  final Rect visibleViewportRect;
  final Rect paddedViewportRect;
  final EdgeInsets viewInsets;
  final EdgeInsets scrollPadding;

  bool get caretWithinViewport =>
      visibleViewportRect.contains(caretRect.topLeft) &&
      visibleViewportRect.contains(caretRect.bottomRight);

  bool get caretWithinScrollPadding =>
      paddedViewportRect.contains(caretRect.topLeft) &&
      paddedViewportRect.contains(caretRect.bottomRight);

  bool stableWith(_CaretScrollSnapshot other) =>
      hasFocus == other.hasFocus &&
      _closeEnough(scrollPixels, other.scrollPixels) &&
      _closeEnough(viewportDimension, other.viewportDimension) &&
      _closeRects(caretRect, other.caretRect) &&
      _closeRects(viewportRect, other.viewportRect) &&
      _closeRects(visibleViewportRect, other.visibleViewportRect) &&
      viewInsets == other.viewInsets &&
      scrollPadding == other.scrollPadding;

  @override
  String toString() =>
      'focus=$hasFocus selection=$selectionOffset '
      'scroll=${scrollPixels.toStringAsFixed(2)} '
      'viewportDimension=${viewportDimension.toStringAsFixed(2)} '
      'caret=$caretRect viewport=$viewportRect '
      'visibleViewport=$visibleViewportRect '
      'paddedViewport=$paddedViewportRect '
      'caretWithinViewport=$caretWithinViewport '
      'caretWithinScrollPadding=$caretWithinScrollPadding '
      'viewInsets=$viewInsets scrollPadding=$scrollPadding';
}

bool _closeEnough(double first, double second) =>
    (first - second).abs() <= 0.05;

bool _closeRects(Rect first, Rect second) =>
    _closeEnough(first.left, second.left) &&
    _closeEnough(first.top, second.top) &&
    _closeEnough(first.right, second.right) &&
    _closeEnough(first.bottom, second.bottom);

ScrollPosition _lessonScrollPosition(WidgetTester tester) {
  final Finder lessonScroll = find.byKey(
    const ValueKey<String>('step_scroll_1'),
    skipOffstage: false,
  );
  final Finder scrollable = find
      .descendant(
        of: lessonScroll,
        matching: find.byType(Scrollable, skipOffstage: false),
      )
      .first;
  return tester.state<ScrollableState>(scrollable).position;
}

RenderBox _lessonViewportRenderBox(WidgetTester tester) {
  final Finder lessonScroll = find.byKey(
    const ValueKey<String>('step_scroll_1'),
    skipOffstage: false,
  );
  final Finder scrollable = find
      .descendant(
        of: lessonScroll,
        matching: find.byType(Scrollable, skipOffstage: false),
      )
      .first;
  final Element scrollableElement = scrollable.evaluate().single;
  // The first abstract viewport is the lesson's vertical viewport; the
  // EditableText's own viewport is nested deeper in this subtree.
  RenderBox? viewportBox;
  void findViewportBox(Element element) {
    if (viewportBox != null) return;
    if (element is RenderObjectElement &&
        element.renderObject is RenderAbstractViewport &&
        element.renderObject is RenderBox) {
      viewportBox = element.renderObject as RenderBox;
      return;
    }
    element.visitChildren(findViewportBox);
  }

  scrollableElement.visitChildren(findViewportBox);
  expect(viewportBox, isNotNull, reason: 'lesson scroll viewport is laid out');
  return viewportBox!;
}

RenderEditable _renderEditableBelow(WidgetTester tester, Finder finder) {
  final RenderObject root = tester.renderObject<RenderObject>(finder);
  RenderEditable? renderEditable;
  void visit(RenderObject object) {
    if (renderEditable != null) return;
    if (object is RenderEditable) {
      renderEditable = object;
      return;
    }
    object.visitChildren(visit);
  }

  visit(root);
  expect(
    renderEditable,
    isNotNull,
    reason: 'the EditableText subtree contains its RenderEditable',
  );
  return renderEditable!;
}

_CaretScrollSnapshot _captureCaretScrollSnapshot(
  WidgetTester tester,
  CodeEditor editor,
) {
  final Finder codeField = find.byKey(
    const ValueKey<String>('code_editor_field'),
    skipOffstage: false,
  );
  final Finder editableText = find.descendant(
    of: codeField,
    matching: find.byType(EditableText, skipOffstage: false),
  );
  final EditableText editableWidget = tester.widget<EditableText>(editableText);
  final RenderEditable renderEditable = _renderEditableBelow(
    tester,
    editableText,
  );
  final int selectionOffset = editor.controller.selection.extentOffset;
  expect(selectionOffset, greaterThanOrEqualTo(0));
  final Rect localCaret = renderEditable.getLocalRectForCaret(
    TextPosition(offset: selectionOffset),
  );
  final Rect caretRect = Rect.fromPoints(
    renderEditable.localToGlobal(localCaret.topLeft),
    renderEditable.localToGlobal(localCaret.bottomRight),
  );

  final RenderBox viewportBox = _lessonViewportRenderBox(tester);
  final Rect viewportRect = Rect.fromPoints(
    viewportBox.localToGlobal(Offset.zero),
    viewportBox.localToGlobal(
      Offset(viewportBox.size.width, viewportBox.size.height),
    ),
  );
  final EdgeInsets scrollPadding = editableWidget.scrollPadding;
  final MediaQueryData mediaQuery = MediaQuery.of(
    tester.element(editableText),
  );
  final EdgeInsets viewInsets = mediaQuery.viewInsets;
  final Rect mediaVisibleRect = Rect.fromLTRB(
    viewInsets.left,
    viewInsets.top,
    mediaQuery.size.width - viewInsets.right,
    mediaQuery.size.height - viewInsets.bottom,
  );
  final Rect visibleViewportRect = viewportRect.intersect(mediaVisibleRect);
  final Rect paddedViewportRect = Rect.fromLTRB(
    visibleViewportRect.left + scrollPadding.left,
    visibleViewportRect.top + scrollPadding.top,
    visibleViewportRect.right - scrollPadding.right,
    visibleViewportRect.bottom - scrollPadding.bottom,
  );
  final ScrollPosition lessonScroll = _lessonScrollPosition(tester);
  expect(
    viewportRect.height,
    closeTo(lessonScroll.viewportDimension, 0.5),
    reason: 'the measured render box matches the lesson viewport dimension',
  );

  return _CaretScrollSnapshot(
    hasFocus: editor.focusNode!.hasFocus,
    selectionOffset: selectionOffset,
    scrollPixels: lessonScroll.pixels,
    viewportDimension: lessonScroll.viewportDimension,
    caretRect: caretRect,
    viewportRect: viewportRect,
    visibleViewportRect: visibleViewportRect,
    paddedViewportRect: paddedViewportRect,
    viewInsets: viewInsets,
    scrollPadding: scrollPadding,
  );
}

Future<_CaretScrollSnapshot> _waitForCaretScrollToSettle(
  WidgetTester tester,
  CodeEditor editor,
  String description, {
  int stableSamples = 3,
  int maxFrames = 30,
}) async {
  _CaretScrollSnapshot? previous;
  _CaretScrollSnapshot? last;
  int stableCount = 0;
  for (int frame = 0; frame < maxFrames; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    final _CaretScrollSnapshot current = _captureCaretScrollSnapshot(
      tester,
      editor,
    );
    last = current;
    if (current.hasFocus &&
        current.caretWithinScrollPadding &&
        previous != null &&
        current.stableWith(previous)) {
      stableCount++;
      if (stableCount >= stableSamples) return current;
    } else {
      stableCount = 0;
    }
    previous = current;
  }
  fail(
    'Focused editor caret did not settle inside its scrollPadding $description '
    'within ${maxFrames * 50}ms; last snapshot: $last',
  );
}

Future<void> _advanceStoryToExample(WidgetTester tester, Lesson lesson) async {
  final String stepCount = lesson.steps.length.toString();
  expect(find.text('1/$stepCount'), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey<String>('lesson_continue')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.text('2/$stepCount'), findsOneWidget);
}

Future<void> _waitForBoard(
  WidgetTester tester, {
  String description = 'authored board loads',
}) async {
  // Asset Futures are warmed before mounting; readiness is bounded pumping
  // only, so this helper cannot leave WidgetTester.runAsync active.
  await tester.pump();
  for (
    int i = 0;
    i < 100 &&
        find
            .byKey(const ValueKey<String>('board_tutor_layer'))
            .evaluate()
            .isEmpty;
    i++
  ) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  final Object? buildException = tester.takeException();
  expect(
    buildException,
    isNull,
    reason: '$description: an exception occurred while mounting the board',
  );
  final bool stillLoading = find
      .byKey(const ValueKey<String>('lesson_board_loading'))
      .evaluate()
      .isNotEmpty;
  expect(
    find.byType(BoardView),
    findsOneWidget,
    reason: '$description (loading=$stillLoading)',
  );
  expect(
    find.byKey(const ValueKey<String>('board_tutor_layer')),
    findsOneWidget,
  );
}

Future<void> _waitForCondition(
  WidgetTester tester,
  bool Function() condition,
  String description,
) async {
  for (int frame = 0; frame < 20; frame++) {
    if (condition()) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(condition(), isTrue, reason: 'Timed out waiting for $description');
}

Future<void> _waitForContinueEnabled(WidgetTester tester) async {
  final Finder continueFinder = find.byKey(
    const ValueKey<String>('lesson_continue'),
  );
  for (int i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (tester.widget<ChunkyButton>(continueFinder).onPressed != null) return;
  }
  fail('Example run did not enable Continue');
}

Future<void> _waitForAuthoredAssetDelivery(
  WidgetTester tester,
  _GatedAssetBundle bundle,
) async {
  await tester.runAsync(
    () => bundle.waitForAuthoredAssets().timeout(const Duration(seconds: 5)),
  );
  expect(
    bundle.deliveredAssetKeys,
    containsAll(_GatedAssetBundle.authoredAssetKeys),
  );
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
}

/// Warm real authored assets inside runAsync before the lesson route starts
/// requesting them from the widget-test fake-async zone. Each fetch is logged
/// and bounded so an unfinished platform asset request cannot hold runAsync.
Future<Map<String, ByteData>> _preloadAuthoredAssetBytes(
  WidgetTester tester, {
  _TracingAssetBundle? bundle,
}) async {
  final _TracingAssetBundle assetBundle =
      bundle ?? _TracingAssetBundle(rootBundle);
  final Map<String, ByteData>? sources = await tester.runAsync(
    () => runZoned<Future<Map<String, ByteData>>>(
      () async {
        final int zoneId = identityHashCode(Zone.current);
        final Map<String, Object> errors = <String, Object>{};
        final Map<String, StackTrace> stacks = <String, StackTrace>{};

        Future<void> load(String key) async {
          final Stopwatch stopwatch = Stopwatch()..start();
          final Future<String> assetFuture = assetBundle.preloadString(key);
          debugPrint(
            '[PQC-011 preload] START key=$key '
            'bundle=${assetBundle.runtimeType}#'
            '${identityHashCode(assetBundle)} '
            'async=WidgetTester.runAsync zone=$zoneId '
            'future=${assetFuture.runtimeType}',
          );
          try {
            final String contents = await assetFuture.timeout(
              const Duration(seconds: 5),
            );
            if (!assetBundle.loadedSources.containsKey(key)) {
              throw StateError(
                'No real bytes captured for authored asset $key',
              );
            }
            debugPrint(
              '[PQC-011 preload] END key=$key elapsed=${stopwatch.elapsed} '
              'characters=${contents.length} zone=$zoneId',
            );
          } on Object catch (error, stackTrace) {
            errors[key] = error;
            stacks[key] = stackTrace;
            debugPrint(
              '[PQC-011 preload] ERROR key=$key elapsed=${stopwatch.elapsed} '
              'zone=$zoneId error=$error',
            );
          }
        }

        await Future.wait<void>(<Future<void>>[
          load(AuthoredBoardRepository.plansAssetKey),
          load(AuthoredBoardRepository.copyAssetKey),
        ]);
        if (errors.isNotEmpty) {
          final String key = errors.keys.first;
          Error.throwWithStackTrace(errors[key]!, stacks[key]!);
        }
        return Map<String, ByteData>.of(assetBundle.loadedSources);
      },
      zoneValues: <Object?, Object?>{
        _pqc011AssetLoadContextKey: 'WidgetTester.runAsync',
      },
    ),
  );
  if (sources == null) {
    throw StateError(
      'PQC-011 authored asset preload returned null from tester.runAsync',
    );
  }
  return sources;
}

Future<void> _finish(WidgetTester tester, AppServices services) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 100));
  services.dispose();
  tester.view.reset();
}

class _TracingAssetBundle extends CachingAssetBundle {
  _TracingAssetBundle(this.delegate);

  final AssetBundle delegate;
  final Map<String, ByteData> loadedSources = <String, ByteData>{};
  final Map<String, String> loadedStrings = <String, String>{};

  Future<String> preloadString(String key) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final int zoneId = identityHashCode(Zone.current);
    final Future<String> assetFuture = super.loadString(key);
    debugPrint(
      '[PQC-011 asset preload] START key=$key '
      'bundle=$runtimeType#${identityHashCode(this)} '
      'async=${Zone.current[_pqc011AssetLoadContextKey]} zone=$zoneId '
      'future=${assetFuture.runtimeType}',
    );
    try {
      final String contents = await assetFuture.timeout(
        const Duration(seconds: 5),
      );
      loadedStrings[key] = contents;
      debugPrint(
        '[PQC-011 asset preload] END key=$key elapsed=${stopwatch.elapsed} '
        'characters=${contents.length} zone=$zoneId',
      );
      return contents;
    } on Object catch (error, stackTrace) {
      debugPrint(
        '[PQC-011 asset preload] ERROR key=$key elapsed=${stopwatch.elapsed} '
        'zone=$zoneId error=$error',
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    final String? contents = loadedStrings[key];
    final int zoneId = identityHashCode(Zone.current);
    if (contents != null) {
      final SynchronousFuture<String> assetFuture = SynchronousFuture<String>(
        contents,
      );
      debugPrint(
        '[PQC-011 route asset] READY key=$key '
        'bundle=$runtimeType#${identityHashCode(this)} '
        'async=${Zone.current[_pqc011AssetLoadContextKey] ?? 'widget-test'} '
        'zone=$zoneId future=${assetFuture.runtimeType}',
      );
      return assetFuture;
    }

    final Future<String> assetFuture = super.loadString(key, cache: cache);
    debugPrint(
      '[PQC-011 route asset] START key=$key '
      'bundle=$runtimeType#${identityHashCode(this)} '
      'async=${Zone.current[_pqc011AssetLoadContextKey] ?? 'widget-test'} '
      'zone=$zoneId future=${assetFuture.runtimeType}',
    );
    return assetFuture.timeout(const Duration(seconds: 5));
  }

  @override
  Future<ByteData> load(String key) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final int zoneId = identityHashCode(Zone.current);
    debugPrint(
      '[PQC-011 route asset] START key=$key '
      'bundle=$runtimeType#${identityHashCode(this)} '
      'delegate=${delegate.runtimeType} '
      'async=${Zone.current[_pqc011AssetLoadContextKey] ?? 'widget-test'} '
      'zone=$zoneId',
    );
    final Future<ByteData> assetFuture = delegate.load(key);
    debugPrint(
      '[PQC-011 route asset] FUTURE key=$key type=${assetFuture.runtimeType} '
      'createdZone=$zoneId',
    );
    try {
      final ByteData bytes = await assetFuture.timeout(
        const Duration(seconds: 5),
      );
      loadedSources[key] = bytes;
      debugPrint(
        '[PQC-011 route asset] END key=$key elapsed=${stopwatch.elapsed} '
        'bytes=${bytes.lengthInBytes} zone=$zoneId',
      );
      return bytes;
    } on Object catch (error, stackTrace) {
      debugPrint(
        '[PQC-011 route asset] ERROR key=$key elapsed=${stopwatch.elapsed} '
        'zone=$zoneId error=$error',
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

class _CorruptBoardAssetBundle extends CachingAssetBundle {
  _CorruptBoardAssetBundle(this.delegate);

  final AssetBundle delegate;

  @override
  Future<ByteData> load(String key) {
    if (key == 'assets/data/tutor_board_plans.v1.json') {
      return Future<ByteData>.value(
        ByteData.sublistView(Uint8List.fromList(utf8.encode('{bad json'))),
      );
    }
    return delegate.load(key);
  }
}

class _GatedAssetBundle extends CachingAssetBundle {
  _GatedAssetBundle(this.delegate, this.authoredSources);

  static const Set<String> authoredAssetKeys = <String>{
    AuthoredBoardRepository.plansAssetKey,
    AuthoredBoardRepository.copyAssetKey,
  };

  final AssetBundle delegate;
  final Map<String, ByteData> authoredSources;
  final Completer<void> _gate = Completer<void>();
  final Completer<void> _allAssetsDelivered = Completer<void>();
  final Set<String> _deliveredAssetKeys = <String>{};

  Set<String> get deliveredAssetKeys =>
      Set<String>.unmodifiable(_deliveredAssetKeys);

  Future<void> waitForAuthoredAssets() => _allAssetsDelivered.future;

  void release() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  Future<ByteData> load(String key) {
    if (!authoredAssetKeys.contains(key)) return delegate.load(key);
    final ByteData? bytes = authoredSources[key];
    if (bytes == null) {
      return Future<ByteData>.error(
        StateError('Preloaded authored bytes missing for $key'),
      );
    }

    return _gate.future.then((_) => bytes).then((ByteData deliveredBytes) {
      _deliveredAssetKeys.add(key);
      if (_deliveredAssetKeys.containsAll(authoredAssetKeys) &&
          !_allAssetsDelivered.isCompleted) {
        _allAssetsDelivered.complete();
      }
      return deliveredBytes;
    });
  }
}
