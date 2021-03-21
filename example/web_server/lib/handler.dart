import 'dart:convert';

import 'package:shelf/shelf.dart';

final handler = const Pipeline()
    .addMiddleware(logRequests())
    .addMiddleware(
      (toWrap) => (request) async {
        if (request.method != 'GET') {
          return Response(400, body: 'only GET is accepted!');
        }

        if (request.url.pathSegments.isNotEmpty) {
          return Response(
            400,
            body: 'No fancy paths, please! (Got "${request.url.path}").',
          );
        }

        Response response;

        try {
          response = await toWrap(request);
          // ignore: avoid_catching_errors
        } on StateError catch (e) {
          response = Response(400, body: e.message);
        }
        return response;
      },
    )
    .addHandler(_math);

Response _math(Request request) {
  int getValue(String key) {
    final str = request.url.queryParameters[key];
    if (str == null) {
      throw StateError('"$key" does not exist');
    }
    try {
      return int.parse(str);
    } on FormatException catch (e) {
      throw StateError(
        'Could not parse "$key" with value "$str" - ${e.message}',
      );
    }
  }

  final a = getValue('a');
  final b = getValue('b');

  return Response.ok(
    _encoder.convert({
      'a': a,
      'b': b,
      'sum': a + b,
    }),
    headers: {'content-type': 'application/json'},
  );
}

final _encoder = JsonUtf8Encoder();
