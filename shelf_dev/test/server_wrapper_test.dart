import 'dart:async';

import 'package:async/async.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf_dev/src/config.dart';
import 'package:shelf_dev/src/server_wrapper.dart';
import 'package:test/test.dart';

void main() {
  late http.Client client;

  setUp(() {
    client = http.Client();

    addTearDown(() {
      client.close();
    });
  });

  test('simple', () async {
    final serverConfig = WebServerConfig(
      path: 'test/src',
      command: 'dart test_server.dart --port {PORT}',
      source: 'api',
    );

    final keyController = StreamController<String>();

    final server = await ServerWrapper.create(
      client: client,
      config: serverConfig,
      cancel: expectAsync0(() {}),
      keyStream: keyController.stream,
    );
    final messageQueue = StreamQueue(server.messages);

    expect(
      await messageQueue.next,
      _messageMatcher(
        contentMatcher: startsWith('Serving at localhost:'),
      ),
    );

    final response = await server.handler(
      Request('GET', Uri.parse('http://ignored/requested/path')),
    );

    expect(response.statusCode, 200);

    expect(
      await messageQueue.next,
      _messageMatcher(
        contentMatcher: contains('GET     [200] /requested/path'),
      ),
    );

    await server.close();

    expect(
      await messageQueue.next,
      _messageMatcher(
        contentMatcher: '-15',
      ),
    );

    expect(messageQueue, emitsDone);
  });
}

Matcher _messageMatcher({Object? contentMatcher, Object? typeMatcher}) {
  var matcher = isA<WrapperMessage>();

  if (contentMatcher != null) {
    matcher = matcher.having((e) => e.content, 'content', contentMatcher);
  }
  if (typeMatcher != null) {
    matcher = matcher.having((e) => e.type, 'tye', typeMatcher);
  }

  return matcher;
}
