import 'dart:convert';
import 'dart:math' as math;

import 'package:_test_web_app/handler.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  test('valid', () async {
    final rnd = math.Random();
    final a = rnd.nextInt(255);
    final b = rnd.nextInt(255);
    final result =
        await handler(Request('GET', Uri.parse('http://localhost/?a=$a&b=$b')));

    final responseBody = await result.readAsString();

    expect(result.statusCode, 200);

    final json = jsonDecode(responseBody) as Map<String, dynamic>;

    expect(json, {'a': a, 'b': b, 'sum': a + b});
  });

  test('missing params', () async {
    final result = await handler(
      Request('GET', Uri.parse('http://localhost/?a=2')),
    );
    final responseBody = await result.readAsString();

    expect(result.statusCode, 400);
    expect(responseBody, '"b" does not exist');
  });

  test('wrong path', () async {
    final result = await handler(
      Request('GET', Uri.parse('http://localhost/bob?a=2')),
    );
    final responseBody = await result.readAsString();

    expect(result.statusCode, 400);
    expect(responseBody, 'No fancy paths, please! (Got "bob").');
  });

  test('wrong verb', () async {
    final result = await handler(
      Request('POST', Uri.parse('http://localhost/api?a=2')),
    );
    final responseBody = await result.readAsString();

    expect(result.statusCode, 400);
    expect(responseBody, 'only GET is accepted!');
  });

  test('invalid params', () async {
    final result = await handler(
      Request('GET', Uri.parse('http://localhost/?a=two&b=three')),
    );
    final responseBody = await result.readAsString();

    expect(result.statusCode, 400);
    expect(
      responseBody,
      'Could not parse "a" with value "two" - Invalid radix-10 number',
    );
  });
}
