import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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
  final String payload = base64Encode(
    GZipCodec(level: 9).encode(utf8.encode(jsonEncode(generated))),
  );
  const int chunkSize = 900;
  for (var start = 0, index = 0; start < payload.length; start += chunkSize, index++) {
    final String chunk = payload.substring(
      start,
      start + chunkSize < payload.length ? start + chunkSize : payload.length,
    );
    test('temporary generated output chunk $index: $chunk', () {
      fail('temporary generated output transfer');
    });
  }
}
