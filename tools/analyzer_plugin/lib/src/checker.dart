import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:flutter_style_guide_analyzer_plugin/src/rules/empty_line_at_eof.dart';

Map<AnalysisError, PrioritizedSourceChange> check(CompilationUnit unit) {
  final result = <AnalysisError, PrioritizedSourceChange>{};

  final lineInfo = unit.lineInfo;
  void addError(
    String code,
    String message,
    int offset,
    int length, [
    String fixMessage,
    List<SourceEdit> edits,
  ]) {
    final offsetLineLocation = lineInfo.getLocation(offset);
    final error = AnalysisError(
      AnalysisErrorSeverity.WARNING,
      AnalysisErrorType.LINT,
      Location(
        unit.declaredElement.source.fullName,
        offset,
        length,
        offsetLineLocation.lineNumber,
        offsetLineLocation.columnNumber,
      ),
      message,
      code,
    );
    final fix = PrioritizedSourceChange(
      1000000,
      SourceChange(
        fixMessage ?? 'Fix it',
        edits: [
          SourceFileEdit(
            unit.declaredElement.source.fullName,
            unit.declaredElement.source.modificationStamp,
            edits: edits,
          )
        ],
      ),
    );
    result[error] = fix;
  }

  final rules = [
    EmptyLineAtEOFRule(addError),
  ];
  for (final rule in rules) {
    rule.visitCompilationUnit(unit);
  }

  return result;
}

typedef ErrorReporter = void Function(
  String code,
  String message,
  int offset,
  int length, [
  String fixMessage,
  List<SourceEdit> edits,
]);

abstract class Rule {
  Rule(
    String code,
    ErrorReporter addError,
  ) : addError = ((
          message,
          offset,
          length, {
          subCode,
          fixMessage,
          edits,
        }) {
          addError(
            'flutter_style.$code' +
                (subCode?.isNotEmpty == true ? '.$subCode' : ''),
            message,
            offset,
            length,
            fixMessage,
            edits,
          );
        });

  final void Function(
    String message,
    int offset,
    int length, {
    String subCode,
    String fixMessage,
    List<SourceEdit> edits,
  }) addError;

  void addErrorWithSimpleFix(
    String message,
    int offset,
    int length,
    String replacement, {
    String subCode,
    String fixMessage,
  }) =>
      addError(
        message,
        offset,
        length,
        subCode: subCode,
        fixMessage: fixMessage,
        edits: [SourceEdit(offset, length, replacement)],
      );

  void visitCompilationUnit(CompilationUnit node);
}
