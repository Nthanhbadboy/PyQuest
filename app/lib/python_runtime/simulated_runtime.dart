import 'python_runtime.dart';
import 'src/errors.dart';
import 'src/interpreter.dart';
import 'src/parser.dart';

/// "PyQuest Python" — a small, safe Python subset interpreted in Dart.
///
/// Honest limits (also shown in the app, see [pyQuestPythonLimits]):
/// no imports, files, network, classes, dictionaries, tuples, slicing,
/// try/except, input(). Integers are 64-bit. Output appears after the run.
class SimulatedPythonRuntime implements PythonRuntime {
  SimulatedPythonRuntime({this.limits = const RuntimeLimits()});

  final RuntimeLimits limits;
  bool _running = false;
  bool _cancelRequested = false;

  @override
  String get displayName => 'PyQuest Python (mô phỏng)';

  @override
  bool get isRunning => _running;

  @override
  void interrupt() => _cancelRequested = true;

  @override
  Future<ExecutionResult> execute(String code, {ExecutionContext? context}) async {
    // Let the UI paint its "running" state first.
    await Future<void>.delayed(Duration.zero);
    return executeSync(code, context: context);
  }

  /// Synchronous variant used by tests and by games that replay host actions.
  ExecutionResult executeSync(String code, {ExecutionContext? context}) {
    final watch = Stopwatch()..start();
    _running = true;
    _cancelRequested = false;
    final interpreter = Interpreter(
      limits: context?.limits ?? limits,
      hostFunctions: context?.hostFunctions ?? const {},
      isCancelled: () => _cancelRequested,
    );
    try {
      final program = Parser.parseSource(code);
      interpreter.run(program);
      return ExecutionResult(
        success: true,
        output: interpreter.output.toString(),
        executionTime: watch.elapsed,
        steps: interpreter.steps,
      );
    } on PyError catch (e) {
      return ExecutionResult(
        success: false,
        output: interpreter.output.toString(),
        errorMessage: e.friendly,
        errorLine: e.line,
        errorKind: _kindOf(e.kind),
        pythonError: e.pythonEquivalent.isEmpty ? null : e.pythonEquivalent,
        executionTime: watch.elapsed,
        steps: interpreter.steps,
      );
    } on HostHalt catch (h) {
      return ExecutionResult(
        success: false,
        output: interpreter.output.toString(),
        errorMessage: h.message,
        errorKind: ExecutionErrorKind.halted,
        executionTime: watch.elapsed,
        steps: interpreter.steps,
      );
    } on StackOverflowError {
      return ExecutionResult(
        success: false,
        output: interpreter.output.toString(),
        errorMessage: 'Chương trình lồng nhau quá sâu nên PyQuest phải dừng lại.',
        errorKind: ExecutionErrorKind.limit,
        executionTime: watch.elapsed,
        steps: interpreter.steps,
      );
    } finally {
      _running = false;
    }
  }

  static ExecutionErrorKind _kindOf(PyErrorKind kind) {
    switch (kind) {
      case PyErrorKind.syntax:
      case PyErrorKind.indentation:
        return ExecutionErrorKind.syntax;
      case PyErrorKind.unsupported:
        return ExecutionErrorKind.unsupported;
      case PyErrorKind.limit:
        return ExecutionErrorKind.limit;
      case PyErrorKind.halted:
        return ExecutionErrorKind.cancelled;
      case PyErrorKind.name:
      case PyErrorKind.type:
      case PyErrorKind.value:
      case PyErrorKind.zeroDivision:
      case PyErrorKind.index:
      case PyErrorKind.runtime:
        return ExecutionErrorKind.runtime;
    }
  }
}

/// Shown in the "Giới hạn của PyQuest Python" sheet.
const List<String> pyQuestPythonSupported = [
  'print(), biến, số nguyên, số thập phân, chuỗi chữ, True/False, None',
  'Phép tính + - * / // % ** và so sánh == != < > <= >=, and/or/not',
  'if / elif / else, while, for ... in range(...), break, continue',
  'Danh sách: [1, 2, 3], ds[0], ds.append(), len(), in',
  'Hàm: def, return, tham số mặc định',
  'f-string đơn giản: f"Xin chào {ten}"',
  'Lệnh có sẵn: len, range, str, int, float, bool, abs, round, min, max, sum, list, sorted, type',
];

const List<String> pyQuestPythonLimits = [
  'Không có import, file, mạng, input(), class, dictionary, tuple, cắt chuỗi [a:b], try/except, lambda.',
  'Tối đa 100.000 bước chạy — vòng lặp vô tận sẽ được dừng an toàn.',
  'Hàm gọi lồng nhau tối đa 50 tầng; in ra tối đa 10.000 ký tự.',
  'Số nguyên giới hạn khoảng ±9 tỉ tỉ (Python thật không giới hạn).',
  'Kết quả hiện ra sau khi chương trình chạy xong, không hiện từng dòng theo thời gian thực.',
  'Không cho đặt tên biến trùng print, len, range để tránh lỗi khó hiểu.',
];
