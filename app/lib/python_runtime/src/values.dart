import 'ast.dart';

/// Python `None`.
class PyNone {
  const PyNone._();
  static const PyNone instance = PyNone._();
  @override
  String toString() => 'None';
}

/// Mutable Python list.
class PyList {
  PyList(this.items);
  final List<Object?> items;
}

/// Lazy `range(...)` object.
class PyRange {
  PyRange(this.start, this.stop, this.step);
  final int start;
  final int stop;
  final int step;

  int get length {
    if (step > 0 && start < stop) return ((stop - start - 1) ~/ step) + 1;
    if (step < 0 && start > stop) return ((start - stop - 1) ~/ -step) + 1;
    return 0;
  }

  int operator [](int i) => start + step * i;
}

/// Function defined with `def`.
class PyFunction {
  PyFunction(this.def, this.closure, this.defaultValues);
  final FunctionDefStmt def;
  final Scope closure;

  /// Default values evaluated once at `def` time (like CPython).
  final List<Object?> defaultValues;
  String get name => def.name;
}

typedef BuiltinImpl = Object? Function(List<Object?> args, Map<String, Object?> kwargs, int line);

/// Function implemented in Dart (print, len, robot commands, ...).
class PyBuiltin {
  PyBuiltin(this.name, this.impl);
  final String name;
  final BuiltinImpl impl;
}

/// Method bound to a receiver, e.g. `items.append`.
class PyBoundMethod {
  PyBoundMethod(this.receiver, this.name, this.impl);
  final Object? receiver;
  final String name;
  final BuiltinImpl impl;
}

/// Variable scope. Lookups walk the parent chain (function -> module).
class Scope {
  Scope([this.parent]);
  final Scope? parent;
  final Map<String, Object?> vars = {};

  bool has(String name) => vars.containsKey(name) || (parent?.has(name) ?? false);

  Object? lookup(String name) {
    Scope? s = this;
    while (s != null) {
      if (s.vars.containsKey(name)) return s.vars[name];
      s = s.parent;
    }
    return _missing;
  }

  static const Object _missing = _Missing();
  static bool isMissing(Object? v) => identical(v, _missing);
}

class _Missing {
  const _Missing();
}
