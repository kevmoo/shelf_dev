import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show Client;
import 'package:shelf/shelf.dart';
import 'package:shelf_proxy/shelf_proxy.dart';

import 'config.dart';
import 'utils.dart';

class ServerWrapper {
  final String name;
  final Handler handler;
  final Process _process;
  final void Function() _cancel;

  ServerWrapper._(this.name, this.handler, this._process, this._cancel) {
    Timer.run(_exitCodePlus);
  }

  static Future<ServerWrapper> create(
    String name,
    Client client,
    BaseWebConfig config,
    void Function() cancel,
  ) async {
    final port = config.port ?? await getOpenPort();

    final command = config.port == null
        ? config.command.replaceAll(BaseWebConfig.portPlaceHolder, '$port')
        : config.command;
    final split = command.split(' ');

    final proc = await Process.start(
      split.first,
      split.skip(1).toList(),
      workingDirectory: config.path,
    );

    final serverProxy = proxyHandler(
      'http://localhost:$port',
      client: client,
    );

    return ServerWrapper._(name, serverProxy, proc, cancel);
  }

  void close() {
    _process.kill();
  }

  Future<void> _exitCodePlus() async {
    try {
      final events = await Future.wait([
        _lines('stdout', _process.stdout),
        _lines('stderr', _process.stderr),
        _process.exitCode
      ]);

      final exitcode = events[2] as int;
      print('$name  exited with code $exitcode');
    } finally {
      _cancel();
    }
  }

  Future<void> _lines(String type, Stream<List<int>> stdout) =>
      stdout.transform(systemEncoding.decoder).forEach((element) {
        print('$name  $type  $element'.trim());
      });
}
