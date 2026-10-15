import 'dart:convert';

import 'package:flutter/services.dart';

/// Everything the AI tutor needs to talk to a provider, loaded from
/// `assets/config/ai_tutor_config.json`.
///
/// The client never holds an API key: [endpoint] must be a relay that keeps
/// the key on the server. A build can point at its own relay with
/// `--dart-define=AI_TUTOR_ENDPOINT=https://relay.example.com`. When no
/// endpoint is configured the app does not pretend: it uses the offline
/// rule-based tutor and says so.
class TutorConfig {
  const TutorConfig({
    this.enabled = true,
    this.endpoint = '',
    this.model = 'gpt-4o-mini',
    this.requestTimeout = const Duration(seconds: 20),
    this.maxRetries = 2,
    this.dailyQuestionLimit = 10,
    this.maxLessonContextChars = 12000,
    this.maxQuestionChars = 500,
    this.maxAnswerChars = 900,
    this.minStepForDirectAnswer = 5,
    this.historyMaxTurns = 40,
    this.temperature = 0.4,
  });

  final bool enabled;

  /// Relay base URL, empty when this build has no AI tutor.
  final String endpoint;
  final String model;
  final Duration requestTimeout;
  final int maxRetries;

  /// How many AI questions one learner may ask per local day. Running code,
  /// hints and lessons are never limited — only the AI conversation is.
  final int dailyQuestionLimit;
  final int maxLessonContextChars;
  final int maxQuestionChars;
  final int maxAnswerChars;

  /// From this step onwards (1-based) the tutor may explain the whole
  /// solution; before that it must guide with questions and partial hints.
  final int minStepForDirectAnswer;
  final int historyMaxTurns;
  final double temperature;

  static const String assetPath = 'assets/config/ai_tutor_config.json';

  /// Build-time override, e.g. `flutter build apk --dart-define=AI_TUTOR_ENDPOINT=...`.
  static const String endpointOverride = String.fromEnvironment('AI_TUTOR_ENDPOINT');

  /// Used when the asset is missing or unreadable: no AI, offline tutor only.
  static const TutorConfig offlineOnly = TutorConfig(endpoint: '', enabled: false);

  static Future<TutorConfig> load(AssetBundle bundle) async {
    try {
      final text = await bundle.loadString(assetPath);
      return TutorConfig.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (_) {
      // A broken config must never break the game: no AI, offline tutor only.
      return offlineOnly;
    }
  }

  factory TutorConfig.fromJson(Map<String, dynamic> j) {
    String str(String key, String fallback) => (j[key] as String?)?.trim() ?? fallback;
    int num_(String key, int fallback) => (j[key] as num?)?.toInt() ?? fallback;
    final endpoint = endpointOverride.trim().isNotEmpty ? endpointOverride.trim() : str('endpoint', '');
    return TutorConfig(
      enabled: j['enabled'] as bool? ?? true,
      endpoint: endpoint,
      model: str('model', 'gpt-4o-mini'),
      requestTimeout: Duration(seconds: num_('request_timeout_seconds', 20).clamp(5, 60)),
      maxRetries: num_('max_retries', 2).clamp(0, 4),
      dailyQuestionLimit: num_('daily_question_limit', 10).clamp(0, 200),
      maxLessonContextChars: num_('max_lesson_context_chars', 12000).clamp(500, 60000),
      maxQuestionChars: num_('max_question_chars', 500).clamp(40, 2000),
      maxAnswerChars: num_('max_answer_chars', 900).clamp(200, 4000),
      minStepForDirectAnswer: num_('min_step_for_direct_answer', 5).clamp(1, 99),
      historyMaxTurns: num_('history_max_turns', 40).clamp(4, 200),
      temperature: ((j['temperature'] as num?)?.toDouble() ?? 0.4).clamp(0.0, 1.5),
    );
  }

  /// True only when this build can really reach an AI provider.
  bool get hasEndpoint => enabled && endpoint.isNotEmpty;

  /// The full chat-completions URL. Accepts either a base URL
  /// (`https://relay.example.com`) or a complete path.
  Uri? get chatUri {
    if (!hasEndpoint) return null;
    final raw = endpoint.endsWith('/') ? endpoint.substring(0, endpoint.length - 1) : endpoint;
    final path = raw.contains('/chat/completions') ? raw : '$raw/v1/chat/completions';
    return Uri.tryParse(path);
  }

  TutorConfig copyWith({bool? enabled, String? endpoint, int? dailyQuestionLimit}) => TutorConfig(
        enabled: enabled ?? this.enabled,
        endpoint: endpoint ?? this.endpoint,
        model: model,
        requestTimeout: requestTimeout,
        maxRetries: maxRetries,
        dailyQuestionLimit: dailyQuestionLimit ?? this.dailyQuestionLimit,
        maxLessonContextChars: maxLessonContextChars,
        maxQuestionChars: maxQuestionChars,
        maxAnswerChars: maxAnswerChars,
        minStepForDirectAnswer: minStepForDirectAnswer,
        historyMaxTurns: historyMaxTurns,
        temperature: temperature,
      );
}
