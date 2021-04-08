import 'package:io/io.dart';

class ShelfDevError extends Error {
  final String message;
  final Object? innerError;
  final StackTrace? innerStack;
  final ExitCode? exitCode;

  ShelfDevError(
    this.message, {
    this.innerError,
    this.innerStack,
    this.exitCode,
  });
}
