import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show Client;
import 'package:shelf/shelf.dart';
import 'package:shelf_proxy/shelf_proxy.dart';

import 'config.dart';
import 'utils.dart';

class ServerWrapper {
  final _messageController = StreamController<WrapperMessage>();
  final _fullyClosedCompleter = Completer<void>();
  final BaseWebConfig _config;
  final Handler _handler;
  final void Function() _cancel;
  final List<String> _commandBits;

  _State _state = _State.notRunning;

  Process? _process;

  late final StreamSubscription _keySub;

  ServerWrapper._(
    this._config,
    this._handler,
    this._commandBits,
    this._cancel,
    Stream<String> keyStream,
  ) {
    _keySub = keyStream.listen((event) {
      if (_config.passThroughKeys.contains(event)) {
        assert(!_config.restartKeys.contains(event));
        _handlePassThroughKey(event);
      }
      if (_config.restartKeys.contains(event)) {
        assert(!_config.passThroughKeys.contains(event));
        _handleRestartKey(event);
      }
    });
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

    final serverProxy = proxyHandler(
      'http://localhost:$port',
      client: client,
    );

    final wrapper = ServerWrapper._(
      config,
      serverProxy,
      commandBits,
      cancel,
      keyStream,
    );

    await wrapper._startProcess();

    return wrapper;
  }

  String get name => _config.name;

  Stream<WrapperMessage> get messages => _messageController.stream;

  Future<void> close() async {
    if (_state != _State.closed) {
      await _gotoState(_State.closeRequested);
    }
    await _fullyClosedCompleter.future;
  }

  Future<Response> handler(Request request) async {
    assert(_state == _State.running);
    try {
      return await _handler(request);
    } on SocketException catch (e) {
      await _gotoState(_State.closeRequested);
      return Response.internalServerError(
        body: 'Shutting down! Error from $name. $e',
      );
    }
  }

  Future<void> _startProcess() async {
    await _gotoState(_State.running);
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

  _State? _transitioningTo;

  void _handlePassThroughKey(String event) {
    _message(WrapperMessageType.info, 'Passing key "$event" to process.');
    _process?.stdin.write(event);
  }

  void _handleRestartKey(String event) {
    _message(
      WrapperMessageType.info,
      'Terminating process and attempting restart.',
    );
    _gotoState(_State.restartRequested);
  }

  Future<void> _gotoState(_State state) async {
    if (_transitioningTo != null) {
      throw StateError(
        'Tried to go to `$state`, but we are already in the middle of a '
        'transition to `$_transitioningTo`!',
      );
    }
    _debug([name, _state, 'to', state].join(' '));
    _transitioningTo = state;
    try {
      if (!_validTransitions[_state]!.contains(state)) {
        throw StateError(
          'Tried to go from `$_state` to `$state` which is not handled (yet)!',
        );
      }

      switch (state) {
        case _State.running:
          await _doRunningTransition();
          break;
        case _State.closeRequested:
          _process?.kill();
          break;
        case _State.processTerminated:
          await _keySub.cancel();
          Timer.run(() {
            // NOTE: now 100% sure this is the best approach, but it should be
            // workable. Queue up this transition for RIGHT AFTER this state
            // is transitioned to!
            _gotoState(_State.closed);
          });
          break;
        case _State.closed:
          _fullyClosedCompleter.complete();
          _cancel();
          await _messageController.close();
          break;
        case _State.restartRequested:
          await _doRestartingTransition();
          break;
        case _State.notRunning:
          throw StateError('Should never transition TO $state!');
      }
      _state = state;
    } finally {
      _transitioningTo = null;
    }
  }

  Future<void> _doRestartingTransition() async {
    assert(_transitioningTo == _State.restartRequested);
    _process?.kill();
  }

  Future<void> _doRunningTransition() async {
    assert(_transitioningTo == _State.running);
    if (_process != null) {
      throw StateError('Process has already started! This is a bug!');
    }

    final process = await Process.start(
      _commandBits.first,
      _commandBits.skip(1).toList(),
      workingDirectory: _config.path,
    );

    Timer.run(() async {
      try {
        final events = await Future.wait([
          _lines(process.stdout),
          _lines(process.stderr, error: true),
          process.exitCode
        ]);

        final exitcode = events[2] as int;
        _message(WrapperMessageType.exit, '$exitcode');
        _process = null;
      } finally {
        switch (_state) {
          case _State.closeRequested:
            await _gotoState(_State.closed);
            break;
          case _State.restartRequested:
            await _gotoState(_State.running);
            break;
          case _State.running:
            await _gotoState(_State.processTerminated);
            break;
          default:
            _debug(
              '$name - process died not sure what to do! - in state $_state '
              '- transitioning to $_transitioningTo',
            );
        }
      }
    });

    _process = process;
    assert(!_fullyClosedCompleter.isCompleted);
    assert(!_messageController.isClosed);
  }
}

void _debug(Object message) {
  //print(message);
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
  exit,
  info,
}

extension WrapperMessageTypeName on WrapperMessageType {
  String get name => toString().split('.').last;
}

const _validTransitions = <_State, Set<_State>>{
  _State.notRunning: {_State.running},
  _State.running: {
    _State.closeRequested,
    _State.restartRequested,
    _State.processTerminated,
  },
  _State.restartRequested: {_State.running},
  _State.closeRequested: {_State.closed},
  _State.processTerminated: {_State.closed},
  _State.closed: {},
};

enum _State {
  notRunning,
  running,
  restartRequested,
  closeRequested,
  processTerminated,
  closed,
}
