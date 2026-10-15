/// Abstract syntax tree for the PyQuest Python subset.
library;

sealed class Node {
  Node(this.line);
  final int line;
}

// ---------------------------------------------------------------- expressions

sealed class Expr extends Node {
  Expr(super.line);
}

class Literal extends Expr {
  Literal(super.line, this.value);
  final Object? value; // int, double, String, bool, PyNone
}

class FStringExpr extends Expr {
  FStringExpr(super.line, this.parts);

  /// Either [String] chunks or [Expr] to be converted with str().
  final List<Object> parts;
}

class NameExpr extends Expr {
  NameExpr(super.line, this.id);
  final String id;
}

class ListExpr extends Expr {
  ListExpr(super.line, this.elements);
  final List<Expr> elements;
}

class UnaryExpr extends Expr {
  UnaryExpr(super.line, this.op, this.operand);
  final String op; // '-', '+', 'not'
  final Expr operand;
}

class BinaryExpr extends Expr {
  BinaryExpr(super.line, this.left, this.op, this.right);
  final Expr left;
  final String op;
  final Expr right;
}

class BoolExpr extends Expr {
  BoolExpr(super.line, this.op, this.values);
  final String op; // 'and' | 'or'
  final List<Expr> values;
}

class CompareExpr extends Expr {
  CompareExpr(super.line, this.left, this.ops, this.comparators);
  final Expr left;
  final List<String> ops; // '<', '>', '==', '!=', '<=', '>=', 'in', 'not in', 'is', 'is not'
  final List<Expr> comparators;
}

class TernaryExpr extends Expr {
  TernaryExpr(super.line, this.condition, this.ifTrue, this.ifFalse);
  final Expr condition;
  final Expr ifTrue;
  final Expr ifFalse;
}

class CallExpr extends Expr {
  CallExpr(super.line, this.callee, this.args, this.kwargs);
  final Expr callee;
  final List<Expr> args;
  final Map<String, Expr> kwargs;
}

class AttributeExpr extends Expr {
  AttributeExpr(super.line, this.target, this.name);
  final Expr target;
  final String name;
}

class SubscriptExpr extends Expr {
  SubscriptExpr(super.line, this.target, this.index);
  final Expr target;
  final Expr index;
}

// ----------------------------------------------------------------- statements

sealed class Stmt extends Node {
  Stmt(super.line);
}

class ExprStmt extends Stmt {
  ExprStmt(super.line, this.expr);
  final Expr expr;
}

class AssignStmt extends Stmt {
  AssignStmt(super.line, this.targets, this.value);
  final List<Expr> targets; // NameExpr or SubscriptExpr
  final Expr value;
}

class AugAssignStmt extends Stmt {
  AugAssignStmt(super.line, this.target, this.op, this.value);
  final Expr target;
  final String op; // '+', '-', '*', '/', '//', '%', '**'
  final Expr value;
}

class IfStmt extends Stmt {
  IfStmt(super.line, this.condition, this.body, this.orElse);
  final Expr condition;
  final List<Stmt> body;
  final List<Stmt> orElse;
}

class WhileStmt extends Stmt {
  WhileStmt(super.line, this.condition, this.body);
  final Expr condition;
  final List<Stmt> body;
}

class ForStmt extends Stmt {
  ForStmt(super.line, this.variable, this.iterable, this.body);
  final String variable;
  final Expr iterable;
  final List<Stmt> body;
}

class FunctionDefStmt extends Stmt {
  FunctionDefStmt(super.line, this.name, this.params, this.defaults, this.body);
  final String name;
  final List<String> params;
  final List<Expr?> defaults;
  final List<Stmt> body;
}

class ReturnStmt extends Stmt {
  ReturnStmt(super.line, this.value);
  final Expr? value;
}

class BreakStmt extends Stmt {
  BreakStmt(super.line);
}

class ContinueStmt extends Stmt {
  ContinueStmt(super.line);
}

class PassStmt extends Stmt {
  PassStmt(super.line);
}
