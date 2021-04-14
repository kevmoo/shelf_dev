import 'dart:convert';

import 'package:io/ansi.dart';
import 'package:path/path.dart' as p;
import 'package:shelf_dev/src/cli_options.dart';
import 'package:shelf_dev/src/constants.dart';
import 'package:shelf_dev/src/runner.dart';
import 'package:shelf_dev/src/version.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:test_process/test_process.dart';

void main() {
  test('help', () async {
    final proc = await _start(['--help']);

    await proc.shouldExit(0);

    await expectLater(
      proc.stdout,
      emitsInOrder([
        ...LineSplitter.split(overrideAnsiOutput(false, () => introduction)),
        ...LineSplitter.split(CommandLineOptions.usage),
        emitsDone,
      ]),
    );
  });

  test('version', () async {
    final proc = await _start(['--version']);

    await proc.shouldExit(0);
    await expectLater(proc.stdout, emitsInOrder([packageVersion, emitsDone]));
  });

  test('bad command line arg', () async {
    final proc = await _start(['--bob']);

    await proc.shouldExit(64);
    await expectLater(
      proc.stdout,
      emitsInOrder([
        'Unsupported command line argument.',
        'Could not find an option named "bob".',
        ...LineSplitter.split(CommandLineOptions.usage),
        emitsDone
      ]),
    );
  });

  test('missing config', () async {
    final proc = await _start([]);

    await proc.shouldExit(78);
    await expectLater(
      proc.stdout,
      emitsInOrder(
        ['Configuration file "$defaultConfigFileName" not found.', emitsDone],
      ),
    );
  });

  test('bad config', () async {
    await d.file(defaultConfigFileName, 'Not valid yaml!').create();

    final proc = await _start([]);

    await proc.shouldExit(78);
    await expectLater(
      proc.stdout,
      emitsInOrder([
        ...LineSplitter.split(r'''
Invalid configuration file
Not a map
line 1, column 1 of shelf_dev.yaml: Not a map
  ╷
1 │ Not valid yaml!
  │ ^^^^^^^^^^^^^^^
  ╵'''),
        emitsDone
      ]),
    );
  });

  test('software crash', () async {
    await d.file(
      defaultConfigFileName,
      r'''
web-app:
  path: web_app
  command: pub run build_runner serve web:{PORT}

web-server:
  path: web_server
  command: dart bin/server.dart --port {PORT}
  source: api
''',
    ).create();

    final proc = await _start(
      [],
      environment: {forceCrashEnvVar: 'true'},
    );

    await proc.shouldExit(70);
    await expectLater(
      proc.stdout,
      emitsInOrder([
        'An error occurred!',
        'Bad state: Test exception to validate error handling!',
        endsWith('  run'),
        endsWith('  main'),
        emitsDone
      ]),
    );
  });
}

Future<TestProcess> _start(
  List<String> args, {
  Map<String, String> environment = const {},
}) =>
    TestProcess.start(
      'dart',
      [p.join(p.current, 'bin/shelf_dev.dart'), ...args],
      workingDirectory: d.sandbox,
      environment: environment,
    );
