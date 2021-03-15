import 'package:json_annotation/json_annotation.dart';

part 'config.g.dart';

@JsonSerializable()
class ShelfDevConfig {
  final WebAppConfig webApp;

  final WebServerConfig webServer;

  ShelfDevConfig({required this.webApp, required this.webServer});

  factory ShelfDevConfig.fromJson(Map json) => _$ShelfDevConfigFromJson(json);
}

abstract class BaseWebConfig {
  final int? port;
  final String path;
  final String command;

  BaseWebConfig({
    required this.path,
    required this.command,
    this.port,
  });
}

@JsonSerializable()
class WebAppConfig extends BaseWebConfig {
  WebAppConfig({
    required String path,
    required String command,
    int? port,
  }) : super(path: path, command: command, port: port);

  factory WebAppConfig.fromJson(Map json) => _$WebAppConfigFromJson(json);
}

@JsonSerializable()
class WebServerConfig extends BaseWebConfig {
  final String source;

  WebServerConfig({
    required String path,
    required String command,
    required this.source,
    int? port,
  }) : super(path: path, command: command, port: port);

  factory WebServerConfig.fromJson(Map json) => _$WebServerConfigFromJson(json);
}
