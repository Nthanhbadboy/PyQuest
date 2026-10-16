import '../../shared/characters/characters.dart';
import 'tutor_models.dart';

/// Who produced a line of the tutor conversation.
///
/// The role is stored on the line itself. It used to be inferred from a
/// `"Bé: "` text prefix, and that is how the tutor's own greeting ended up
/// attributed to the child: whatever the microphone heard was labelled as the
/// child's speech, even when the words came out of the speaker.
enum TutorSpeakerRole {
  /// The learner, by keyboard or by microphone.
  child,

  /// A cast member — the offline tutor, the AI provider or a live voice turn.
  assistant;

  bool get isChild => this == TutorSpeakerRole.child;
  bool get isAssistant => this == TutorSpeakerRole.assistant;
}

/// One utterance in the tutor panel, typed or spoken.
class TutorLine {
  const TutorLine({
    required this.role,
    required this.text,
    this.character,
    this.source,
    this.hintLevel,
    this.failKind,
    this.isFinal = true,
    this.spoken = false,
    this.interrupted = false,
  });

  /// Child or assistant — the only thing that decides how the bubble looks.
  final TutorSpeakerRole role;
  final String text;

  /// Which cast member said it (assistant lines only).
  final CharacterId? character;

  /// Where an assistant answer came from, so AI text is never confused with
  /// the on-device tutor.
  final TutorSource? source;

  final TutorHintLevel? hintLevel;

  /// Why the AI call failed, when this offline answer replaced one.
  final TutorFailKind? failKind;

  /// False while a live transcription can still be revised.
  final bool isFinal;

  /// True when this line came from the microphone instead of the keyboard.
  final bool spoken;

  /// True when an assistant turn was cut off before it finished speaking.
  final bool interrupted;

  bool get isChild => role.isChild;
  bool get isOpen => !isFinal;

  TutorLine copyWith({String? text, bool? isFinal, bool? interrupted}) => TutorLine(
        role: role,
        text: text ?? this.text,
        character: character,
        source: source,
        hintLevel: hintLevel,
        failKind: failKind,
        isFinal: isFinal ?? this.isFinal,
        spoken: spoken,
        interrupted: interrupted ?? this.interrupted,
      );

  @override
  String toString() => '${role.name}${character == null ? '' : '/${character!.name}'}'
      '(${isFinal ? 'final' : 'open'}${spoken ? ', spoken' : ''}${interrupted ? ', interrupted' : ''}): $text';
}

/// The tutor conversation as an ordered list of role-tagged lines.
///
/// Both input paths write into this one model — the typed question/answer
/// exchange and the Gemini Live transcripts — so a spoken turn and a typed
/// turn mean the same thing to the UI. The merge rule is deliberately boring:
/// a revision replaces the SAME speaker's open line and nothing else, so a
/// partial transcript updates its own bubble without ever landing in the other
/// speaker's.
class TutorTranscript {
  TutorTranscript({this.limit = 40});

  /// Lines are kept for the sheet only; the durable history lives in
  /// [TutorSession]. This bound just stops a long voice session from growing
  /// the widget list forever.
  final int limit;

  final List<TutorLine> _lines = <TutorLine>[];

  List<TutorLine> get lines => List<TutorLine>.unmodifiable(_lines);

  int get length => _lines.length;
  bool get isEmpty => _lines.isEmpty;
  bool get isNotEmpty => _lines.isNotEmpty;
  TutorLine? get last => _lines.isEmpty ? null : _lines.last;

  void clear() => _lines.clear();

  /// At most one line is ever open: the newest one. Starting a new utterance
  /// seals what came before, so a revision can only ever land in the bubble of
  /// the speaker who is currently saying it.
  ///
  /// Index of the newest line of [role] that is still open, if any.
  int? openIndexOf(TutorSpeakerRole role) {
    for (var i = _lines.length - 1; i >= 0; i--) {
      if (_lines[i].role == role && _lines[i].isOpen) return i;
    }
    return null;
  }

  /// Closes every open line: the transcript of a session that ended must not
  /// stay "partial" in the UI.
  int sealOpen() {
    var sealed = 0;
    for (var i = 0; i < _lines.length; i++) {
      if (_lines[i].isOpen) {
        _lines[i] = _lines[i].copyWith(isFinal: true);
        sealed++;
      }
    }
    return sealed;
  }

  /// Adds what [role] just said and returns the index of the line it landed on
  /// (-1 when the text was empty and nothing was added).
  ///
  /// [isFinal] false keeps the line open so the next revision of the same
  /// utterance replaces it. When a speaker starts a new turn, the other
  /// speaker's unfinished line is closed first — an answer that never got its
  /// end-of-turn is still something the child saw, and it must not be
  /// overwritten by the next one.
  int say(
    String text, {
    required TutorSpeakerRole role,
    CharacterId? character,
    TutorSource? source,
    TutorHintLevel? hintLevel,
    TutorFailKind? failKind,
    bool isFinal = true,
    bool spoken = false,
    bool interrupted = false,
  }) {
    final clean = text.trim();
    if (clean.isEmpty) return -1;

    final open = openIndexOf(role);
    if (open != null) {
      final line = _lines[open];
      _lines[open] = TutorLine(
        role: role,
        text: clean,
        character: character ?? line.character,
        source: source ?? line.source,
        hintLevel: hintLevel ?? line.hintLevel,
        failKind: failKind ?? line.failKind,
        isFinal: isFinal,
        spoken: line.spoken || spoken,
        interrupted: line.interrupted || interrupted,
      );
      return open;
    }

    sealOpen();
    _lines.add(TutorLine(
      role: role,
      text: clean,
      character: character,
      source: source,
      hintLevel: hintLevel,
      failKind: failKind,
      isFinal: isFinal,
      spoken: spoken,
      interrupted: interrupted,
    ));
    if (_lines.length > limit) _lines.removeAt(0);
    return _lines.length - 1;
  }
}
