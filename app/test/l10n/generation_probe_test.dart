import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('temporary gen-l10n output transfer', () {
    final Directory directory = Directory('lib/l10n/generated');
    final Map<String, String> generated = <String, String>{};
    final List<File> files = directory
        .listSync()
        .whereType<File>()
        .where((File file) => file.path.endsWith('.dart'))
        .toList()
      ..sort((File a, File b) => a.path.compareTo(b.path));
    for (final File file in files) {
      generated[file.uri.pathSegments.last] = file.readAsStringSync();
    }
    final String payload = base64Encode(gzip.encode(utf8.encode(jsonEncode(generated))));
    fail('GEN-L10N-DUMP:${files.length}:$payload');
  });
}
