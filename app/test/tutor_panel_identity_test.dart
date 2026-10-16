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
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUpAll(loadAppFonts);

  const String answer = 'Bạn đã dùng biến đúng rồi.\n\n```python\nten = "Bi"\nprint(ten)\n```';

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
    tester.view.physicalSize = const Size(1080, 2100);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: 620,
            width: 360,
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
    expect(find.text(greeting), findsOneWidget, reason: 'the tutor greets the learner');
    expect(find.text('Bé'), findsNothing, reason: 'nobody has spoken yet');
    expect(find.text('Nova'), findsWidgets, reason: 'the greeting is labelled with the speaker');
  });

  testWidgets('a typed question is the child’s line and the answer is the tutor’s', (tester) async {
    final services = await boot(tester, withAi: true);
    await openPanel(tester, services);

    await tester.enterText(find.byKey(const ValueKey('tutor_input')), 'Vì sao cần biến?');
    await tapAndSettle(tester, find.byKey(const ValueKey('tutor_send')), wait: const Duration(milliseconds: 700));

    expect(find.text('Bé'), findsOneWidget, reason: 'one child line');
    expect(find.textContaining('Vì sao cần biến?'), findsWidgets);
    expect(find.textContaining('Do AI soạn'), findsOneWidget, reason: 'the answer says where it came from');

    // The greeting is still there, still the tutor's, and still only once.
    final greeting = CastDialogue.line(CharacterId.nova, DialogueMoment.greet, PqLang.vi);
    expect(find.text(greeting), findsOneWidget);
  });

  testWidgets('an offline answer is never shown as an AI answer', (tester) async {
    final services = await boot(tester);
    await openPanel(tester, services);

    await tester.enterText(find.byKey(const ValueKey('tutor_input')), 'Biến là gì?');
    await tapAndSettle(tester, find.byKey(const ValueKey('tutor_send')), wait: const Duration(milliseconds: 700));

    expect(find.textContaining(PqStrings.vi.labelOffline), findsWidgets);
    expect(find.textContaining(PqStrings.vi.labelAiWritten), findsNothing);
    // The child is still the only one whose name is «Bé».
    expect(find.text('Bé'), findsOneWidget);
  });

  testWidgets('the voice sheet keeps the speaking character as the only identity', (tester) async {
    final services = await boot(tester);
    await openPanel(tester, services, speakingAs: CharacterId.kai);

    expect(find.text('Kai'), findsWidgets);
    // Voice controls are there, and starting a session without a key reports
    // honestly instead of pretending the tutor is speaking.
    await tapAndSettle(tester, find.byKey(const ValueKey('tutor_gemini_live_voice')), wait: const Duration(milliseconds: 400));
    expect(find.textContaining('GEMINI_API_KEY'), findsOneWidget);
    expect(find.text('Bé'), findsNothing);
  });
}
