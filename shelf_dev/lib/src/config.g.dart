// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package, lines_longer_than_80_chars, prefer_expression_function_bodies

part of 'config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShelfDevConfig _$ShelfDevConfigFromJson(Map json) {
  return $checkedNew('ShelfDevConfig', json, () {
    $checkKeys(json, allowedKeys: const ['web-app', 'web-server']);
    final val = ShelfDevConfig(
      webApp: $checkedConvert(
          json, 'web-app', (v) => WebAppConfig.fromJson(v as Map)),
      webServer: $checkedConvert(
          json, 'web-server', (v) => WebServerConfig.fromJson(v as Map)),
    );
    return val;
  }, fieldKeyMap: const {'webApp': 'web-app', 'webServer': 'web-server'});
}

WebAppConfig _$WebAppConfigFromJson(Map json) {
  return $checkedNew('WebAppConfig', json, () {
    $checkKeys(json, allowedKeys: const ['port', 'path', 'command']);
    final val = WebAppConfig(
      path: $checkedConvert(json, 'path', (v) => v as String),
      command: $checkedConvert(json, 'command', (v) => v as String),
      port: $checkedConvert(json, 'port', (v) => v as int?),
    );
    return val;
  });
}

WebServerConfig _$WebServerConfigFromJson(Map json) {
  return $checkedNew('WebServerConfig', json, () {
    $checkKeys(json, allowedKeys: const ['port', 'path', 'command', 'source']);
    final val = WebServerConfig(
      path: $checkedConvert(json, 'path', (v) => v as String),
      command: $checkedConvert(json, 'command', (v) => v as String),
      source: $checkedConvert(json, 'source', (v) => v as String),
      port: $checkedConvert(json, 'port', (v) => v as int?),
    );
    return val;
  });
}
