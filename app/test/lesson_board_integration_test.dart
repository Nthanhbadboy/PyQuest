import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/app/app_scope.dart';
import 'package:pyquest/app/app_services.dart';
import 'package:pyquest/core/events.dart';
import 'package:pyquest/modules/main_quest/lesson_screen.dart';
import 'package:pyquest/modules/main_quest/quest_models.dart';
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

    await tester.ensureVisible(find.byKey(const ValueKey<String>('example_run')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('example_run')));
    await tester.pumpAndSettle();
    expect(find.text('Xin chào!'), findsWidgets);
    expect(events, contains(EventTypes.codeRun));
    expect(events, isNot(contains(EventTypes.exerciseSolved)));
    expect(events, isNot(contains(EventTypes.lessonCompleted)));
    continueButton = tester.widget<ChunkyButton>(find.byKey(const ValueKey<String>('lesson_continue')));
    expect(continueButton.onPressed, isNotNull,
        reason: 'running the example keeps its pre-existing Continue behavior');

    editor = tester.widget<CodeEditor>(find.byKey(const ValueKey<String>('example_code_editor_mq1_01_s2')));
    editor.controller.text = 'print("Đã sửa")';
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('board_code_mismatch')), findsOneWidget);
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

  testWidgets('embedded lesson board and controls stay reachable at 360x640 with 2x text',
      (WidgetTester tester) async {
    final AppServices services = await _createServices(tester);
    await _mountLesson(
      tester,
      services,
      services.mainQuest.byId('mq1_01')!,
      viewport: const Size(360, 640),
      textScale: 2,
    );
    await _advanceStoryToExample(tester);
    await _waitForBoard(tester);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const ValueKey<String>('board_next')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey<String>('lesson_continue')));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('board_next')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('lesson_continue')), findsOneWidget);
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
    final _GatedAssetBundle bundle = _GatedAssetBundle(rootBundle);
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

    bundle.release();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('lesson_authored_board_mq1_01_s2')), findsNothing);
    expect(find.byType(BoardView), findsNothing);
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
  await tester.pumpAndSettle(const Duration(milliseconds: 50), const Duration(seconds: 10));
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
  _GatedAssetBundle(this.delegate);

  final AssetBundle delegate;
  final Completer<void> _gate = Completer<void>();

  void release() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  Future<ByteData> load(String key) async {
    if (key == 'assets/data/tutor_board_plans.v1.json' ||
        key == 'assets/data/tutor_board_authored-copy.v1.json') {
      await _gate.future;
    }
    return delegate.load(key);
  }
}
