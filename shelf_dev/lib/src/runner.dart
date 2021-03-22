import 'dart:async';

import 'package:http/http.dart' show Client;
import 'package:shelf/shelf.dart';

import 'complete_on_terminate.dart';
import 'config.dart';
import 'server_wrapper.dart';
import 'shelf_host.dart';

Future<void> run(ShelfDevConfig config) async {
  final client = Client();

  try {
    final userCancelOperation = completeOnTerminate();

    void complete() {
      if (!userCancelOperation.isCompleted) {
        userCancelOperation.complete();
      }
    }

    try {
      final serverWrapper = await ServerWrapper.create(
        'server',
        client,
        config.webServer,
        complete,
      );
      try {
        final webAppWrapper = await ServerWrapper.create(
          'webapp',
          client,
          config.webApp,
          complete,
        );
        try {
          Future<Response> handler(Request request) async {
            if (_underSegments(
              request.url.pathSegments,
              config.webServer.sourceSegments,
            )) {
              return serverWrapper
                  .handler(request.change(path: config.webServer.source));
            }

            return webAppWrapper.handler(request);
          }

          await runShelfHandler(
            config.port,
            handler,
            userCancelOperation.future,
          );
        } finally {
          webAppWrapper.close();
        }
      } finally {
        serverWrapper.close();
      }
    } finally {
      complete();
    }
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
