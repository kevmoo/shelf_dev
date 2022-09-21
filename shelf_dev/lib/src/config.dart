import 'package:json_annotation/json_annotation.dart';

import 'constants.dart';

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
    // TODO: webApp and webServer cannot have overlapping listen keys
  }

  factory ShelfDevConfig.fromJson(Map json) => _$ShelfDevConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ShelfDevConfigToJson(this);
}

abstract class BaseWebConfig {
  static const portPlaceHolder = '{PORT}';

  final int? port;
  final String path;
  final String command;
  final Set<String> passThroughKeys;
  final Set<String> restartKeys;

  String get name;

  BaseWebConfig({
    required this.path,
    required this.command,
    this.port,
    this.passThroughKeys = const {},
    this.restartKeys = const {},
  }) {
    // TODO: key sets cannot overlap!!
    if (command.trim().isEmpty) {
      throw ArgumentError.value(command, 'command', 'Cannot be empty');
    }
    if (port == null) {
      if (!command.contains(portPlaceHolder)) {
        throw ArgumentError.value(
          command,
          'command',
          'If `port` is omitted, `command` must include "$portPlaceHolder" '
              'so a dynamic port can be specified.',
        );
      }
    }
  }
}

@JsonSerializable()
class WebAppConfig extends BaseWebConfig {
  WebAppConfig({
    required super.path,
    required super.command,
    super.port,
  }) : super(passThroughKeys: passThroughKeys);

  factory WebAppConfig.fromJson(Map json) => _$WebAppConfigFromJson(json);

  Map<String, dynamic> toJson() => _$WebAppConfigToJson(this);

  @override
  String get name => 'webapp';
}

@JsonSerializable()
class WebServerConfig extends BaseWebConfig {
  final String source;
  final List<String> sourceSegments;

  WebServerConfig({
    required super.path,
    required super.command,
    required this.source,
    super.port,
  })  : sourceSegments = _parsePath(source),
        super(restartKeys: restartKeys);

  factory WebServerConfig.fromJson(Map json) => _$WebServerConfigFromJson(json);

  Map<String, dynamic> toJson() => _$WebServerConfigToJson(this);

  static List<String> _parsePath(String path) {
    final uri = Uri.parse(path);
    // TODO: much validation
    return uri.pathSegments;
  }

  @override
  String get name => 'server';
}
