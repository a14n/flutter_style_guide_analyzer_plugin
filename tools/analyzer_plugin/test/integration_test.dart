import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';

import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

main() async {
  final errorsPerFile = <String, List<dynamic>>{};

  final dir = await Directory.systemTemp
      .createTemp('flutter_style_guide_analyzer_plugin_');
  final dirPath = dir.path;

  // copy integration dart files
  final testFilesPath = join(dirname(currentFile.path), 'integration');
  final files = Directory(testFilesPath)
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((e) => e.path.endsWith('.dart'));
  for (final file in files) {
    final filePath = relative(file.path, from: testFilesPath);
    final newPath = join(dirPath, filePath);
    Directory(dirname(newPath)).createSync();
    file.copySync(newPath);
    errorsPerFile[filePath] = const [];
  }

  // create pubspec.yaml
  await File(join(dirPath, 'pubspec.yaml')).writeAsString(
    '''
name: test
environment:
  # The pub client defaults to an <2.0.0 sdk constraint which we need to explicitly overwrite.
  sdk: ">=2.0.0-dev.68.0 <3.0.0"

dev_dependencies:
  flutter_style_guide_analyzer_plugin:
    path: ${dirname(currentFile.path) + '/../../..'}
''',
  );

  // create analysis_options.yaml
  await File(join(dirPath, 'analysis_options.yaml')).writeAsString(
    '''
analyzer:
  plugins:
  - flutter_style_guide_analyzer_plugin
''',
  );

  // pub get
  await Process.run(
      join(dirname(Platform.resolvedExecutable), 'pub'), ['get', '--offline'],
      workingDirectory: dirPath);

  // launch analysis server and wait for errors
  final serverPath = normalize(join(dirname(Platform.resolvedExecutable),
      'snapshots', 'analysis_server.dart.snapshot'));
  final Process server = await Process.start(
      Platform.resolvedExecutable,
      [
        serverPath,
        "--instrumentation-log-file=$dirPath/analyzerInstrumentationLogFile.txt"
      ],
      workingDirectory: dirPath);
  final commands = [
    {
      'id': '1',
      'method': 'server.setSubscriptions',
      'params': {
        'subscriptions': ['STATUS']
      },
      'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
    },
    {
      'id': '2',
      'method': 'analysis.setAnalysisRoots',
      'params': {
        'excluded': [],
        'included': [dirPath]
      },
      'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
    },
  ];
  for (final command in commands) {
    server.stdin
      ..add(utf8.encode(json.encode(command)))
      ..writeln();
  }
  await server.stdin.flush();

  final counts = Map.fromIterable(errorsPerFile.entries,
      key: (e) => e.key, value: (_) => 0);
  var responses = server.stdout
      .timeout(const Duration(minutes: 1), onTimeout: (_) => server.kill())
      .map(utf8.decode)
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .map(json.decode);
  await for (final response in responses) {
    if (response['event'] == 'analysis.errors') {
      final params = response['params'];
      final file = params['file'];
      final filePath = relative(file, from: dirPath);

      if (!filePath.endsWith('.dart')) {
        continue;
      }

      counts[filePath] += 1;
      errorsPerFile[filePath] = params['errors'];

      if (counts.values.every((e) => e >= 2)) {
        break;
      }
    }
  }

  for (var entry in errorsPerFile.entries) {
    final file = entry.key;
    final errors = entry.value;

    test(file, () {
      final expectedLints = readLints(File(join(dirPath, file)))
          .map((e) => '${e.lineNumber}:${e.columnNumber}');
      final actualLints = errors
          .where((e) => (e['code'] as String)
              .startsWith('flutter_style.${dirname(file)}'))
          .map((e) =>
              '${e['location']['startLine']}:${e['location']['startColumn']}')
          .toList();
      try {
        for (var lint in expectedLints) {
          expect(actualLints, contains(lint));
        }
        for (var lint in actualLints) {
          expect(expectedLints, contains(lint));
        }
      } catch (e) {
        print(file);
        print('expected: $expectedLints');
        errors
            .where((e) => (e['code'] as String)
                .startsWith('flutter_style.${dirname(file)}'))
            .forEach(print);
        rethrow;
      }
    });
  }
}

const lintsPattern = '// LINT ';

List<CharacterLocation> readLints(File file) {
  final result = <CharacterLocation>[];
  int currentLineNumber = 1;
  for (final line in file.readAsLinesSync()) {
    if (line.trimLeft().startsWith(lintsPattern)) {
      line
          .substring(lintsPattern.length)
          .split(' ')
          .map((e) => e.trim())
          .where(RegExp(r'^([+-]?\d+)?:\d+$').hasMatch)
          .forEach((e) {
        final parts = e.split(':');
        int lineNumber;
        if (parts[0].isEmpty) {
          lineNumber = currentLineNumber + 1;
        } else if (parts[0].startsWith('-')) {
          lineNumber = currentLineNumber - int.parse(parts[0].substring(1));
        } else if (parts[0].startsWith('+')) {
          lineNumber = currentLineNumber + int.parse(parts[0].substring(1));
        } else {
          lineNumber = int.parse(parts[0]);
        }
        result.add(CharacterLocation(lineNumber, int.parse(parts[1])));
      });
    }
    currentLineNumber++;
  }
  return result;
}

// TODO(aar): replace with something else once https://github.com/dart-lang/test/issues/110 is fixed
Uri get currentFile => (reflectClass(_TestUtils).owner as LibraryMirror).uri;

class _TestUtils {}
