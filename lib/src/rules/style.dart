import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:flutter_style_guide_analyzer_plugin/src/checker.dart';

class StyleRule extends Rule {
  StyleRule(ErrorReporter addError) : super('style', addError);

  LineInfo lineInfo;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    lineInfo = node.lineInfo;
    final styleVisitor = _StyleVisitor(0, this);
    styleVisitor.visitCompilationUnit(node);
  }
}

class _StyleVisitor extends GeneralizingAstVisitor<void> {
  _StyleVisitor(
    this.indentation,
    this.rule,
  );

  final int indentation;
  final StyleRule rule;

  int get expectedColumn => 1 + indentation;

  _StyleVisitor indent([int padding = 2]) =>
      _StyleVisitor(indentation + padding, rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _checkIndentation(node.firstTokenAfterCommentAndMetadata.offset);
    final visitor = indent();
    for (final member in node.members) {
      visitor.visitClassMember(member);
    }
  }

  @override
  void visitClassMember(ClassMember node) {
    super.visitClassMember(node);
    _checkIndentation(node.firstTokenAfterCommentAndMetadata.offset);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _checkIndentation(node.firstTokenAfterCommentAndMetadata.offset);
    final visitor = indent();
    for (final constant in node.constants) {
      visitor.visitEnumConstantDeclaration(constant);
    }
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _checkIndentation(node.firstTokenAfterCommentAndMetadata.offset);
    final visitor = indent();
    for (final member in node.members) {
      visitor.visitClassMember(member);
    }
  }

  @override
  void visitNamedCompilationUnitMember(NamedCompilationUnitMember node) {
    super.visitNamedCompilationUnitMember(node);
    _checkIndentation(node.firstTokenAfterCommentAndMetadata.offset);
  }

  @override
  void visitNode(AstNode node) {
    super.visitNode(node);
    _visitComments(node);
  }

  void _visitComments(AstNode node) {
    Token comment = node.beginToken.precedingComments;
    if (comment == null) {
      return;
    }

    do {
      final column = _columnAt(comment.offset);
      final isDoc = comment.lexeme.startsWith('///');
      final isEol = !isDoc &&
          comment.previous == null &&
          node.beginToken.previous != null &&
          _lineAt(comment.offset) == _lineAt(node.beginToken.previous.end);
      if (isDoc || !isEol && column > 1) {
        _checkIndentation(comment.offset);
      } else if (isEol && comment.offset - node.beginToken.previous.end < 1) {
        rule.addError(
          'Put at least one space before end of line comments',
          node.beginToken.previous.end,
          comment.offset - node.beginToken.previous.end,
        );
      }
    } while ((comment = comment.next) != null);
  }

  int _lineAt(int offset) => rule.lineInfo.getLocation(offset).lineNumber;
  int _columnAt(int offset) => rule.lineInfo.getLocation(offset).columnNumber;

  void _checkIndentation(
    int offset, [
    String message,
  ]) {
    if (_columnAt(offset) != expectedColumn) {
      rule.addError(
        message ?? 'Bad position (expected at column $expectedColumn)',
        offset,
        0,
      );
    }
  }
}
