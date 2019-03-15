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

  final _indents = <int>[];

  static const defaultIndent = 2;

  void _indent([int size = defaultIndent]) {
    _indents.add(_indents.last + size);
  }

  void _unIndent() {
    _indents.removeLast();
  }

  @override
  void visitAnnotation(Annotation node) {
    // No call to super because annotations are treated in visitNode.
  }

  @override
  void visitAnnotatedNode(AnnotatedNode node) {
    _checkCommentsAndAnnotations(node);
    super.visitAnnotatedNode(node);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _checkIndent(node);
    super.visitAssertInitializer(node);
  }

  @override
  void visitBlock(Block node) {
    if (_startsLine(node)) _checkIndent(node);
    if (_isOneLiner(node)) {
      _checkSpaceAfter(node.leftBracket, 1);
      _checkSpaceBefore(node.rightBracket, 1);
      for (final statement in node.statements.skip(1)) {
        _checkSpaceBefore(statement.beginToken, 1);
      }
      node.visitChildren(this);
    } else if (node.rightBracket.precedingComments == null &&
        node.statements.isEmpty) {
      addError(
        'Use a oneliner for empty block',
        node.leftBracket.offset,
        node.rightBracket.end - node.leftBracket.offset,
      );
    } else {
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
        }
        lines.add(line);
      }
      _indent();
      node.visitChildren(this);
      _unIndent();
      _checkTokenIndent(node.rightBracket);
    }
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
  void visitClassDeclaration(ClassDeclaration node) {
    _checkStartsLine(node);
    _checkIndent(node);
    _indent();
    node.visitChildren(this);
    _unIndent();
  }

  @override
  void visitClassMember(ClassMember node) {
    _checkStartsLine(node);
    _checkIndent(node);
    super.visitClassMember(node);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    lineInfo = node.lineInfo;
    _indents.add(1);
    super.visitCompilationUnit(node);
    _unIndent();
  }

  @override
  void visitCompilationUnitMember(CompilationUnitMember node) {
    _checkStartsLine(node);
    _checkIndent(node);
    super.visitCompilationUnitMember(node);
  }

  @override
  void visitComment(Comment node) {
    // No call to super because comments are treated in visitNode.
    // (only doc comments reach this method)
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _checkCommentsAndAnnotations(node);
    _checkStartsLine(node);
    _checkIndent(node);
    if (node.period != null) {
      _checkSpaceBefore(node.period, 0);
      _checkSpaceAfter(node.period, 0);
    }
    _checkSpaceBefore(node.parameters.beginToken, 0);
    node.parameters.accept(this);
    if (node.separator != null) {
      if (_areOnSameLine(node.separator.offset, node.parameters.end)) {
        _checkSpaceBefore(node.separator, 1);
      }
      _checkSpaceAfter(node.separator, 1);
      if (node.initializers != null) {
        if (_isOneLiner(node) && node.initializers.length == 1) {
          node.initializers.accept(this);
        } else {
          if (_isOneLiner(node.parameters)) {
            _checkTokenStartsLine(node.separator);
            _checkLocation(node.separator.offset,
                column: _indents.last + defaultIndent);
          }
          _indent(_columnAt(node.separator.offset) + 2 - _indents.last);
          node.initializers.accept(this);
          node.initializers //
              .skip(1) // to avoid redondancy with space after colon
              .forEach(_checkIndent);
          _unIndent();
        }
      }
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    _checkStartsLine(node);
    _checkSpaceAfter(node.ifKeyword, 1);
    _checkSpaceAfter(node.leftParenthesis, 0);
    _checkSpaceBefore(node.rightParenthesis, 0);
    if (node.thenStatement is Block) {
      _checkSpaceBefore(node.thenStatement.beginToken, 1);
      node.thenStatement.accept(this);
    } else {
      _checkStartsLine(node.thenStatement);
      _indent();
      node.thenStatement.accept(this);
      _unIndent();
    }
    if (node.elseKeyword != null) {
      if (node.thenStatement is Block &&
          node.elseKeyword.precedingComments == null) {
        _checkSpaceBefore(node.elseKeyword, 1);
      } else {
        _checkTokenStartsLine(node.elseKeyword);
      }
      if (node.elseStatement is Block) {
        _checkSpaceBefore(node.elseStatement.beginToken, 1);
        node.elseStatement.accept(this);
      } else {
        _checkStartsLine(node.elseStatement);
        _indent();
        node.elseStatement.accept(this);
        _unIndent();
      }
    }
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    if (node.rightBracket.precedingComments == null && node.entries.isEmpty) {
      _checkSpaceAfter(node.leftBracket, 0);
    } else if (_isOneLiner(node)) {
      if (node.entries.length > 1) {
        addError('every entries should be on its own line',
            node.entries.beginToken.offset, 0);
      } else {
        _checkSpaceAfter(node.leftBracket, 0);
        node.entries.accept(this);
        _checkSpaceBefore(node.rightBracket, 0);
        if (node.rightBracket.previous.type == TokenType.COMMA) {
          addError('avoid trailing comma in a single element one liner map.',
              node.rightBracket.previous.offset, 1);
        }
      }
    } else {
      _indent();
      for (var entry in node.entries) {
        final token = entry.beginToken;
        _checkTokenStartsLine(token);
        _checkTokenIndent(token);
        if (entry.endToken.next.type != TokenType.COMMA) {
          addError('Add a trailing comma.', entry.endToken.end, 0);
        }
      }
      node.entries.accept(this);
      _unIndent();
      _checkTokenIndent(node.rightBracket);
    }
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    node.key.accept(this);
    _checkSpaceBefore(node.separator, 0);
    if (_areOnSameLine(node.separator.offset, node.value.offset)) {
      _checkSpaceAfter(node.separator, 1);
      node.value.accept(this);
    } else {
      _indent();
      node.value.accept(this);
      _unIndent();
    }
    if (node.endToken.next.type == TokenType.COMMA) {
      _checkSpaceAfter(node.endToken, 0);
    }
  }

  @override
  void visitStatement(Statement node) {
    if (_startsLine(node)) _checkIndent(node);
    super.visitStatement(node);
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

  Token _getBeginToken(AstNode node) {
    return node is AnnotatedNode
        ? node.firstTokenAfterCommentAndMetadata
        : node.beginToken;
  }

  bool _startsLine(AstNode node) {
    return _tokenStartsLine(_getBeginToken(node));
  }

  bool _tokenStartsLine(Token token) {
    return token.previous == null ||
        token.previous.offset == -1 ||
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
    return _areOnSameLine(_getBeginToken(node).offset, node.end);
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

  void _checkSpaceBefore(
    Token token,
    int numberOfSpaces, {
    bool skipIfEol = false,
  }) {
    final previousToken = _previousToken(token);
    if (previousToken == null ||
        skipIfEol && _areNotOnSameLine(previousToken.end, token.offset)) {
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

  void _checkSpaceAfter(
    Token token,
    int numberOfSpaces, {
    bool skipIfEol = false,
  }) {
    final nextToken = _nextToken(token);
    if (nextToken == null ||
        skipIfEol && _areNotOnSameLine(token.end, nextToken.offset)) {
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

  void _checkStartsLine(AstNode node) {
    _checkTokenStartsLine(_getBeginToken(node));
  }

  void _checkTokenStartsLine(Token token) {
    if (!_tokenStartsLine(token)) {
      addError(
        'It should start the line',
        token.offset,
        token.length,
      );
    }
  }

  void _checkIndent(AstNode node) {
    _checkTokenIndent(_getBeginToken(node));
  }

  void _checkTokenIndent(Token token) {
    _checkLocation(token.offset, column: _indents.last);
  }
}
