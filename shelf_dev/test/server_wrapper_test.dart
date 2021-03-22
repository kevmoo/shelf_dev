import 'dart:async';

import 'package:async/async.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf_dev/src/config.dart';
import 'package:shelf_dev/src/server_wrapper.dart';
import 'package:test/test.dart';

void main() {
  late http.Client client;
  late ServerWrapper server;
  late StreamQueue<WrapperMessage> messageQueue;
  late StreamController<String> keyController;

  setUp(() async {
    client = http.Client();

    addTearDown(() {
      client.close();
    });

    final serverConfig = WebServerConfig(
      path: 'test/src',
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

  test('simple', () async {
    await _testRequest(server, messageQueue);

    await server.close();

    expect(
      await messageQueue.next,
      _messageMatcher(
        typeMatcher: WrapperMessageType.exit,
        contentMatcher: '-15',
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
        typeMatcher: WrapperMessageType.keyRestart,
        contentMatcher: 's',
      ),
    );

    expect(
      await messageQueue.next,
      _messageMatcher(
        typeMatcher: WrapperMessageType.exit,
        contentMatcher: '-15',
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
        contentMatcher: '-15',
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
}

Future<void> _testRequest(
    ServerWrapper server, StreamQueue<WrapperMessage> messageQueue) async {
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

Matcher _messageMatcher(
        {required Object contentMatcher, required Object typeMatcher}) =>
    isA<WrapperMessage>()
        .having((e) => e.content, 'content', contentMatcher)
        .having((e) => e.type, 'type', typeMatcher);
