import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_style_guide_analyzer_plugin/src/ast_util.dart';
import 'package:flutter_style_guide_analyzer_plugin/src/checker.dart';

const indentSize = 2;

/// Ensure statements are indented with the same length.
class IndentationsRule extends Rule {
  IndentationsRule(ErrorReporter addError) : super('indentations', addError);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _Visitor(this).visitCompilationUnit(node);
  }
}

class _Visitor extends GeneralizingAstVisitor<void> {
  _Visitor(this.rule);

  final Rule rule;

  LocationHelper locationHelper;

  final indentStack = <Token>[];

  @override
  void visitCompilationUnit(CompilationUnit node) {
    locationHelper = LocationHelper(node.lineInfo);
    super.visitCompilationUnit(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    if (locationHelper.lineAt(node.offset) !=
        locationHelper.lineAt(node.question.offset)) {
      _indentAtToken(
        node.thenExpression.beginToken,
        () => node.thenExpression.accept(this),
      );
    }
    if (locationHelper.lineAt(node.question.offset) !=
        locationHelper.lineAt(node.colon.offset)) {
      _indentAtToken(
        node.elseExpression.beginToken,
        () => node.elseExpression.accept(this),
      );
    }
  }

  @override
  void visitConstructorInitializer(ConstructorInitializer node) {
    final constDeclaration = node.parent as ConstructorDeclaration;
    if (locationHelper.tokenStartsLine(constDeclaration.separator)) {
      _indentAtToken(
        node.beginToken,
        () => super.visitConstructorInitializer(node),
      );
    } else {
      super.visitConstructorInitializer(node);
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _indentAtToken(
      locationHelper.tokenStartingLine(node.beginToken),
      () => super.visitFunctionExpression(node),
    );
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _indentAtToken(
      locationHelper.tokenStartingLine(node.beginToken),
      () {
        node.elements.forEach(_checkIndent);
        super.visitListLiteral(node);
      },
    );
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _indentAtToken(
      locationHelper.tokenStartingLine(node.beginToken),
      () {
        // TODO dans le cas des Maps, on autorise une indentation supérieure uniquement si tous les éléments sont alignés niveau colon
        node.elements.forEach(_checkIndent);
        super.visitSetOrMapLiteral(node);
      },
    );
  }

  @override
  void visitStatement(Statement node) {
    _checkIndent(node);
    _indentAtNode(
      node.thisOrAncestorMatching((e) => locationHelper.startsLine(e)),
      () => super.visitStatement(node),
    );
  }

  @override
  void visitSwitchMember(SwitchMember node) {
    _checkIndent(node);
    _indentAtNode(node, () => super.visitSwitchMember(node));
  }

  void _indentAtNode(AstNode node, void Function() f) {
    _indentAtToken(getBeginToken(node), f);
  }

  void _indentAtToken(Token token, void Function() f) {
    if (indentStack.isNotEmpty &&
        locationHelper.lineAt(token.offset) <=
            locationHelper.lineAt(indentStack.last.offset)) {
      f();
    } else {
      indentStack.add(token);
      f();
      indentStack.removeLast();
    }
  }

  void _checkIndent(AstNode node) {
    if (!locationHelper.startsLine(node)) {
      return;
    }

    final expected = indentSize +
        (indentStack.isEmpty
            ? 1
            : locationHelper.columnAt(indentStack.last.offset));
    final current = locationHelper.columnAt(node.offset);
    final message = 'Indent issue (currently at $current '
        'but should be at $expected)'
        '';
    //', ${indentStack.map((e) => "${locationHelper.lineAt(e.offset)},${locationHelper.columnAt(e.offset)}").join('+')} / ${dumpParents(node)}';

    if (expected != current) {
      rule.addError(
        message,
        node.offset,
        0,
      );
    }
  }
}
