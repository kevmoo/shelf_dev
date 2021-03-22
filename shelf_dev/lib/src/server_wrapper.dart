import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show Client;
import 'package:shelf/shelf.dart';
import 'package:shelf_proxy/shelf_proxy.dart';

import 'config.dart';
import 'utils.dart';

class ServerWrapper {
  final _messageController = StreamController<WrapperMessage>();
  final _processTerminatedCompleter = Completer<void>();
  final BaseWebConfig _config;
  final Handler handler;
  final Process _process;
  final void Function() _cancel;

  late final StreamSubscription _keySub;

  ServerWrapper._(
    this._config,
    this.handler,
    this._process,
    this._cancel,
    Stream<String> keyStream,
  ) {
    _keySub = keyStream.listen((event) {
      if (_config.passThroughKeys.contains(event)) {
        _message(WrapperMessageType.keyPassThrough, event);
        _process.stdin.write(event);
        return;
      }
      if (_config.restartKeys.contains(event)) {
        _message(WrapperMessageType.keyRestart, event);
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

  String get name => _config.name;

  Stream<WrapperMessage> get messages => _messageController.stream;

  Future<void> close() {
    _keySub.cancel();
    _process.kill();
    return _processTerminatedCompleter.future;
  }

  Future<void> _exitCodePlus() async {
    try {
      final events = await Future.wait([
        _lines(_process.stdout),
        _lines(_process.stderr, error: true),
        _process.exitCode
      ]);

      final exitcode = events[2] as int;
      _message(WrapperMessageType.exit, '$exitcode');
    } finally {
      _processTerminatedCompleter.complete();
      _cancel();
      await _messageController.close();
    }
  }

  Future<void> _lines(Stream<List<int>> stdout, {bool error = false}) =>
      stdout.transform(systemEncoding.decoder).forEach((element) {
        _message(
          error ? WrapperMessageType.stderr : WrapperMessageType.stdout,
          element,
        );
      });

  void _message(WrapperMessageType type, String content) =>
      _messageController.add(WrapperMessage._(type, content));
}

class WrapperMessage {
  final WrapperMessageType type;
  final String content;

  WrapperMessage._(this.type, this.content);

  @override
  String toString() =>
      '${type.toString().split('.').last.padRight(15)} ${content.trim()}';
}

enum WrapperMessageType {
  stdout,
  stderr,
  keyPassThrough,
  keyRestart,
  exit,
}
