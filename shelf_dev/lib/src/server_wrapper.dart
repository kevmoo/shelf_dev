import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show Client;
import 'package:shelf/shelf.dart';
import 'package:shelf_proxy/shelf_proxy.dart';

import 'config.dart';

class ServerWrapper {
  final String name;
  final Handler handler;
  final Process _process;
  final Future<void> Function() _cancel;

  ServerWrapper._(this.name, this.handler, this._process, this._cancel) {
    Timer.run(() async {
      try {
        final exit = await _exitCodePlus(name, _process);
        print('$name  exited with code $exit');
      } finally {
        await _cancel();
      }
    });
  }

  static Future<ServerWrapper> create(
    String name,
    Client client,
    BaseWebConfig config,
    Future<void> Function() cancel,
  ) async {
    final proc = await Process.start(
      config.executable,
      config.arguments,
      workingDirectory: config.path,
    );

    final serverProxy = proxyHandler(
      'http://localhost:${config.port}',
      client: client,
    );

    return ServerWrapper._(name, serverProxy, proc, cancel);
  }

  void close() {
    _process.kill();
  }
}

Future<int> _exitCodePlus(String name, Process process) async {
  final events = await Future.wait([
    _lines(name, 'stdout', process.stdout),
    _lines(name, 'stderr', process.stderr),
    process.exitCode
  ]);

  return events[2] as int;
}

Future<void> _lines(String name, String type, Stream<List<int>> stdout) =>
    stdout.transform(systemEncoding.decoder).forEach((element) {
      print('$name  $type  $element'.trim());
    });
