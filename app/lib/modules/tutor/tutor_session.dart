import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/clock.dart';
import '../../core/settings_service.dart';
import 'offline_tutor.dart';
import 'tutor_config.dart';
import 'tutor_models.dart';
import 'tutor_prompt.dart';
import 'tutor_provider.dart';

/// Owns the conversation with the tutor for the whole app.
///
/// Responsibilities kept deliberately small and testable:
/// * decide AI vs offline before every question (never fake an AI answer);
/// * count today's AI questions and reset them at local midnight;
/// * keep a bounded history in `settings` so the panel reopens with context;
/// * keep the prompt builder's two promises (privacy, honest teaching).
///
/// Running code, lesson hints and mini-games never go through here, so they
/// are never limited by the AI quota.
class TutorSession extends ChangeNotifier {
  TutorSession({
    required this.settings,
    required this.config,
    required this.clock,
    TutorProvider? provider,
    OfflineTutor offline = const OfflineTutor(),
  })  : _provider = provider ?? (config.hasEndpoint ? RemoteTutorProvider(config) : null),
        _offline = offline;

  final SettingsService settings;
  final TutorConfig config;
  final Clock clock;
  final TutorProvider? _provider;
  final OfflineTutor _offline;

  static const String keyQuotaDay = 'tutor_quota_day';
  static const String keyQuotaUsed = 'tutor_quota_used';
  static const String keyHistory = 'tutor_history';

  /// Answers are stored trimmed: history is for reading back, not archiving.
  static const int storedAnswerChars = 1200;

  List<TutorTurn> _history = const [];
  bool _busy = false;
  int _quotaUsed = 0;
  TutorFailKind? _lastFail;
  DateTime? _lastFailAt;

  /// True while a provider call is in flight (the panel disables Send).
  bool get busy => _busy;

  /// True when this build can really reach an AI provider.
  bool get hasAi => config.enabled && config.hasEndpoint && _provider != null;

  /// Why the last AI call failed — for the honest note under the answer.
  TutorFailKind? get lastFail => _lastFail;
  DateTime? get lastFailAt => _lastFailAt;

  List<TutorTurn> get history => List.unmodifiable(_history);

  int get quotaLimit => config.dailyQuestionLimit;
  int get quotaUsed => _quotaUsed;
  int get quotaLeft => (quotaLimit - _quotaUsed).clamp(0, quotaLimit);
  bool get quotaEmpty => quotaLeft <= 0;
  String get todayKey => localDayKey(clock.now());

  /// Loads quota + history from settings and rolls the quota over if the local
  /// day changed while the app was closed.
  Future<void> load() async {
    final today = todayKey;
    if (settings.raw(keyQuotaDay) != today) {
      _quotaUsed = 0;
      await settings.setRaw(keyQuotaDay, today);
      await settings.setRaw(keyQuotaUsed, '0');
    } else {
      _quotaUsed = int.tryParse(settings.raw(keyQuotaUsed) ?? '0') ?? 0;
      if (_quotaUsed < 0 || _quotaUsed > quotaLimit) _quotaUsed = _quotaUsed.clamp(0, quotaLimit);
    }
    _history = _decodeHistory(settings.raw(keyHistory));
    notifyListeners();
  }

  /// Answers a question from the AI when it is configured and has quota left,
  /// otherwise from the offline tutor, and records the exchange in history.
  Future<TutorReply> askAndRemember(TutorRequest request) async {
    await load();
    final reply = await _answer(request);
    _remember(request, reply);
    await persistHistory();
    notifyListeners();
    return reply;
  }

  /// Answering without touching the history (used by tests and diagnostics).
  Future<TutorReply> ask(TutorRequest request) async {
    await load();
    return _answer(request);
  }

  Future<TutorReply> _answer(TutorRequest request) async {
    final question = request.question.trim();
    if (question.isEmpty) {
      // Nothing to ask: answer from the lesson itself, offline, free of charge.
      return _offlineReply(request, source: TutorSource.offline);
    }
    if (!hasAi) {
      return _offlineReply(request, source: TutorSource.offlineNoEndpoint);
    }
    if (quotaEmpty) {
      return _offlineReply(request, source: TutorSource.offlineQuota);
    }

    _busy = true;
    notifyListeners();
    final started = clock.now();
    try {
      final text = await _provider!.complete(
        TutorChatRequest(
          model: config.model,
          messages: TutorPrompt.build(request, config),
          temperature: config.temperature,
          timeout: config.requestTimeout,
        ),
      );
      final latency = clock.now().difference(started);
      await _useQuota();
      _lastFail = null;
      return TutorReply(
        text: text,
        source: TutorSource.ai,
        character: request.character,
        latency: latency,
        usedQuota: true,
        attempts: 1,
      );
    } on TutorProviderException catch (e) {
      _lastFail = e.kind;
      _lastFailAt = clock.now();
      debugPrint('Tutor provider failed: ${e.kind.name} ${e.detail}');
      return _offlineReply(
        request,
        source: e.kind == TutorFailKind.notConfigured
            ? TutorSource.offlineNoEndpoint
            : TutorSource.offlineAfterError,
        failKind: e.kind,
        latency: clock.now().difference(started),
      );
    } catch (e) {
      // Nothing coming back from a provider may ever break a lesson.
      _lastFail = TutorFailKind.server;
      _lastFailAt = clock.now();
      debugPrint('Tutor provider error: $e');
      return _offlineReply(
        request,
        source: TutorSource.offlineAfterError,
        failKind: TutorFailKind.server,
        latency: clock.now().difference(started),
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// The free hint ladder: always local, never counted against the AI quota,
  /// never a full solution before the late steps.
  TutorReply hintLadder(TutorRequest request) {
    final level = _offline.levelFor(request.context);
    return TutorReply(
      text: _offline.hint(level, request.context, request.lang),
      source: TutorSource.offline,
      character: request.character,
      hintLevel: level,
    );
  }

  /// Same as [hintLadder] but kept in the transcript.
  Future<TutorReply> rememberHint(TutorRequest request) async {
    await load();
    final reply = hintLadder(request);
    _remember(request, reply);
    await persistHistory();
    notifyListeners();
    return reply;
  }

  Future<void> clearHistory() async {
    _history = const [];
    await settings.setRaw(keyHistory, '[]');
    notifyListeners();
  }

  TutorReply _offlineReply(
    TutorRequest request, {
    required TutorSource source,
    TutorFailKind? failKind,
    Duration latency = Duration.zero,
  }) =>
      TutorReply(
        text: _offline.answer(request),
        source: source,
        character: request.character,
        failKind: failKind,
        latency: latency,
      );

  Future<void> _useQuota() async {
    _quotaUsed = (_quotaUsed + 1).clamp(0, quotaLimit);
    await settings.setRaw(keyQuotaDay, todayKey);
    await settings.setRaw(keyQuotaUsed, '$_quotaUsed');
  }

  void _remember(TutorRequest request, TutorReply reply) {
    if (reply.text.trim().isEmpty) return;
    final turns = [
      ..._history,
      TutorTurn(
        question: reply.hintLevel == null
            ? TutorPrompt.sanitiseQuestion(request.question, config.maxQuestionChars)
            : request.context.stepPrompt,
        answer: reply.text,
        source: reply.source,
        lessonId: request.context.lessonId,
        at: clock.now(),
        character: reply.character,
        hintLevel: reply.hintLevel,
      ),
    ];
    final max = config.historyMaxTurns;
    _history = turns.length > max ? turns.sublist(turns.length - max) : turns;
  }

  /// Persisting is best effort: losing the transcript must never break a lesson.
  Future<void> persistHistory() async {
    final payload = [
      for (final t in _history)
        {
          ...t.toJson(),
          if (t.answer.length > storedAnswerChars) 'a': t.answer.substring(0, storedAnswerChars),
        },
    ];
    await settings.setRaw(keyHistory, jsonEncode(payload));
  }

  List<TutorTurn> _decodeHistory(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final turns = <TutorTurn>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final turn = TutorTurn.fromJson(item.cast<String, dynamic>());
        if (turn != null) turns.add(turn);
      }
      return turns;
    } catch (e) {
      debugPrint('Tutor history unreadable, starting fresh: $e');
      return const [];
    }
  }

  @override
  void dispose() {
    final provider = _provider;
    if (provider is RemoteTutorProvider) provider.dispose();
    super.dispose();
  }
}
