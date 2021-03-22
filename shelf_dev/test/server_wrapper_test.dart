import 'dart:async';

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

    final cancelCompleter = Completer<void>();

    void cancelFunction() {
      cancelCompleter.complete();
    }

    final keyController = StreamController<String>();

    final server = await ServerWrapper.create(
      client: client,
      config: serverConfig,
      cancel: cancelFunction,
      keyStream: keyController.stream,
    );

    // TODO: should probably have ServerWrapper expose a stream of events
    await Future.delayed(const Duration(seconds: 1));

    final response = await server.handler(
      Request('GET', Uri.parse('http://ignored/requested/path')),
    );

    expect(response.statusCode, 200);

    print(await response.readAsString());

    server.close();

    // Cancel completer should run!
    await cancelCompleter.future;
  });
}
