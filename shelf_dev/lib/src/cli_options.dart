import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:io/io.dart';
import 'shelf_dev_error.dart';

import 'version.dart';

part 'cli_options.g.dart';

@CliOptions()
class CommandLineOptions {
  @CliOption(
    abbr: '?',
    help: 'Print out usage information.',
    negatable: false,
  )
  final bool help;

  @CliOption(
    help: 'Print out the version of the executable.',
    negatable: false,
  )
  final bool version;

  CommandLineOptions({
    this.help = false,
    this.version = false,
  });

  static CommandLineOptions? parse(List<String> arguments) {
    CommandLineOptions cliOptions;
    try {
      cliOptions = parseCommandLineOptions(arguments);
    } on FormatException catch (e, stack) {
      throw ShelfDevError(
        [
          'Unsupported command line argument.',
          e.message,
          _$parserForCommandLineOptions.usage,
        ].join('\n'),
        innerError: e,
        innerStack: stack,
        exitCode: ExitCode.usage,
      );
    }

    if (cliOptions.help) {
      print('Yes, I need to add a LOT more here. Sorry...');
      print(_$parserForCommandLineOptions.usage);
      return null;
    }

    if (cliOptions.version) {
      print(packageVersion);
      return null;
    }

    return cliOptions;
  }
}
