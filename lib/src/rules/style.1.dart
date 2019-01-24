import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:flutter_style_guide_analyzer_plugin/src/checker.dart';

class SemiColonAtEolRule extends Rule with GeneralizingAstVisitor<void> {
  SemiColonAtEolRule(ErrorReporter addError)
      : super('semicolon_at_eol', addError);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    Token token = node.beginToken;
    do {
      if (token.lexeme == ';') {
        _visit(token);
      }
    } while ((token = token.next) != node.endToken);
  }

  void _visit(Token semicolon) {
    final previousEnd = semicolon.previous.end;
    final semicolonOffset = semicolon.offset;
    if (previousEnd != semicolonOffset) {
      final offset = previousEnd;
      final length = semicolonOffset - previousEnd;
      addErrorWithSimpleFix(
        'Semicolon should be next to its expression',
        offset,
        length,
        '',
        fixMessage: 'Remove empty chars before semicolon',
      );
    }
  }
}

class IndentRule3 extends Rule with GeneralizingAstVisitor<void> {
  IndentRule3(ErrorReporter addError) : super('indent', addError);

  LineInfo lineInfo;

  @override
  void visitBlock(Block node) {
    super.visitBlock(node);

    if (_lineAt(node.leftBracket.offset) == _lineAt(node.rightBracket.offset)) {
      {
        // space after left bracket
        final firstToken =
            node.leftBracket.next.precedingComments ?? node.leftBracket.next;
        if (false && node.leftBracket.end + 1 != firstToken.offset) {
          _checkIndentation(
              firstToken.offset, _columnAt(node.leftBracket.end) + 1);
        }
      }
      {
        // space before right bracket
        Token lastToken;
        if (node.rightBracket.precedingComments != null) {
          lastToken = node.rightBracket.precedingComments;
          while (lastToken.next != null) {
            lastToken = lastToken.next;
          }
        } else {
          lastToken = node.rightBracket.previous;
        }
        if (false && node.rightBracket.offset - 1 != lastToken.end) {
          _checkIndentation(
              node.rightBracket.offset, _columnAt(lastToken.end) + 1);
        }
      }
    } else {
      int baseOffset;
      if (node.parent is Block) {
        baseOffset = node.offset;
      } else if (node.parent is ForEachStatement) {
        final ref = node.parent as ForEachStatement;
        baseOffset =
            ref.awaitKeyword != null ? ref.awaitKeyword.offset : ref.offset;
      } else if (node.parent is Statement) {
        Statement ref = node.parent as Statement;
        if (ref is IfStatement) {
          while (ref.parent is IfStatement &&
              (ref.parent as IfStatement).elseStatement == ref) {
            ref = ref.parent as IfStatement;
          }
        }
        baseOffset = ref.offset;
      }
      if (baseOffset != null) {
        for (final child in node.statements) {
          _checkIndentationOfNode(child, _columnAt(baseOffset) + 2);
        }
        _checkIndentation(node.rightBracket.offset, _columnAt(baseOffset));
      }
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    super.visitClassDeclaration(node);
    _checkIndentationOfNode(node, 1);
  }

  @override
  void visitClassMember(ClassMember node) {
    super.visitClassMember(node);
    _checkIndentationOfNode(node, 3);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    super.visitClassTypeAlias(node);
    _checkIndentationOfNode(node, 1);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    lineInfo = node.lineInfo;
    super.visitCompilationUnit(node);
  }

  @override
  void visitDirective(Directive node) {
    super.visitDirective(node);
    _checkIndentationOfNode(node, 1);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    super.visitEnumDeclaration(node);
    _checkIndentationOfNode(node, 1);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    super.visitEnumConstantDeclaration(node);
    if (_lineAt(node.offset) !=
        _lineAt((node.parent as EnumDeclaration)
            .firstTokenAfterCommentAndMetadata
            .offset)) {
      _checkIndentationOfNode(node, 3);
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    super.visitIfStatement(node);
    IfStatement ref = node;
    while (ref.parent is IfStatement &&
        (ref.parent as IfStatement).elseStatement == ref) {
      ref = ref.parent as IfStatement;
    }
    if (node.thenStatement is! Block) {
      _checkIndentationOfNode(node.thenStatement, _columnAt(ref.offset) + 2);
    }
    if (node.elseKeyword != null && node.thenStatement is! Block) {
      _checkIndentation(node.elseKeyword.offset, _columnAt(ref.offset));
    }
    if (node.elseStatement != null &&
        node.elseStatement is! Block &&
        node.elseStatement is! IfStatement) {
      _checkIndentationOfNode(node.elseStatement, _columnAt(ref.offset) + 2);
    }
  }

  int _lineAt(int offset) => lineInfo.getLocation(offset).lineNumber;
  int _columnAt(int offset) => lineInfo.getLocation(offset).columnNumber;

  void _checkIndentationOfNode(AstNode node, int expectedColumn) {
    final offsets = <int>[];
    if (node is AnnotatedNode) {
      if (node.documentationComment != null) {
        node.documentationComment.tokens
            .map((e) => e.offset)
            .forEach(offsets.add);
      }
      if (node.metadata.isNotEmpty &&
          _lineAt(node.metadata.first.offset) ==
              _lineAt(node.firstTokenAfterCommentAndMetadata.offset)) {
        offsets.add(node.metadata.first.offset);
      } else {
        node.metadata.map((e) => e.offset).forEach(offsets.add);
        offsets.add(node.firstTokenAfterCommentAndMetadata.offset);
      }
    } else {
      offsets.add(node.offset);
    }
    for (final offset in offsets) {
      _checkIndentation(
        offset,
        expectedColumn,
        'Bad indentation (${dumpParents(node)})',
      );
    }
  }

  void _checkIndentation(
    int offset,
    int expectedColumn, [
    String message,
  ]) {
    final location = lineInfo.getLocation(offset);
    final start = location.columnNumber;
    if (start != expectedColumn) {
      addError(
        message ?? 'Bad position (expected at column $expectedColumn)',
        offset,
        0,
        //' ' * (expectedColumn - 1),
      );
    }
  }

  int _getOffset(AstNode node) {
    if (node is AnnotatedNode) {
      return node.childEntities
          .skipWhile((e) => e is Comment || e is Annotation)
          .first
          .offset;
    }
    return node.offset;
  }
}

class IndentRule2 extends Rule with GeneralizingAstVisitor<void> {
  IndentRule2(ErrorReporter addError) : super('indent', addError);

  LineInfo lineInfo;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    lineInfo = node.lineInfo;
    super.visitCompilationUnit(node);
  }

  @override
  void visitNode(AstNode node) {
    super.visitNode(node);

    AstNode parent = node.parent;
    if (node.parent == null) {
      return;
    }

    if (node is CommentReference) {
      return;
    }

    if (node is ConstructorInitializer) {
      _checkNode(
          node,
          lineInfo
                  .getLocation(
                      (parent as ConstructorDeclaration).separator.offset)
                  .columnNumber +
              2);
    } else if (node is Comment || node is Annotation) {
      _checkNode(node, lineInfo.getLocation(parent.offset).columnNumber);
    } else if (_lineAt(_getOffset(node)) != _lineAt(_getOffset(parent))) {
      int lineNumber = lineInfo.getLocation(_getOffset(parent)).lineNumber;
      while (parent.parent != null &&
          lineNumber ==
              lineInfo.getLocation(_getOffset(parent.parent)).lineNumber) {
        parent = parent.parent;
      }
      _checkNode(
          node,
          parent is CompilationUnit
              ? 1
              : lineInfo.getLocation(parent.offset).columnNumber + 2);
    }
  }

  int _getOffset(AstNode node) {
    if (node is AnnotatedNode) {
      return node.childEntities
          .skipWhile((e) => e is Comment || e is Annotation)
          .first
          .offset;
    }
    return node.offset;
  }

  int _lineAt(int offset) => lineInfo.getLocation(offset).lineNumber;
  void _checkNode(AstNode node, int expectedColumn) {
    final location = lineInfo.getLocation(node.offset);
    final start = location.columnNumber;
    if (start != expectedColumn) {
      final lineStart = lineInfo.getOffsetOfLine(location.lineNumber - 1);
      addErrorWithSimpleFix(
        'Indent by 2 spaces (${dumpParents(node)})',
        lineStart,
        start - 1,
        ' ' * (expectedColumn - 1),
      );
    }
  }
}

class IndentRule extends Rule with GeneralizingAstVisitor<void> {
  IndentRule(ErrorReporter addError) : super('indent', addError);

  LineInfo lineInfo;

  @override
  void visitComment(Comment node) {
    super.visitComment(node);
    if (node.isDocumentation) {
      _checkNode(
          node.offset, lineInfo.getLocation(node.parent.offset).columnNumber);
    }
  }

  @override
  void visitAnnotation(Annotation node) {
    super.visitAnnotation(node);
    _checkNode(
        node.offset, lineInfo.getLocation(node.parent.offset).columnNumber);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    lineInfo = node.lineInfo;
    super.visitCompilationUnit(node);

    for (final directive in node.directives) {
      _checkNode(directive.offset, 1);
    }
    for (final declaration in node.declarations) {
      _checkNode(declaration.offset, 1);
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    super.visitClassDeclaration(node);
    int column = lineInfo
        .getLocation(node.firstTokenAfterCommentAndMetadata.offset)
        .columnNumber;
    for (final member in node.members) {
      _checkNode(member.offset, column + 2);
      _checkNode(member.firstTokenAfterCommentAndMetadata.offset, column + 2);
    }
  }

  int _lineAt(int offset) => lineInfo.getLocation(offset).lineNumber;

  @override
  void visitBlock(Block block) {
    super.visitBlock(block);

    if (_lineAt(block.offset) == _lineAt(block.end)) {
      return;
    }

    int column;
    AstNode parent = block.parent;
    if (parent is Block) {
      column = lineInfo.getLocation(block.offset).columnNumber;
    } else if (parent is IfStatement ||
        parent is WhileStatement ||
        parent is ForStatement ||
        parent is DoStatement) {
      while ((parent.parent is IfStatement ||
              parent.parent is WhileStatement ||
              parent.parent is ForStatement ||
              parent.parent is DoStatement) &&
          _lineAt(parent.offset) == _lineAt(parent.parent.offset)) {
        parent = parent.parent;
      }
      column = lineInfo.getLocation(parent.offset).columnNumber;
    } else if (parent is BlockFunctionBody) {
      if (parent.parent is ConstructorDeclaration) {
        column = lineInfo
            .getLocation((parent.parent as ConstructorDeclaration)
                .firstTokenAfterCommentAndMetadata
                .offset)
            .columnNumber;
      } else if (parent.parent is MethodDeclaration) {
        column = lineInfo
            .getLocation((parent.parent as MethodDeclaration)
                .firstTokenAfterCommentAndMetadata
                .offset)
            .columnNumber;
      } else if (parent.parent is FunctionExpression &&
          parent.parent.parent is FunctionDeclaration) {
        column = lineInfo
            .getLocation((parent.parent.parent as FunctionDeclaration)
                .firstTokenAfterCommentAndMetadata
                .offset)
            .columnNumber;
      } else if (parent.parent is FunctionExpression &&
          parent.parent.parent is VariableDeclaration &&
          parent.parent.parent.parent is VariableDeclarationList &&
          parent.parent.parent.parent.parent is TopLevelVariableDeclaration) {
        column = lineInfo
            .getLocation((parent.parent.parent.parent.parent
                    as TopLevelVariableDeclaration)
                .firstTokenAfterCommentAndMetadata
                .offset)
            .columnNumber;
      } else if (parent.parent is FunctionExpression &&
          parent.parent.parent is VariableDeclaration &&
          parent.parent.parent.parent is VariableDeclarationList &&
          parent.parent.parent.parent.parent is FieldDeclaration) {
        column = lineInfo
            .getLocation(
                (parent.parent.parent.parent.parent as FieldDeclaration)
                    .firstTokenAfterCommentAndMetadata
                    .offset)
            .columnNumber;
      }
    }
    if (column == null) {
      addError(dumpParents(block), block.offset, 0);
      return;
    }
    // if (parent is FunctionExpression) {
    //   int lineNumber = lineInfo.getLocation(parent.offset).lineNumber;
    //   while (parent.parent != null &&
    //       lineNumber == lineInfo.getLocation(parent.parent.offset).lineNumber) {
    //     parent = parent.parent;
    //   }
    // }

    for (final statement in block.statements) {
      _checkNode(statement.offset, column + 2);
    }
  }

  void _checkNode(int offset, int expectedColumn) {
    final location = lineInfo.getLocation(offset);
    final start = location.columnNumber;
    if (start != expectedColumn) {
      final lineStart = lineInfo.getOffsetOfLine(location.lineNumber - 1);
      addErrorWithSimpleFix(
        'Indent by 2 spaces',
        lineStart,
        start - 1,
        ' ' * (expectedColumn - 1),
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
