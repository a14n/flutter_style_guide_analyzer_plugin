
import 'package:analyzer/dart/ast/ast.dart';

String dumpParents(AstNode node) {
  if (node == null) return '';
  final types = <Type>[];
  do {
    types.insert(0, node.runtimeType);
  } while (node != node.parent && (node = node.parent) != null);
  return types.reversed.map((e) => '$e').join(' <- ');
}
