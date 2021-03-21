import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart';

import 'config.dart';

// TODO: support specifying config in CLI
ShelfDevConfig configAtRuntime([List<String>? arguments]) => checkedYamlDecode(
      File(_defaultFile).readAsStringSync(),
      (m) => ShelfDevConfig.fromJson(m!),
      sourceUrl: Uri.parse(_defaultFile),
    );

const _defaultFile = 'shelf_dev.yaml';
