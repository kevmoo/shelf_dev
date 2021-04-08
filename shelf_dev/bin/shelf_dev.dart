import 'dart:io';

import 'package:shelf_dev/src/config_utils.dart';
import 'package:shelf_dev/src/runner.dart';
import 'package:shelf_dev/src/shelf_dev_error.dart';

Future<void> main(List<String> arguments) async {
  try {
    final config = configAtRuntime(arguments);
    if (config == null) {
      // Nothing to do! Just exit!
      return;
    }
    await run(config);
  } catch (e, stack) {
    if (e is ShelfDevError) {
      print(e.message);
      exitCode = e.exitCode?.code ?? 1;
    } else {
      // TODO: pkg:stack_trace
      print(e);
      print(stack);
      exitCode = 1;
    }
  }
}
