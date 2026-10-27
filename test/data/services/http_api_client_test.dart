import 'dart:convert';

import 'package:agora_im_flutter/data/services/http_api_client.dart';
import 'package:agora_im_flutter/domain/errors/app_failure.dart';
import 'package:agora_im_flutter/domain/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('HttpApiClient', () {
    test('sends JSON, query, and bearer auth', () async {
      late http.Request captured;
      final api = HttpApiClient(
        baseUrl: Uri.parse('https://api.example.test/v1'),
        accessToken: () async => 'token-123',
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            '{"ok":true}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(api.close);

      final response = await api.send(
        const ApiRequest(
          method: ApiMethod.post,
          path: 'ping',
          query: {'page': '2'},
          body: {'hello': 'world'},
        ),
      );

      expect(
        captured.url.toString(),
        'https://api.example.test/v1/ping?page=2',
      );
      expect(captured.headers['Authorization'], 'Bearer token-123');
      expect(captured.headers['Content-Type'], 'application/json');
      expect(jsonDecode(captured.body), {'hello': 'world'});
      expect(response.statusCode, 200);
      expect(response.json, {'ok': true});
    });

    test('maps non-2xx responses to ApiFailure', () async {
      final api = HttpApiClient(
        baseUrl: Uri.parse('https://api.example.test'),
        client: MockClient((_) async => http.Response('{"error":"nope"}', 422)),
      );
      addTearDown(api.close);

      await expectLater(
        api.send(const ApiRequest(method: ApiMethod.get, path: 'missing')),
        throwsA(
          isA<ApiFailure>()
              .having((error) => error.statusCode, 'statusCode', 422)
              .having((error) => error.body, 'body', contains('nope')),
        ),
      );
    });

    test('maps timeouts to NetworkFailure', () async {
      final api = HttpApiClient(
        baseUrl: Uri.parse('https://api.example.test'),
        timeout: const Duration(milliseconds: 1),
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response('{}', 200);
        }),
      );
      addTearDown(api.close);

      await expectLater(
        api.send(const ApiRequest(method: ApiMethod.get, path: 'slow')),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });
}
