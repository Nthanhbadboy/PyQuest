/// Injectable time source so energy regeneration, daily resets and
/// achievements can be tested deterministically.
class Clock {
  const Clock();
  DateTime now() => DateTime.now();
}

/// Local calendar day key, e.g. `2026-10-15` (resets at local midnight).
String localDayKey(DateTime t) {
  final local = t.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)}';
}
