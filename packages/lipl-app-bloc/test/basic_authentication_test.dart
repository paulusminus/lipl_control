import 'dart:io';

import 'package:dio/dio.dart';
import 'package:lipl_model/lipl_model.dart';
import 'package:lipl_app_bloc/src/basic_authentication.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

class MockRequestHandler extends Mock implements RequestInterceptorHandler {}

String? username() => Platform.environment['LIPL_USERNAME'];

void main() {
  Credentials createSubject() =>
      Credentials(username: username()!, password: 'test');

  group('Credentials', () {
    test('constructor', () {
      final credentials = createSubject();
      expect(credentials.username, username()!);
      expect(credentials.password, 'test');
    });

    test('props', () {
      expect(createSubject().props, [username()!, 'test']);
    });

    test('toString', () {
      expect(
        createSubject().toString(),
        'paul:test',
      );
    });
  });

  group('Authentication', () {
    test('basic', () async {
      final handler = MockRequestHandler();
      final interceptor = basicAuthentication(credentials: createSubject());
      RequestOptions options =
          RequestOptions(path: 'https://www.paulmin.nl/api/v1/lyric');
      interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], 'Basic cGF1bDp0ZXN0');
      verify(
        () => handler.next(options),
      ).called(1);
    });
  });
}
