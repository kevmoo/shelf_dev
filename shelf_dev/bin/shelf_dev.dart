import 'package:shelf_dev/src/config_utils.dart';
import 'package:shelf_dev/src/runner.dart';

Future<void> main(List<String> arguments) async {
  final config = configAtRuntime(arguments);
  await run(config);
}
