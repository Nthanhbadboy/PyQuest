@Tags(<String>['render'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('temporary PQC-016 test diagnostic (remove before handoff)', () async {
    final ProcessResult result = await Process.run(
      'flutter',
      <String>[
        'test',
        '--reporter',
        'expanded',
        'test/l10n/settings_sheet_localization_test.dart',
      ],
      workingDirectory: Directory.current.path,
    );
    final List<String> lines = '${result.stdout}\n${result.stderr}'.split('\n');
    final RegExp interesting = RegExp(
      r'^(══╡|Expected:|Actual:|Which:|Bad state:|Exception:|StateError:|NoSuchMethodError:|LateInitializationError:|A RenderFlex|RenderBox was not laid out|The test description was:|Failing tests:)',
      caseSensitive: false,
    );
    final Set<String> selected = <String>{};
    for (final String line in lines) {
      final String trimmed = line.trimLeft();
      if (interesting.hasMatch(trimmed) ||
          (line.contains(' [E]') && line.contains('settings_sheet_localization_test.dart:'))) {
        selected.add(trimmed);
      }
    }
    stdout.writeln('PQC-016 focused diagnostics child exit=${result.exitCode}');
    for (final String line in selected) {
      stdout.writeln(line);
    }
    stdout.writeln('PQC-016 focused diagnostics emitted ${selected.length} unique lines.');
  });
}
