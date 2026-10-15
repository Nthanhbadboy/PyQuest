import 'dart:math' as math;

import '../python_runtime.dart' show RuntimeLimits, HostFunction;
import 'ast.dart';
import 'errors.dart';
import 'values.dart';

enum _Flow { normal, breakLoop, continueLoop, returned }

class PyTypeObject {
  const PyTypeObject(this.name);
  final String name;
}

/// Tree-walking evaluator with step, depth, output and size limits.
class Interpreter {
  Interpreter({
    required this.limits,
    Map<String, HostFunction> hostFunctions = const {},
    bool Function()? isCancelled,
  }) : _isCancelled = isCancelled {
    _installBuiltins();
    hostFunctions.forEach((name, fn) {
      _builtins.vars[name] = PyBuiltin(name, (args, kwargs, line) {
        if (kwargs.isNotEmpty) {
          throw typeError('Lệnh $name() không nhận đối số có tên.', "$name() got an unexpected keyword argument", line);
        }
        final result = fn(args);
        return result ?? PyNone.instance;
      });
    });
  }

  final RuntimeLimits limits;
  final bool Function()? _isCancelled;
  final StringBuffer output = StringBuffer();
  int steps = 0;
  int _depth = 0;
  Object? _returnValue;
  final Scope _builtins = Scope();
  late final Scope globals = Scope(_builtins);

  // ------------------------------------------------------------- running

  void run(List<Stmt> program) {
    final flow = _execBlock(program, globals);
    if (flow == _Flow.breakLoop || flow == _Flow.continueLoop) {
      throw syntaxError('"break"/"continue" chỉ dùng được bên trong vòng lặp.', program.isEmpty ? 1 : program.last.line,
          "'break' outside loop");
    }
    if (flow == _Flow.returned) {
      throw syntaxError('"return" chỉ dùng được bên trong hàm (def).', program.isEmpty ? 1 : program.last.line,
          "'return' outside function");
    }
  }

  void _tick(int line) {
    steps++;
    if (steps > limits.stepBudget) {
      throw PyError(
        PyErrorKind.limit,
        'Chương trình chạy lâu quá rồi (hơn ${limits.stepBudget} bước)! Có thể có một vòng lặp không bao giờ dừng. '
        'Hãy kiểm tra điều kiện của vòng lặp nhé.',
        line: line,
      );
    }
    if ((steps & 1023) == 0 && (_isCancelled?.call() ?? false)) {
      throw PyError(PyErrorKind.halted, 'Chương trình đã được dừng.', line: line);
    }
  }

  _Flow _execBlock(List<Stmt> body, Scope scope) {
    for (final stmt in body) {
      final flow = _exec(stmt, scope);
      if (flow != _Flow.normal) return flow;
    }
    return _Flow.normal;
  }

  _Flow _exec(Stmt stmt, Scope scope) {
    _tick(stmt.line);
    try {
      switch (stmt) {
        case ExprStmt s:
          _eval(s.expr, scope);
          return _Flow.normal;
        case AssignStmt s:
          final value = _eval(s.value, scope);
          for (final target in s.targets) {
            _assign(target, value, scope);
          }
          return _Flow.normal;
        case AugAssignStmt s:
          final current = _eval(s.target, scope);
          final value = _binary(s.op, current, _eval(s.value, scope), s.line);
          _assign(s.target, value, scope);
          return _Flow.normal;
        case IfStmt s:
          if (_truthy(_eval(s.condition, scope))) return _execBlock(s.body, scope);
          return _execBlock(s.orElse, scope);
        case WhileStmt s:
          while (_truthy(_eval(s.condition, scope))) {
            _tick(s.line);
            final flow = _execBlock(s.body, scope);
            if (flow == _Flow.breakLoop) break;
            if (flow == _Flow.returned) return flow;
          }
          return _Flow.normal;
        case ForStmt s:
          final iterable = _eval(s.iterable, scope);
          for (final item in _iterate(iterable, s.iterable.line)) {
            scope.vars[s.variable] = item;
            final flow = _execBlock(s.body, scope);
            if (flow == _Flow.breakLoop) break;
            if (flow == _Flow.returned) return flow;
          }
          return _Flow.normal;
        case FunctionDefStmt s:
          if (_builtins.vars.containsKey(s.name) && _isProtectedName(s.name)) {
            throw PyError(PyErrorKind.runtime, 'Tên "${s.name}" đã là một lệnh có sẵn. Hãy đặt tên hàm khác nhé.',
                line: s.line);
          }
          final defaults = [for (final d in s.defaults) d == null ? null : _eval(d, scope)];
          scope.vars[s.name] = PyFunction(s, scope, defaults);
          return _Flow.normal;
        case ReturnStmt s:
          _returnValue = s.value == null ? PyNone.instance : _eval(s.value!, scope);
          return _Flow.returned;
        case BreakStmt _:
          return _Flow.breakLoop;
        case ContinueStmt _:
          return _Flow.continueLoop;
        case PassStmt _:
          return _Flow.normal;
      }
    } on PyError catch (e) {
      e.line ??= stmt.line;
      rethrow;
    }
  }

  bool _isProtectedName(String name) => name == 'print' || name == 'len' || name == 'range';

  void _assign(Expr target, Object? value, Scope scope) {
    switch (target) {
      case NameExpr n:
        if (_isProtectedName(n.id)) {
          throw PyError(PyErrorKind.runtime,
              'Không nên đặt tên biến là "${n.id}" vì đó là lệnh có sẵn của Python. Hãy chọn tên khác nhé.',
              line: n.line);
        }
        scope.vars[n.id] = value;
      case SubscriptExpr s:
        final container = _eval(s.target, scope);
        final index = _eval(s.index, scope);
        if (container is PyList) {
          final i = _normalizeIndex(index, container.items.length, s.line, 'danh sách');
          container.items[i] = value;
        } else if (container is String) {
          throw typeError('Chuỗi chữ không thể sửa từng ký tự. Hãy tạo một chuỗi mới.',
              "'str' object does not support item assignment", s.line);
        } else {
          throw typeError('Không thể gán vào [ ] của giá trị kiểu ${_typeName(container)}.',
              "'${_typeName(container)}' object does not support item assignment", s.line);
        }
      default:
        throw syntaxError('Không thể gán giá trị vào đây.', target.line, 'cannot assign to expression');
    }
  }

  // --------------------------------------------------------- expressions

  Object? _eval(Expr expr, Scope scope) {
    switch (expr) {
      case Literal e:
        return e.value;
      case NameExpr e:
        final value = scope.lookup(e.id);
        if (Scope.isMissing(value)) throw _nameError(e.id, e.line, scope);
        return value;
      case FStringExpr e:
        final buf = StringBuffer();
        for (final part in e.parts) {
          if (part is String) {
            buf.write(part);
          } else {
            buf.write(pyStr(_eval(part as Expr, scope)));
          }
        }
        return _checkString(buf.toString(), e.line);
      case ListExpr e:
        final items = <Object?>[for (final el in e.elements) _eval(el, scope)];
        return PyList(items);
      case UnaryExpr e:
        final v = _eval(e.operand, scope);
        if (e.op == 'not') return !_truthy(v);
        final n = _numeric(v);
        if (n == null) {
          throw typeError('Dấu "${e.op}" chỉ dùng trước một con số.', "bad operand type for unary ${e.op}: '${_typeName(v)}'",
              e.line);
        }
        if (e.op == '-') {
          if (n is int) return -n;
          return -(n as double);
        }
        return n;
      case BinaryExpr e:
        return _binary(e.op, _eval(e.left, scope), _eval(e.right, scope), e.line);
      case BoolExpr e:
        Object? last;
        for (final v in e.values) {
          last = _eval(v, scope);
          final t = _truthy(last);
          if (e.op == 'and' && !t) return last;
          if (e.op == 'or' && t) return last;
        }
        return last;
      case CompareExpr e:
        var left = _eval(e.left, scope);
        for (var i = 0; i < e.ops.length; i++) {
          final right = _eval(e.comparators[i], scope);
          if (!_compare(e.ops[i], left, right, e.line)) return false;
          left = right;
        }
        return true;
      case TernaryExpr e:
        return _truthy(_eval(e.condition, scope)) ? _eval(e.ifTrue, scope) : _eval(e.ifFalse, scope);
      case CallExpr e:
        return _call(e, scope);
      case AttributeExpr e:
        return _attribute(_eval(e.target, scope), e.name, e.line);
      case SubscriptExpr e:
        return _index(_eval(e.target, scope), _eval(e.index, scope), e.line);
    }
  }

  PyError _nameError(String name, int line, Scope scope) {
    final known = <String>{};
    Scope? s = scope;
    while (s != null) {
      known.addAll(s.vars.keys);
      s = s.parent;
    }
    String? suggestion;
    var best = 99;
    for (final k in known) {
      final d = _levenshtein(name.toLowerCase(), k.toLowerCase());
      if (d < best) {
        best = d;
        suggestion = k;
      }
    }
    if (best > (name.length <= 3 ? 1 : 2)) suggestion = null;
    final buf = StringBuffer('Mình chưa biết "$name" là gì.');
    if (suggestion != null && suggestion != name) {
      if (suggestion.toLowerCase() == name.toLowerCase()) {
        buf.write(' Python phân biệt chữ hoa và chữ thường — có phải ý bạn là "$suggestion"?');
      } else {
        buf.write(' Có phải ý bạn là "$suggestion"?');
      }
    } else {
      buf.write(' Nếu đó là biến, hãy tạo nó trước (ví dụ: $name = 0). Nếu muốn viết chữ, hãy đặt trong dấu ngoặc kép: "$name".');
    }
    return PyError(PyErrorKind.nameError, buf.toString(),
        line: line, pythonName: 'NameError', pythonMessage: "name '$name' is not defined");
  }

  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final cur = List<int>.filled(b.length + 1, 0);
      cur[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        cur[j] = math.min(math.min(cur[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost);
      }
      prev = cur;
    }
    return prev[b.length];
  }

  Object? _call(CallExpr e, Scope scope) {
    final callee = _eval(e.callee, scope);
    final args = <Object?>[for (final a in e.args) _eval(a, scope)];
    final kwargs = <String, Object?>{for (final k in e.kwargs.entries) k.key: _eval(k.value, scope)};
    _tick(e.line);
    if (callee is PyBuiltin) return callee.impl(args, kwargs, e.line);
    if (callee is PyBoundMethod) return callee.impl(args, kwargs, e.line);
    if (callee is PyFunction) return _callFunction(callee, args, kwargs, e.line);
    final what = e.callee is NameExpr ? '"${(e.callee as NameExpr).id}"' : 'Giá trị này';
    throw typeError('$what là ${_typeNameVi(callee)}, không phải hàm, nên không gọi bằng dấu ( ) được.',
        "'${_typeName(callee)}' object is not callable", e.line);
  }

  Object? _callFunction(PyFunction fn, List<Object?> args, Map<String, Object?> kwargs, int line) {
    if (_depth >= limits.maxCallDepth) {
      throw PyError(
        PyErrorKind.limit,
        'Các hàm gọi lồng nhau quá ${limits.maxCallDepth} tầng! Nếu hàm tự gọi chính nó, hãy chắc chắn có điều kiện để dừng.',
        line: line,
        pythonName: 'RecursionError',
        pythonMessage: 'maximum recursion depth exceeded',
      );
    }
    final params = fn.def.params;
    if (args.length > params.length) {
      throw typeError('Hàm ${fn.name}() nhận ${params.length} giá trị nhưng bạn đưa vào ${args.length}.',
          '${fn.name}() takes ${params.length} positional arguments but ${args.length} were given', line);
    }
    final local = Scope(fn.closure);
    final remaining = Map<String, Object?>.of(kwargs);
    for (var i = 0; i < params.length; i++) {
      final p = params[i];
      if (i < args.length) {
        if (remaining.containsKey(p)) {
          throw typeError('Tham số "$p" của ${fn.name}() được truyền hai lần.',
              "${fn.name}() got multiple values for argument '$p'", line);
        }
        local.vars[p] = args[i];
      } else if (remaining.containsKey(p)) {
        local.vars[p] = remaining.remove(p);
      } else if (fn.def.defaults[i] != null) {
        local.vars[p] = fn.defaultValues[i];
      } else {
        throw typeError('Hàm ${fn.name}() còn thiếu giá trị cho tham số "$p".',
            "${fn.name}() missing 1 required positional argument: '$p'", line);
      }
    }
    if (remaining.isNotEmpty) {
      final k = remaining.keys.first;
      throw typeError('Hàm ${fn.name}() không có tham số tên "$k".',
          "${fn.name}() got an unexpected keyword argument '$k'", line);
    }
    _depth++;
    try {
      final flow = _execBlock(fn.def.body, local);
      if (flow == _Flow.returned) {
        final v = _returnValue;
        _returnValue = null;
        return v;
      }
      if (flow == _Flow.breakLoop || flow == _Flow.continueLoop) {
        throw syntaxError('"break"/"continue" chỉ dùng được bên trong vòng lặp.', fn.def.line, "'break' outside loop");
      }
      return PyNone.instance;
    } finally {
      _depth--;
    }
  }

  // ------------------------------------------------------------ operators

  Object? _numeric(Object? v) {
    if (v is bool) return v ? 1 : 0;
    if (v is int || v is double) return v;
    return null;
  }

  Object? _binary(String op, Object? a, Object? b, int line) {
    final na = _numeric(a);
    final nb = _numeric(b);
    if (na != null && nb != null) return _arith(op, na, nb, line);
    switch (op) {
      case '+':
        if (a is String && b is String) return _checkString(a + b, line);
        if (a is PyList && b is PyList) return _checkList(PyList([...a.items, ...b.items]), line);
        if (a is String && nb != null) {
          throw typeError(
              'Không thể cộng chữ với số. Hãy đổi số thành chữ bằng str(...), ví dụ: "Điểm: " + str(10).',
              'can only concatenate str (not "${_typeName(b)}") to str', line);
        }
        if (na != null && b is String) {
          throw typeError(
              'Không thể cộng số với chữ. Nếu muốn ghép thành câu, hãy dùng str(...) cho con số.',
              "unsupported operand type(s) for +: '${_typeName(a)}' and 'str'", line);
        }
      case '*':
        if (a is String && nb is int) return _checkString(a * math.max(0, nb), line);
        if (na is int && b is String) return _checkString(b * math.max(0, na), line);
        if (a is PyList && nb is int) return _repeatList(a, nb, line);
        if (na is int && b is PyList) return _repeatList(b, na, line);
      case '%':
        if (a is String) {
          throw unsupported('định dạng chuỗi bằng dấu % (hãy dùng f-string, ví dụ f"Điểm: {diem}")', line);
        }
    }
    final symbol = op;
    throw typeError(
        'Không dùng được phép "$symbol" giữa ${_typeNameVi(a)} và ${_typeNameVi(b)}.',
        "unsupported operand type(s) for $symbol: '${_typeName(a)}' and '${_typeName(b)}'", line);
  }

  Object _arith(String op, Object a, Object b, int line) {
    if (a is int && b is int) {
      switch (op) {
        case '+':
          final r = a + b;
          if ((a > 0 && b > 0 && r < 0) || (a < 0 && b < 0 && r >= 0)) throw _overflow(line);
          return r;
        case '-':
          final r = a - b;
          if ((a >= 0 && b < 0 && r < 0) || (a < 0 && b > 0 && r >= 0)) throw _overflow(line);
          return r;
        case '*':
          if (a.abs() > 3037000499 || b.abs() > 3037000499) {
            final big = BigInt.from(a) * BigInt.from(b);
            if (!big.isValidInt) throw _overflow(line);
            return big.toInt();
          }
          return a * b;
        case '/':
          if (b == 0) throw _zeroDivision('division by zero', line);
          return a / b;
        case '//':
          if (b == 0) throw _zeroDivision('integer division or modulo by zero', line);
          return _floorDiv(a, b);
        case '%':
          if (b == 0) throw _zeroDivision('integer modulo by zero', line);
          return _pyMod(a, b);
        case '**':
          if (b < 0) {
            if (a == 0) throw _zeroDivision('0.0 cannot be raised to a negative power', line);
            return math.pow(a.toDouble(), b).toDouble();
          }
          if (a == 0) return b == 0 ? 1 : 0;
          if (a == 1) return 1;
          if (a == -1) return b.isEven ? 1 : -1;
          if (b > 64) throw _overflow(line);
          final big = BigInt.from(a).pow(b);
          if (!big.isValidInt) throw _overflow(line);
          return big.toInt();
      }
    }
    final x = (a as num).toDouble();
    final y = (b as num).toDouble();
    switch (op) {
      case '+':
        return x + y;
      case '-':
        return x - y;
      case '*':
        return x * y;
      case '/':
        if (y == 0) throw _zeroDivision('float division by zero', line);
        return x / y;
      case '//':
        if (y == 0) throw _zeroDivision('float floor division by zero', line);
        return (x / y).floorToDouble();
      case '%':
        if (y == 0) throw _zeroDivision('float modulo', line);
        final r = x % y;
        return (y < 0 && r != 0) ? r + y : r;
      case '**':
        if (x == 0 && y < 0) throw _zeroDivision('0.0 cannot be raised to a negative power', line);
        if (x < 0 && y != y.roundToDouble()) {
          throw valueError('Lũy thừa số âm với số mũ thập phân cho ra số phức — PyQuest Python chưa hỗ trợ.',
              'math domain error', line);
        }
        return math.pow(x, y).toDouble();
    }
    throw syntaxError('Phép toán "$op" chưa được hỗ trợ.', line);
  }

  static int _floorDiv(int a, int b) {
    final q = a ~/ b;
    if ((a % b != 0) && ((a < 0) != (b < 0))) return q - 1;
    return q;
  }

  static int _pyMod(int a, int b) {
    final r = a % b; // Dart: non-negative for b != 0
    return (b < 0 && r != 0) ? r + b : r;
  }

  PyError _overflow(int line) => PyError(
        PyErrorKind.valueError,
        'Con số quá lớn với PyQuest Python (giới hạn khoảng 9 tỉ tỉ). Python thật tính được số lớn hơn, '
        'nhưng phiên bản mô phỏng này thì chưa.',
        line: line,
        pythonName: 'OverflowError',
        pythonMessage: 'PyQuest integer limit',
      );

  PyError _zeroDivision(String pyMsg, int line) => PyError(PyErrorKind.zeroDivision,
      'Không thể chia cho 0 nhé! Hãy kiểm tra số chia.', line: line, pythonName: 'ZeroDivisionError', pythonMessage: pyMsg);

  PyList _repeatList(PyList list, int times, int line) {
    final n = math.max(0, times);
    if (list.items.length * n > limits.maxCollectionLength) throw _tooLong('Danh sách', line);
    final out = <Object?>[];
    for (var i = 0; i < n; i++) {
      out.addAll(list.items);
    }
    return PyList(out);
  }

  String _checkString(String s, int line) {
    if (s.length > limits.maxStringLength) throw _tooLong('Chuỗi chữ', line);
    return s;
  }

  PyList _checkList(PyList l, int line) {
    if (l.items.length > limits.maxCollectionLength) throw _tooLong('Danh sách', line);
    return l;
  }

  PyError _tooLong(String what, int line) => PyError(PyErrorKind.limit,
      '$what quá dài so với giới hạn của PyQuest Python. Hãy dùng ít phần tử hơn nhé.', line: line);

  bool _compare(String op, Object? a, Object? b, int line) {
    switch (op) {
      case '==':
        return pyEquals(a, b);
      case '!=':
        return !pyEquals(a, b);
      case 'is':
        return _identical(a, b);
      case 'is not':
        return !_identical(a, b);
      case 'in':
        return _contains(b, a, line);
      case 'not in':
        return !_contains(b, a, line);
    }
    final c = _order(a, b, op, line);
    switch (op) {
      case '<':
        return c < 0;
      case '>':
        return c > 0;
      case '<=':
        return c <= 0;
      case '>=':
        return c >= 0;
    }
    throw syntaxError('Phép so sánh "$op" chưa được hỗ trợ.', line);
  }

  bool _identical(Object? a, Object? b) {
    if (a is PyNone || a == null) return b is PyNone || b == null;
    if (a is bool || a is int || a is String) return a == b;
    return identical(a, b);
  }

  int _order(Object? a, Object? b, String op, int line) {
    final na = _numeric(a);
    final nb = _numeric(b);
    if (na != null && nb != null) return (na as num).compareTo(nb as num);
    if (a is String && b is String) return a.compareTo(b);
    if (a is PyList && b is PyList) {
      for (var i = 0; i < math.min(a.items.length, b.items.length); i++) {
        if (!pyEquals(a.items[i], b.items[i])) return _order(a.items[i], b.items[i], op, line);
      }
      return a.items.length.compareTo(b.items.length);
    }
    throw typeError('Không thể so sánh ${_typeNameVi(a)} với ${_typeNameVi(b)} bằng "$op".',
        "'$op' not supported between instances of '${_typeName(a)}' and '${_typeName(b)}'", line);
  }

  bool _contains(Object? container, Object? item, int line) {
    if (container is String) {
      if (item is! String) {
        throw typeError('Để kiểm tra "in" với chuỗi chữ, giá trị bên trái cũng phải là chữ.',
            "'in <string>' requires string as left operand, not ${_typeName(item)}", line);
      }
      return container.contains(item);
    }
    if (container is PyList) return container.items.any((x) => pyEquals(x, item));
    if (container is PyRange) {
      final n = _numeric(item);
      if (n is! int) return false;
      if (container.step > 0 ? (n < container.start || n >= container.stop) : (n > container.start || n <= container.stop)) {
        return false;
      }
      return (n - container.start) % container.step == 0;
    }
    throw typeError('Không thể dùng "in" với ${_typeNameVi(container)}.',
        "argument of type '${_typeName(container)}' is not iterable", line);
  }

  // -------------------------------------------------------- data access

  int _normalizeIndex(Object? index, int length, int line, String what) {
    final n = index is bool ? (index ? 1 : 0) : index;
    if (n is! int) {
      throw typeError('Vị trí trong [ ] phải là số nguyên, không phải ${_typeNameVi(index)}.',
          'indices must be integers, not ${_typeName(index)}', line);
    }
    final i = n < 0 ? n + length : n;
    if (i < 0 || i >= length) {
      final range = length == 0 ? '$what đang trống' : 'vị trí hợp lệ từ 0 đến ${length - 1}';
      throw PyError(PyErrorKind.indexError, 'Vị trí $n không có trong $what ($range).',
          line: line, pythonName: 'IndexError', pythonMessage: what == 'chuỗi' ? 'string index out of range' : 'list index out of range');
    }
    return i;
  }

  Object? _index(Object? target, Object? index, int line) {
    if (target is PyList) return target.items[_normalizeIndex(index, target.items.length, line, 'danh sách')];
    if (target is String) {
      final runes = target.runes.toList();
      return String.fromCharCode(runes[_normalizeIndex(index, runes.length, line, 'chuỗi')]);
    }
    if (target is PyRange) return target[_normalizeIndex(index, target.length, line, 'range')];
    throw typeError('Không thể lấy phần tử [ ] từ ${_typeNameVi(target)}.',
        "'${_typeName(target)}' object is not subscriptable", line);
  }

  Iterable<Object?> _iterate(Object? value, int line) sync* {
    if (value is PyRange) {
      final n = value.length;
      for (var i = 0; i < n; i++) {
        _tick(line);
        yield value[i];
      }
    } else if (value is PyList) {
      for (var i = 0; i < value.items.length; i++) {
        _tick(line);
        yield value.items[i];
      }
    } else if (value is String) {
      for (final r in value.runes) {
        _tick(line);
        yield String.fromCharCode(r);
      }
    } else {
      throw typeError(
          'Không thể lặp qua ${_typeNameVi(value)}. Nếu muốn lặp nhiều lần, hãy dùng range(...), ví dụ: for i in range(5):',
          "'${_typeName(value)}' object is not iterable", line);
    }
  }

  List<Object?> _materialize(Object? value, int line) {
    final out = <Object?>[];
    for (final v in _iterate(value, line)) {
      out.add(v);
      if (out.length > limits.maxCollectionLength) throw _tooLong('Danh sách', line);
    }
    return out;
  }

  Object? _attribute(Object? target, String name, int line) {
    BuiltinImpl? impl;
    if (target is PyList) impl = _listMethod(target, name);
    if (target is String) impl = _stringMethod(target, name);
    if (impl == null) {
      throw PyError(PyErrorKind.typeError, '${_typeNameVi(target)} không có phương thức "$name".',
          line: line, pythonName: 'AttributeError', pythonMessage: "'${_typeName(target)}' object has no attribute '$name'");
    }
    return PyBoundMethod(target, name, impl);
  }

  void _arity(String name, List<Object?> args, int min, int max, int line) {
    if (args.length < min || args.length > max) {
      final expected = min == max ? '$min' : '$min đến $max';
      throw typeError('$name() cần $expected giá trị nhưng nhận ${args.length}.',
          '$name() takes ${min == max ? 'exactly $min' : 'from $min to $max'} arguments (${args.length} given)', line);
    }
  }

  BuiltinImpl? _listMethod(PyList list, String name) {
    switch (name) {
      case 'append':
        return (args, kw, line) {
          _arity('append', args, 1, 1, line);
          list.items.add(args[0]);
          _checkList(list, line);
          return PyNone.instance;
        };
      case 'pop':
        return (args, kw, line) {
          _arity('pop', args, 0, 1, line);
          if (list.items.isEmpty) {
            throw PyError(PyErrorKind.indexError, 'Danh sách đang trống nên không lấy ra được phần tử nào.',
                line: line, pythonName: 'IndexError', pythonMessage: 'pop from empty list');
          }
          final i = args.isEmpty ? list.items.length - 1 : _normalizeIndex(args[0], list.items.length, line, 'danh sách');
          return list.items.removeAt(i);
        };
      case 'insert':
        return (args, kw, line) {
          _arity('insert', args, 2, 2, line);
          final raw = _numeric(args[0]);
          if (raw is! int) throw typeError('Vị trí chèn phải là số nguyên.', 'integer argument expected', line);
          var i = raw < 0 ? raw + list.items.length : raw;
          i = i.clamp(0, list.items.length);
          list.items.insert(i, args[1]);
          _checkList(list, line);
          return PyNone.instance;
        };
      case 'remove':
        return (args, kw, line) {
          _arity('remove', args, 1, 1, line);
          final i = list.items.indexWhere((x) => pyEquals(x, args[0]));
          if (i < 0) {
            throw valueError('Không tìm thấy ${pyRepr(args[0])} trong danh sách để xoá.', 'list.remove(x): x not in list', line);
          }
          list.items.removeAt(i);
          return PyNone.instance;
        };
      case 'index':
        return (args, kw, line) {
          _arity('index', args, 1, 1, line);
          final i = list.items.indexWhere((x) => pyEquals(x, args[0]));
          if (i < 0) throw valueError('Không tìm thấy ${pyRepr(args[0])} trong danh sách.', '${pyRepr(args[0])} is not in list', line);
          return i;
        };
      case 'count':
        return (args, kw, line) {
          _arity('count', args, 1, 1, line);
          return list.items.where((x) => pyEquals(x, args[0])).length;
        };
      case 'clear':
        return (args, kw, line) {
          _arity('clear', args, 0, 0, line);
          list.items.clear();
          return PyNone.instance;
        };
      case 'reverse':
        return (args, kw, line) {
          _arity('reverse', args, 0, 0, line);
          final r = list.items.reversed.toList();
          list.items
            ..clear()
            ..addAll(r);
          return PyNone.instance;
        };
      case 'sort':
        return (args, kw, line) {
          _arity('sort', args, 0, 0, line);
          final reverse = _truthy(kw['reverse'] ?? false);
          list.items.sort((x, y) => _order(x, y, '<', line));
          if (reverse) {
            final r = list.items.reversed.toList();
            list.items
              ..clear()
              ..addAll(r);
          }
          return PyNone.instance;
        };
      case 'copy':
        return (args, kw, line) => PyList(List<Object?>.of(list.items));
    }
    return null;
  }

  BuiltinImpl? _stringMethod(String s, String name) {
    String needStr(Object? v, String fn, int line) {
      if (v is String) return v;
      throw typeError('$fn() cần một chuỗi chữ.', 'must be str, not ${_typeName(v)}', line);
    }

    switch (name) {
      case 'upper':
        return (args, kw, line) => s.toUpperCase();
      case 'lower':
        return (args, kw, line) => s.toLowerCase();
      case 'strip':
        return (args, kw, line) => s.trim();
      case 'capitalize':
        return (args, kw, line) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
      case 'isdigit':
        return (args, kw, line) => s.isNotEmpty && RegExp(r'^[0-9]+$').hasMatch(s);
      case 'replace':
        return (args, kw, line) {
          _arity('replace', args, 2, 2, line);
          return _checkString(s.replaceAll(needStr(args[0], 'replace', line), needStr(args[1], 'replace', line)), line);
        };
      case 'startswith':
        return (args, kw, line) {
          _arity('startswith', args, 1, 1, line);
          return s.startsWith(needStr(args[0], 'startswith', line));
        };
      case 'endswith':
        return (args, kw, line) {
          _arity('endswith', args, 1, 1, line);
          return s.endsWith(needStr(args[0], 'endswith', line));
        };
      case 'find':
        return (args, kw, line) {
          _arity('find', args, 1, 1, line);
          return s.indexOf(needStr(args[0], 'find', line));
        };
      case 'count':
        return (args, kw, line) {
          _arity('count', args, 1, 1, line);
          final sub = needStr(args[0], 'count', line);
          if (sub.isEmpty) return s.length + 1;
          var count = 0;
          var from = 0;
          while (true) {
            final i = s.indexOf(sub, from);
            if (i < 0) break;
            count++;
            from = i + sub.length;
          }
          return count;
        };
      case 'split':
        return (args, kw, line) {
          _arity('split', args, 0, 1, line);
          if (args.isEmpty || args[0] is PyNone) {
            return PyList(s.trim().split(RegExp(r'\s+')).where((x) => x.isNotEmpty).toList());
          }
          final sep = needStr(args[0], 'split', line);
          if (sep.isEmpty) throw valueError('Dấu tách không được rỗng.', 'empty separator', line);
          return PyList(s.split(sep));
        };
      case 'join':
        return (args, kw, line) {
          _arity('join', args, 1, 1, line);
          final parts = _materialize(args[0], line);
          for (final p in parts) {
            if (p is! String) {
              throw typeError('join() chỉ nối được các chuỗi chữ. Hãy đổi số thành chữ bằng str(...).',
                  'sequence item: expected str instance, ${_typeName(p)} found', line);
            }
          }
          return _checkString(parts.cast<String>().join(s), line);
        };
    }
    return null;
  }

  // ------------------------------------------------------------- builtins

  void _installBuiltins() {
    void def(String name, BuiltinImpl impl) => _builtins.vars[name] = PyBuiltin(name, impl);

    def('print', (args, kw, line) {
      for (final k in kw.keys) {
        if (k != 'sep' && k != 'end') {
          throw typeError('print() không có tuỳ chọn "$k". Chỉ có sep và end.',
              "'$k' is an invalid keyword argument for print()", line);
        }
      }
      String opt(String key, String fallback) {
        final v = kw[key];
        if (v == null || v is PyNone) return fallback;
        if (v is String) return v;
        throw typeError('$key phải là chuỗi chữ.', '$key must be None or a string, not ${_typeName(v)}', line);
      }

      final text = args.map(pyStr).join(opt('sep', ' ')) + opt('end', '\n');
      _write(text, line);
      return PyNone.instance;
    });
    def('len', (args, kw, line) {
      _arity('len', args, 1, 1, line);
      final v = args[0];
      if (v is String) return v.runes.length;
      if (v is PyList) return v.items.length;
      if (v is PyRange) return v.length;
      throw typeError('Không đo được độ dài của ${_typeNameVi(v)}.', "object of type '${_typeName(v)}' has no len()", line);
    });
    def('range', (args, kw, line) {
      _arity('range', args, 1, 3, line);
      final ints = <int>[];
      for (final a in args) {
        final n = _numeric(a);
        if (n is! int) {
          throw typeError('range() chỉ nhận số nguyên, không nhận ${_typeNameVi(a)}.',
              "'${_typeName(a)}' object cannot be interpreted as an integer", line);
        }
        ints.add(n);
      }
      if (ints.length == 1) return PyRange(0, ints[0], 1);
      final step = ints.length == 3 ? ints[2] : 1;
      if (step == 0) throw valueError('Bước nhảy của range() không được bằng 0.', 'range() arg 3 must not be zero', line);
      return PyRange(ints[0], ints[1], step);
    });
    def('str', (args, kw, line) {
      _arity('str', args, 0, 1, line);
      return args.isEmpty ? '' : pyStr(args[0]);
    });
    def('int', (args, kw, line) {
      _arity('int', args, 0, 1, line);
      if (args.isEmpty) return 0;
      final v = args[0];
      if (v is bool) return v ? 1 : 0;
      if (v is int) return v;
      if (v is double) {
        if (v.isNaN || v.isInfinite) throw valueError('Không đổi được $v thành số nguyên.', 'cannot convert float to integer', line);
        return v.truncate();
      }
      if (v is String) {
        final parsed = int.tryParse(v.trim().replaceAll('_', ''));
        if (parsed == null) {
          throw valueError('Không đổi được "${v.trim()}" thành số nguyên.',
              "invalid literal for int() with base 10: ${pyRepr(v)}", line);
        }
        return parsed;
      }
      throw typeError('Không đổi được ${_typeNameVi(v)} thành số nguyên.',
          "int() argument must be a string or a number, not '${_typeName(v)}'", line);
    });
    def('float', (args, kw, line) {
      _arity('float', args, 0, 1, line);
      if (args.isEmpty) return 0.0;
      final v = args[0];
      final n = _numeric(v);
      if (n != null) return (n as num).toDouble();
      if (v is String) {
        final t = v.trim().toLowerCase();
        if (t == 'inf' || t == '+inf') return double.infinity;
        if (t == '-inf') return double.negativeInfinity;
        final parsed = double.tryParse(t);
        if (parsed == null || t.contains('infinity') || t == 'nan') {
          throw valueError('Không đổi được "${v.trim()}" thành số thập phân.', "could not convert string to float: ${pyRepr(v)}", line);
        }
        return parsed;
      }
      throw typeError('Không đổi được ${_typeNameVi(v)} thành số thập phân.',
          "float() argument must be a string or a real number, not '${_typeName(v)}'", line);
    });
    def('bool', (args, kw, line) {
      _arity('bool', args, 0, 1, line);
      return args.isEmpty ? false : _truthy(args[0]);
    });
    def('abs', (args, kw, line) {
      _arity('abs', args, 1, 1, line);
      final n = _numeric(args[0]);
      if (n == null) throw typeError('abs() cần một con số.', "bad operand type for abs(): '${_typeName(args[0])}'", line);
      return n is int ? n.abs() : (n as double).abs();
    });
    def('round', (args, kw, line) {
      _arity('round', args, 1, 2, line);
      final n = _numeric(args[0]);
      if (n == null) throw typeError('round() cần một con số.', "type ${_typeName(args[0])} doesn't define __round__ method", line);
      if (args.length == 1 || args[1] is PyNone) {
        if (n is int) return n;
        final d = n as double;
        if (d.isNaN || d.isInfinite) {
          throw valueError('Không làm tròn được $d thành số nguyên.', 'cannot convert float to integer', line);
        }
        return _roundHalfEven(d).toInt();
      }
      final digits = _numeric(args[1]);
      if (digits is! int) throw typeError('Số chữ số làm tròn phải là số nguyên.', 'integer argument expected', line);
      if (n is int) return n;
      final factor = math.pow(10, digits).toDouble();
      return _roundHalfEven((n as double) * factor) / factor;
    });
    BuiltinImpl extreme(String name, bool wantMax) => (args, kw, line) {
          if (args.isEmpty) throw typeError('$name() cần ít nhất một giá trị.', '$name expected at least 1 argument, got 0', line);
          final items = args.length == 1 ? _materialize(args[0], line) : args;
          if (items.isEmpty) {
            throw valueError('$name() không dùng được với danh sách rỗng.', '$name() arg is an empty sequence', line);
          }
          var best = items.first;
          for (final v in items.skip(1)) {
            final c = _order(v, best, wantMax ? '>' : '<', line);
            if (wantMax ? c > 0 : c < 0) best = v;
          }
          return best;
        };
    def('min', extreme('min', false));
    def('max', extreme('max', true));
    def('sum', (args, kw, line) {
      _arity('sum', args, 1, 2, line);
      Object total = args.length == 2 ? (_numeric(args[1]) ?? 0) : 0;
      for (final v in _iterate(args[0], line)) {
        final n = _numeric(v);
        if (n == null) {
          throw typeError('sum() chỉ cộng được các con số.', "unsupported operand type(s) for +: 'int' and '${_typeName(v)}'", line);
        }
        total = _arith('+', total, n, line);
      }
      return total;
    });
    def('list', (args, kw, line) {
      _arity('list', args, 0, 1, line);
      return PyList(args.isEmpty ? <Object?>[] : _materialize(args[0], line));
    });
    def('sorted', (args, kw, line) {
      _arity('sorted', args, 1, 1, line);
      final items = _materialize(args[0], line)..sort((x, y) => _order(x, y, '<', line));
      if (_truthy(kw['reverse'] ?? false)) return PyList(items.reversed.toList());
      return PyList(items);
    });
    def('type', (args, kw, line) {
      _arity('type', args, 1, 1, line);
      return PyTypeObject(_typeName(args[0]));
    });
    def('input', (args, kw, line) {
      throw PyError(
        PyErrorKind.unsupported,
        'PyQuest Python chưa hỗ trợ input() (nhập từ bàn phím). Hãy gán giá trị trực tiếp, ví dụ: ten = "Py".',
        line: line,
      );
    });
  }

  static double _roundHalfEven(double x) {
    if (x.isNaN || x.isInfinite) return x;
    final f = x.floorToDouble();
    final diff = x - f;
    if (diff > 0.5) return f + 1;
    if (diff < 0.5) return f;
    return (f % 2 == 0) ? f : f + 1;
  }

  void _write(String text, int line) {
    final room = limits.maxOutputChars - output.length;
    if (text.length > room) {
      if (room > 0) output.write(text.substring(0, room));
      throw PyError(
        PyErrorKind.limit,
        'Chương trình in ra quá nhiều chữ rồi! PyQuest chỉ hiển thị tối đa ${limits.maxOutputChars} ký tự.',
        line: line,
      );
    }
    output.write(text);
  }

  // ------------------------------------------------------------- helpers

  static bool _truthy(Object? v) {
    if (v is bool) return v;
    if (v == null || v is PyNone) return false;
    if (v is int) return v != 0;
    if (v is double) return v != 0.0;
    if (v is String) return v.isNotEmpty;
    if (v is PyList) return v.items.isNotEmpty;
    if (v is PyRange) return v.length > 0;
    return true;
  }

  static String _typeName(Object? v) {
    if (v == null || v is PyNone) return 'NoneType';
    if (v is bool) return 'bool';
    if (v is int) return 'int';
    if (v is double) return 'float';
    if (v is String) return 'str';
    if (v is PyList) return 'list';
    if (v is PyRange) return 'range';
    if (v is PyFunction) return 'function';
    if (v is PyBuiltin || v is PyBoundMethod) return 'builtin_function_or_method';
    if (v is PyTypeObject) return 'type';
    return 'object';
  }

  static String _typeNameVi(Object? v) {
    switch (_typeName(v)) {
      case 'NoneType':
        return 'None (giá trị rỗng)';
      case 'bool':
        return 'giá trị đúng/sai (bool)';
      case 'int':
        return 'số nguyên (int)';
      case 'float':
        return 'số thập phân (float)';
      case 'str':
        return 'chuỗi chữ (str)';
      case 'list':
        return 'danh sách (list)';
      case 'range':
        return 'range';
      case 'function':
      case 'builtin_function_or_method':
        return 'một hàm';
      default:
        return 'giá trị này';
    }
  }
}

// --------------------------------------------------------------- formatting

/// Python's `str()` of a runtime value.
String pyStr(Object? v) {
  if (v == null || v is PyNone) return 'None';
  if (v is bool) return v ? 'True' : 'False';
  if (v is int) return v.toString();
  if (v is double) return pyFloat(v);
  if (v is String) return v;
  if (v is PyList) return '[${v.items.map(pyRepr).join(', ')}]';
  if (v is PyRange) return v.step == 1 ? 'range(${v.start}, ${v.stop})' : 'range(${v.start}, ${v.stop}, ${v.step})';
  if (v is PyFunction) return '<function ${v.name}>';
  if (v is PyBuiltin) return '<built-in function ${v.name}>';
  if (v is PyBoundMethod) return '<built-in method ${v.name}>';
  if (v is PyTypeObject) return "<class '${v.name}'>";
  return v.toString();
}

/// Python's `repr()`.
String pyRepr(Object? v) {
  if (v is String) {
    final useDouble = v.contains("'") && !v.contains('"');
    final q = useDouble ? '"' : "'";
    final escaped = v.replaceAll('\\', '\\\\').replaceAll('\n', '\\n').replaceAll('\t', '\\t');
    return useDouble ? '$q$escaped$q' : "$q${escaped.replaceAll("'", "\\'")}$q";
  }
  return pyStr(v);
}

String pyFloat(double v) {
  if (v.isNaN) return 'nan';
  if (v.isInfinite) return v > 0 ? 'inf' : '-inf';
  if (v == 0) return v.isNegative ? '-0.0' : '0.0';
  if (v == v.truncateToDouble() && v.abs() < 1e16) return v.toStringAsFixed(1);
  final a = v.abs();
  if (a >= 1e16 || (a < 1e-4 && a != 0)) {
    var s = v.toStringAsExponential();
    final m = RegExp(r'^(-?[\d.]+)e([+-])(\d+)$').firstMatch(s);
    if (m != null) {
      var mant = m.group(1)!;
      if (mant.contains('.')) {
        mant = mant.replaceFirst(RegExp(r'0+$'), '');
        if (mant.endsWith('.')) mant = mant.substring(0, mant.length - 1);
      }
      final exp = m.group(3)!.padLeft(2, '0');
      s = '${mant}e${m.group(2)}$exp';
    }
    return s;
  }
  return v.toString();
}

bool pyEquals(Object? a, Object? b) {
  if ((a == null || a is PyNone) && (b == null || b is PyNone)) return true;
  final na = a is bool ? (a ? 1 : 0) : a;
  final nb = b is bool ? (b ? 1 : 0) : b;
  if (na is num && nb is num) return na == nb;
  if (a is String && b is String) return a == b;
  if (a is PyList && b is PyList) {
    if (a.items.length != b.items.length) return false;
    for (var i = 0; i < a.items.length; i++) {
      if (!pyEquals(a.items[i], b.items[i])) return false;
    }
    return true;
  }
  if (a is PyRange && b is PyRange) return a.start == b.start && a.stop == b.stop && a.step == b.step;
  return identical(a, b);
}
