import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/line_info.dart';

String dumpParents(AstNode node) {
  if (node == null) return '';
  final types = <Type>[];
  do {
    types.insert(0, node.runtimeType);
  } while (node != node.parent && (node = node.parent) != null);
  return types.reversed.map((e) => '$e').join(' <- ');
}

Token getBeginToken(AstNode node) {
  return node is AnnotatedNode
      ? node.firstTokenAfterCommentAndMetadata
      : node.beginToken;
}

class LocationHelper {
  LocationHelper(this.lineInfo);
  final LineInfo lineInfo;

  bool startsLine(AstNode node) {
    return tokenStartsLine(getBeginToken(node));
  }

  bool tokenStartsLine(Token token) {
    return token == tokenStartingLine(token);
  }

  int startOfLine(Token token) {
    return columnAt(tokenStartingLine(token).offset);
  }

  Token tokenStartingLine(Token token) {
    while (token.previous != null &&
        token.previous.offset != -1 &&
        token.previous != token &&
        areOnSameLine(token.offset, token.previous.offset)) {
      token = token.previous;
    }
    return token;
  }

  bool isOneLiner(AstNode node) {
    return areOnSameLine(getBeginToken(node).offset, node.end);
  }

  bool areNotOnSameLine(int offset1, int offset2) {
    return !areOnSameLine(offset1, offset2);
  }

  bool areOnSameLine(int offset1, int offset2) {
    return lineAt(offset1) == lineAt(offset2);
  }

  int lineAt(int offset) => lineInfo.getLocation(offset).lineNumber;
  int columnAt(int offset) => lineInfo.getLocation(offset).columnNumber;
}
