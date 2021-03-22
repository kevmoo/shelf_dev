import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';

CancelableCompleter<void> completeOnTerminate() {
  // sigIntSub is copied below to avoid a race condition - ignoring this lint
  // ignore: cancel_subscriptions
  StreamSubscription? sigIntSub, sigTermSub;
  Future<void> cancelSubscriptions() async {
    final subCopy = sigIntSub;
    if (subCopy != null) {
      sigIntSub = null;
      await subCopy.cancel();
      sigIntSub = null;
      if (sigTermSub != null) {
        await sigTermSub!.cancel();
        sigTermSub = null;
      }
    }
  }

  final completer = CancelableCompleter<void>(onCancel: cancelSubscriptions);

  Future<void> signalHandler(ProcessSignal signal) async {
    print('Received signal $signal - closing');
    await cancelSubscriptions();
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  sigIntSub = ProcessSignal.sigint.watch().listen(signalHandler);

  // SIGTERM is not supported on Windows. Attempting to register a SIGTERM
  // handler raises an exception.
  if (!Platform.isWindows) {
    sigTermSub = ProcessSignal.sigterm.watch().listen(signalHandler);
  }

  return completer;
}
