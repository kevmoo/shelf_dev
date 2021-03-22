import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show Client;
import 'package:io/ansi.dart' as ansi;
import 'package:shelf/shelf.dart';

import 'complete_on_terminate.dart';
import 'config.dart';
import 'server_wrapper.dart';
import 'shelf_host.dart';

Future<void> run(ShelfDevConfig config) async {
  final subscriptionsToClose = <StreamSubscription>[];

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

      subscriptionsToClose.add(
        stdin.transform(systemEncoding.decoder).listen(keyStreamController.add),
      );

      try {
        final serverWrapper = await ServerWrapper.create(
          client: client,
          config: config.webServer,
          cancel: terminateComplete,
          keyStream: keyStreamController.stream,
        );

        subscriptionsToClose.add(_listenToWrapper(serverWrapper));
        try {
          final webAppWrapper = await ServerWrapper.create(
            client: client,
            config: config.webApp,
            cancel: terminateComplete,
            keyStream: keyStreamController.stream,
          );
          subscriptionsToClose.add(_listenToWrapper(webAppWrapper));
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
            await webAppWrapper.close();
          }
        } finally {
          await serverWrapper.close();
        }
      } finally {
        await keyStreamController.close();
      }
    } finally {
      terminateComplete();
    }
  } finally {
    client.close();
  }

  for (var sub in subscriptionsToClose) {
    await sub.cancel();
  }
}

StreamSubscription _listenToWrapper(ServerWrapper wrapper) =>
    wrapper.messages.listen((event) {
      final nameWithColor = _nameWithColor(wrapper.name);

      print([
        nameWithColor,
        event.type.toString().split('.').last.padRight(15),
        event.content.trim(),
      ].join(' '));
    });

String _nameWithColor(String name) {
  switch (name) {
    case 'webapp':
      return ansi.lightCyan.wrap(name)!;
    case 'server':
      return ansi.lightGreen.wrap(name)!;
    default:
      return name;
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
