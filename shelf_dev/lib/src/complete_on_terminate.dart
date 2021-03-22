import 'dart:async';
import 'dart:io';

Completer<void> completeOnTerminate() {
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

  final completer = Completer<void>();

  Timer.run(() async {
    await completer.future;
    await cancelSubscriptions();
  });

  Future<void> signalHandler(ProcessSignal signal) async {
    print('\nReceived signal $signal - closing');
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
