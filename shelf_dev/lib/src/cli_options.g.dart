// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cli_options.dart';

// **************************************************************************
// CliGenerator
// **************************************************************************

CommandLineOptions _$parseCommandLineOptionsResult(ArgResults result) =>
    CommandLineOptions(
        help: result['help'] as bool, version: result['version'] as bool);

ArgParser _$populateCommandLineOptionsParser(ArgParser parser) => parser
  ..addFlag('help',
      abbr: '?', help: 'Print out usage information.', negatable: false)
  ..addFlag('version',
      help: 'Print out the version of the executable.', negatable: false);

final _$parserForCommandLineOptions =
    _$populateCommandLineOptionsParser(ArgParser());

CommandLineOptions parseCommandLineOptions(List<String> args) {
  final result = _$parserForCommandLineOptions.parse(args);
  return _$parseCommandLineOptionsResult(result);
}
