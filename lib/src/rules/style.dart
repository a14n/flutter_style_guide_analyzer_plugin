import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:flutter_style_guide_analyzer_plugin/src/checker.dart';

class StyleRule extends Rule with GeneralizingAstVisitor<void> {
  StyleRule(ErrorReporter addError) : super('style', addError);

  LineInfo lineInfo;
  final List<int> indentations = [1];

  @override
  void visitAnnotation(Annotation node) {
    // No call to super because annotations are treated in visitNode.
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    node.leftHandSide.accept(this);
    _checkIndentation(node.operator.offset,
        column: _columnAt(node.leftHandSide.end) + 1);
    if (_lineAt(node.offset) != _lineAt(node.rightHandSide.offset)) {
      _indent(() {
        node.rightHandSide.accept(this);
      });
    } else {
      _checkIndentation(node.rightHandSide.offset,
          column: _columnAt(node.operator.end) + 1);
      node.rightHandSide.accept(this);
    }
  }

  @override
  void visitArgumentList(ArgumentList node) {
    if (node.arguments.isEmpty) {
      return;
    }
    Token previousToken = node.leftParenthesis;
    for (var expression in node.arguments) {
      if (_areOnSameLine(expression.offset, node.leftParenthesis.offset)) {
        expression.accept(this);
      } else {
        _indent(() {
          if (_lineAt(expression.offset) != _lineAt(previousToken.end)) {
            _checkIndentation(expression.offset);
          }
          expression.accept(this);
        });
      }
      previousToken = expression.endToken;
    }
  }

  @override
  void visitBlock(Block node) {
    if (_startsLine(node)) {
      _checkIndentation(node.offset);
    }
    _checkCommentsAndAnnotations(node);
    if (_isOneLiner(node)) {
      for (final statement in node.statements) {
        statement.accept(this);
      }
    } else {
      _indent(() {
        for (final statement in node.statements) {
          statement.accept(this);
        }
      });
    }
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    for (var section in node.cascadeSections) {
      if (_lineAt(node.offset) != _lineAt(section.offset)) {
        _indent(() {
          _checkIndentation(section.offset);
        });
      }
    }
    node.target?.accept(this);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _checkIndentation(node.offset);
    _checkCommentsAndAnnotations(node);
    _indent(() {
      for (final member in node.members) {
        member.accept(this);
      }
    });
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
    _checkIndentation(node.offset);
    _checkCommentsAndAnnotations(node);
    // TODO visit all
    if (node.separator?.type == TokenType.COLON) {
      if (_areOnSameLine(node.parameters.end, node.separator.offset)) {
        _checkIndentation(node.separator.offset,
            column: _columnAt(node.parameters.end) + 1);
      } else {
        _checkIndentation(node.separator.offset,
            column: _columnAt(node.firstTokenAfterCommentAndMetadata.offset) +
                (node.body is EmptyFunctionBody ? 2 : 4));
      }
      _indent(() {
        for (final initializer in node.initializers) {
          _checkIndentation(initializer.offset);
          initializer.accept(this);
        }
      },
          padding: _columnAt(node.separator.end) -
              _columnAt(node.firstTokenAfterCommentAndMetadata.offset) +
              1);
    }
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    super.visitDefaultFormalParameter(node);

    if (node.covariantKeyword != null) {
      _checkIndentation(node.covariantKeyword.next.offset,
          column: _columnAt(node.covariantKeyword.end) + 1);
    }
    if (node.separator != null) {
      _checkIndentation(node.separator.offset,
          column: _columnAt(node.separator.previous.end) + 1);
      _checkIndentation(node.separator.next.offset,
          column: _columnAt(node.separator.end) + 1);
    }
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _checkIndentation(node.offset);
    _checkCommentsAndAnnotations(node);
    _indent(() {
      for (final constant in node.constants) {
        constant.accept(this);
      }
    });
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    if (node.leftDelimiter != null) {
      if (node.parameters.every((e) => e.isOptional)) {
        _checkIndentation(node.leftDelimiter.offset,
            column: _columnAt(node.leftParenthesis.end));
      } else {
        _checkIndentation(node.leftDelimiter.offset,
            column: _columnAt(node.leftDelimiter.previous.end) + 1);
      }
    }
    if (node.rightDelimiter != null) {
      _checkIndentation(node.rightParenthesis.offset,
          column: _columnAt(node.rightDelimiter.end));
    }
    for (final parameter in node.parameters) {
      if (parameter.endToken.next.type == TokenType.COMMA) {
        _checkIndentation(parameter.endToken.next.offset,
            column: _columnAt(parameter.endToken.end));
      }
    }
    if (_areOnSameLine(
        node.leftParenthesis.offset, node.rightParenthesis.offset)) {
      for (final parameter in node.parameters) {
        parameter.accept(this);
        if (parameter.beginToken.previous.type == TokenType.COMMA) {
          _checkIndentation(parameter.offset,
              column: _columnAt(parameter.beginToken.previous.end) + 1);
        }
      }
      if (node.leftDelimiter != null) {
        _checkIndentation(node.leftDelimiter.next.offset,
            column: _columnAt(node.leftDelimiter.end) + 1);
        _checkIndentation(node.rightDelimiter.offset,
            column: _columnAt(node.rightDelimiter.previous.end) + 1);
      }
    } else {
      _indent(() {
        for (final parameter in node.parameters) {
          _checkIndentation(parameter.offset);
          parameter.accept(this);
        }
      });
      if (node.rightDelimiter != null) {
        _checkIndentation(node.rightDelimiter.offset);
      } else {
        _checkIndentation(node.rightParenthesis.offset);
      }
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    AstNode parent = node.parent;
    if (!(parent is IfStatement && parent.elseStatement == node)) {
      _checkIndentation(node.offset);
      _checkCommentsAndAnnotations(node);
    }
    _indentStatementInControlFlow(node.thenStatement);
    if (node.elseStatement != null) {
      if (node.elseStatement is IfStatement) {
        node.elseStatement.accept(this);
      } else {
        _indentStatementInControlFlow(node.elseStatement);
      }
    }
    _indent(() {
      node.condition.accept(this);
    });
  }

  @override
  void visitListLiteral(ListLiteral node) {
    if (_startsLine(node)) {
      _checkIndentation(node.offset);
      _checkCommentsAndAnnotations(node);
    }
    if (_areOnSameLine(node.leftBracket.offset, node.rightBracket.offset)) {
    } else {
      _indent(() {
        for (final element in node.elements) {
          if (_startsLine(element)) {
            _checkIndentation(element.offset);
          }
          element.accept(this);
        }
      });
    }
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    if (_startsLine(node)) {
      _checkIndentation(node.offset);
      _checkCommentsAndAnnotations(node);
    }
    if (_areOnSameLine(node.leftBracket.offset, node.rightBracket.offset)) {
    } else {
      _indent(() {
        for (final entry in node.entries) {
          _checkIndentation(entry.offset);
          entry.accept(this);
        }
      });
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    void f() {
      if (node.operator != null) {
        _checkIndentation(node.function.offset,
            column: _columnAt(node.operator.end));
      }
      if (node.typeArguments != null) {
        _checkIndentation(node.typeArguments.offset,
            column: _columnAt(node.function.end));
        node.typeArguments.accept(this);
      }
      node.argumentList.accept(this);
    }

    if (_lineAt(node.offset) != _lineAt(node.function.offset)) {
      _indent(() {
        _checkIndentation(node.operator.offset);
        f();
      });
    } else {
      f();
    }
    node.target?.accept(this);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _checkIndentation(node.offset);
    _checkCommentsAndAnnotations(node);
    _indent(() {
      for (final member in node.members) {
        member.accept(this);
      }
    });
  }

  @override
  void visitNode(AstNode node) {
    if (_startsLine(node)) {
      _checkIndentation(node.offset);
    }
    _checkCommentsAndAnnotations(node);
    super.visitNode(node);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    if (!_areOnSameLine(node.offset, node.end)) {
      _indent(() {
        for (final name in node.shownNames) {
          name.accept(this);
        }
      });
    }
  }

  @override
  void visitSwitchMember(SwitchMember node) {
    _checkIndentation(node.offset);
    _checkCommentsAndAnnotations(node);
    for (final statement in node.statements) {
      _indentStatementInControlFlow(statement);
    }
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _checkIndentation(node.offset);
    _checkCommentsAndAnnotations(node);
    _indent(() {
      for (final member in node.members) {
        member.accept(this);
      }
    });
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (_startsLine(node)) {
      _checkIndentation(node.offset);
      _checkCommentsAndAnnotations(node);
    }
    if (node.equals != null) {
      _checkIndentation(node.equals.offset,
          column: _columnAt(node.name.end) + 1);
      if (_lineAt(node.offset) != _lineAt(node.initializer.offset)) {
        _indent(() {
          node.initializer.accept(this);
        });
      } else {
        _checkIndentation(node.initializer.offset,
            column: _columnAt(node.equals.end) + 1);
        node.initializer.accept(this);
      }
    }
  }

  final _tokenAlreadyCheckedForComments = <Token>[];

  void _checkComments(AstNode node) {
    Token comment = node.beginToken.precedingComments;
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
          node.beginToken.previous != null &&
          _lineAt(comment.offset) == _lineAt(node.beginToken.previous.end);
      if (isDoc || !isEol && column > 1) {
        _checkIndentation(
          comment.offset,
          column: indentations.last,
          message: '$column != ${indentations.last}' + dumpParents(node),
        );
      } else if (isEol && comment.offset - node.beginToken.previous.end < 1) {
        addError(
          'Put at least one space before end of line comments',
          node.beginToken.previous.end,
          comment.offset - node.beginToken.previous.end,
        );
      }
    } while ((comment = comment.next) != null);
  }

  void _checkCommentsAndAnnotations(AstNode node) {
    if (node is AnnotatedNode) {
      for (final annotation in node.metadata) {
        _checkIndentation(annotation.offset);
        _checkComments(annotation);
      }
    } else {
      _checkComments(node);
    }
  }

  bool _startsLine(AstNode node) {
    return node.beginToken.previous == null ||
        !_areOnSameLine(node.offset, node.beginToken.previous.end);
  }

  bool _isOneLiner(AstNode node) {
    return _areOnSameLine(
        node.end,
        node is AnnotatedNode
            ? node.firstTokenAfterCommentAndMetadata.offset
            : node.offset);
  }

  bool _areOnSameLine(int offset1, int offset2) {
    return _lineAt(offset1) == _lineAt(offset2);
  }

  int _lineAt(int offset) => lineInfo.getLocation(offset).lineNumber;
  int _columnAt(int offset) => lineInfo.getLocation(offset).columnNumber;

  void _checkIndentation(
    int offset, {
    int column,
    String message,
  }) {
    column ??= indentations.last;
    if (_columnAt(offset) != column) {
      addError(
        message ??
            'Bad position (expected at column $column) $indentations $column',
        offset,
        0,
      );
    }
  }

  void _indent(void Function() f, {int padding = 2}) {
    indentations.add(indentations.last + padding);
    f();
    indentations.removeLast();
  }

  void _indentStatementInControlFlow(Statement statement, {int padding = 2}) {
    if (statement is Block) {
      statement.accept(this);
    } else {
      _indent(() {
        statement.accept(this);
      }, padding: padding);
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
