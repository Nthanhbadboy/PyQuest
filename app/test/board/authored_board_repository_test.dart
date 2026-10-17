import 'dart:convert';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/modules/main_quest/quest_models.dart';
import 'package:pyquest/modules/tutor/board/authored_board_repository.dart';
import 'package:pyquest/modules/tutor/board/board_models.dart';
import 'package:pyquest/python_runtime/simulated_runtime.dart';
import 'package:pyquest/shared/characters/cast.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'actual Flutter bundle contains and loads both root-level authored assets',
    () async {
      final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(
        rootBundle,
      );
      expect(
        manifest.listAssets(),
        containsAll(<String>[
          AuthoredBoardRepository.plansAssetKey,
          AuthoredBoardRepository.copyAssetKey,
        ]),
      );
      expect(
        await rootBundle.loadString(AuthoredBoardRepository.plansAssetKey),
        isNotEmpty,
      );
      expect(
        await rootBundle.loadString(AuthoredBoardRepository.copyAssetKey),
        isNotEmpty,
      );
      await expectLater(AuthoredBoardRepository.load(rootBundle), completes);
    },
  );

  test(
    'plan and copy catalogs use set membership, independent of asset ordering',
    () async {
      final Map<String, String> assets = await _readAuthoredAssets();
      final Map<String, dynamic> plans =
          jsonDecode(assets[AuthoredBoardRepository.plansAssetKey]!)
              as Map<String, dynamic>;
      final Map<String, dynamic> copy =
          jsonDecode(assets[AuthoredBoardRepository.copyAssetKey]!)
              as Map<String, dynamic>;
      final List<dynamic> planMembers = plans['plans']! as List<dynamic>;
      planMembers.setAll(0, planMembers.reversed.toList());
      final List<dynamic> copyMembers = copy['plans']! as List<dynamic>;
      copyMembers.setAll(0, copyMembers.reversed.toList());
      assets[AuthoredBoardRepository.plansAssetKey] = jsonEncode(plans);
      assets[AuthoredBoardRepository.copyAssetKey] = jsonEncode(copy);

      await expectLater(
        AuthoredBoardRepository.load(_MemoryAssetBundle(assets)),
        completes,
      );
    },
  );

  test(
    'plan and copy catalogs reject missing, extra and duplicate members',
    () async {
      final Map<String, String> baseline = await _readAuthoredAssets();

      Future<void> expectCatalogFailure(
        String assetKey,
        String memberKey,
        void Function(List<dynamic>) mutate,
      ) async {
        final Map<String, String> assets = Map<String, String>.of(baseline);
        final Map<String, dynamic> document =
            jsonDecode(assets[assetKey]!) as Map<String, dynamic>;
        final List<dynamic> members = document['plans']! as List<dynamic>;
        mutate(members);
        assets[assetKey] = jsonEncode(document);
        await expectLater(
          AuthoredBoardRepository.load(_MemoryAssetBundle(assets)),
          throwsFormatException,
          reason: '$assetKey must reject $memberKey catalog members',
        );
      }

      for (final MapEntry<String, String> source in <MapEntry<String, String>>[
        MapEntry<String, String>(
          AuthoredBoardRepository.plansAssetKey,
          'stepId',
        ),
        MapEntry<String, String>(
          AuthoredBoardRepository.copyAssetKey,
          'sourceStep',
        ),
      ]) {
        await expectCatalogFailure(source.key, 'missing', (
          List<dynamic> members,
        ) {
          members.removeLast();
        });
        await expectCatalogFailure(source.key, 'extra', (
          List<dynamic> members,
        ) {
          final Map<String, dynamic> extra = _cloneMap(
            members.first as Map<String, dynamic>,
          );
          extra[source.value] = 'mq1_99_s99';
          members.add(extra);
        });
        await expectCatalogFailure(source.key, 'duplicate', (
          List<dynamic> members,
        ) {
          members.add(_cloneMap(members.first as Map<String, dynamic>));
        });
      }
    },
  );

  test(
    'real lesson examples validate and derive Nova/Pixel from lesson skill',
    () async {
      final MainQuestContent content = await MainQuestContent.load(rootBundle);
      final AuthoredBoardRepository repository =
          await AuthoredBoardRepository.load(rootBundle);
      final Map<String, String> expectedCharacters = <String, String>{
        'mq1_01_s2': 'nova',
        'mq1_03_s2': 'pixel',
      };

      for (final MapEntry<String, String> entry in expectedCharacters.entries) {
        final Lesson lesson = content.lessons.firstWhere(
          (Lesson candidate) =>
              candidate.steps.any((LessonStep step) => step.id == entry.key),
        );
        final ExampleStep example = lesson.steps
            .whereType<ExampleStep>()
            .singleWhere((ExampleStep step) => step.id == entry.key);
        final BoardValidation validation = repository.validateFor(
          lessonId: lesson.id,
          stepId: example.id,
          trustedCode: example.code,
          characterId: CastRegistry.tutorForSkill(lesson.skill).id.name,
          locale: 'vi',
          referenceRuntime: SimulatedPythonRuntime(),
        );

        expect(
          validation.accepted,
          isTrue,
          reason: '${lesson.id}/${example.id}: ${validation.issues}',
        );
        expect(validation.plan!.characterId, entry.value);
        expect(validation.plan!.beats, hasLength(4));
        expect(
          validation.plan!.beats.map(
            (BoardBeat beat) => beat.copy.keys.toSet(),
          ),
          everyElement(equals(<String>{'vi', 'en'})),
        );
      }
    },
  );

  test(
    'repository exposes exact failure causes for copy, owner, source and host IDs',
    () async {
      final Map<String, String> baseline = await _readAuthoredAssets();

      final Map<String, String> missingLocale = Map<String, String>.of(
        baseline,
      );
      final Map<String, dynamic> localeDoc = _documentFor(
        missingLocale,
        AuthoredBoardRepository.copyAssetKey,
      );
      final Map<String, dynamic> localePlan = _firstMap(
        localeDoc['plans']! as List<dynamic>,
      );
      final Map<String, dynamic> localeBeat = _firstMap(
        localePlan['beats']! as List<dynamic>,
      );
      (localeBeat['copy']! as Map<String, dynamic>).remove('en');
      missingLocale[AuthoredBoardRepository.copyAssetKey] = jsonEncode(
        localeDoc,
      );
      expect(
        (await _validateWithAssets(missingLocale)).codes,
        contains(BoardIssueCode.missingCopy),
      );

      final Map<String, String> missingBeat = Map<String, String>.of(baseline);
      final Map<String, dynamic> missingBeatDoc = _documentFor(
        missingBeat,
        AuthoredBoardRepository.copyAssetKey,
      );
      final Map<String, dynamic> missingBeatPlan = _firstMap(
        missingBeatDoc['plans']! as List<dynamic>,
      );
      (missingBeatPlan['beats']! as List<dynamic>).removeLast();
      missingBeat[AuthoredBoardRepository.copyAssetKey] = jsonEncode(
        missingBeatDoc,
      );
      expect(
        (await _validateWithAssets(missingBeat)).codes,
        contains(BoardIssueCode.missingCopy),
      );

      final Map<String, String> wrongWait = Map<String, String>.of(baseline);
      final Map<String, dynamic> wrongWaitDoc = _documentFor(
        wrongWait,
        AuthoredBoardRepository.copyAssetKey,
      );
      final Map<String, dynamic> wrongWaitPlan = _firstMap(
        wrongWaitDoc['plans']! as List<dynamic>,
      );
      final Map<String, dynamic> wrongWaitBeat = _firstMap(
        wrongWaitPlan['beats']! as List<dynamic>,
      );
      wrongWaitBeat['waitForLearner'] =
          !(wrongWaitBeat['waitForLearner']! as bool);
      wrongWait[AuthoredBoardRepository.copyAssetKey] = jsonEncode(
        wrongWaitDoc,
      );
      expect(
        (await _validateWithAssets(wrongWait)).codes,
        contains(BoardIssueCode.missingCopy),
      );

      expect(
        (await _validateWithAssets(baseline, lessonId: 'mq1_03')).codes,
        contains(BoardIssueCode.foreignKey),
      );

      final Map<String, String> untrustedStatement = Map<String, String>.of(
        baseline,
      );
      final Map<String, dynamic> statementDoc = _documentFor(
        untrustedStatement,
        AuthoredBoardRepository.plansAssetKey,
      );
      final Map<String, dynamic> statementPlan = _firstMap(
        statementDoc['plans']! as List<dynamic>,
      );
      final Map<String, dynamic> statementBeat = _firstMap(
        statementPlan['beats']! as List<dynamic>,
      );
      statementBeat['sourceStatement'] = 'print("not from lesson")';
      untrustedStatement[AuthoredBoardRepository.plansAssetKey] = jsonEncode(
        statementDoc,
      );
      expect(
        (await _validateWithAssets(untrustedStatement)).codes,
        contains(BoardIssueCode.outputMismatch),
      );

      final Map<String, String> unregisteredId = Map<String, String>.of(
        baseline,
      );
      final Map<String, dynamic> idDoc = _documentFor(
        unregisteredId,
        AuthoredBoardRepository.plansAssetKey,
      );
      final Map<String, dynamic> idPlan = _firstMap(
        idDoc['plans']! as List<dynamic>,
      );
      final Map<String, dynamic> idBeat = _firstMap(
        idPlan['beats']! as List<dynamic>,
      );
      (idBeat['objectIds']! as List<dynamic>)[0] = 'attacker-object';
      unregisteredId[AuthoredBoardRepository.plansAssetKey] = jsonEncode(idDoc);
      expect(
        (await _validateWithAssets(unregisteredId)).codes,
        contains(BoardIssueCode.unknownObject),
      );
    },
  );

  test(
    'payload registered IDs and character cannot replace host-owned values',
    () async {
      final Map<String, String> assets = await _readAuthoredAssets();
      final Map<String, dynamic> planDocument =
          jsonDecode(assets[AuthoredBoardRepository.plansAssetKey]!)
              as Map<String, dynamic>;
      final List<dynamic> plans = planDocument['plans']! as List<dynamic>;
      final Map<String, dynamic> first = plans.first as Map<String, dynamic>;
      first['registeredObjects'] = <String>['attacker-object'];
      first['characterId'] = 'attacker-character';
      assets[AuthoredBoardRepository.plansAssetKey] = jsonEncode(planDocument);

      final AuthoredBoardRepository repository =
          await AuthoredBoardRepository.load(_MemoryAssetBundle(assets));
      final ExampleStep trustedExample = _exampleFor(
        await MainQuestContent.load(rootBundle),
        'mq1_01_s2',
      );
      final BoardValidation validation = repository.validateFor(
        lessonId: 'mq1_01',
        stepId: trustedExample.id,
        trustedCode: trustedExample.code,
        characterId: 'nova',
        locale: 'vi',
        referenceRuntime: SimulatedPythonRuntime(),
      );

      expect(validation.accepted, isTrue, reason: '${validation.issues}');
      expect(validation.plan!.characterId, 'nova');
      expect(
        validation.plan!.registeredObjects,
        <String>['cmd-print', 'quote-open', 'quote-close', 'out-box'],
        reason:
            'payload allowlist is discarded; host catalog supplies registered IDs to validation',
      );
    },
  );

  test(
    'foreign steps and plan-provided output cannot become the trusted reference',
    () async {
      final AuthoredBoardRepository repository =
          await AuthoredBoardRepository.load(rootBundle);
      final ExampleStep trustedExample = _exampleFor(
        await MainQuestContent.load(rootBundle),
        'mq1_01_s2',
      );
      final BoardValidation foreign = repository.validateFor(
        lessonId: 'mq1_03',
        stepId: trustedExample.id,
        trustedCode: trustedExample.code,
        characterId: 'pixel',
        locale: 'vi',
        referenceRuntime: SimulatedPythonRuntime(),
      );
      expect(foreign.accepted, isFalse);
      expect(foreign.codes, contains(BoardIssueCode.foreignKey));
    },
  );

  test(
    'authored output values are compared with a fresh trusted-engine reference',
    () async {
      final Map<String, String> assets = await _readAuthoredAssets();
      final Map<String, dynamic> planDocument =
          jsonDecode(assets[AuthoredBoardRepository.plansAssetKey]!)
              as Map<String, dynamic>;
      final List<dynamic> plans = planDocument['plans']! as List<dynamic>;
      final Map<String, dynamic> first = plans.first as Map<String, dynamic>;
      final bool changed = _replaceOutputValue(
        first,
        'Xin chào!',
        'forged output',
      );
      expect(
        changed,
        isTrue,
        reason: 'asset should contain an authored comparison output',
      );
      assets[AuthoredBoardRepository.plansAssetKey] = jsonEncode(planDocument);

      final AuthoredBoardRepository repository =
          await AuthoredBoardRepository.load(_MemoryAssetBundle(assets));
      final ExampleStep trustedExample = _exampleFor(
        await MainQuestContent.load(rootBundle),
        'mq1_01_s2',
      );
      final BoardValidation validation = repository.validateFor(
        lessonId: 'mq1_01',
        stepId: trustedExample.id,
        trustedCode: trustedExample.code,
        characterId: 'nova',
        locale: 'vi',
        referenceRuntime: SimulatedPythonRuntime(),
      );
      expect(validation.accepted, isFalse);
      expect(validation.codes, contains(BoardIssueCode.outputMismatch));
    },
  );

  test('malformed and oversized fake-bundle assets fail atomically', () async {
    final Map<String, String> assets = await _readAuthoredAssets();
    final Map<String, String> malformed = Map<String, String>.of(assets)
      ..[AuthoredBoardRepository.plansAssetKey] = '{not json';
    await expectLater(
      AuthoredBoardRepository.load(_MemoryAssetBundle(malformed)),
      throwsFormatException,
    );

    final Map<String, String> oversized = Map<String, String>.of(assets)
      ..[AuthoredBoardRepository.plansAssetKey] =
          ' ' * (BoardLimits.maxDocumentChars + 1);
    await expectLater(
      AuthoredBoardRepository.load(_MemoryAssetBundle(oversized)),
      throwsFormatException,
    );
  });
}

Future<BoardValidation> _validateWithAssets(
  Map<String, String> assets, {
  String lessonId = 'mq1_01',
}) async {
  final AuthoredBoardRepository repository = await AuthoredBoardRepository.load(
    _MemoryAssetBundle(assets),
  );
  final ExampleStep example = _exampleFor(
    await MainQuestContent.load(rootBundle),
    'mq1_01_s2',
  );
  return repository.validateFor(
    lessonId: lessonId,
    stepId: example.id,
    trustedCode: example.code,
    characterId: 'nova',
    locale: 'vi',
    referenceRuntime: SimulatedPythonRuntime(),
  );
}

Map<String, dynamic> _documentFor(Map<String, String> assets, String key) =>
    jsonDecode(assets[key]!) as Map<String, dynamic>;

Map<String, dynamic> _firstMap(List<dynamic> values) =>
    values.first as Map<String, dynamic>;

Map<String, dynamic> _cloneMap(Map<String, dynamic> source) =>
    jsonDecode(jsonEncode(source)) as Map<String, dynamic>;

ExampleStep _exampleFor(MainQuestContent content, String stepId) {
  for (final Lesson lesson in content.lessons) {
    for (final LessonStep step in lesson.steps) {
      if (step.id == stepId && step is ExampleStep) return step;
    }
  }
  throw StateError('No ExampleStep $stepId in the trusted lesson dataset');
}

bool _replaceOutputValue(Object? node, String oldValue, String replacement) {
  if (node is Map<String, dynamic>) {
    if (node['value'] == oldValue) {
      node['value'] = replacement;
      return true;
    }
    for (final Object? child in node.values) {
      if (_replaceOutputValue(child, oldValue, replacement)) return true;
    }
  } else if (node is List<dynamic>) {
    for (final Object? child in node) {
      if (_replaceOutputValue(child, oldValue, replacement)) return true;
    }
  }
  return false;
}

Future<Map<String, String>> _readAuthoredAssets() async => <String, String>{
  AuthoredBoardRepository.plansAssetKey: await rootBundle.loadString(
    AuthoredBoardRepository.plansAssetKey,
  ),
  AuthoredBoardRepository.copyAssetKey: await rootBundle.loadString(
    AuthoredBoardRepository.copyAssetKey,
  ),
};

class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final String? source = assets[key];
    if (source == null) throw FlutterError('Test bundle has no asset $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(source)));
  }
}
