import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:flutter_style_guide_analyzer_plugin/src/checker.dart';

/// Ensure a trailing comma is used if the last parameter/argument in list is
/// not on the same line as the closing parenthesis.
///
/// There's an exception for argument list with only one element. It's allowed
/// to not have a trailing comma. However this exception doesn't apply for
/// constructor trees.
class TrailingCommasRule extends Rule with RecursiveAstVisitor<void> {
  TrailingCommasRule(ErrorReporter addError)
      : super('trailing_commas', addError);

  LineInfo lineInfo;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    lineInfo = node.lineInfo;
    super.visitCompilationUnit(node);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _visitNodeList(node.parameters);
    super.visitFormalParameterList(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (node.argumentList.arguments.length > 1)
      _visitNodeList(node.argumentList.arguments);
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.argumentList.arguments.length > 1) {
      _visitNodeList(node.argumentList.arguments);
    } else if (node.argumentList.arguments.length == 1) {
      var arg = node.argumentList.arguments.first;
      if (arg is NamedExpression) arg = (arg as NamedExpression).expression;
      if (arg is InstanceCreationExpression &&
          arg.argumentList.arguments.isNotEmpty &&
          arg.argumentList.arguments.last.endToken?.next?.type ==
              TokenType.COMMA) {
        _visitNodeList(node.argumentList.arguments);
      }
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _visitNodeList(node.elements);
    super.visitListLiteral(node);
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    _visitNodeList(node.entries);
    super.visitMapLiteral(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.argumentList.arguments.length > 1)
      _visitNodeList(node.argumentList.arguments);
    super.visitMethodInvocation(node);
  }

  void _visitNodeList<T extends AstNode>(NodeList<T> list) {
    if (list.isEmpty) return;

    if (list.last.endToken?.next?.type != TokenType.COMMA &&
        _lineOf(list.last.end) != _lineOf(list.owner.end)) {
      addError(
        'A trailing comma should end this line',
        list.last.end,
        0,
        fixMessage: 'Add a trailing comma',
        edits: [SourceEdit(list.last.end, 0, ',')],
      );
    }
  }

  int _lineOf(int offset) => lineInfo.getLocation(offset).lineNumber;
}
