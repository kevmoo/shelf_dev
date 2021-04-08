import 'dart:convert';

import 'package:shelf_dev/src/version.dart';
import 'package:test/test.dart';

import 'package:test_process/test_process.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:path/path.dart' as p;

void main() {
  test('help', () async {
    final proc = await _start(['--help']);

    await proc.shouldExit(0);

    await expectLater(
      proc.stdout,
      emitsInOrder([
        'Yes, I need to add a LOT more here. Sorry...',
        ..._helpOutputLines,
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
        ..._helpOutputLines,
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
        ['Configuration file "shelf_dev.yaml" not found.', emitsDone],
      ),
    );
  });

  test('bad config', () async {
    await d.file('shelf_dev.yaml', 'Not valid yaml!').create();

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
}

Future<TestProcess> _start(List<String> args) => TestProcess.start(
      'dart',
      [_shelfDevBinary, ...args],
      workingDirectory: d.sandbox,
    );

final _shelfDevBinary = p.join(p.current, 'bin/shelf_dev.dart');

Iterable get _helpOutputLines => LineSplitter.split(_helpOutput);

const _helpOutput = r'''
-?, --help       Print out usage information.
    --version    Print out the version of the executable.''';
