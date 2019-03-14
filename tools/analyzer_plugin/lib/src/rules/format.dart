import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:flutter_style_guide_analyzer_plugin/src/ast_util.dart';
import 'package:flutter_style_guide_analyzer_plugin/src/checker.dart';
import 'package:meta/meta.dart';

class FormatRule extends Rule with GeneralizingAstVisitor<void> {
  FormatRule(ErrorReporter addError) : super('format', addError);

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
  void visitNode(AstNode node) {
    if (_startsLine(node)) {
      _checkIndent(node, node.offset);
    }
    super.visitNode(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.operator != null && _tokenStartsLine(node.operator)) {
      _checkIndent(node.methodName, node.operator.offset);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.operator != null && _tokenStartsLine(node.operator)) {
      _checkIndent(node.propertyName, node.operator.offset);
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitBlock(Block node) {
    if (_isOneLiner(node)) {
      _checkSpaceAfter(node.leftBracket, 1);
      _checkSpaceBefore(node.rightBracket, 1);
    } else if (node.rightBracket.precedingComments == null &&
        node.statements.isEmpty) {
      if (_areNotOnSameLine(
          node.leftBracket.offset, node.rightBracket.offset)) {
        addError(
          'Use a oneliner for empty block',
          node.leftBracket.offset,
          node.rightBracket.end - node.leftBracket.offset,
        );
      }
    } else {
      int column = _startOfLine(node.leftBracket);
      if (column != _columnAt(node.rightBracket.offset) ||
          !_tokenStartsLine(node.rightBracket)) {
        addError(
          'This closing parenthesis should start the line at column $column',
          node.rightBracket.offset,
          1,
        );
      }

      // check every statements on their own lines and at the good column
      final lines = <int>[];
      for (final statement in node.statements) {
        final line = _lineAt(statement.offset);
        if (lines.contains(line)) {
          addError(
            'This statement should be on its own line',
            statement.offset,
            statement.length,
          );
        } else if (_columnAt(_getRealOffset(statement)) != column + 2) {
          addError(
            'This statement should start at column $column',
            statement.offset,
            statement.length,
          );
        }
        lines.add(line);
      }
    }
    super.visitBlock(node);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    if (node.keyword != null) {
      _checkSpaceBefore(node.keyword, 1);
      if (node.star != null) {
        _checkSpaceBefore(node.star, 0);
      }
    }
    _checkSpaceBefore(node.block.leftBracket, 1);
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


  int _getBaseColumn(AstNode node, int offset) {
    int column;
    var current = node;
    var child;
    for (;;) {
      child = current;
      current = current?.parent;
      if (current == null) break;
      if (current.offset == offset) continue;

      if (current is MethodInvocation &&
          child is ArgumentList &&
          current.operator != null &&
          _tokenStartsLine(current.operator) &&
          _areNotOnSameLine(current.operator.offset, offset)) {
        column = _columnAt(current.operator.offset) + 2;
        break;
      }
      if (current is MethodInvocation &&
          current.operator != null &&
          _startsLine(current) &&
          _areNotOnSameLine(current.target.offset, current.operator.offset)) {
        column = _columnAt(current.target.offset) +
            ((!_isOneLiner(current.target) &&
                    _columnAt(_getRealOffset(current.target)) ==
                        _columnAt(_startOfLine(current.target.endToken)))
                ? 0
                : 2);
        break;
      }
      if (current is PropertyAccess &&
          current.operator != null &&
          _startsLine(current) &&
          _areNotOnSameLine(current.target.offset, current.operator.offset)) {
        column = _columnAt(current.target.offset) +
            ((!_isOneLiner(current.target) &&
                    _columnAt(_getRealOffset(current.target)) ==
                        _columnAt(_startOfLine(current.target.endToken)))
                ? 0
                : 2);
        break;
      }
      if (_startsLine(current) &&
          _areNotOnSameLine(current.offset, offset) &&
          (current is Statement ||
              current is MapLiteralEntry ||
              current is MapLiteral ||
              current is ListLiteral ||
              current is SetLiteral ||
              current is NamedExpression ||
              current is InstanceCreationExpression ||
              current is SwitchMember ||
              current is MethodInvocation ||
              current is! AdjacentStrings && current?.parent is ArgumentList ||
              current?.parent is CascadeExpression)) {
        column = _columnAt(current.offset) + 2;
        break;
      }
      if (current is ConditionalExpression &&
          _areNotOnSameLine(current.offset, current.elseExpression.offset) &&
          current.condition != child) {
        column = _columnAt(child.offset) + 2;
        break;
      }
    }
    return column;
  }


  void _checkIndent(AstNode node, int offset) {
    int column = _getBaseColumn(node, offset);
    if (column != null) {
      _checkLocation(offset,
          column: column,
          message: 'expected at column $column: ' + dumpParents(node));
    }
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

  int _startOfLine(Token token) {
    while (token.previous != null &&
        token.previous.offset != -1 &&
        token.previous != token &&
        _areOnSameLine(token.offset, token.previous.offset)) {
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

  void _checkSpaceBefore(Token token, int numberOfSpaces) {
    final previousToken = _previousToken(token);
    if (previousToken == null ||
        _areNotOnSameLine(previousToken.end, token.offset)) {
      return;
    }

    final locationOfPreviousEnd = lineInfo.getLocation(previousToken.end);
    if (!_isOffsetAtLocation(token.offset,
        line: locationOfPreviousEnd.lineNumber,
        column: locationOfPreviousEnd.columnNumber + numberOfSpaces)) {
      addError(
        'There should be $numberOfSpaces space',
        previousToken.end,
        token.offset - previousToken.end,
        subCode: 'space.before',
      );
    }
  }

  void _checkSpaceAfter(Token token, int numberOfSpaces) {
    final nextToken = _nextToken(token);
    if (nextToken == null || _areNotOnSameLine(token.end, nextToken.offset)) {
      return;
    }

    final locationOfEnd = lineInfo.getLocation(token.end);
    if (!_isOffsetAtLocation(nextToken.offset,
        line: locationOfEnd.lineNumber,
        column: locationOfEnd.columnNumber + numberOfSpaces)) {
      addError(
        'There should be $numberOfSpaces space',
        token.end,
        nextToken.offset - token.end,
        subCode: 'space.after',
      );
    }
  }

  Token _nextToken(Token token) {
    return token?.next?.precedingComments ?? token?.next;
  }

  Token _previousToken(Token token) {
    if (token.precedingComments != null) {
      Token result = token.precedingComments;
      while (result.next != null) {
        result = result.next;
      }
      return result;
    } else {
      return token.previous;
    }
  }
}
