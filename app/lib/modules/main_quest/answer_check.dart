/// Output comparison helpers for Main Quest exercises.
library;

String normalizeOutput(String s) => s.split('\n').map((l) => l.trimRight()).join('\n').trim();

const Map<String, String> _vi = {
  'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a', 'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
  'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a', 'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
  'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e', 'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
  'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o', 'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
  'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o', 'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
  'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u', 'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
  'đ': 'd',
};

String stripDiacritics(String s) {
  final buf = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    buf.write(_vi[ch] ?? ch);
  }
  return buf.toString();
}

/// Loose form: no accents, no case, no punctuation, single spaces.
String looseOutput(String s) => stripDiacritics(normalizeOutput(s))
    .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
    .replaceAll(RegExp(r'[ \t]+'), ' ')
    .split('\n')
    .map((l) => l.trim())
    .join('\n');

enum OutputMatch { exact, loose, wrong }

OutputMatch compareOutput(String actual, String expected) {
  if (normalizeOutput(actual) == normalizeOutput(expected)) return OutputMatch.exact;
  if (looseOutput(actual) == looseOutput(expected)) return OutputMatch.loose;
  return OutputMatch.wrong;
}

/// Checks the "must contain" requirements, ignoring extra spaces.
List<String> missingParts(String code, List<String> required) {
  final compact = code.replaceAll(RegExp(r'[ \t]+'), ' ');
  return [
    for (final r in required)
      if (!compact.contains(r.replaceAll(RegExp(r'[ \t]+'), ' ')) && !code.replaceAll(' ', '').contains(r.replaceAll(' ', ''))) r,
  ];
}
