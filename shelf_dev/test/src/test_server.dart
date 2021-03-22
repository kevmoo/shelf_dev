import 'dart:convert';

import 'package:args/args.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()..addOption('port', defaultsTo: '8080');
  final result = parser.parse(args);
  final server =
      await serve(_handler, 'localhost', int.parse(result['port'] as String));

  print('Serving at ${server.address.host}:${server.port}');
}

Future<Response> _handler(Request request) async => Response.ok(
      const JsonEncoder.withIndent(' ').convert({
        'method': request.method,
        'requestedUri': request.requestedUri.toString(),
        'headers': request.headers,
        'body': await request.readAsString(),
      }),
    );
