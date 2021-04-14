import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:io/io.dart';

import 'cli_options.dart';
import 'config.dart';
import 'constants.dart';
import 'shelf_dev_error.dart';

// TODO: support specifying config in CLI
ShelfDevConfig? configAtRuntime([List<String> arguments = const []]) {
  final cliOptions = CommandLineOptions.parse(arguments);

  if (cliOptions == null) {
    return null;
  }

  final file = File(defaultConfigFileName);

  if (!file.existsSync()) {
    throw ShelfDevError(
      'Configuration file "$defaultConfigFileName" not found.',
      exitCode: ExitCode.config,
    );
  }

  try {
    return checkedYamlDecode(
      file.readAsStringSync(),
      (m) => ShelfDevConfig.fromJson(m!),
      sourceUrl: Uri.parse(defaultConfigFileName),
    );
  } on ParsedYamlException catch (e, stack) {
    throw ShelfDevError(
      [
        'Invalid configuration file',
        e.message,
        if (e.formattedMessage != null) e.formattedMessage,
      ].join('\n'),
      innerError: e,
      innerStack: stack,
      exitCode: ExitCode.config,
    );
  }
}
