@Tags(<String>['render'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('temporary PQC-016 focused diagnostics (remove before handoff)', () async {
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
    final List<String> summary = <String>[];
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i].trim();
      if (line.startsWith('══╡ EXCEPTION CAUGHT')) {
        summary.add(line);
        for (int j = i + 1; j < lines.length && j <= i + 10; j++) {
          final String detail = lines[j].trim();
          if (detail.startsWith('When the exception was thrown')) break;
          if (detail.startsWith('Expected:') ||
              detail.startsWith('Actual:') ||
              detail.startsWith('Which:') ||
              detail.startsWith('Bad state:') ||
              detail.startsWith('Exception:') ||
              detail.startsWith('DatabaseException') ||
              detail.startsWith('Null check') ||
              detail.startsWith('A RenderFlex') ||
              detail.startsWith('RenderBox was not laid out')) {
            summary.add(detail);
          }
        }
      } else if (line == 'Failing tests:') {
        summary.add(line);
        for (int j = i + 1; j < lines.length; j++) {
          final String failed = lines[j].trim();
          if (failed.isEmpty) break;
          summary.add(failed.replaceFirst(RegExp(r'^.*/app/test/l10n/'), ''));
        }
      }
    }
    stdout.writeln('PQC-016 child exit=${result.exitCode}');
    for (final String line in summary.toSet()) {
      stdout.writeln(line);
    }
  });
}
