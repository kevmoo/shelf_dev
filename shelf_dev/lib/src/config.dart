import 'package:json_annotation/json_annotation.dart';

part 'config.g.dart';

@JsonSerializable()
class ShelfDevConfig {
  @JsonKey(defaultValue: 8080)
  final int port;

  final WebAppConfig webApp;

  final WebServerConfig webServer;

  ShelfDevConfig({
    required this.port,
    required this.webApp,
    required this.webServer,
  }) {
    // TODO: webApp cannot be "underneath" server – or everything will blow up
  }

  factory ShelfDevConfig.fromJson(Map json) => _$ShelfDevConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ShelfDevConfigToJson(this);
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

  Map<String, dynamic> toJson() => _$WebAppConfigToJson(this);
}

@JsonSerializable()
class WebServerConfig extends BaseWebConfig {
  final String source;
  final List<String> sourceSegments;

  WebServerConfig({
    required String path,
    required String command,
    required this.source,
    int? port,
  })  : sourceSegments = _parsePath(source),
        super(path: path, command: command, port: port);

  factory WebServerConfig.fromJson(Map json) => _$WebServerConfigFromJson(json);

  Map<String, dynamic> toJson() => _$WebServerConfigToJson(this);

  static List<String> _parsePath(String path) {
    final uri = Uri.parse(path);
    // TODO: much validation
    return uri.pathSegments;
  }
}
