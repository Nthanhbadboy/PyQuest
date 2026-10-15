/// Error types raised by the simulated Python runtime.
///
/// Every error carries a kid-friendly Vietnamese explanation plus the
/// equivalent message real Python would print, so children learn the real
/// vocabulary without being scared by raw tracebacks.
library;

enum PyErrorKind { syntax, indentation, name, type, value, zeroDivision, index, unsupported, limit, halted, runtime }

class PyError implements Exception {
  PyError(
    this.kind,
    this.friendly, {
    this.line,
    this.pythonName,
    this.pythonMessage,
  });

  final PyErrorKind kind;

  /// Friendly Vietnamese explanation shown to the child.
  final String friendly;

  /// 1-based source line, when known.
  int? line;

  /// Real Python exception class name, e.g. `NameError`.
  final String? pythonName;

  /// Real Python message, e.g. `name 'x' is not defined`.
  final String? pythonMessage;

  String get pythonEquivalent {
    if (pythonName == null) return '';
    if (pythonMessage == null || pythonMessage!.isEmpty) return pythonName!;
    return '$pythonName: $pythonMessage';
  }

  @override
  String toString() => 'PyError(${kind.name}, line $line): $friendly';
}

PyError syntaxError(String friendly, int line, [String? pythonMessage]) =>
    PyError(PyErrorKind.syntax, friendly,
        line: line, pythonName: 'SyntaxError', pythonMessage: pythonMessage ?? 'invalid syntax');

PyError indentError(String friendly, int line, [String? pythonMessage]) =>
    PyError(PyErrorKind.indentation, friendly,
        line: line, pythonName: 'IndentationError', pythonMessage: pythonMessage ?? 'unexpected indent');

PyError unsupported(String feature, int line) => PyError(
      PyErrorKind.unsupported,
      'PyQuest Python là phiên bản đơn giản hoá của Python và chưa hỗ trợ $feature.',
      line: line,
    );

PyError typeError(String friendly, String pythonMessage, [int? line]) =>
    PyError(PyErrorKind.type, friendly, line: line, pythonName: 'TypeError', pythonMessage: pythonMessage);

PyError valueError(String friendly, String pythonMessage, [int? line]) =>
    PyError(PyErrorKind.value, friendly, line: line, pythonName: 'ValueError', pythonMessage: pythonMessage);

/// Thrown by host functions (e.g. robot commands) to stop the program on
/// purpose, for example when the robot bumps into a wall.
class HostHalt implements Exception {
  HostHalt(this.message);
  final String message;
}
