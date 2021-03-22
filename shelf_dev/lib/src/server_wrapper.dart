import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show Client;
import 'package:io/ansi.dart' as ansi;
import 'package:shelf/shelf.dart';
import 'package:shelf_proxy/shelf_proxy.dart';

import 'config.dart';
import 'utils.dart';

class ServerWrapper {
  final String name;
  final Handler handler;
  final Process _process;
  final void Function() _cancel;
  final String _prefix;

  ServerWrapper._(this.name, this.handler, this._process, this._cancel)
      : _prefix = _codeFromName(name).wrap(name)! {
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

    final split = command
        .split(' ')
        .map((e) => e.trim())
        .where((element) => element.isNotEmpty)
        .toList();

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
        _lines(_process.stdout),
        _lines(_process.stderr, error: true),
        _process.exitCode
      ]);

      final exitcode = events[2] as int;
      final exitMessage = ansi.styleBold.wrap('exited with code $exitcode');
      print('$_prefix     $exitMessage');
    } finally {
      _cancel();
    }
  }

  Future<void> _lines(Stream<List<int>> stdout, {bool error = false}) =>
      stdout.transform(systemEncoding.decoder).forEach((element) {
        final errorBit = error ? ansi.red.wrap('[E]') : '   ';
        print('$_prefix $errorBit $element'.trim());
      });

  static ansi.AnsiCode _codeFromName(String name) {
    switch (name) {
      case 'server':
        return ansi.lightCyan;
      case 'webapp':
        return ansi.lightGreen;
      default:
        return ansi.resetAll;
    }
  }
}
