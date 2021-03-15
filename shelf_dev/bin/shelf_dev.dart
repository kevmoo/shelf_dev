import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:shelf_dev/src/config.dart';

Future<void> main(List<String> arguments) async {
  final config = checkedYamlDecode(
    File(_defaultFile).readAsStringSync(),
    (m) => ShelfDevConfig.fromJson(m!),
    sourceUrl: Uri.parse(_defaultFile),
  );
  print(config);
}

const _defaultFile = 'shelf_dev.yaml';
