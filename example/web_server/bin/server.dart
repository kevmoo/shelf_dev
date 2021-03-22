import 'package:_test_web_app/handler.dart';
import 'package:args/args.dart';
import 'package:shelf/shelf_io.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()..addOption('port', defaultsTo: '8080');
  final result = parser.parse(args);
  final server =
      await serve(handler, 'localhost', int.parse(result['port'] as String));

  print('Serving at ${server.address.host}:${server.port}');
}
