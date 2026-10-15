import 'package:pyquest/core/clock.dart';

class FakeClock extends Clock {
  FakeClock(this.current);
  DateTime current;
  @override
  DateTime now() => current;
  void advance(Duration d) => current = current.add(d);
}
