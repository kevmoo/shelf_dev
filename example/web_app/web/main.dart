import 'dart:html';

import 'package:http/http.dart';

Future<void> main() async {
  _writeLog('Dart app running');

  final sumUri = Uri.parse('/api?a=1&b=2');

  _writeLog('Requesting $sumUri');

  try {
    final result = await get(sumUri);
    if (result.statusCode == 200) {
      _writeLog(result.body);
    } else {
      _writeLog('${result.statusCode} - ${result.body}', error: true);
    }
  } catch (e) {
    _writeLog('Error');
    _writeLog(e, error: true);
  }
}

void _writeLog(Object message, {bool error = false}) {
  final paragraph = ParagraphElement()..text = '$message';
  if (error) {
    paragraph.style.color = 'red';
  }
  _output.append(paragraph);
}

final _output = querySelector('#output') as DivElement;
