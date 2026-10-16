import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/python_runtime/python_runtime.dart';
import 'package:pyquest/python_runtime/simulated_runtime.dart';

void main() {
  final runtime = SimulatedPythonRuntime();

  ExecutionResult run(String code, {ExecutionContext? context}) => runtime.executeSync(code, context: context);

  String out(String code) {
    final r = run(code);
    expect(r.success, isTrue, reason: 'Expected success but got: ${r.errorMessage} (${r.pythonError})');
    return r.output;
  }

  group('core language', () {
    test('print and strings', () {
      expect(out('print("Xin chào!")'), 'Xin chào!\n');
      expect(out("print('a', 'b', sep='-', end='!')"), 'a-b!');
      expect(out('print("Py" + "Quest")'), 'PyQuest\n');
      expect(out('print("ha" * 3)'), 'hahaha\n');
      expect(out('print()'), '\n');
    });

    test('numbers follow Python semantics', () {
      expect(out('print(7 // 2, -7 // 2, 7 % 3, -7 % 3, 7 % -3)'), '3 -4 1 2 -2\n');
      expect(out('print(6 / 3, 1 / 4, 0.1 + 0.2)'), '2.0 0.25 0.30000000000000004\n');
      expect(out('print(2 ** 10, 2 ** -1, round(2.5), round(3.5))'), '1024 0.5 2 4\n');
      expect(out('print(True + 1, 3 == 3.0, 10 > 3 > 1)'), '2 True True\n');
    });

    test('variables, updates and f-strings', () {
      expect(out('diem = 5\ndiem += 10\ndiem = diem * 2\nprint(f"Điểm: {diem}!")'), 'Điểm: 30!\n');
      expect(out('ten = "Robo"\nprint("Xin chào " + ten)'), 'Xin chào Robo\n');
      expect(out('a = b = 3\nprint(a + b)'), '6\n');
    });

    test('if / elif / else and boolean logic', () {
      const code = '''
diem = 75
if diem >= 90:
    print("3 sao")
elif diem >= 50:
    print("2 sao")
else:
    print("1 sao")
if not False and (1 < 2 or x):
    print("ok")
''';
      expect(out(code), '2 sao\nok\n');
    });

    test('loops, break, continue', () {
      expect(out('for i in range(3):\n    print(i)'), '0\n1\n2\n');
      expect(out('t = 0\nfor i in range(1, 11):\n    if i % 2 == 0:\n        continue\n    t += i\nprint(t)'), '25\n');
      expect(out('n = 0\nwhile True:\n    n += 1\n    if n == 4:\n        break\nprint(n)'), '4\n');
      expect(out('for c in "abc":\n    print(c, end="")'), 'abc');
    });

    test('lists and methods', () {
      expect(out('ds = [3, 1, 2]\nds.append(5)\nds.sort()\nprint(ds, len(ds), ds[-1], 2 in ds)'), '[1, 2, 3, 5] 4 5 True\n');
      expect(out("print(['a', 1, True, None])"), "['a', 1, True, None]\n");
      expect(out('print(sum([1, 2, 3]), max(4, 9, 2), min([5, 3]))'), '6 9 3\n');
      expect(out('print("-".join(["a", "b"]), "Py".upper(), "a b".split())'), "a-b PY ['a', 'b']\n");
    });

    test('functions, defaults, recursion', () {
      const code = '''
def chao(ten, loi="Xin chào"):
    return loi + ", " + ten + "!"

def giai_thua(n):
    if n <= 1:
        return 1
    return n * giai_thua(n - 1)

print(chao("Pip"))
print(chao("Bitsy", loi="Hi"))
print(giai_thua(10))
''';
      expect(out(code), 'Xin chào, Pip!\nHi, Bitsy!\n3628800\n');
    });

    test('str(), int(), type()', () {
      expect(out('print("Điểm: " + str(10))'), 'Điểm: 10\n');
      expect(out('print(int("42") + 1, float("2.5"), int(3.9))'), '43 2.5 3\n');
      expect(out('print(type("5"), type(5))'), "<class 'str'> <class 'int'>\n");
    });
  });

  group('friendly errors', () {
    test('NameError suggests the close name', () {
      final r = run('diem = 3\nprint(diemm)');
      expect(r.success, isFalse);
      expect(r.errorKind, ExecutionErrorKind.runtime);
      expect(r.errorLine, 2);
      expect(r.pythonError, "NameError: name 'diemm' is not defined");
      expect(r.errorMessage, contains('diem'));
    });

    test('case sensitivity hint', () {
      final r = run('Print("hi")');
      expect(r.errorMessage, contains('chữ hoa'));
    });

    test('str + int explains str()', () {
      final r = run('print("Điểm: " + 10)');
      expect(r.pythonError, startsWith('TypeError'));
      expect(r.errorMessage, contains('str('));
    });

    test('missing colon and indentation', () {
      final colon = run('if 3 > 2\n    print("x")');
      expect(colon.errorKind, ExecutionErrorKind.syntax);
      expect(colon.errorMessage, contains(':'));
      final indent = run('if True:\nprint("x")');
      expect(indent.errorKind, ExecutionErrorKind.syntax);
      expect(indent.pythonError, startsWith('IndentationError'));
    });

    test('unclosed string and paren', () {
      expect(run('print("hi)').errorMessage, contains('chưa được đóng'));
      expect(run('print("hi"').errorMessage, contains('chưa được đóng'));
    });

    test('python 2 print hint', () {
      expect(run('print "hi"').errorMessage, contains('print("hi")'));
    });

    test('single = in condition', () {
      expect(run('x = 1\nif x = 1:\n    print(x)').errorMessage, contains('=='));
    });

    test('zero division and index errors', () {
      expect(run('print(1 / 0)').pythonError, startsWith('ZeroDivisionError'));
      expect(run('ds = [1]\nprint(ds[3])').pythonError, 'IndexError: list index out of range');
    });

    test('unsupported features are reported honestly', () {
      expect(run('import os').errorKind, ExecutionErrorKind.unsupported);
      expect(run('class A:\n    pass').errorKind, ExecutionErrorKind.unsupported);
      expect(run('x = input()').errorKind, ExecutionErrorKind.unsupported);
    });
  });

  group('limits', () {
    test('infinite loop is stopped by the step budget', () {
      final r = run('while True:\n    pass');
      expect(r.success, isFalse);
      expect(r.errorKind, ExecutionErrorKind.limit);
    });

    test('runaway recursion is stopped', () {
      final r = run('def f(n):\n    return f(n + 1)\nf(0)');
      expect(r.errorKind, ExecutionErrorKind.limit);
      expect(r.pythonError, startsWith('RecursionError'));
    });

    test('output is capped', () {
      final r = run('for i in range(100000):\n    print("xxxxxxxxxx")');
      expect(r.success, isFalse);
      expect(r.output.length, lessThanOrEqualTo(10000));
    });

    test('huge list and huge numbers are refused', () {
      expect(run('x = [0] * 100000000').errorKind, ExecutionErrorKind.limit);
      expect(run('print(10 ** 100)').success, isFalse);
      expect(run('print(sum(range(10 ** 9)))').errorKind, ExecutionErrorKind.limit);
    });
  });

  group('host functions', () {
    test('host commands are called in order and can halt', () {
      final calls = <String>[];
      final context = ExecutionContext(hostFunctions: {
        'right': (args) {
          calls.add('R');
          if (calls.length > 3) throw HostHalt('Ối! Robo đụng tường.');
          return null;
        },
        'at_chest': (args) => calls.length >= 2,
      });
      final ok = run('while not at_chest():\n    right()', context: context);
      expect(ok.success, isTrue);
      expect(calls, ['R', 'R']);
      calls.clear();
      final halted = run('for i in range(10):\n    right()', context: context);
      expect(halted.errorKind, ExecutionErrorKind.halted);
      expect(calls.length, 4);
    });
  });
}
