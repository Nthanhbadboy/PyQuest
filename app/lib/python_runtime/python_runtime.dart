/// Public gateway to running child-written code.
///
/// Every module must go through [PythonRuntime]; nobody touches the
/// interpreter directly (see docs/TECHNICAL_ARCHITECTURE.md §2.4). Today the
/// only implementation is [SimulatedPythonRuntime] — a limited Python-like
/// subset written in Dart. It is **not** CPython and the UI says so.
library;

export 'src/errors.dart' show HostHalt, PyErrorKind;

/// A host function exposed to the child's program, e.g. `right()` in Robot
/// Maze. It may return a Python-compatible value (bool, int, double, String,
/// null for None) or throw [HostHalt] to stop the program on purpose.
typedef HostFunction = Object? Function(List<Object?> args);

class RuntimeLimits {
  const RuntimeLimits({
    this.stepBudget = 100000,
    this.maxCallDepth = 50,
    this.maxOutputChars = 10000,
    this.maxCollectionLength = 10000,
    this.maxStringLength = 50000,
  });

  /// Hard stop: number of interpreter steps (statements, loop iterations,
  /// calls). This is the primary guarantee that `while True:` terminates.
  final int stepBudget;
  final int maxCallDepth;
  final int maxOutputChars;
  final int maxCollectionLength;
  final int maxStringLength;

  factory RuntimeLimits.fromJson(Map<String, dynamic> json) => RuntimeLimits(
        stepBudget: (json['step_budget'] as num?)?.toInt() ?? 100000,
        maxCallDepth: (json['max_call_depth'] as num?)?.toInt() ?? 50,
        maxOutputChars: (json['max_output_chars'] as num?)?.toInt() ?? 10000,
        maxCollectionLength: (json['max_collection_length'] as num?)?.toInt() ?? 10000,
        maxStringLength: (json['max_string_length'] as num?)?.toInt() ?? 50000,
      );
}

class ExecutionContext {
  const ExecutionContext({this.hostFunctions = const {}, this.limits});

  final Map<String, HostFunction> hostFunctions;

  /// Overrides the runtime's default limits for this execution.
  final RuntimeLimits? limits;
}

enum ExecutionErrorKind { none, syntax, runtime, limit, unsupported, halted, cancelled }

class ExecutionResult {
  const ExecutionResult({
    required this.success,
    required this.output,
    this.errorMessage,
    this.errorLine,
    this.errorKind = ExecutionErrorKind.none,
    this.pythonError,
    this.executionTime = Duration.zero,
    this.steps = 0,
  });

  final bool success;

  /// Everything printed by the program (possibly truncated at the limit).
  final String output;

  /// Kid-friendly explanation (Vietnamese) when [success] is false.
  final String? errorMessage;
  final int? errorLine;
  final ExecutionErrorKind errorKind;

  /// What real Python would have reported, e.g. `NameError: name 'x' is not defined`.
  final String? pythonError;
  final Duration executionTime;
  final int steps;

  bool get hitLimit => errorKind == ExecutionErrorKind.limit;
}

abstract class PythonRuntime {
  /// Human readable name shown in the UI (honest about being a simulation).
  String get displayName;

  Future<ExecutionResult> execute(String code, {ExecutionContext? context});

  /// Requests cancellation. The simulated runtime checks this between steps;
  /// the step budget remains the hard guarantee for CPU-bound loops.
  void interrupt();

  bool get isRunning;
}
