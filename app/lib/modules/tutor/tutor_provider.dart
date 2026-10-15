import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'tutor_config.dart';
import 'tutor_models.dart';

/// A provider turns a chat request into text. Keeping it an interface lets the
/// tests drive every failure path with no network at all.
abstract interface class TutorProvider {
  Future<String> complete(TutorChatRequest request);
}

/// Provider-agnostic request: an OpenAI-compatible chat completion.
class TutorChatRequest {
  const TutorChatRequest({
    required this.model,
    required this.messages,
    required this.temperature,
    required this.timeout,
  });

  final String model;
  final List<TutorMessage> messages;
  final double temperature;
  final Duration timeout;

  Map<String, Object?> toJson({bool stream = false}) => {
        'model': model,
        'messages': [for (final m in messages) m.toJson()],
        'temperature': temperature,
        'stream': stream,
        'max_tokens': 700,
      };
}

class TutorMessage {
  const TutorMessage(this.role, this.content);

  final String role;
  final String content;

  Map<String, Object?> toJson() => {'role': role, 'content': content};
}

class TutorProviderException implements Exception {
  TutorProviderException(this.kind, [this.detail = '']);

  final TutorFailKind kind;

  /// Technical detail for logs/diagnostics — never shown to the child.
  final String detail;

  @override
  String toString() => 'TutorProviderException(${kind.name}${detail.isEmpty ? '' : ': $detail'})';
}

/// Talks to an OpenAI-compatible `/v1/chat/completions` endpoint through
/// `dart:io`, so no extra dependency is needed.
///
/// Deliberate design rules:
/// * no API key is ever read, stored or sent by the app — [config] must point
///   at a relay that keeps the key server-side;
/// * one request at a time (the session enforces this), short timeout, at most
///   [TutorConfig.maxRetries] extra attempts for retryable failures;
/// * the reply is truncated to [TutorConfig.maxAnswerChars];
/// * the client never executes code and never sends anything but the lesson
///   context and the child's question.
class RemoteTutorProvider implements TutorProvider {
  RemoteTutorProvider(this.config, {HttpClient? client}) : _client = client ?? HttpClient();

  final TutorConfig config;
  final HttpClient _client;

  @override
  Future<String> complete(TutorChatRequest request) async {
    final uri = config.chatUri;
    if (uri == null) {
      throw TutorProviderException(TutorFailKind.notConfigured, 'no endpoint configured');
    }
    TutorFailKind? lastKind;
    var attempt = 0;
    while (attempt <= config.maxRetries) {
      attempt++;
      try {
        return await _send(uri, request);
      } on TutorProviderException catch (e) {
        lastKind = e.kind;
        if (!e.kind.isRetryable || attempt > config.maxRetries) rethrow;
        // Small backoff so a flaky connection gets a second chance.
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      } on SocketException catch (e) {
        lastKind = TutorFailKind.network;
        if (attempt > config.maxRetries) {
          throw TutorProviderException(TutorFailKind.network, e.message);
        }
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      } on TimeoutException catch (e) {
        lastKind = TutorFailKind.timeout;
        if (attempt > config.maxRetries) {
          throw TutorProviderException(TutorFailKind.timeout, e.message ?? 'timeout');
        }
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      } on HandshakeException catch (e) {
        // Certificates are not worth retrying; report honestly.
        throw TutorProviderException(TutorFailKind.network, 'tls: ${e.message}');
      } on FormatException catch (e) {
        throw TutorProviderException(TutorFailKind.badResponse, e.message);
      }
    }
    throw TutorProviderException(lastKind ?? TutorFailKind.network, 'gave up after $attempt attempts');
  }

  Future<String> _send(Uri uri, TutorChatRequest request) async {
    HttpClientRequest? req;
    try {
      req = await _client.postUrl(uri).timeout(request.timeout);
      req.headers.contentType = ContentType.json;
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      // No Authorization header: the relay owns the API key.
      req.write(jsonEncode(request.toJson()));
      final res = await req.close().timeout(request.timeout);
      final body = await res.transform(utf8.decoder).join().timeout(request.timeout);
      if (res.statusCode == 429) {
        throw TutorProviderException(TutorFailKind.rateLimited, 'http 429');
      }
      if (res.statusCode >= 500) {
        throw TutorProviderException(TutorFailKind.server, 'http ${res.statusCode}');
      }
      if (res.statusCode == 401 || res.statusCode == 403) {
        // The build points at a relay that refused it — treat as not configured.
        throw TutorProviderException(TutorFailKind.notConfigured, 'http ${res.statusCode}');
      }
      if (res.statusCode != 200) {
        throw TutorProviderException(TutorFailKind.badResponse, 'http ${res.statusCode}');
      }
      return _parse(body);
    } finally {
      req?.abort(); // harmless when the request already completed
    }
  }

  String _parse(String body) {
    late final Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      throw TutorProviderException(TutorFailKind.badResponse, 'not json');
    }
    final choices = json['choices'];
    if (choices is! List || choices.isEmpty) {
      throw TutorProviderException(TutorFailKind.empty, 'no choices');
    }
    final first = choices.first;
    if (first is! Map) throw TutorProviderException(TutorFailKind.badResponse, 'choice not an object');
    if (first['finish_reason'] == 'content_filter') {
      throw TutorProviderException(TutorFailKind.blocked, 'content filter');
    }
    final message = first['message'];
    final content = message is Map ? message['content'] : null;
    final text = switch (content) {
      String s => s,
      List parts => parts
          .whereType<Map>()
          .map((p) => p['text'])
          .whereType<String>()
          .join('\n')
          .trim(),
      _ => '',
    };
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw TutorProviderException(TutorFailKind.empty, 'empty content');
    return trimmed.length <= config.maxAnswerChars
        ? trimmed
        : '${trimmed.substring(0, config.maxAnswerChars).trimRight()}…';
  }

  void dispose() => _client.close(force: true);
}

/// Answers a fixed text. Used by render previews and widget tests so they can
/// show the AI-labelled state without any network.
class StaticTutorProvider implements TutorProvider {
  const StaticTutorProvider(this.text, {this.delay = Duration.zero});

  final String text;
  final Duration delay;

  @override
  Future<String> complete(TutorChatRequest request) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (text.trim().isEmpty) throw TutorProviderException(TutorFailKind.empty, 'static empty');
    return text;
  }
}

/// Always fails with [kind]. Lets a test or a demo walkthrough prove the
/// fallback path (offline tutor + honest message) without breaking the network.
class FailingTutorProvider implements TutorProvider {
  const FailingTutorProvider(this.kind, {this.detail = 'test'});

  final TutorFailKind kind;
  final String detail;

  @override
  Future<String> complete(TutorChatRequest request) async =>
      throw TutorProviderException(kind, detail);
}
