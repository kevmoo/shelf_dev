import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show Client;
import 'package:io/ansi.dart' as ansi;
import 'package:shelf/shelf.dart';
import 'package:shelf_proxy/shelf_proxy.dart';

import 'config.dart';
import 'utils.dart';

class ServerWrapper {
  final BaseWebConfig _config;
  final Handler handler;
  final Process _process;
  final void Function() _cancel;
  final String _prefix;

  late final StreamSubscription _keySub;

  ServerWrapper._(
    this._config,
    this.handler,
    this._process,
    this._cancel,
    Stream<String> keyStream,
  ) : _prefix = _codeFromName(_config.name).wrap(_config.name)! {
    _keySub = keyStream.listen((event) {
      if (_config.passThroughKeys.contains(event)) {
        print('Sending "$event" to $_prefix');
        _process.stdin.write(event);
        return;
      }
      if (_config.restartKeys.contains(event)) {
        print('Got "$event" - $_prefix – will restart at some point');
        return;
      }
    });

    Timer.run(_exitCodePlus);
  }

  static Future<ServerWrapper> create({
    required Client client,
    required BaseWebConfig config,
    required void Function() cancel,
    required Stream<String> keyStream,
  }) async {
    final port = config.port ?? await getOpenPort();

    final command = config.port == null
        ? config.command.replaceAll(BaseWebConfig.portPlaceHolder, '$port')
        : config.command;

    final commandBits = List<String>.unmodifiable(
      command
          .split(' ')
          .map((e) => e.trim())
          .where((element) => element.isNotEmpty)
          .toList(),
    );

    final process = await Process.start(
      commandBits.first,
      commandBits.skip(1).toList(),
      workingDirectory: config.path,
    );

    final serverProxy = proxyHandler(
      'http://localhost:$port',
      client: client,
    );

    return ServerWrapper._(
      config,
      serverProxy,
      process,
      cancel,
      keyStream,
    );
  }

  void close() {
    _keySub.cancel();
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
