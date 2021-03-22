import 'dart:async';
import 'dart:io';

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

    void terminateComplete() {
      if (!userCancelOperation.isCompleted) {
        userCancelOperation.complete();
      }
    }

    try {
      final keyStreamController = StreamController<String>.broadcast();

      stdin.echoMode = false;
      stdin.lineMode = false;
      final stdinSub = stdin
          .transform(systemEncoding.decoder)
          .listen(keyStreamController.add);

      try {
        final serverWrapper = await ServerWrapper.create(
          client: client,
          config: config.webServer,
          cancel: terminateComplete,
          keyStream: keyStreamController.stream,
        );
        try {
          final webAppWrapper = await ServerWrapper.create(
            client: client,
            config: config.webApp,
            cancel: terminateComplete,
            keyStream: keyStreamController.stream,
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
        await keyStreamController.close();
        await stdinSub.cancel();
      }
    } finally {
      terminateComplete();
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
