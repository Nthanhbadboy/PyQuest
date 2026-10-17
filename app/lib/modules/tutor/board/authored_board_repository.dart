import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../python_runtime/python_runtime.dart' show ExecutionResult;
import '../../../python_runtime/simulated_runtime.dart';
import 'board_models.dart';
import 'board_plan_codec.dart';
import 'board_validator.dart';

/// Loads the two app-bundled authored sources and composes them into a validated
/// plan. Nothing in a board asset is executable: reference output, owner IDs,
/// registered objects, and tutor identity all come from the host.
class AuthoredBoardRepository {
  AuthoredBoardRepository._({
    required Map<String, Map<String, dynamic>> plansByStep,
    required Map<String, Map<String, Map<String, dynamic>>> copyByStepAndBeat,
    required Map<String, String> copyLessonIdByStep,
  })  : _plansByStep = plansByStep,
        _copyByStepAndBeat = copyByStepAndBeat,
        _copyLessonIdByStep = copyLessonIdByStep;

  static const String plansAssetKey = 'assets/data/tutor_board_plans.v1.json';
  static const String copyAssetKey = 'assets/data/tutor_board_authored-copy.v1.json';
  static const String sourceDatasetSha256 =
      'bead251d9f290db0b8fa4475f7413976324b00e7b0f498c633a25a5e6392f8b8';

  static const Map<String, List<String>> _registeredObjectsByStep = <String, List<String>>{
    'mq1_01_s2': <String>['cmd-print', 'quote-open', 'quote-close', 'out-box'],
    'mq1_03_s2': <String>[
      'expr-add',
      'lit-text',
      'out-box',
      'stone-1',
      'stone-2',
      'stone-3',
      'stone-4',
      'stone-5',
      'stone-6',
      'stone-7',
    ],
  };

  final Map<String, Map<String, dynamic>> _plansByStep;
  final Map<String, Map<String, Map<String, dynamic>>> _copyByStepAndBeat;
  final Map<String, String> _copyLessonIdByStep;

  static bool supportsStep(String stepId) => _registeredObjectsByStep.containsKey(stepId);

  /// The bundle keys are root-level entries in the existing `assets/data/`
  /// directory. Flutter does not recursively include JSON subdirectories.
  static Future<AuthoredBoardRepository> load(AssetBundle bundle) async {
    final Map<String, dynamic> planDocument =
        await _loadJson(bundle, plansAssetKey);
    final Map<String, dynamic> copyDocument =
        await _loadJson(bundle, copyAssetKey);

    if (copyDocument['contentVersion'] != 1) {
      throw const FormatException('Unsupported authored board content version');
    }
    if (copyDocument['sourceDatasetSha256'] != sourceDatasetSha256) {
      throw const FormatException('Authored board copy points at a different lesson dataset');
    }

    final Map<String, Map<String, dynamic>> plansByStep = <String, Map<String, dynamic>>{};
    final Object? rawPlans = planDocument['plans'];
    if (rawPlans is! List<dynamic>) {
      throw const FormatException('Authored board plans must be a list');
    }
    for (final Object? raw in rawPlans) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Authored board plan must be an object');
      }
      if (raw['schemaVersion'] != TeachingPlan.currentSchemaVersion) {
        throw const FormatException('Unsupported authored board plan schema version');
      }
      final Object? step = raw['stepId'];
      if (step is! String || !supportsStep(step) || plansByStep.containsKey(step)) {
        throw const FormatException('Unknown or duplicate authored board step');
      }
      plansByStep[step] = _deepCopyMap(raw);
    }
    if (!_sameStringMembers(plansByStep.keys.toSet(), _registeredObjectsByStep.keys.toSet())) {
      throw const FormatException('Authored board plan catalog does not match the host catalog');
    }

    final Map<String, Map<String, Map<String, dynamic>>> copyByStepAndBeat =
        <String, Map<String, Map<String, dynamic>>>{};
    final Map<String, String> copyLessonIdByStep = <String, String>{};
    final Object? rawCopyPlans = copyDocument['plans'];
    if (rawCopyPlans is! List<dynamic>) {
      throw const FormatException('Authored board copy plans must be a list');
    }
    for (final Object? rawPlan in rawCopyPlans) {
      if (rawPlan is! Map<String, dynamic>) {
        throw const FormatException('Authored board copy plan must be an object');
      }
      final Object? step = rawPlan['sourceStep'];
      final Object? lesson = rawPlan['lessonId'];
      final Object? rawBeats = rawPlan['beats'];
      if (step is! String || !supportsStep(step) || lesson is! String || rawBeats is! List<dynamic>) {
        throw const FormatException('Malformed authored board copy plan');
      }
      if (copyByStepAndBeat.containsKey(step)) {
        throw const FormatException('Duplicate authored board copy plan');
      }
      copyLessonIdByStep[step] = lesson;
      final Map<String, Map<String, dynamic>> beats = <String, Map<String, dynamic>>{};
      for (final Object? rawBeat in rawBeats) {
        if (rawBeat is! Map<String, dynamic> ||
            rawBeat['beatId'] is! String ||
            rawBeat['copy'] is! Map<String, dynamic> ||
            rawBeat['waitForLearner'] is! bool) {
          throw const FormatException('Malformed authored board copy beat');
        }
        final String beatId = rawBeat['beatId']! as String;
        if (beats.containsKey(beatId)) {
          throw const FormatException('Duplicate authored board copy beat');
        }
        beats[beatId] = _deepCopyMap(rawBeat);
      }
      copyByStepAndBeat[step] = beats;
    }
    if (!_sameStringMembers(copyByStepAndBeat.keys.toSet(), _registeredObjectsByStep.keys.toSet())) {
      throw const FormatException('Authored board copy catalog does not match the host catalog');
    }

    return AuthoredBoardRepository._(
      plansByStep: plansByStep,
      copyByStepAndBeat: copyByStepAndBeat,
      copyLessonIdByStep: copyLessonIdByStep,
    );
  }

  /// Compose one host-selected plan, then decode and validate it as a whole.
  /// [trustedCode] must be the immutable code field of the host's `ExampleStep`;
  /// no code, statement, output, ID list or character from the payload is trusted.
  BoardValidation validateFor({
    required String lessonId,
    required String stepId,
    required String trustedCode,
    required String characterId,
    required String locale,
    required SimulatedPythonRuntime referenceRuntime,
  }) {
    final Map<String, dynamic>? rawPlan = _plansByStep[stepId];
    final List<String>? registeredObjects = _registeredObjectsByStep[stepId];
    final Map<String, Map<String, dynamic>>? sourceCopy = _copyByStepAndBeat[stepId];
    if (rawPlan == null || registeredObjects == null || sourceCopy == null) {
      return BoardValidation.rejected(<BoardIssue>[
        const BoardIssue(BoardIssueCode.foreignKey, 'No authored board is registered for this step'),
      ]);
    }
    if (rawPlan['lessonId'] != lessonId ||
        rawPlan['stepId'] != stepId ||
        _copyLessonIdByStep[stepId] != lessonId) {
      return BoardValidation.rejected(<BoardIssue>[
        const BoardIssue(BoardIssueCode.foreignKey, 'Authored plan/copy belongs to another lesson or step'),
      ]);
    }

    final Object? rawBeats = rawPlan['beats'];
    if (rawBeats is! List<dynamic>) {
      return BoardValidation.rejected(<BoardIssue>[
        const BoardIssue(BoardIssueCode.missingCopy, 'Authored board beats are missing'),
      ]);
    }
    final Map<String, dynamic> composed = _deepCopyMap(rawPlan);
    composed['lessonId'] = lessonId;
    composed['stepId'] = stepId;
    composed['characterId'] = characterId;
    // The payload's list is retained only as provenance in the source file, never
    // passed through to the codec or used to expand the host's ID allowlist.
    composed.remove('registeredObjects');

    final Set<String> seenBeatIds = <String>{};
    for (final Object? rawBeat in composed['beats']! as List<dynamic>) {
      if (rawBeat is! Map<String, dynamic> || rawBeat['beatId'] is! String) {
        return BoardValidation.rejected(<BoardIssue>[
          const BoardIssue(BoardIssueCode.wrongType, 'Authored board beat is malformed'),
        ]);
      }
      final String beatId = rawBeat['beatId']! as String;
      if (!seenBeatIds.add(beatId)) {
        return BoardValidation.rejected(<BoardIssue>[
          BoardIssue(BoardIssueCode.duplicateId, 'Authored board beat ID is duplicated'),
        ]);
      }
      final Map<String, dynamic>? authoredCopy = sourceCopy[beatId];
      if (authoredCopy == null ||
          authoredCopy['waitForLearner'] != rawBeat['waitForLearner']) {
        return BoardValidation.rejected(<BoardIssue>[
          BoardIssue(BoardIssueCode.missingCopy, 'Authored copy does not match beat $beatId'),
        ]);
      }
      rawBeat['copy'] = _deepCopyMap(authoredCopy['copy']! as Map<String, dynamic>);
    }
    if (seenBeatIds.length != sourceCopy.length || !seenBeatIds.containsAll(sourceCopy.keys)) {
      return BoardValidation.rejected(<BoardIssue>[
        const BoardIssue(BoardIssueCode.missingCopy, 'Authored plan and copy beat sets differ'),
      ]);
    }

    final DeterministicReference? reference =
        _referenceFromTrustedCode(trustedCode, referenceRuntime);
    if (reference == null) {
      return BoardValidation.rejected(<BoardIssue>[
        const BoardIssue(BoardIssueCode.outputMismatch, 'Trusted lesson example did not run successfully'),
      ]);
    }

    return validateBoardDocument(
      jsonEncode(composed),
      reference: reference,
      locale: locale,
      expectedLessonId: lessonId,
      expectedStepId: stepId,
      registeredObjects: List<String>.unmodifiable(registeredObjects),
      requiredLocales: const <String>['vi', 'en'],
    );
  }

  static Future<Map<String, dynamic>> _loadJson(AssetBundle bundle, String key) async {
    final String source = await bundle.loadString(key);
    if (source.length > BoardLimits.maxDocumentChars) {
      throw FormatException('$key exceeds the authored asset limit');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException('Invalid JSON in $key: ${error.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('$key must have a JSON object at its root');
    }
    return decoded;
  }

  static DeterministicReference? _referenceFromTrustedCode(
    String trustedCode,
    SimulatedPythonRuntime runtime,
  ) {
    final List<String> lines = trustedCode
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) return null;

    final Map<String, String> outputs = <String, String>{};
    final List<String> trustedStatements = <String>{trustedCode, ...lines}.toList(growable: false);
    for (final String statement in trustedStatements) {
      final ExecutionResult result = runtime.executeSync(statement);
      if (!result.success) return null;
      outputs[statement] = result.output.trimRight();
    }
    return DeterministicReference(outputs);
  }

  static bool _sameStringMembers(Set<String> left, Set<String> right) =>
      left.length == right.length && left.containsAll(right);

  static Map<String, dynamic> _deepCopyMap(Map<String, dynamic> source) =>
      jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
}
