import 'package:_test_web_app/handler.dart';
import 'package:shelf/shelf_io.dart';

Future<void> main(List<String> args) async {
  final server = await serve(handler, '127.0.0.1', 8090);

  print('Serving at ${server.address}:${server.port}');
}
