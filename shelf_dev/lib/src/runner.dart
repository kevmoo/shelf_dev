import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

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

  var lastItems = <String>[];
  void logLine(List<String> items) {
    final copy = List.of(items);
    var allSameSoFar = true;
    // skipping the last item – we always want to print that!
    for (var i = 0; i < items.length - 1; i++) {
      if (lastItems.length > i && lastItems[i] == items[i] && allSameSoFar) {
        // replace with spaces!
        copy[i] = ' ' * lastItems[i].length;
        break;
      }

      allSameSoFar = false;

      if (i == 0) {
        // if it's the first one and we have not overwritten it, give it color!
        copy[i] = _nameWithColor(copy[i]);
      }
    }
    print(copy.join(' '));
    lastItems = items;
  }

  void logWrapperMessage(ServerWrapper wrapper, WrapperMessage event) {
    for (var line in LineSplitter.split(event.content.trim())
        .map((e) => e.trim())
        .where((element) => element.isNotEmpty)) {
      logLine([
        wrapper.name,
        event.type.name.padRight(_eventTypeMaxLength),
        line,
      ]);
    }
  }

  StreamSubscription _listenToWrapper(ServerWrapper wrapper) =>
      wrapper.messages.listen((event) => logWrapperMessage(wrapper, event));

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

final _eventTypeMaxLength = WrapperMessageType.values
    .map((e) => e.name)
    .fold<int>(
        0, (previousValue, element) => math.max(previousValue, element.length));

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
