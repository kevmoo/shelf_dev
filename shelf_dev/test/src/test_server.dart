import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()..addOption('port', defaultsTo: '8080');
  final result = parser.parse(args);

  late HttpServer server;

  server = await serve(
    const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware((innerHandler) => (request) {
              if (request.url.path == 'terminate') {
                Timer.run(() {
                  server.close(force: true);
                });

                return Response.ok('shutting down!');
              }

              return innerHandler(request);
            })
        .addHandler(_handler),
    'localhost',
    int.parse(result['port'] as String),
  );

  print('Serving at ${server.address.host}:${server.port}');
}

Future<Response> _handler(Request request) async => Response.ok(
      jsonEncode({
        'method': request.method,
        'requestedUri': request.requestedUri.toString(),
        'headers': request.headers,
        'body': await request.readAsString(),
      }),
    );
