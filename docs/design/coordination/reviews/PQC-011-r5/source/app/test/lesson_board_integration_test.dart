import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUpAll(loadAppFonts);

  testWidgets('authored example editor/run and board controls do not grade or progress',
      (WidgetTester tester) async {
    final AppServices services = await _createServices(tester);
    final Lesson lesson = services.mainQuest.byId('mq1_01')!;
    await _mountLesson(tester, services, lesson);

    await _advanceStoryToExample(tester);
    await _waitForBoard(tester);
    expect(find.byKey(const ValueKey<String>('lesson_authored_board_mq1_01_s2')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('lesson_board_authored_badge')), findsOneWidget);
    expect(find.text('Bảng soạn sẵn'), findsOneWidget);
    expect(find.text('Nova'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('board_scaffold')), findsNothing);
    expect(find.text('mq1_01_s2'), findsNothing);

    CodeEditor editor = tester.widget<CodeEditor>(
      find.byKey(const ValueKey<String>('example_code_editor_mq1_01_s2')),
    );
    expect(editor.controller.text, 'print("Xin chào!")');
    final BoardController board = tester.widget<BoardView>(find.byType(BoardView)).controller;
    expect(board.plan?.characterId, 'nova');
    expect(board.beatCount, 4);

    final int energyBefore = services.energy.current;
    final List<String> events = <String>[];
    final StreamSubscription<StandardEvent> subscription =
        services.events.stream.listen((StandardEvent event) => events.add(event.type));
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
    await tester.tap(next);
    await tester.pump();
    expect(board.beatIndex, 3);
    expect(board.isWaitingForLearner, isFalse,
        reason: 'the learner may acknowledge the authored wait beat without advancing the lesson');
    expect(find.text('2/5'), findsOneWidget);
    expect(services.energy.current, energyBefore);
    ChunkyButton continueButton = tester.widget<ChunkyButton>(
      find.byKey(const ValueKey<String>('lesson_continue')),
    );
    expect(continueButton.onPressed, isNull,
        reason: 'board controls never call lesson Continue or change the lesson step');
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

    editor = tester.widget<CodeEditor>(find.byKey(const ValueKey<String>('example_code_editor_mq1_01_s2')));
    editor.controller.value = TextEditingValue(
      text: 'print("Xin chào!")',
      selection: const TextSelection.collapsed(offset: 5),
    );
    await tester.pump();
    expect(board.beatIndex, 3);
    expect(board.isWaitingForLearner, isTrue,
        reason: 'selection-only changes do not count as learner editing');

    await tester.ensureVisible(find.byKey(const ValueKey<String>('example_run')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('example_run')));
    await tester.pumpAndSettle();
    expect(find.text('Xin chào!'), findsWidgets);
    expect(board.beatIndex, 3);
    expect(board.isWaitingForLearner, isFalse,
        reason: 'running the example acknowledges the wait without changing the beat');
    expect(events, contains(EventTypes.codeRun));
    expect(events, isNot(contains(EventTypes.exerciseSolved)));
    expect(events, isNot(contains(EventTypes.lessonCompleted)));
    continueButton = tester.widget<ChunkyButton>(find.byKey(const ValueKey<String>('lesson_continue')));
    expect(continueButton.onPressed, isNotNull,
        reason: 'running the example keeps its pre-existing Continue behavior');

    await tester.ensureVisible(find.byKey(const ValueKey<String>('board_replay')));
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
    expect(find.byKey(const ValueKey<String>('board_code_mismatch')), findsOneWidget);
    expect(board.beatIndex, 3);
    expect(board.isWaitingForLearner, isFalse,
        reason: 'a text edit acknowledges wait without advancing the board');
    await tester.ensureVisible(find.byKey(const ValueKey<String>('example_run')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('example_run')));
    await tester.pumpAndSettle();
    expect(find.text('Đã sửa'), findsWidgets);
    expect(board.stepId, 'mq1_01_s2');
    expect(board.beatIndex, 3);
    expect(events, isNot(contains(EventTypes.exerciseSolved)));
    expect(events, isNot(contains(EventTypes.lessonCompleted)));

    await _finish(tester, services);
  });

  testWidgets('tutor sheet and locale changes preserve the lesson-owned board/editor state',
      (WidgetTester tester) async {
    final AppServices services = await _createServices(tester);
    await tester.runAsync(() => services.settings.setLang(PqLang.vi));
    final Lesson lesson = services.mainQuest.byId('mq1_03')!;
    await _mountLesson(tester, services, lesson);
    await _advanceStoryToExample(tester);
    await _waitForBoard(tester);

    final BoardView view = tester.widget<BoardView>(find.byType(BoardView));
    final BoardController board = view.controller;
    expect(board.plan?.characterId, 'pixel');
    expect(find.text('Pixel'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('lesson_board_authored_badge')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey<String>('board_next')));
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
    await tester.ensureVisible(find.byKey(const ValueKey<String>('example_run')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('example_run')));
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);

    final double scrollOffsetBeforeTutor = _lessonScrollOffset(tester);
    await tester.tap(find.byKey(const ValueKey<String>('lesson_tutor')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('tutor_close')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('tutor_close')));
    await tester.pumpAndSettle();

    final BoardController afterTutor = tester.widget<BoardView>(find.byType(BoardView)).controller;
    expect(identical(afterTutor, board), isTrue);
    expect(board.beatIndex, 1);
    expect(board.learner.note, 'test-only marker');
    expect(board.learner.strokes, <String>['test-only-stroke']);
    expect(editor.controller.text, 'print(10 + 2)');
    expect(editor.controller.selection, const TextSelection.collapsed(offset: 8));
    expect(editor.focusNode!.hasFocus, isTrue);
    expect(find.text('12'), findsOneWidget, reason: 'the last run result survives the tutor route');
    expect(_lessonScrollOffset(tester), closeTo(scrollOffsetBeforeTutor, 0.5));

    await tester.tap(find.byKey(const ValueKey<String>('lesson_tutor')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('tutor_close')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('tutor_close')));
    await tester.pumpAndSettle();
    expect(identical(tester.widget<BoardView>(find.byType(BoardView)).controller, board), isTrue);
    expect(board.beatIndex, 1);
    expect(board.learner.note, 'test-only marker');
    expect(board.learner.strokes, <String>['test-only-stroke']);
    expect(editor.controller.text, 'print(10 + 2)');
    expect(editor.controller.selection, const TextSelection.collapsed(offset: 8));
    expect(editor.focusNode!.hasFocus, isTrue);
    expect(find.text('12'), findsOneWidget);
    expect(_lessonScrollOffset(tester), closeTo(scrollOffsetBeforeTutor, 0.5));

    await tester.runAsync(() => services.settings.setLang(PqLang.en));
    await tester.pumpAndSettle();
    expect(board.locale, 'en');
    expect(board.beatIndex, 1);
    expect(find.text('Authored example'), findsOneWidget);
    expect(find.text('Join them and count'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(board.learner.note, 'test-only marker');
    expect(board.learner.strokes, <String>['test-only-stroke']);
    expect(editor.controller.text, 'print(10 + 2)');
    expect(editor.controller.selection, const TextSelection.collapsed(offset: 8));

    await tester.runAsync(() => services.settings.setLang(PqLang.vi));
    await tester.pumpAndSettle();
    expect(board.locale, 'vi');
    expect(board.beatIndex, 1);
    expect(find.text('Bảng soạn sẵn'), findsOneWidget);
    expect(find.text('Gộp lại và đếm'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(editor.controller.text, 'print(10 + 2)');
    expect(editor.controller.selection, const TextSelection.collapsed(offset: 8));

    await _finish(tester, services);
  });

  testWidgets('embedded board controls are hit-testable at both sizes in VI/EN, including 2x text',
      (WidgetTester tester) async {
    final AppServices services = await _createServices(tester);
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
      await _mountLesson(
        tester,
        services,
        services.mainQuest.byId('mq1_01')!,
        viewport: testCase.key,
      );
      await _advanceStoryToExample(tester);
      await _waitForBoard(tester);
      expect(find.byKey(const ValueKey<String>('lesson_board_authored_badge')), findsOneWidget);
      expect(find.text(testCase.value == PqLang.vi ? 'Bảng soạn sẵn' : 'Authored example'), findsOneWidget);
      expect(find.text('mq1_01_s2'), findsNothing);

      final BoardController board = tester.widget<BoardView>(find.byType(BoardView)).controller;
      final Finder next = find.byKey(const ValueKey<String>('board_next'));
      await tester.ensureVisible(next);
      await tester.pump();
      await tester.tap(next);
      await tester.pump();
      expect(board.beatIndex, 1, reason: '${testCase.key}/${testCase.value}: board control accepted a real hit');

      final Finder run = find.byKey(const ValueKey<String>('example_run'));
      await tester.ensureVisible(run);
      await tester.pump();
      await tester.tap(run);
      await tester.pumpAndSettle();
      final Finder continueButton = find.byKey(const ValueKey<String>('lesson_continue'));
      await tester.ensureVisible(continueButton);
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      expect(find.text('3/5'), findsOneWidget,
          reason: '${testCase.key}/${testCase.value}: existing lesson Continue remains reachable');
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(() => services.settings.setLang(PqLang.vi));
    await _mountLesson(
      tester,
      services,
      services.mainQuest.byId('mq1_01')!,
      viewport: const Size(360, 640),
      textScale: 2,
    );
    await _advanceStoryToExample(tester);
    await _waitForBoard(tester);
    expect(find.byKey(const ValueKey<String>('lesson_board_authored_badge')), findsOneWidget);
    expect(find.text('Bảng soạn sẵn'), findsOneWidget);
    final Finder nextAtTwoX = find.byKey(const ValueKey<String>('board_next'));
    await tester.ensureVisible(nextAtTwoX);
    await tester.tap(nextAtTwoX);
    await tester.pump();
    expect(tester.widget<BoardView>(find.byType(BoardView)).controller.beatIndex, 1);

    final Finder runAtTwoX = find.byKey(const ValueKey<String>('example_run'));
    await tester.ensureVisible(runAtTwoX);
    await tester.pump();
    await tester.tap(runAtTwoX);
    await _waitForContinueEnabled(tester);
    await tester.pumpAndSettle();

    final Finder continueAtTwoX = find.byKey(const ValueKey<String>('lesson_continue'));
    await tester.ensureVisible(continueAtTwoX);
    await tester.pump();
    await tester.tap(continueAtTwoX);
    await tester.pumpAndSettle();
    expect(find.text('3/5'), findsOneWidget,
        reason: 'Run enables Continue and both remain reachable at 360x640 with 2x text');
    expect(tester.takeException(), isNull);
    await _finish(tester, services);
  });

  testWidgets('unsupported ExampleStep keeps the existing read-only example UI without a blank board',
      (WidgetTester tester) async {
    final AppServices services = await _createServices(tester);
    await _mountLesson(tester, services, services.mainQuest.byId('mq1_02')!);
    await _advanceStoryToExample(tester);
    expect(find.byType(BoardView), findsNothing);
    expect(find.byKey(const ValueKey<String>('lesson_authored_board_mq1_02_s2')), findsNothing);
    expect(find.byKey(const ValueKey<String>('example_code_editor_mq1_02_s2')), findsNothing);
    expect(find.byKey(const ValueKey<String>('example_run')), findsOneWidget);
    await _finish(tester, services);
  });

  testWidgets('malformed authored assets show labeled fallback without blocking the lesson',
      (WidgetTester tester) async {
    final AppServices services = await _createServices(tester);
    final _CorruptBoardAssetBundle bundle = _CorruptBoardAssetBundle(rootBundle);
    await _mountLesson(tester, services, services.mainQuest.byId('mq1_01')!, bundle: bundle);
    await _advanceStoryToExample(tester);
    for (int i = 0; i < 30 && find.byKey(const ValueKey<String>('board_fallback')).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const ValueKey<String>('board_fallback')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('lesson_board_authored_badge')), findsOneWidget);
    expect(find.text('2/5'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _finish(tester, services);
  });

  testWidgets('late asset completion cannot apply to a step whose board owner was disposed',
      (WidgetTester tester) async {
    final AppServices services = await _createServices(tester);
    final Lesson lesson = services.mainQuest.byId('mq1_01')!;
    final Map<String, ByteData> authoredSources = await _preloadAuthoredAssetBytes(tester);
    final _GatedAssetBundle bundle = _GatedAssetBundle(rootBundle, authoredSources);
    addTearDown(bundle.release);
    await _mountLesson(tester, services, lesson, bundle: bundle);
    await _advanceStoryToExample(tester);
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('lesson_board_loading')), findsOneWidget,
        reason: 'asset load is intentionally held behind the test gate');

    await tester.tap(find.byKey(const ValueKey<String>('example_run')));
    await _waitForContinueEnabled(tester);
    await tester.tap(find.byKey(const ValueKey<String>('lesson_continue')));
    await tester.pumpAndSettle();
    expect(find.text('3/5'), findsOneWidget);
    expect(find.byType(BoardView), findsNothing);

    expect(bundle.deliveredAssetKeys, isEmpty,
        reason: 'the gate keeps both authored asset deliveries pending until after step disposal');
    bundle.release();
    await _waitForAuthoredAssetDelivery(tester, bundle);
    expect(find.byKey(const ValueKey<String>('lesson_authored_board_mq1_01_s2')), findsNothing);
    expect(find.byType(BoardView), findsNothing);
    expect(tester.takeException(), isNull);
    await _finish(tester, services);
  });

  testWidgets('late asset completion after leaving LessonScreen is ignored safely',
      (WidgetTester tester) async {
    final AppServices services = await _createServices(tester);
    final Map<String, ByteData> authoredSources = await _preloadAuthoredAssetBytes(tester);
    final _GatedAssetBundle bundle = _GatedAssetBundle(rootBundle, authoredSources);
    addTearDown(bundle.release);
    await _mountLesson(
      tester,
      services,
      services.mainQuest.byId('mq1_01')!,
      bundle: bundle,
    );
    await _advanceStoryToExample(tester);
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('lesson_board_loading')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(bundle.deliveredAssetKeys, isEmpty,
        reason: 'the gate keeps both authored asset deliveries pending until after unmount');
    bundle.release();
    await _waitForAuthoredAssetDelivery(tester, bundle);
    expect(find.byKey(const ValueKey<String>('lesson_authored_board_mq1_01_s2')), findsNothing);
    expect(find.byType(BoardView), findsNothing);
    expect(tester.takeException(), isNull,
        reason: 'late repository completion must not call setState/apply on a disposed lesson');
    await _finish(tester, services);
  });
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
  if (bundle != null) screen = DefaultAssetBundle(bundle: bundle, child: screen);
  await tester.pumpWidget(MaterialApp(
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child ?? const SizedBox.shrink(),
    ),
    home: AppScope(services: services, child: screen),
  ));
  await tester.pumpAndSettle(
    const Duration(milliseconds: 50),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 10),
  );
}

double _lessonScrollOffset(WidgetTester tester) {
  final Finder scrollable = find
      .descendant(
        of: find.byKey(const ValueKey<String>('step_scroll_1')),
        matching: find.byType(Scrollable),
      )
      .first;
  return tester.state<ScrollableState>(scrollable).position.pixels;
}

Future<void> _advanceStoryToExample(WidgetTester tester) async {
  expect(find.text('1/5'), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey<String>('lesson_continue')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.text('2/5'), findsOneWidget);
}

Future<void> _waitForBoard(WidgetTester tester) async {
  for (int i = 0; i < 100 && find.byKey(const ValueKey<String>('board_tutor_layer')).evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(find.byType(BoardView), findsOneWidget);
  expect(find.byKey(const ValueKey<String>('board_tutor_layer')), findsOneWidget);
}

Future<void> _waitForContinueEnabled(WidgetTester tester) async {
  final Finder continueFinder = find.byKey(const ValueKey<String>('lesson_continue'));
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
  expect(bundle.deliveredAssetKeys, containsAll(_GatedAssetBundle.authoredAssetKeys));
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<Map<String, ByteData>> _preloadAuthoredAssetBytes(WidgetTester tester) async {
  final Map<String, ByteData>? sources = await tester.runAsync(() async => <String, ByteData>{
        AuthoredBoardRepository.plansAssetKey:
            await rootBundle.load(AuthoredBoardRepository.plansAssetKey),
        AuthoredBoardRepository.copyAssetKey:
            await rootBundle.load(AuthoredBoardRepository.copyAssetKey),
      });
  return sources!;
}

Future<void> _finish(WidgetTester tester, AppServices services) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 100));
  services.dispose();
  tester.view.reset();
}

class _CorruptBoardAssetBundle extends CachingAssetBundle {
  _CorruptBoardAssetBundle(this.delegate);

  final AssetBundle delegate;

  @override
  Future<ByteData> load(String key) {
    if (key == 'assets/data/tutor_board_plans.v1.json') {
      return Future<ByteData>.value(ByteData.sublistView(Uint8List.fromList(utf8.encode('{bad json'))));
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

  Set<String> get deliveredAssetKeys => Set<String>.unmodifiable(_deliveredAssetKeys);

  Future<void> waitForAuthoredAssets() => _allAssetsDelivered.future;

  void release() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  Future<ByteData> load(String key) {
    if (!authoredAssetKeys.contains(key)) return delegate.load(key);
    final ByteData? bytes = authoredSources[key];
    if (bytes == null) {
      return Future<ByteData>.error(StateError('Preloaded authored bytes missing for $key'));
    }

    return _gate.future.then((_) => bytes).then((ByteData deliveredBytes) {
      _deliveredAssetKeys.add(key);
      if (_deliveredAssetKeys.containsAll(authoredAssetKeys) && !_allAssetsDelivered.isCompleted) {
        _allAssetsDelivered.complete();
      }
      return deliveredBytes;
    });
  }
}
