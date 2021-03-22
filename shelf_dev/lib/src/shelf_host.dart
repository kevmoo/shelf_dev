import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> runShelfHandler(
  int port,
  Handler handler,
  Future<void> closeSignal,
) async {
  final server = await shelf_io.serve(
    handler,
    InternetAddress.loopbackIPv4,
    port,
  );
  print('Listening on ${server.address.host}:${server.port}');

  await closeSignal;
  await server.close(force: true);
}
