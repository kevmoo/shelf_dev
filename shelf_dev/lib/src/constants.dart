import 'package:io/ansi.dart';

/// The name of the package and the executable registered with
/// `pub global activate`.
const appName = 'shelf_dev';

/// The location of the source code
const appSource = 'https://github.com/kevmoo/shelf_dev';

/// The default file name for configuration.
const defaultConfigFileName = 'shelf_dev.yaml';

/// Keys passed through from [appName] to "web-app".
const passThroughKeys = {'r', 'R'};

/// Keys that signal the "web-server" should be terminated and restarted.
const restartKeys = {'s', 'S'};

String get introduction => '''
${_bold(appName)} must be run in a directory with a ${_bold(defaultConfigFileName)} configuration file.

See ${_bold(appSource)} for information on the configuration format.

While running, these keys – ${_quoteJoinBold(passThroughKeys)} – will be passed to the "web-app" target.
When used with `flutter run` this cause a hot restart.

When these keys – ${_quoteJoinBold(restartKeys)} – are pressed, ${_bold(appName)} will 
attempt to restart the "web-server" target.

Other options:''';

String _bold(String input) => styleBold.wrap(input)!;

String _quoteJoinBold(Iterable<String> values) =>
    _bold(values.map((e) => '"$e"').join(', '));
