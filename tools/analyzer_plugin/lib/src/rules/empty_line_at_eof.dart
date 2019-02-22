import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:flutter_style_guide_analyzer_plugin/src/checker.dart';

class EmptyLineAtEOFRule extends Rule {
  EmptyLineAtEOFRule(ErrorReporter addError)
      : super('empty_line_at_eof', addError);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final LineInfo lineInfo = node.lineInfo;
    final int lineCount = lineInfo.lineCount;
    final int lastLineStart = lineInfo.getOffsetOfLine(lineCount - 1);
    if (node.end - lastLineStart > 0) {
      addError(
        'File should end with an empty line',
        node.end,
        0,
        fixMessage: 'Add an empty line at the end of file',
        edits: [SourceEdit(node.end, 0, '\n')],
      );
    }
  }
}
