import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf_dev/src/config.dart';
import 'package:shelf_dev/src/server_wrapper.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

const _testServerFileName = 'test_server.dart';

final _serverSourceCode = File('test/src/test_server.dart').readAsStringSync();

final _pubCommand = Platform.isWindows ? 'pub.bat' : 'pub';

final _terminatedExitCode = Platform.isWindows ? '-1' : '-15';

void main() {
  late http.Client client;
  late ServerWrapper server;
  late StreamQueue<WrapperMessage> messageQueue;
  late StreamController<String> keyController;
  late String workingDir;

  setUp(() async {
    await d.dir('test_server', [
      d.file('pubspec.yaml', r'''
name: temp_server
environment:
  sdk: ^2.14.0
dependencies:
  args: any
  shelf: any
'''),
      d.file(
        _testServerFileName,
        _serverSourceCode,
      )
    ]).create();

    workingDir = p.join(d.sandbox, 'test_server');

    final result = Process.runSync(
      _pubCommand,
      ['get', '--offline'],
      workingDirectory: workingDir,
    );

    if (result.exitCode != 0) {
      fail([
        result.stderr,
        result.stderr,
        result.exitCode,
      ].join('\n'));
    }

    client = http.Client();

    addTearDown(() {
      client.close();
    });

    final serverConfig = WebServerConfig(
      path: workingDir,
      command: 'dart test_server.dart --port {PORT}',
      source: 'api',
    );

    keyController = StreamController<String>();

    server = await ServerWrapper.create(
      client: client,
      config: serverConfig,
      cancel: expectAsync0(() {}),
      keyStream: keyController.stream,
    );
    messageQueue = StreamQueue(server.messages);

    expect(
      await messageQueue.next,
      _messageMatcher(
        typeMatcher: WrapperMessageType.stdout,
        contentMatcher: startsWith('Serving at localhost:'),
      ),
    );
  });

  test('basic setup', () async {
    await _testRequest(server, messageQueue);

    await server.close();

    expect(
      await messageQueue.next,
      _messageMatcher(
        typeMatcher: WrapperMessageType.exit,
        contentMatcher: _terminatedExitCode,
      ),
    );

    expect(messageQueue, emitsDone);
  });

  test('request server restart', () async {
    await _testRequest(server, messageQueue);

    keyController.add('s');

    expect(
      await messageQueue.next,
      _messageMatcher(
        typeMatcher: WrapperMessageType.info,
        contentMatcher: 'Terminating process and attempting restart.',
      ),
    );

    expect(
      await messageQueue.next,
      _messageMatcher(
        typeMatcher: WrapperMessageType.exit,
        contentMatcher: _terminatedExitCode,
      ),
    );

    expect(
      await messageQueue.next,
      _messageMatcher(
        typeMatcher: WrapperMessageType.stdout,
        contentMatcher: startsWith('Serving at localhost:'),
      ),
    );

    await _testRequest(server, messageQueue);

    await server.close();

    expect(
      await messageQueue.next,
      _messageMatcher(
        typeMatcher: WrapperMessageType.exit,
        contentMatcher: _terminatedExitCode,
      ),
    );

    expect(messageQueue, emitsDone);
  });

  test('server shutdown', () async {
    await _testRequest(server, messageQueue);

    final response = await server.handler(
      Request('GET', Uri.parse('http://ignored/terminate')),
    );

    expect(response.statusCode, 200);

    expect(
      await messageQueue.next,
      _messageMatcher(
        typeMatcher: WrapperMessageType.stdout,
        contentMatcher: contains('GET     [200] /terminate'),
      ),
    );

    await expectLater(
      messageQueue,
      emitsInOrder(
        [
          _messageMatcher(
            typeMatcher: WrapperMessageType.exit,
            contentMatcher: '0',
          ),
          emitsDone,
        ],
      ),
    );
    await server.close();
  });

  test(
    'server code edited',
    () async {
      await _testRequest(server, messageQueue);

      // Now change the server source to be broken!
      final newContent = '$_serverSourceCode\ninvalid_dart';
      File(p.join(workingDir, _testServerFileName))
          .writeAsStringSync(newContent);

      keyController.add('s');

      expect(
        await messageQueue.next,
        _messageMatcher(
          typeMatcher: WrapperMessageType.info,
          contentMatcher: 'Terminating process and attempting restart.',
        ),
      );

      expect(
        await messageQueue.next,
        _messageMatcher(
          typeMatcher: WrapperMessageType.exit,
          contentMatcher: _terminatedExitCode,
        ),
      );

      expect(
        await messageQueue.next,
        _messageMatcher(
          typeMatcher: WrapperMessageType.stderr,
          contentMatcher: startsWith('test_server.dart:'),
        ),
      );

      final response = await server.handler(
        Request('GET', Uri.parse('http://ignored/requested/path/')),
      );

      expect(response.statusCode, 500);

      expect(
        await messageQueue.next,
        _messageMatcher(
          typeMatcher: WrapperMessageType.exit,
          contentMatcher: _terminatedExitCode,
        ),
      );

      expect(messageQueue, emitsDone);
    },
    skip: Platform.isWindows ? 'Need to debug Windows failure' : null,
  );
}

Future<void> _testRequest(
  ServerWrapper server,
  StreamQueue<WrapperMessage> messageQueue,
) async {
  final response = await server.handler(
    Request('GET', Uri.parse('http://ignored/requested/path/')),
  );

  expect(response.statusCode, 200);

  expect(
    await messageQueue.next,
    _messageMatcher(
      typeMatcher: WrapperMessageType.stdout,
      contentMatcher: contains('GET     [200] /requested/path'),
    ),
  );
}

Matcher _messageMatcher({
  required Object contentMatcher,
  required Object typeMatcher,
}) =>
    isA<WrapperMessage>()
        .having((e) => e.content, 'content', contentMatcher)
        .having((e) => e.type, 'type', typeMatcher);
