import 'dart:convert';

import 'package:http/http.dart' show Client;
import 'package:shelf/shelf.dart';
import 'package:shelf_proxy/shelf_proxy.dart';

import 'config.dart';
import 'shelf_host.dart';

Future<void> run(ShelfDevConfig config) async {
  print(const JsonEncoder.withIndent(' ').convert(config));

  final client = Client();

  try {
    final serverProxy = proxyHandler(
      'http://localhost:${config.webServer.port}',
      client: client,
    );
    final webAppProxy = proxyHandler(
      'http://localhost:${config.webApp.port}',
      client: client,
    );

    Future<Response> handler(Request request) async {
      if (_underSegments(
        request.url.pathSegments,
        config.webServer.sourceSegments,
      )) {
        return serverProxy(request.change(path: config.webServer.source));
      }

      return webAppProxy(request);
    }

    await runShelfHandler(config.port, handler);
  } finally {
    client.close();
  }
}

bool _underSegments(List<String> source, List<String> target) {
  if (source.length < target.length) {
    return false;
  }

  for (var i = 0; i < target.length; i++) {
    if (target[i] != source[i]) {
      return false;
    }
  }

  return true;
}
