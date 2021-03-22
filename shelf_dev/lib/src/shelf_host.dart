import 'dart:async';
import 'dart:io';

import 'package:io/ansi.dart';
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
  print(
    styleBold
        .wrap('shelf_dev Listening on ${server.address.host}:${server.port}'),
  );

  await closeSignal;
  await server.close(force: true);
}
