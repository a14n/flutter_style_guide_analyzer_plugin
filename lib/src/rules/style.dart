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
    styleVisitor.visitNode(node);
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

  _StyleVisitor _indent([int padding = 2]) =>
      _StyleVisitor(indentation + padding, rule);

  @override
  void visitAnnotation(Annotation node) {
    // No call to super because annotations are treated in visitNode.
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    super.visitClassDeclaration(node);
    _checkIndentation(node.firstTokenAfterCommentAndMetadata.offset);
  }

  @override
  void visitClassMember(ClassMember node) {
    super.visitClassMember(node);
    _checkIndentation(node.firstTokenAfterCommentAndMetadata.offset);
  }

  @override
  void visitComment(Comment node) {
    // No call to super because comments are treated in visitNode.
    // (only doc comments reach this method)
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    super.visitEnumDeclaration(node);
    _checkIndentation(node.firstTokenAfterCommentAndMetadata.offset);
  }

  @override
  void visitForEachStatement(ForEachStatement node) {
    super.visitForEachStatement(node);
    _checkIndentation(node.offset);
  }

  @override
  void visitForStatement(ForStatement node) {
    super.visitForStatement(node);
    _checkIndentation(node.offset);
  }

  @override
  void visitIfStatement(IfStatement node) {
    super.visitIfStatement(node);
    if (node.parent is! IfStatement) {
      _checkIndentation(node.offset);
    }
    if (node.elseKeyword != null) {
      final thenStatement = node.thenStatement;
      _checkIndentation(node.elseKeyword.offset,
          column: thenStatement is Block
              ? _columnAt(thenStatement.end) + 1
              : expectedColumn);
    }
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    super.visitMixinDeclaration(node);
    _checkIndentation(node.firstTokenAfterCommentAndMetadata.offset);
  }

  @override
  void visitNamedCompilationUnitMember(NamedCompilationUnitMember node) {
    super.visitNamedCompilationUnitMember(node);
    _checkIndentation(node.firstTokenAfterCommentAndMetadata.offset);
  }

  @override
  void visitNode(AstNode node, {bool afterIndent = false}) {
    if (!afterIndent) {
      if (node is AnnotatedNode) {
        for (final annotation in node.metadata) {
          _checkIndentation(annotation.offset);
          _visitComments(annotation);
        }
      } else {
        _visitComments(node);
      }
    }
    if (!afterIndent && _needIndent(node)) {
      _indent().visitNode(node, afterIndent: true);
    } else {
      super.visitNode(node);
    }
  }

  bool _needIndent(AstNode node) {
    return node is BlockFunctionBody ||
        node is ClassDeclaration ||
        node is EnumDeclaration ||
        node is ForEachStatement ||
        node is ForStatement ||
        node is MixinDeclaration ||
        node is IfStatement && node.parent is! IfStatement ||
        node is SwitchMember ||
        node is SwitchStatement ||
        node is TryStatement ||
        node is WhileStatement;
  }

  @override
  void visitSwitchMember(SwitchMember node) {
    super.visitSwitchMember(node);
    _checkIndentation(node.offset);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    super.visitSwitchStatement(node);
    _checkIndentation(node.offset);
  }

  @override
  void visitTryStatement(TryStatement node) {
    super.visitTryStatement(node);
    _checkIndentation(node.offset);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    super.visitWhileStatement(node);
    _checkIndentation(node.offset);
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
        _checkIndentation(
          comment.offset,
          column: expectedColumn,
          message: '$column != $expectedColumn' + dumpParents(node),
        );
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
    int offset, {
    int column,
    String message,
  }) {
    column ??= expectedColumn;
    if (_columnAt(offset) != column) {
      rule.addError(
        message ?? 'Bad position (expected at column $column)',
        offset,
        0,
      );
    }
  }
}

String dumpParents(AstNode node) {
  if (node == null) return '';
  final types = <Type>[];
  do {
    types.insert(0, node.runtimeType);
  } while (node != node.parent && (node = node.parent) != null);
  return types.reversed.map((e) => '$e').join(' <- ');
}
