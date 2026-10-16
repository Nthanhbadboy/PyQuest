import 'errors.dart';

enum TokType { name, number, string, op, newline, indent, dedent, eof }

class Token {
  Token(this.type, this.text, this.line, {this.value, this.isFString = false});

  final TokType type;
  final String text;
  final int line;

  /// Parsed literal value for numbers (int/double) and strings (String).
  final Object? value;
  final bool isFString;

  bool isOp(String op) => type == TokType.op && text == op;
  bool isName(String name) => type == TokType.name && text == name;

  @override
  String toString() => '$type($text)@$line';
}

const Set<String> pyKeywords = {
  'False', 'None', 'True', 'and', 'as', 'assert', 'async', 'await', 'break', 'class', 'continue',
  'def', 'del', 'elif', 'else', 'except', 'finally', 'for', 'from', 'global', 'if', 'import', 'in',
  'is', 'lambda', 'nonlocal', 'not', 'or', 'pass', 'raise', 'return', 'try', 'while', 'with', 'yield',
};

const List<String> _ops3 = ['**=', '//=', '>>=', '<<=', '...'];
const List<String> _ops2 = ['**', '//', '==', '!=', '<=', '>=', '+=', '-=', '*=', '/=', '%=', '->', '<<', '>>', ':='];
const String _ops1 = '+-*/%<>=()[]{},:.;@&|^~!';

final RegExp _identStart = RegExp(r'[\p{L}_]', unicode: true);
final RegExp _identPart = RegExp(r'[\p{L}\p{N}_]', unicode: true);

/// Converts source code into tokens, producing INDENT/DEDENT tokens the way
/// CPython's tokenizer does (tabs count as 4 spaces for kid-friendliness).
class Lexer {
  Lexer(String source) : src = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  final String src;
  int _pos = 0;
  int _line = 1;
  final List<int> _indents = [0];
  final List<_OpenBracket> _brackets = [];
  final List<Token> _tokens = [];

  List<Token> tokenize() {
    var atLineStart = true;
    while (_pos < src.length) {
      if (atLineStart && _brackets.isEmpty) {
        atLineStart = false;
        if (_handleIndentation()) {
          atLineStart = true;
          continue;
        }
      }
      if (_pos >= src.length) break;
      final c = src[_pos];
      if (c == '\n') {
        if (_brackets.isEmpty) {
          _emitNewline();
          atLineStart = true;
        }
        _line++;
        _pos++;
        continue;
      }
      if (c == ' ' || c == '\t') {
        _pos++;
        continue;
      }
      if (c == '#') {
        while (_pos < src.length && src[_pos] != '\n') {
          _pos++;
        }
        continue;
      }
      if (c == '\\') {
        if (_pos + 1 < src.length && src[_pos + 1] == '\n') {
          _pos += 2;
          _line++;
          continue;
        }
        throw syntaxError('Dấu \\ chỉ dùng bên trong chuỗi chữ.', _line, 'unexpected character after line continuation character');
      }
      if (_isDigit(c) || (c == '.' && _pos + 1 < src.length && _isDigit(src[_pos + 1]))) {
        _readNumber();
        continue;
      }
      if (c == '"' || c == "'") {
        _readString('');
        continue;
      }
      if (c == '“' || c == '”' || c == '‘' || c == '’') {
        throw syntaxError(
            'Dấu ngoặc kép cong “ ” không dùng được trong code. Hãy dùng dấu " thẳng trên bàn phím.', _line,
            "invalid character '$c'");
      }
      if (_identStart.hasMatch(c)) {
        final start = _pos;
        while (_pos < src.length && _identPart.hasMatch(src[_pos])) {
          _pos++;
        }
        final word = src.substring(start, _pos);
        final lower = word.toLowerCase();
        if (_pos < src.length && (src[_pos] == '"' || src[_pos] == "'") &&
            (lower == 'f' || lower == 'r' || lower == 'rf' || lower == 'fr' || lower == 'b' || lower == 'u')) {
          _readString(lower);
          continue;
        }
        _tokens.add(Token(TokType.name, word, _line));
        continue;
      }
      if (_readOperator()) continue;
      throw syntaxError('Mình không hiểu ký tự "$c" ở đây.', _line, "invalid character '$c'");
    }
    if (_brackets.isNotEmpty) {
      final open = _brackets.last;
      throw syntaxError('Dấu "${open.char}" ở dòng ${open.line} chưa được đóng. Hãy thêm "${_closing(open.char)}".',
          open.line, "'${open.char}' was never closed");
    }
    if (_tokens.isNotEmpty && _tokens.last.type != TokType.newline && _tokens.last.type != TokType.dedent) {
      _tokens.add(Token(TokType.newline, '', _line));
    }
    while (_indents.length > 1) {
      _indents.removeLast();
      _tokens.add(Token(TokType.dedent, '', _line));
    }
    _tokens.add(Token(TokType.eof, '', _line));
    return _tokens;
  }

  /// Measures indentation at the start of a logical line. Returns true when
  /// the line was blank / comment-only and has been skipped completely.
  bool _handleIndentation() {
    var width = 0;
    var p = _pos;
    while (p < src.length && (src[p] == ' ' || src[p] == '\t')) {
      width += src[p] == '\t' ? 4 : 1;
      p++;
    }
    if (p >= src.length) {
      _pos = p;
      return true;
    }
    if (src[p] == '\n' || src[p] == '#') {
      while (p < src.length && src[p] != '\n') {
        p++;
      }
      if (p < src.length) {
        p++;
        _line++;
      }
      _pos = p;
      return true;
    }
    _pos = p;
    final current = _indents.last;
    if (width > current) {
      _indents.add(width);
      _tokens.add(Token(TokType.indent, '', _line));
    } else if (width < current) {
      while (_indents.length > 1 && width < _indents.last) {
        _indents.removeLast();
        _tokens.add(Token(TokType.dedent, '', _line));
      }
      if (width != _indents.last) {
        throw indentError('Dòng này thụt lề không khớp với các dòng phía trên. Hãy thẳng hàng với khối lệnh trước đó.',
            _line, 'unindent does not match any outer indentation level');
      }
    }
    return false;
  }

  void _emitNewline() {
    if (_tokens.isEmpty) return;
    final last = _tokens.last.type;
    if (last == TokType.newline || last == TokType.indent || last == TokType.dedent) return;
    _tokens.add(Token(TokType.newline, '', _line));
  }

  bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

  void _readNumber() {
    final start = _pos;
    var isFloat = false;
    while (_pos < src.length && (_isDigit(src[_pos]) || src[_pos] == '_')) {
      _pos++;
    }
    if (_pos < src.length && src[_pos] == '.') {
      isFloat = true;
      _pos++;
      while (_pos < src.length && (_isDigit(src[_pos]) || src[_pos] == '_')) {
        _pos++;
      }
    }
    if (_pos < src.length && (src[_pos] == 'e' || src[_pos] == 'E')) {
      var p = _pos + 1;
      if (p < src.length && (src[p] == '+' || src[p] == '-')) p++;
      if (p < src.length && _isDigit(src[p])) {
        isFloat = true;
        _pos = p;
        while (_pos < src.length && _isDigit(src[_pos])) {
          _pos++;
        }
      }
    }
    final text = src.substring(start, _pos);
    if (_pos < src.length && _identStart.hasMatch(src[_pos])) {
      throw syntaxError('Tên biến không được bắt đầu bằng chữ số (ví dụ "$text${src[_pos]}...").', _line,
          'invalid decimal literal');
    }
    final clean = text.replaceAll('_', '');
    Object? value;
    if (isFloat) {
      value = double.tryParse(clean);
    } else {
      value = int.tryParse(clean);
      if (value == null) {
        throw PyError(PyErrorKind.valueError, 'Số $text quá lớn với PyQuest Python.', line: _line);
      }
    }
    _tokens.add(Token(TokType.number, text, _line, value: value));
  }

  void _readString(String prefix) {
    final startLine = _line;
    final quote = src[_pos];
    final triple = _pos + 2 < src.length && src[_pos + 1] == quote && src[_pos + 2] == quote;
    _pos += triple ? 3 : 1;
    final raw = prefix.contains('r');
    final buf = StringBuffer();
    while (true) {
      if (_pos >= src.length) {
        throw syntaxError('Chuỗi chữ bắt đầu ở dòng $startLine chưa được đóng. Hãy thêm dấu $quote ở cuối.', startLine,
            'unterminated string literal');
      }
      final c = src[_pos];
      if (triple) {
        if (c == quote && _pos + 2 < src.length && src[_pos + 1] == quote && src[_pos + 2] == quote) {
          _pos += 3;
          break;
        }
      } else if (c == quote) {
        _pos++;
        break;
      }
      if (c == '\n') {
        if (!triple) {
          throw syntaxError('Chuỗi chữ ở dòng $startLine chưa được đóng. Hãy thêm dấu $quote ở cuối dòng.', startLine,
              'unterminated string literal');
        }
        _line++;
        buf.write(c);
        _pos++;
        continue;
      }
      if (c == '\\' && !raw && _pos + 1 < src.length) {
        final n = src[_pos + 1];
        _pos += 2;
        switch (n) {
          case 'n':
            buf.write('\n');
          case 't':
            buf.write('\t');
          case '\\':
            buf.write('\\');
          case "'":
            buf.write("'");
          case '"':
            buf.write('"');
          case '\n':
            _line++;
          default:
            buf.write('\\');
            buf.write(n);
        }
        continue;
      }
      buf.write(c);
      _pos++;
    }
    final text = buf.toString();
    _tokens.add(Token(TokType.string, text, startLine, value: text, isFString: prefix.contains('f')));
  }

  bool _readOperator() {
    for (final op in _ops3) {
      if (src.startsWith(op, _pos)) {
        _tokens.add(Token(TokType.op, op, _line));
        _pos += 3;
        return true;
      }
    }
    for (final op in _ops2) {
      if (src.startsWith(op, _pos)) {
        _tokens.add(Token(TokType.op, op, _line));
        _pos += 2;
        return true;
      }
    }
    final c = src[_pos];
    if (_ops1.contains(c)) {
      if (c == '(' || c == '[' || c == '{') {
        _brackets.add(_OpenBracket(c, _line));
      } else if (c == ')' || c == ']' || c == '}') {
        if (_brackets.isEmpty) {
          throw syntaxError('Có dấu "$c" thừa — không có dấu mở tương ứng.', _line, "unmatched '$c'");
        }
        final open = _brackets.removeLast();
        if (_closing(open.char) != c) {
          throw syntaxError(
              'Dấu "$c" không khớp với dấu "${open.char}" ở dòng ${open.line}.', _line,
              "closing parenthesis '$c' does not match opening parenthesis '${open.char}'");
        }
      }
      _tokens.add(Token(TokType.op, c, _line));
      _pos++;
      return true;
    }
    return false;
  }

  static String _closing(String open) => open == '(' ? ')' : (open == '[' ? ']' : '}');
}

class _OpenBracket {
  _OpenBracket(this.char, this.line);
  final String char;
  final int line;
}
