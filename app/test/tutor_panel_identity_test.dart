import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/app/app_services.dart';
import 'package:pyquest/modules/tutor/tutor_config.dart';
import 'package:pyquest/modules/tutor/tutor_models.dart';
import 'package:pyquest/modules/tutor/tutor_panel.dart';
import 'package:pyquest/modules/tutor/tutor_provider.dart';
import 'package:pyquest/shared/characters/characters.dart';
import 'package:pyquest/shared/characters/dialogue.dart';
import 'package:pyquest/shared/l10n/pq_l10n.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_helpers.dart';

/// Who the tutor panel says is speaking.
///
/// The report this reproduces: the assistant's greeting «Chào bạn!» was shown
/// as “Bé: Chào bạn”. The panel had no message model for a spoken turn — the
/// speaker was a text prefix, and the first line the microphone produced (the
/// tutor's own voice, heard back through the loudspeaker) became the child's
/// sentence. Here the role is data, so the greeting belongs to the tutor and
/// the child's question belongs to the child.
///
/// These tests drive the composer with the keyboard action rather than a tap:
/// what is under scrutiny is the label on each line, not whether a hit test
/// lands on a chunky button (the render suite covers tapping the real sheet).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUpAll(loadAppFonts);

  const String answer = 'Bạn đã dùng biến đúng rồi.\n\n```python\nten = "Bi"\nprint(ten)\n```';

  /// Every string the panel paints, including rich spans.
  List<String> onScreen(WidgetTester tester) => tester
      .widgetList<RichText>(find.byType(RichText))
      .map((RichText w) => w.text.toPlainText())
      .toList();

  /// Sends through the composer. The keyboard action is the primary path and
  /// the button is pressed as well; `_send` clears the field, so the second
  /// trigger sees an empty question and returns without duplicating the line.
  Future<void> typeAndSend(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const ValueKey('tutor_input')), text);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await pumpFor(tester, const Duration(milliseconds: 120));
    await tester.tap(find.byKey(const ValueKey('tutor_send')), warnIfMissed: false);
    await pumpFor(tester, const Duration(milliseconds: 900));
  }

  Future<AppServices> boot(WidgetTester tester, {bool withAi = false}) async {
    final services = (await tester.runAsync(() => AppServices.create(
          bundle: rootBundle,
          databaseFactory: databaseFactoryFfiNoIsolate,
          databasePath: inMemoryDatabasePath,
          clock: FakeClock(DateTime(2026, 10, 16, 9)),
          audioEnabled: false,
          startSessionTimer: false,
          tutorConfig: withAi ? const TutorConfig(endpoint: 'https://relay.invalid') : null,
          tutorProvider: withAi ? const StaticTutorProvider(answer) : null,
        )))!;
    addTearDown(() => services.dispose());
    return services;
  }

  Future<void> openPanel(WidgetTester tester, AppServices services, {CharacterId? speakingAs}) async {
    tester.view.physicalSize = const Size(1200, 4200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: 1360,
            width: 400,
            child: TutorPanel(
              services: services,
              tutorContext: const TutorContext(
                lessonId: 'mq1_04',
                lessonTitle: 'Biến đầu tiên',
                skill: 'variables',
                stepIndex: 2,
                stepCount: 5,
                stepType: 'exercise',
                stepPrompt: 'In ra tên của em.',
              ),
              character: speakingAs ?? CharacterId.nova,
            ),
          ),
        ),
      ),
    ));
    await pumpFor(tester, const Duration(milliseconds: 400));
  }

  testWidgets('the opening greeting belongs to the tutor, not to the child', (tester) async {
    final services = await boot(tester);
    await openPanel(tester, services);

    final greeting = CastDialogue.line(CharacterId.nova, DialogueMoment.greet, PqLang.vi);
    final said = onScreen(tester);
    expect(said.where((String t) => t == greeting), hasLength(1), reason: 'the tutor greets the learner once');
    expect(said.contains(PqStrings.vi.childLabel), isFalse, reason: 'nobody has spoken yet');
    expect(said.any((String t) => t.contains('Nova')), isTrue, reason: 'the greeting is labelled with the speaker');
  });

  testWidgets('a typed question is the child’s line and the answer is the tutor’s', (tester) async {
    final services = await boot(tester, withAi: true);
    await openPanel(tester, services);

    await typeAndSend(tester, 'Vì sao cần biến?');

    final said = onScreen(tester);
    // Exactly one line wears the learner's name, and it is the question.
    expect(said.where((String t) => t == PqStrings.vi.childLabel), hasLength(1));
    expect(said.any((String t) => t.contains('Vì sao cần biến?')), isTrue);
    expect(said.any((String t) => t.contains('Bạn đã dùng biến đúng rồi.')), isTrue);
    expect(
      said.any((String t) => t.contains(PqStrings.vi.labelAiWritten) && t.contains('Nova')),
      isTrue,
      reason: 'the answer says who wrote it and where it came from',
    );

    // The greeting is still there, still the tutor's, and still only once.
    final greeting = CastDialogue.line(CharacterId.nova, DialogueMoment.greet, PqLang.vi);
    expect(said.where((String t) => t == greeting), hasLength(1));
    expect(said.any((String t) => t.contains('Bé') && t.contains(greeting)), isFalse,
        reason: 'the greeting is never re-labelled as something the child said');
  });

  testWidgets('an offline answer is never shown as an AI answer', (tester) async {
    final services = await boot(tester);
    await openPanel(tester, services);

    await typeAndSend(tester, 'Biến là gì?');

    final said = onScreen(tester);
    expect(said.any((String t) => t.contains(PqStrings.vi.labelOffline)), isTrue,
        reason: 'the panel must say the answer came from the offline tutor');
    expect(said.any((String t) => t.contains(PqStrings.vi.labelAiWritten)), isFalse);
    // The learner is still the only one named «Bé», and still has one line.
    expect(said.where((String t) => t == PqStrings.vi.childLabel), hasLength(1),
        reason: 'the typed question is one line by the child');
  });

  testWidgets('the sheet offers a voice persona without inventing a speaker', (tester) async {
    final services = await boot(tester);
    await openPanel(tester, services, speakingAs: CharacterId.kai);

    final said = onScreen(tester);
    expect(said.any((String t) => t.contains('Kai')), isTrue, reason: 'the tutor that will speak is the one named');
    expect(said.any((String t) => t.contains('Lumi')), isTrue, reason: 'the persona can be chosen before speaking');
    expect(find.byKey(const ValueKey('tutor_gemini_live_voice')), findsOneWidget);
    // Nothing has been said by the learner, so no line may wear the child's name.
    expect(said.contains(PqStrings.vi.childLabel), isFalse);
    expect(said.any((String t) => t.contains('GEMINI_API_KEY')), isFalse);
  });
}
