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
      r'\[E\]|Expected:|Actual:|Which:|══╡|EXCEPTION|Exception:|Error:|overflowed by|Failing tests:|settings_sheet_localization_test.dart:',
      caseSensitive: false,
    );
    stdout.writeln('PQC-016 focused diagnostics child exit=${result.exitCode}');
    int printed = 0;
    for (final String line in lines) {
      if (interesting.hasMatch(line)) {
        stdout.writeln(line);
        printed++;
      }
      if (printed >= 100) break;
    }
    stdout.writeln('PQC-016 focused diagnostics emitted $printed matching lines.');
  });
}
