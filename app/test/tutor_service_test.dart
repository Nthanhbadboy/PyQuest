import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/core/settings_service.dart';
import 'package:pyquest/data/database/app_database.dart';
import 'package:pyquest/data/repositories/state_repositories.dart';
import 'package:pyquest/modules/tutor/offline_tutor.dart';
import 'package:pyquest/modules/tutor/tutor_config.dart';
import 'package:pyquest/modules/tutor/tutor_models.dart';
import 'package:pyquest/modules/tutor/tutor_prompt.dart';
import 'package:pyquest/modules/tutor/tutor_provider.dart';
import 'package:pyquest/modules/tutor/tutor_session.dart';
import 'package:pyquest/shared/characters/characters.dart';
import 'package:pyquest/shared/l10n/pq_l10n.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_helpers.dart';

/// A real HTTP server on loopback standing in for the provider relay.
///
/// These tests never touch the internet and never hold a credential: the
/// point is to prove the *shape* of what the app sends (no key, lesson
/// context only) and that every provider failure produces the labelled
/// offline answer instead of a fake AI answer.
class FakeRelay {
  FakeRelay(this._server) {
    _server.listen(_handle);
  }

  static Future<FakeRelay> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return FakeRelay(server);
  }

  final HttpServer _server;
  final List<Map<String, Object?>> requests = [];
  final List<Map<String, String>> headers = [];

  int status = 200;
  Object body = {
    'choices': [
      {'message': {'role': 'assistant', 'content': 'AI: bạn thử đổi số 3 thành 4 nhé.'}, 'finish_reason': 'stop'}
    ]
  };
  String rawBody = '';
  Duration delay = Duration.zero;

  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  int get callCount => requests.length;

  void _handle(HttpRequest req) async {
    try {
      final text = await utf8.decoder.bind(req).join();
      requests.add(jsonDecode(text) as Map<String, Object?>);
      final seen = <String, String>{};
      req.headers.forEach((name, values) => seen[name.toLowerCase()] = values.join(', '));
      headers.add(seen);
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      req.response.statusCode = status;
      req.response.headers.contentType = ContentType.json;
      req.response.write(rawBody.isNotEmpty ? rawBody : jsonEncode(body));
      await req.response.close();
    } catch (_) {
      // The client may have timed out and gone away; that is part of the test.
      try {
        await req.response.close();
      } catch (_) {}
    }
  }

  Future<void> stop() => _server.close(force: true);

  /// Every header/body string the app sent, for key-leak assertions.
  String get sentText => '${jsonEncode(requests)} ${jsonEncode(headers)}';
}

/// Dart has no string repetition operator; tests use this.
String repeated(String s, int times) => List.filled(times, s).join();

TutorContext context({int stepIndex = 2, int fails = 0, String? code, String? error}) => TutorContext(
      lessonId: 'mq1_05',
      lessonTitle: 'Biến và chiếc hộp',
      skill: 'Biến',
      summary: 'Bé học cách cất giá trị vào biến.',
      stepIndex: stepIndex,
      stepCount: 6,
      stepType: 'write',
      stepPrompt: 'In ra số 3 bằng biến.',
      expectedOutput: '3',
      lessonHint: 'Tạo biến rồi print biến đó.',
      learnerCode: code,
      lastError: error,
      fails: fails,
    );

TutorRequest request({String q = 'Vì sao code của mình không chạy?', PqLang lang = PqLang.vi, int fails = 0, int stepIndex = 2}) =>
    TutorRequest(question: q, context: context(stepIndex: stepIndex, fails: fails), lang: lang);

Future<TutorSession> sessionFor(
  FakeRelay relay, {
  Duration timeout = const Duration(seconds: 5),
  int maxRetries = 0,
  int dailyLimit = 10,
  FakeClock? clock,
}) async {
  final c = clock ?? FakeClock(DateTime(2026, 10, 15, 9));
  final db = await AppDatabase.open(factory: databaseFactoryFfiNoIsolate, path: inMemoryDatabasePath);
  final settings = SettingsService(SettingsRepository(db));
  await settings.load();
  final config = TutorConfig(
    endpoint: relay.baseUrl,
    model: 'gpt-4o-mini',
    requestTimeout: timeout,
    maxRetries: maxRetries,
    dailyQuestionLimit: dailyLimit,
  );
  final session = TutorSession(settings: settings, config: config, clock: c, provider: RemoteTutorProvider(config));
  await session.load();
  return session;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late FakeRelay relay;

  setUp(() async => relay = await FakeRelay.start());
  tearDown(() async => relay.stop());

  group('real provider path (HTTP, local stub)', () {
    test('sends an OpenAI-compatible chat request with no credential in it', () async {
      final session = await sessionFor(relay);
      final reply = await session.askAndRemember(request());

      expect(relay.callCount, 1);
      expect(reply.source, TutorSource.ai, reason: 'the AI is the primary path when an endpoint exists');
      expect(reply.text, contains('AI:'));
      expect(reply.usedQuota, isTrue);
      expect(session.quotaLeft, 9);

      final sent = relay.requests.single;
      expect(sent['model'], 'gpt-4o-mini');
      expect(sent['stream'], isFalse);
      final messages = (sent['messages'] as List).cast<Map>();
      expect(messages.first['role'], 'system');
      expect('${messages.first['content']}', contains('PyQuest'));
      expect(messages.last['role'], 'user');
      expect('${messages.last['content']}', contains('Vì sao code của mình không chạy?'));

      // The app must never ship or send a key: no auth header, no key-shaped string.
      final headerNames = relay.headers.single.keys.toList();
      expect(headerNames, isNot(contains('authorization')));
      expect(relay.sentText.toLowerCase(), isNot(contains('apikey')));
      expect(relay.sentText, isNot(contains('sk-')));
      expect(relay.sentText, isNot(contains('Bearer')));
      session.dispose();
    });

    test('joins list-style content parts and truncates a very long answer', () async {
      relay.body = {
        'choices': [
          {
            'message': {
              'content': [
                {'type': 'text', 'text': 'Phần một.'},
                {'type': 'text', 'text': 'Phần hai.'},
              ]
            },
            'finish_reason': 'stop'
          }
        ]
      };
      final session = await sessionFor(relay);
      final reply = await session.askAndRemember(request());
      expect(reply.text, 'Phần một.\nPhần hai.');

      relay.body = {
        'choices': [
          {'message': {'content': repeated('x', 5000)}, 'finish_reason': 'stop'}
        ]
      };
      final long = await session.askAndRemember(request());
      expect(long.text.length, lessThanOrEqualTo(session.config.maxAnswerChars + 1));
      expect(long.text, endsWith('…'));
      session.dispose();
    });

    test('retries a server error, then falls back and does not spend quota', () async {
      relay.status = 500;
      final session = await sessionFor(relay, maxRetries: 1);
      final reply = await session.askAndRemember(request());

      expect(relay.callCount, 2, reason: 'one retry for a retryable failure');
      expect(reply.source, TutorSource.offlineAfterError);
      expect(reply.failKind, TutorFailKind.server);
      expect(reply.usedQuota, isFalse);
      expect(session.quotaLeft, session.quotaLimit, reason: 'a failed AI call must not cost a question');
      expect(reply.text, isNotEmpty);
      session.dispose();
    });

    test('rate limit is reported as busy, not retried', () async {
      relay.status = 429;
      final session = await sessionFor(relay, maxRetries: 2);
      final reply = await session.askAndRemember(request());
      expect(relay.callCount, 1);
      expect(reply.failKind, TutorFailKind.rateLimited);
      expect(reply.source, TutorSource.offlineAfterError);
      session.dispose();
    });

    test('timeout, malformed JSON, empty answer and safety block all fall back honestly', () async {
      final cases = <String, Future<TutorFailKind?> Function()>{
        'timeout': () async {
          relay.delay = const Duration(milliseconds: 500);
          final session = await sessionFor(relay, timeout: const Duration(milliseconds: 120));
          final r = await session.askAndRemember(request());
          session.dispose();
          return r.failKind;
        },
        'malformed': () async {
          relay.rawBody = 'not json at all';
          final session = await sessionFor(relay);
          final r = await session.askAndRemember(request());
          session.dispose();
          return r.failKind;
        },
        'empty': () async {
          relay.body = {'choices': [{'message': {'content': '   '}, 'finish_reason': 'stop'}]};
          final session = await sessionFor(relay);
          final r = await session.askAndRemember(request());
          session.dispose();
          return r.failKind;
        },
        'filtered': () async {
          relay.body = {'choices': [{'message': {'content': 'hi'}, 'finish_reason': 'content_filter'}]};
          final session = await sessionFor(relay);
          final r = await session.askAndRemember(request());
          session.dispose();
          return r.failKind;
        },
      };
      for (final entry in cases.entries) {
        relay.delay = Duration.zero;
        relay.rawBody = '';
        relay.status = 200;
        relay.body = {'choices': [{'message': {'content': 'ok'}, 'finish_reason': 'stop'}]};
        final kind = await entry.value();
        expect(kind, isNotNull, reason: '${entry.key} must be reported as a failure');
        expect(kind!.isRetryable || kind == TutorFailKind.empty || kind == TutorFailKind.blocked || kind == TutorFailKind.badResponse, isTrue);
      }
    });
  });

  group('offline fallback is never presented as AI', () {
    test('no endpoint configured means no provider and an explicit offline source', () async {
      final db = await AppDatabase.open(factory: databaseFactoryFfiNoIsolate, path: inMemoryDatabasePath);
      final settings = SettingsService(SettingsRepository(db));
      await settings.load();
      const config = TutorConfig(endpoint: '');
      final session = TutorSession(settings: settings, config: config, clock: FakeClock(DateTime(2026, 10, 15, 9)));
      await session.load();

      expect(session.hasAi, isFalse);
      final reply = await session.askAndRemember(request());
      expect(reply.source, TutorSource.offlineNoEndpoint);
      expect(reply.isAi, isFalse);
      expect(reply.text, isNotEmpty);
      expect(session.quotaLeft, session.quotaLimit, reason: 'offline answers are free');
      session.dispose();
    });

    test('AI and offline answers carry different labels', () async {
      final session = await sessionFor(relay);
      final ai = await session.askAndRemember(request());
      relay.status = 500;
      final offline = await session.askAndRemember(request());

      expect(ai.source.label(PqStrings.vi), PqStrings.vi.labelAiWritten);
      expect(offline.source.label(PqStrings.vi), PqStrings.vi.labelOffline);
      expect(ai.source.label(PqStrings.vi), isNot(offline.source.label(PqStrings.vi)));
      for (final s in TutorSource.values) {
        expect(s.label(PqStrings.vi), isNotEmpty);
        expect(s.label(PqStrings.en), isNotEmpty);
      }
      session.dispose();
    });

    test('used-up quota falls back offline and the provider is not called again', () async {
      final session = await sessionFor(relay, dailyLimit: 1);
      final first = await session.askAndRemember(request());
      expect(first.source, TutorSource.ai);
      expect(session.quotaEmpty, isTrue);

      final second = await session.askAndRemember(request(q: 'Còn cách nào khác không?'));
      expect(relay.callCount, 1, reason: 'no AI call once the daily limit is reached');
      expect(second.source, TutorSource.offlineQuota);
      expect(second.usedQuota, isFalse);
      session.dispose();
    });

    test('quota rolls over on the next local day', () async {
      final clock = FakeClock(DateTime(2026, 10, 15, 23, 30));
      final session = await sessionFor(relay, dailyLimit: 1, clock: clock);
      await session.askAndRemember(request());
      expect(session.quotaEmpty, isTrue);

      clock.advance(const Duration(hours: 1));
      await session.load();
      expect(session.quotaLeft, 1, reason: 'a new local day restores the AI questions');
      final reply = await session.askAndRemember(request());
      expect(reply.source, TutorSource.ai);
      session.dispose();
    });

    test('the free hint ladder never spends quota and stays offline', () async {
      final session = await sessionFor(relay, dailyLimit: 1);
      final hint = await session.rememberHint(request(fails: 2));
      expect(hint.hintLevel, TutorHintLevel.structure);
      expect(hint.source, TutorSource.offline);
      expect(relay.callCount, 0);
      expect(session.quotaUsed, 0, reason: 'hints are part of the lesson, not the AI quota');

      final last = await session.rememberHint(request(fails: 9, stepIndex: 6));
      expect(last.hintLevel, TutorHintLevel.full);
      session.dispose();
    });
  });

  group('prompt privacy and teaching rules', () {
    test('personal data inside a child question is redacted before sending', () {
      final dirty = 'Mình là Minh, email minh.nguyen@example.com, số 0912345678 nhé';
      final clean = TutorPrompt.sanitiseQuestion(dirty, 500);
      expect(clean, isNot(contains('minh.nguyen@example.com')));
      expect(clean, isNot(contains('0912345678')));
      expect(clean, contains('Mình là Minh'));
    });

    test('the request carries lesson context only — no identity fields', () {
      final messages = TutorPrompt.build(
        TutorRequest(
          question: 'Giúp mình với',
          context: context(code: 'a = 3\nprint(a)'),
          lang: PqLang.vi,
          character: CharacterId.bit,
        ),
        const TutorConfig(endpoint: 'https://relay.example.com'),
      );
      final all = messages.map((m) => m.content).join('\n');
      expect(all, contains('Biến và chiếc hộp'));
      expect(all, contains('a = 3'));
      expect(all, contains('print(a)'));
      expect(all.toLowerCase(), isNot(contains('học sinh:')));
      expect(all.toLowerCase(), isNot(contains('tuổi')));
      expect(all, isNot(contains('@')));
      expect(all, contains('Bit —'), reason: 'the character persona is part of the system prompt');
      expect(all, contains('cannot run code'));
    });

    test('a solution is only allowed once the child reached a late step', () {
      final early = TutorPrompt.build(request(stepIndex: 2), const TutorConfig(endpoint: 'https://relay.example.com'));
      final late = TutorPrompt.build(request(stepIndex: 6), const TutorConfig(endpoint: 'https://relay.example.com'));
      expect(early.first.content, contains('Do NOT give the complete solution'));
      expect(late.first.content, contains('you may explain the complete solution'));
    });

    test('long code and long questions are capped', () {
      final cfg = const TutorConfig(endpoint: 'https://relay.example.com', maxQuestionChars: 40, maxLessonContextChars: 600);
      final messages = TutorPrompt.build(
        TutorRequest(question: repeated('x', 500), context: context(code: repeated('y = 1\n', 400)), lang: PqLang.vi),
        cfg,
      );
      expect(messages.last.content.length, lessThan(cfg.maxLessonContextChars + cfg.maxQuestionChars + 400));
      expect(messages.last.content, contains('đã bỏ bớt'));
    });
  });

  group('history', () {
    test('the transcript survives a restart and corrupt data does not break loading', () async {
      final session = await sessionFor(relay);
      await session.askAndRemember(request(q: 'Câu hỏi của bé'));
      await session.persistHistory();
      final stored = session.settings.raw(TutorSession.keyHistory);
      expect(stored, isNotNull);
      expect(stored, contains('Câu hỏi của bé'));

      final restored = TutorSession(
        settings: session.settings,
        config: session.config,
        clock: FakeClock(DateTime(2026, 10, 15, 9)),
        provider: FailingTutorProvider(TutorFailKind.network),
      );
      await restored.load();
      expect(restored.history.length, 1);
      expect(restored.history.first.answer, isNotEmpty);

      await session.settings.setRaw(TutorSession.keyHistory, '{not a list');
      await restored.load();
      expect(restored.history, isEmpty, reason: 'unreadable history is dropped, not fatal');
      session.dispose();
      restored.dispose();
    });

    test('offline tutor answers from the lesson, in both languages', () {
      const offline = OfflineTutor();
      for (final lang in PqLang.values) {
        final text = offline.answer(TutorRequest(question: 'Giải thích giúp mình', context: context(fails: 2), lang: lang));
        expect(text, isNotEmpty);
        expect(text, contains('3'), reason: 'the expected output of the step is used');
      }
      final explained = offline.answer(TutorRequest(question: 'Giải thích giúp mình', context: context(), lang: PqLang.vi));
      final hinted = offline.answer(TutorRequest(question: 'Cho mình gợi ý', context: context(), lang: PqLang.vi));
      expect(explained, isNot(hinted), reason: 'a hint is not the same as an explanation');
    });
  });
}
