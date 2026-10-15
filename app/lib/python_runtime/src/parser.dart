import 'ast.dart';
import 'errors.dart';
import 'lexer.dart';
import 'values.dart';

/// Recursive-descent parser for the PyQuest Python subset.
class Parser {
  Parser(this.tokens);

  final List<Token> tokens;
  int _i = 0;

  static List<Stmt> parseSource(String source) => Parser(Lexer(source).tokenize()).parseModule();

  Token get _tok => tokens[_i];
  Token get _next => tokens[_i + 1 < tokens.length ? _i + 1 : _i];

  Token _advance() => tokens[_i++];

  bool _atOp(String op) => _tok.isOp(op);
  bool _atName(String n) => _tok.isName(n);

  bool _acceptOp(String op) {
    if (_atOp(op)) {
      _i++;
      return true;
    }
    return false;
  }

  void _expectOp(String op, String friendly) {
    if (!_acceptOp(op)) {
      throw syntaxError(friendly, _tok.line, "expected '$op'");
    }
  }

  List<Stmt> parseModule() {
    final body = <Stmt>[];
    while (_tok.type != TokType.eof) {
      if (_tok.type == TokType.newline) {
        _i++;
        continue;
      }
      if (_tok.type == TokType.indent) {
        throw indentError('Dòng này bị thụt lề thừa. Hãy xoá bớt dấu cách ở đầu dòng.', _tok.line);
      }
      body.addAll(_statement());
    }
    return body;
  }

  List<Stmt> _statement() {
    final t = _tok;
    if (t.type == TokType.name) {
      switch (t.text) {
        case 'if':
          return [_ifStatement()];
        case 'while':
          return [_whileStatement()];
        case 'for':
          return [_forStatement()];
        case 'def':
          return [_functionDef()];
        case 'class':
          throw unsupported('class (lớp đối tượng)', t.line);
        case 'try':
        case 'except':
        case 'finally':
          throw unsupported('try/except', t.line);
        case 'with':
          throw unsupported('with', t.line);
        case 'elif':
        case 'else':
          throw syntaxError('"${t.text}" phải đi ngay sau một khối "if" (cùng mức thụt lề).', t.line);
      }
    }
    return _simpleStatementLine();
  }

  List<Stmt> _simpleStatementLine() {
    final stmts = <Stmt>[_smallStatement()];
    while (_acceptOp(';')) {
      if (_tok.type == TokType.newline || _tok.type == TokType.eof) break;
      stmts.add(_smallStatement());
    }
    if (_tok.type == TokType.newline) {
      _i++;
    } else if (_tok.type != TokType.eof && _tok.type != TokType.dedent) {
      throw _unexpectedAfterStatement();
    }
    return stmts;
  }

  PyError _unexpectedAfterStatement() {
    final t = _tok;
    final prev = tokens[_i - 1];
    if (t.type == TokType.string && prev.type == TokType.name) {
      return syntaxError('Hình như thiếu dấu ngoặc tròn. Hãy viết ${prev.text}(${_quoted(t)}).', t.line,
          "Missing parentheses in call to '${prev.text}'");
    }
    if (t.isOp('=')) {
      return syntaxError('Không thể gán giá trị vào vị trí này. Bên trái dấu = phải là tên biến.', t.line,
          'cannot assign to expression');
    }
    if (t.isOp(':')) {
      return syntaxError('Dấu ":" ở đây không đúng chỗ.', t.line);
    }
    return syntaxError(
        'Mình không hiểu "${t.text}" ở đây. Có thể thiếu dấu phẩy, dấu ngoặc hoặc phép tính (+, -, ...).', t.line);
  }

  String _quoted(Token t) => '"${t.text}"';

  Stmt _smallStatement() {
    final t = _tok;
    if (t.type == TokType.name) {
      switch (t.text) {
        case 'pass':
          _i++;
          return PassStmt(t.line);
        case 'break':
          _i++;
          return BreakStmt(t.line);
        case 'continue':
          _i++;
          return ContinueStmt(t.line);
        case 'return':
          _i++;
          if (_tok.type == TokType.newline || _tok.type == TokType.eof || _atOp(';')) {
            return ReturnStmt(t.line, null);
          }
          return ReturnStmt(t.line, _expression());
        case 'import':
        case 'from':
          throw unsupported('import (nạp thư viện)', t.line);
        case 'global':
        case 'nonlocal':
          throw unsupported('"${t.text}"', t.line);
        case 'lambda':
          throw unsupported('lambda', t.line);
        case 'del':
          throw unsupported('del', t.line);
        case 'assert':
        case 'raise':
          throw unsupported('"${t.text}"', t.line);
        case 'yield':
        case 'async':
        case 'await':
          throw unsupported('"${t.text}"', t.line);
      }
    }
    final first = _expression();
    if (_atOp(',')) {
      throw unsupported('gán nhiều giá trị cùng lúc bằng dấu phẩy (tuple)', _tok.line);
    }
    if (_atOp('=')) {
      final targets = <Expr>[first];
      Expr value = first;
      while (_acceptOp('=')) {
        value = _expression();
        targets.add(value);
      }
      targets.removeLast();
      for (final target in targets) {
        _checkAssignable(target);
      }
      return AssignStmt(t.line, targets, value);
    }
    const aug = {'+=': '+', '-=': '-', '*=': '*', '/=': '/', '//=': '//', '%=': '%', '**=': '**'};
    if (_tok.type == TokType.op && aug.containsKey(_tok.text)) {
      final op = aug[_advance().text]!;
      _checkAssignable(first);
      return AugAssignStmt(t.line, first, op, _expression());
    }
    return ExprStmt(t.line, first);
  }

  void _checkAssignable(Expr target) {
    if (target is NameExpr) {
      if (pyKeywords.contains(target.id)) {
        throw syntaxError('"${target.id}" là từ khoá của Python nên không dùng làm tên biến.', target.line);
      }
      return;
    }
    if (target is SubscriptExpr) return;
    if (target is Literal) {
      throw syntaxError('Không thể gán giá trị cho một con số hay chuỗi chữ. Tên biến phải ở bên trái dấu =.',
          target.line, 'cannot assign to literal');
    }
    if (target is CallExpr) {
      throw syntaxError('Không thể gán giá trị cho lời gọi hàm. Có phải bạn muốn so sánh bằng "=="?', target.line,
          'cannot assign to function call');
    }
    throw syntaxError('Bên trái dấu = phải là một tên biến.', target.line, 'cannot assign to expression');
  }

  // ------------------------------------------------------------ compound

  Stmt _ifStatement() {
    final line = _advance().line; // 'if' or 'elif'
    final condition = _condition('if');
    final body = _block('if');
    var orElse = <Stmt>[];
    if (_atName('elif')) {
      orElse = [_ifStatement()];
    } else if (_atName('else')) {
      _i++;
      _expectColon('else');
      orElse = _block('else');
    }
    return IfStmt(line, condition, body, orElse);
  }

  Expr _condition(String keyword) {
    if (_tok.type == TokType.newline || _atOp(':')) {
      throw syntaxError('Sau "$keyword" cần một điều kiện, ví dụ: $keyword diem > 10:', _tok.line);
    }
    final condition = _expression();
    if (_atOp('=')) {
      throw syntaxError('Trong điều kiện hãy dùng "==" để so sánh. Một dấu "=" là để gán giá trị.', _tok.line,
          "invalid syntax. Maybe you meant '==' instead of '='?");
    }
    _expectColon(keyword);
    return condition;
  }

  void _expectColon(String keyword) {
    if (!_acceptOp(':')) {
      throw syntaxError('Thiếu dấu hai chấm ":" ở cuối dòng "$keyword".', _tok.line, "expected ':'");
    }
  }

  List<Stmt> _block(String keyword) {
    if (_tok.type == TokType.newline) {
      _i++;
      if (_tok.type != TokType.indent) {
        throw indentError('Sau dòng "$keyword ...:" cần các lệnh thụt vào trong (thêm 4 dấu cách ở đầu dòng).',
            _tok.line, "expected an indented block after '$keyword' statement");
      }
      _i++;
      final body = <Stmt>[];
      while (_tok.type != TokType.dedent && _tok.type != TokType.eof) {
        if (_tok.type == TokType.newline) {
          _i++;
          continue;
        }
        if (_tok.type == TokType.indent) {
          throw indentError('Dòng này bị thụt lề thừa so với các dòng phía trên.', _tok.line);
        }
        body.addAll(_statement());
      }
      if (_tok.type == TokType.dedent) _i++;
      return body;
    }
    if (_tok.type == TokType.eof) {
      throw indentError('Sau dòng "$keyword ...:" cần ít nhất một lệnh.', _tok.line,
          "expected an indented block after '$keyword' statement");
    }
    return _simpleStatementLine();
  }

  Stmt _whileStatement() {
    final line = _advance().line;
    final condition = _condition('while');
    final body = _block('while');
    if (_atName('else')) throw unsupported('while ... else', _tok.line);
    return WhileStmt(line, condition, body);
  }

  Stmt _forStatement() {
    final line = _advance().line;
    final t = _tok;
    if (t.type != TokType.name || pyKeywords.contains(t.text)) {
      throw syntaxError('Sau "for" cần một tên biến, ví dụ: for i in range(3):', t.line);
    }
    _i++;
    if (_atOp(',')) throw unsupported('nhiều biến trong vòng lặp for', _tok.line);
    if (!_atName('in')) {
      throw syntaxError('Vòng lặp for cần từ "in", ví dụ: for ${t.text} in range(3):', _tok.line, "expected 'in'");
    }
    _i++;
    final iterable = _expression();
    _expectColon('for');
    final body = _block('for');
    if (_atName('else')) throw unsupported('for ... else', _tok.line);
    return ForStmt(line, t.text, iterable, body);
  }

  Stmt _functionDef() {
    final line = _advance().line;
    final nameTok = _tok;
    if (nameTok.type != TokType.name || pyKeywords.contains(nameTok.text)) {
      throw syntaxError('Sau "def" cần tên hàm, ví dụ: def chao():', nameTok.line);
    }
    _i++;
    _expectOp('(', 'Sau tên hàm cần dấu "(" — ví dụ: def ${nameTok.text}():');
    final params = <String>[];
    final defaults = <Expr?>[];
    if (!_atOp(')')) {
      do {
        if (_atOp(')')) break;
        final p = _tok;
        if (p.isOp('*') || p.isOp('**')) throw unsupported('tham số *args/**kwargs', p.line);
        if (p.type != TokType.name || pyKeywords.contains(p.text)) {
          throw syntaxError('Tham số của hàm phải là tên biến.', p.line);
        }
        _i++;
        if (params.contains(p.text)) {
          throw syntaxError('Tham số "${p.text}" bị lặp lại.', p.line, "duplicate argument '${p.text}'");
        }
        params.add(p.text);
        if (_acceptOp('=')) {
          defaults.add(_expression());
        } else {
          if (defaults.any((d) => d != null)) {
            throw syntaxError('Tham số không có giá trị mặc định phải đứng trước tham số có giá trị mặc định.', p.line,
                'non-default argument follows default argument');
          }
          defaults.add(null);
        }
      } while (_acceptOp(','));
    }
    _expectOp(')', 'Thiếu dấu ")" để đóng danh sách tham số.');
    _expectColon('def');
    final body = _block('def');
    return FunctionDefStmt(line, nameTok.text, params, defaults, body);
  }

  // ---------------------------------------------------------- expressions

  Expr _expression() {
    final t = _tok;
    if (t.isName('lambda')) throw unsupported('lambda', t.line);
    final value = _orTest();
    if (_atName('if')) {
      _i++;
      final condition = _orTest();
      if (!_atName('else')) {
        throw syntaxError('Biểu thức "... if ... else ..." cần phần "else".', _tok.line, "expected 'else'");
      }
      _i++;
      final other = _expression();
      return TernaryExpr(t.line, condition, value, other);
    }
    return value;
  }

  Expr _orTest() {
    final first = _andTest();
    if (!_atName('or')) return first;
    final values = [first];
    while (_atName('or')) {
      _i++;
      values.add(_andTest());
    }
    return BoolExpr(first.line, 'or', values);
  }

  Expr _andTest() {
    final first = _notTest();
    if (!_atName('and')) return first;
    final values = [first];
    while (_atName('and')) {
      _i++;
      values.add(_notTest());
    }
    return BoolExpr(first.line, 'and', values);
  }

  Expr _notTest() {
    if (_atName('not')) {
      final line = _advance().line;
      return UnaryExpr(line, 'not', _notTest());
    }
    return _comparison();
  }

  Expr _comparison() {
    final left = _arith();
    final ops = <String>[];
    final rights = <Expr>[];
    while (true) {
      final t = _tok;
      String? op;
      if (t.type == TokType.op && const {'<', '>', '==', '!=', '<=', '>='}.contains(t.text)) {
        op = t.text;
        _i++;
      } else if (t.isName('in')) {
        op = 'in';
        _i++;
      } else if (t.isName('not') && _next.isName('in')) {
        op = 'not in';
        _i += 2;
      } else if (t.isName('is')) {
        _i++;
        if (_atName('not')) {
          _i++;
          op = 'is not';
        } else {
          op = 'is';
        }
      } else if (t.isOp('!')) {
        throw syntaxError('Trong Python, "khác" viết là "!=" và "phủ định" viết là "not".', t.line);
      }
      if (op == null) break;
      ops.add(op);
      rights.add(_arith());
    }
    if (ops.isEmpty) return left;
    return CompareExpr(left.line, left, ops, rights);
  }

  Expr _arith() {
    var left = _term();
    while (_atOp('+') || _atOp('-')) {
      final op = _advance();
      left = BinaryExpr(op.line, left, op.text, _term());
    }
    if (_tok.type == TokType.op && const {'|', '&', '^', '<<', '>>'}.contains(_tok.text)) {
      throw unsupported('phép toán bit "${_tok.text}"', _tok.line);
    }
    return left;
  }

  Expr _term() {
    var left = _factor();
    while (_atOp('*') || _atOp('/') || _atOp('//') || _atOp('%')) {
      final op = _advance();
      left = BinaryExpr(op.line, left, op.text, _factor());
    }
    if (_atOp('@')) throw unsupported('toán tử @', _tok.line);
    return left;
  }

  Expr _factor() {
    if (_atOp('-') || _atOp('+')) {
      final op = _advance();
      return UnaryExpr(op.line, op.text, _factor());
    }
    if (_atOp('~')) throw unsupported('toán tử ~', _tok.line);
    return _power();
  }

  Expr _power() {
    final base = _primary();
    if (_atOp('**')) {
      final op = _advance();
      return BinaryExpr(op.line, base, '**', _factor());
    }
    return base;
  }

  Expr _primary() {
    var expr = _atom();
    while (true) {
      if (_atOp('(')) {
        expr = _call(expr);
      } else if (_atOp('[')) {
        final line = _advance().line;
        if (_atOp(':')) throw unsupported('cắt chuỗi/danh sách bằng dấu ":"', line);
        final index = _expression();
        if (_atOp(':')) throw unsupported('cắt chuỗi/danh sách bằng dấu ":"', line);
        _expectOp(']', 'Thiếu dấu "]" để đóng chỉ số.');
        expr = SubscriptExpr(line, expr, index);
      } else if (_atOp('.')) {
        final line = _advance().line;
        final name = _tok;
        if (name.type != TokType.name) {
          throw syntaxError('Sau dấu "." cần tên của phương thức, ví dụ: ds.append(5)', line);
        }
        _i++;
        expr = AttributeExpr(line, expr, name.text);
      } else {
        return expr;
      }
    }
  }

  Expr _call(Expr callee) {
    final line = _advance().line; // (
    final args = <Expr>[];
    final kwargs = <String, Expr>{};
    if (!_atOp(')')) {
      do {
        if (_atOp(')')) break;
        if (_atOp('*') || _atOp('**')) throw unsupported('dấu * khi gọi hàm', _tok.line);
        if (_tok.type == TokType.name && _next.isOp('=') && !pyKeywords.contains(_tok.text)) {
          final key = _advance().text;
          _i++; // =
          kwargs[key] = _expression();
        } else {
          if (kwargs.isNotEmpty) {
            throw syntaxError('Đối số có tên (ví dụ end="") phải đứng sau các đối số thường.', _tok.line,
                'positional argument follows keyword argument');
          }
          args.add(_expression());
          if (_atName('for')) throw unsupported('list comprehension', _tok.line);
        }
      } while (_acceptOp(','));
    }
    if (!_acceptOp(')')) {
      if (_tok.type == TokType.string || _tok.type == TokType.number || _tok.type == TokType.name) {
        throw syntaxError('Các giá trị trong dấu ngoặc cần được ngăn cách bằng dấu phẩy "," hoặc nối bằng dấu "+".',
            _tok.line, "invalid syntax. Perhaps you forgot a comma?");
      }
      throw syntaxError('Thiếu dấu ")" để đóng lời gọi hàm.', _tok.line, "'(' was never closed");
    }
    return CallExpr(line, callee, args, kwargs);
  }

  Expr _atom() {
    final t = _tok;
    switch (t.type) {
      case TokType.number:
        _i++;
        return Literal(t.line, t.value);
      case TokType.string:
        return _strings();
      case TokType.name:
        if (t.text == 'True') {
          _i++;
          return Literal(t.line, true);
        }
        if (t.text == 'False') {
          _i++;
          return Literal(t.line, false);
        }
        if (t.text == 'None') {
          _i++;
          return Literal(t.line, PyNone.instance);
        }
        if (pyKeywords.contains(t.text)) {
          throw syntaxError('"${t.text}" là từ khoá của Python, không đặt ở vị trí này được.', t.line);
        }
        _i++;
        return NameExpr(t.line, t.text);
      case TokType.op:
        if (t.text == '(') {
          _i++;
          if (_atOp(')')) throw unsupported('tuple rỗng ()', t.line);
          final inner = _expression();
          if (_atOp(',')) throw unsupported('tuple (nhiều giá trị trong dấu ngoặc tròn)', t.line);
          _expectOp(')', 'Thiếu dấu ")" để đóng ngoặc.');
          return inner;
        }
        if (t.text == '[') {
          _i++;
          final items = <Expr>[];
          while (!_atOp(']')) {
            items.add(_expression());
            if (_atName('for')) throw unsupported('list comprehension', _tok.line);
            if (!_acceptOp(',')) break;
          }
          _expectOp(']', 'Thiếu dấu "]" hoặc dấu phẩy giữa các phần tử của danh sách.');
          return ListExpr(t.line, items);
        }
        if (t.text == '{') throw unsupported('dictionary/set { }', t.line);
        break;
      case TokType.newline:
      case TokType.eof:
        throw syntaxError('Dòng này kết thúc giữa chừng — hình như còn thiếu một giá trị.', t.line);
      case TokType.indent:
        throw indentError('Dòng này bị thụt lề thừa.', t.line);
      case TokType.dedent:
        throw syntaxError('Câu lệnh chưa hoàn chỉnh.', t.line);
    }
    throw syntaxError('Mình không hiểu "${t.text}" ở đây.', t.line);
  }

  Expr _strings() {
    final first = _tok;
    final parts = <Object>[];
    var hasF = false;
    while (_tok.type == TokType.string) {
      final s = _advance();
      if (s.isFString) {
        hasF = true;
        parts.addAll(_parseFString(s));
      } else {
        parts.add(s.text);
      }
    }
    if (!hasF) return Literal(first.line, parts.cast<String>().join());
    return FStringExpr(first.line, parts);
  }

  List<Object> _parseFString(Token s) {
    final out = <Object>[];
    final text = s.text;
    final buf = StringBuffer();
    var i = 0;
    while (i < text.length) {
      final c = text[i];
      if (c == '{') {
        if (i + 1 < text.length && text[i + 1] == '{') {
          buf.write('{');
          i += 2;
          continue;
        }
        final end = text.indexOf('}', i);
        if (end < 0) {
          throw syntaxError('Trong f-string, dấu "{" cần có dấu "}" đi kèm.', s.line, "f-string: expecting '}'");
        }
        if (buf.isNotEmpty) {
          out.add(buf.toString());
          buf.clear();
        }
        final inner = text.substring(i + 1, end).trim();
        if (inner.isEmpty) {
          throw syntaxError('Trong f-string, giữa { } cần có tên biến hoặc phép tính.', s.line,
              'f-string: empty expression not allowed');
        }
        if (inner.contains(':') || inner.contains('!')) {
          throw unsupported('định dạng nâng cao trong f-string', s.line);
        }
        final sub = Lexer(inner).tokenize();
        // Re-number tokens to the f-string's line for clearer error messages.
        final renum = sub.map((t) => Token(t.type, t.text, s.line, value: t.value, isFString: t.isFString)).toList();
        final p = Parser(renum);
        final expr = p._expression();
        if (p._tok.type != TokType.newline && p._tok.type != TokType.eof) {
          throw syntaxError('Biểu thức trong f-string chưa đúng: {$inner}', s.line);
        }
        out.add(expr);
        i = end + 1;
        continue;
      }
      if (c == '}') {
        if (i + 1 < text.length && text[i + 1] == '}') {
          buf.write('}');
          i += 2;
          continue;
        }
        throw syntaxError('Trong f-string, dấu "}" đứng một mình. Dùng "}}" nếu muốn in dấu }.', s.line,
            "f-string: single '}' is not allowed");
      }
      buf.write(c);
      i++;
    }
    if (buf.isNotEmpty) out.add(buf.toString());
    return out;
  }
}
