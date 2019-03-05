import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:flutter_style_guide_analyzer_plugin/src/ast_util.dart';
import 'package:flutter_style_guide_analyzer_plugin/src/checker.dart';
import 'package:meta/meta.dart';

class SimpleIndentRule extends Rule with GeneralizingAstVisitor<void> {
  SimpleIndentRule(ErrorReporter addError) : super('simple_indent', addError);

  LineInfo lineInfo;

  @override
  void visitAnnotation(Annotation node) {
    // No call to super because annotations are treated in visitNode.
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _checkLocation(_getRealOffset(node), column: 1);
    _checkCommentsAndAnnotations(node);
    super.visitClassDeclaration(node);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    lineInfo = node.lineInfo;
    super.visitCompilationUnit(node);
  }

  @override
  void visitComment(Comment node) {
    // No call to super because comments are treated in visitNode.
    // (only doc comments reach this method)
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _checkLocation(_getRealOffset(node), column: 3);
    _checkCommentsAndAnnotations(node);
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitDirective(Directive node) {
    _checkLocation(_getRealOffset(node), column: 1);
    _checkCommentsAndAnnotations(node);
    super.visitDirective(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _checkLocation(_getRealOffset(node), column: 3);
    _checkCommentsAndAnnotations(node);
    super.visitFieldDeclaration(node);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    if (!_isOneLiner(node.block)) {
      int columnRef;
      AstNode current = node;
      final descendants = <AstNode>[];
      for (;;) {
        descendants.insert(0, current);
        current = current.parent;
        if (current == null) {
          break;
        }
        if (current is Statement ||
            current is ConstructorDeclaration ||
            current is ConstructorFieldInitializer ||
            current is SuperConstructorInvocation ||
            current is FunctionDeclaration ||
            current is MethodDeclaration ||
            current is FieldDeclaration ||
            current is TopLevelVariableDeclaration ||
            current is Assertion) {
          columnRef = _columnAt(_getRealOffset(current));
          break;
        }
        if (_startsLine(current) &&
            (current is NamedExpression ||
                current is MapLiteralEntry ||
                current is FunctionExpression ||
                current is InstanceCreationExpression)) {
          columnRef = _columnAt(_getRealOffset(current));
          break;
        }
        if (current is MethodInvocation) {
          if (current.operator != null) {
            if (_tokenStartsLine(current.operator)) {
              columnRef = _columnAt(current.operator.offset);
              break;
            }
            if (current.target != null && _startsLine(current.target)) {
              columnRef = _columnAt(_getRealOffset(current));
              break;
            }
          } else if (_startsLine(current)) {
            columnRef = _columnAt(_getRealOffset(current));
            break;
          }
        }
        if (current is ConditionalExpression) {
          if (descendants.first == current.thenExpression &&
              _tokenStartsLine(current.question)) {
            columnRef = _columnAt(_getRealOffset(descendants.first));
            break;
          }
          if (descendants.first == current.elseExpression &&
              _tokenStartsLine(current.colon)) {
            columnRef = _columnAt(_getRealOffset(descendants.first));
            break;
          }
        }
        if (current is ListLiteral && _startsLine(descendants.first)) {
          columnRef = _columnAt(_getRealOffset(descendants.first));
          break;
        }
        if (current is CascadeExpression && _startsLine(descendants.first)) {
          columnRef = _columnAt(_getRealOffset(descendants.first));
          break;
        }
      }
      if (columnRef == null) {
        addError(
          'unknown ancestor:' + dumpParents(node),
          node.offset,
          0,
        );
        return;
      } else if (columnRef != _columnAt(node.endToken.offset)) {
        addError(
          'This closing parenthesis should be at column $columnRef',
          node.endToken.offset,
          1,
        );
      }
      int column = columnRef + 2;
      for (final e in node.block.statements) {
        _checkLocation(_getRealOffset(e),
            column: column,
            message: 'expected at column $column : ' + dumpParents(node));
        _checkCommentsAndAnnotations(e);
      }
    }
    super.visitBlockFunctionBody(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _checkLocation(_getRealOffset(node), column: 3);
    _checkCommentsAndAnnotations(node);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _checkLocation(_getRealOffset(node), column: 1);
    _checkCommentsAndAnnotations(node);
    super.visitMixinDeclaration(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _checkLocation(_getRealOffset(node), column: 1);
    _checkCommentsAndAnnotations(node);
    super.visitTopLevelVariableDeclaration(node);
  }

  @override
  void visitTypeAlias(TypeAlias node) {
    _checkLocation(_getRealOffset(node), column: 1);
    _checkCommentsAndAnnotations(node);
    super.visitTypeAlias(node);
  }

  final _tokenAlreadyCheckedForComments = <Token>[];

  void _checkComments(Token beginToken) {
    Token comment = beginToken.precedingComments;
    if (comment == null) {
      return;
    } else if (_tokenAlreadyCheckedForComments.contains(comment)) {
      return;
    } else {
      _tokenAlreadyCheckedForComments.add(comment);
    }

    do {
      final column = _columnAt(comment.offset);
      final isDoc = comment.lexeme.startsWith('///');
      final isEol = !isDoc &&
          comment.previous == null &&
          beginToken.previous != null &&
          _lineAt(comment.offset) == _lineAt(beginToken.previous.end);
      if (isDoc) {
        _checkLocation(
          comment.offset,
          column: _columnAt(beginToken.offset),
          message: '$column != ${_columnAt(beginToken.offset)}',
        );
      } else if (isEol && comment.offset - beginToken.previous.end < 1) {
        addError(
          'Put at least one space before end of line comments',
          beginToken.previous.end,
          comment.offset - beginToken.previous.end,
        );
      }
    } while ((comment = comment.next) != null);
  }

  void _checkCommentsAndAnnotations(AstNode node) {
    if (node is AnnotatedNode) {
      for (final annotation in node.metadata) {
        _checkLocation(annotation.offset,
            column: _columnAt(node.firstTokenAfterCommentAndMetadata.offset));
      }
      _checkComments(node.firstTokenAfterCommentAndMetadata);
    } else {
      _checkComments(node.beginToken);
    }
  }

  int _getRealOffset(AstNode node) {
    return node is AnnotatedNode
        ? node.firstTokenAfterCommentAndMetadata.offset
        : node.offset;
  }

  bool _startsLine(AstNode node) {
    return _tokenStartsLine(node.beginToken);
  }

  bool _tokenStartsLine(Token token) {
    return token.previous == null ||
        !_areOnSameLine(token.offset, token.previous.end);
  }

  int _startOfLine(AstNode node) {
    var token = node.beginToken;
    while (_areOnSameLine(token.offset, token.previous.offset)) {
      token = token.previous;
    }
    return _columnAt(token.offset);
  }

  bool _isOneLiner(AstNode node) {
    return _areOnSameLine(
        node.end,
        node is AnnotatedNode
            ? node.firstTokenAfterCommentAndMetadata.offset
            : node.offset);
  }

  bool _areNotOnSameLine(int offset1, int offset2) {
    return !_areOnSameLine(offset1, offset2);
  }

  bool _areOnSameLine(int offset1, int offset2) {
    return _lineAt(offset1) == _lineAt(offset2);
  }

  int _lineAt(int offset) => lineInfo.getLocation(offset).lineNumber;
  int _columnAt(int offset) => lineInfo.getLocation(offset).columnNumber;

  void _checkLocation(
    int offset, {
    int line,
    @required int column,
    String subCode,
    String message,
  }) {
    if (!_isOffsetAtLocation(offset, line: line, column: column)) {
      addError(
        message ?? 'Bad position (expected at $line:$column)',
        offset,
        0,
        subCode: subCode,
      );
    }
  }

  bool _isOffsetAtLocation(
    int offset, {
    int line,
    @required int column,
  }) {
    final location = lineInfo.getLocation(offset);
    return (line == null || line == location.lineNumber) &&
        column == location.columnNumber;
  }
}
