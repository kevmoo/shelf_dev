import 'dart:io';

import 'package:io/ansi.dart';

import 'constants.dart';

/// Returns an open port by creating a temporary Socket
// Copied with love from
// https://github.com/dart-lang/coverage/blob/89355571a42a9cb810e0eb2a3c0e9f6f13c5d880/lib/src/util.dart#L58-L74
Future<int> getOpenPort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);

  try {
    return socket.port;
  } finally {
    await socket.close();
  }
}

void appPrint(Object object) => print(styleBold.wrap('$appName $object'));
