// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: require_trailing_commas

part of 'config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShelfDevConfig _$ShelfDevConfigFromJson(Map json) => $checkedCreate(
      'ShelfDevConfig',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const ['port', 'web-app', 'web-server'],
        );
        final val = ShelfDevConfig(
          port: $checkedConvert('port', (v) => v as int? ?? 8080),
          webApp: $checkedConvert(
              'web-app', (v) => WebAppConfig.fromJson(v as Map)),
          webServer: $checkedConvert(
              'web-server', (v) => WebServerConfig.fromJson(v as Map)),
        );
        return val;
      },
      fieldKeyMap: const {'webApp': 'web-app', 'webServer': 'web-server'},
    );

Map<String, dynamic> _$ShelfDevConfigToJson(ShelfDevConfig instance) =>
    <String, dynamic>{
      'port': instance.port,
      'web-app': instance.webApp,
      'web-server': instance.webServer,
    };

WebAppConfig _$WebAppConfigFromJson(Map json) => $checkedCreate(
      'WebAppConfig',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const ['port', 'path', 'command'],
        );
        final val = WebAppConfig(
          path: $checkedConvert('path', (v) => v as String),
          command: $checkedConvert('command', (v) => v as String),
          port: $checkedConvert('port', (v) => v as int?),
        );
        return val;
      },
    );

Map<String, dynamic> _$WebAppConfigToJson(WebAppConfig instance) =>
    <String, dynamic>{
      'port': instance.port,
      'path': instance.path,
      'command': instance.command,
    };

WebServerConfig _$WebServerConfigFromJson(Map json) => $checkedCreate(
      'WebServerConfig',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const ['port', 'path', 'command', 'source'],
        );
        final val = WebServerConfig(
          path: $checkedConvert('path', (v) => v as String),
          command: $checkedConvert('command', (v) => v as String),
          source: $checkedConvert('source', (v) => v as String),
          port: $checkedConvert('port', (v) => v as int?),
        );
        return val;
      },
    );

Map<String, dynamic> _$WebServerConfigToJson(WebServerConfig instance) =>
    <String, dynamic>{
      'port': instance.port,
      'path': instance.path,
      'command': instance.command,
      'source': instance.source,
    };
