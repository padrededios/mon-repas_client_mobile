import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mon_repas_client_mobile/core/api/api_client.dart';
import 'package:mon_repas_client_mobile/core/api/api_exception.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

ResponseBody jsonResponse(int statusCode, Object body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

void main() {
  late MockHttpClientAdapter adapter;
  late ApiClient client;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
  });

  setUp(() {
    adapter = MockHttpClientAdapter();
    client = ApiClient();
    client.dio.httpClientAdapter = adapter;
  });

  void stubResponse(ResponseBody body) {
    when(() => adapter.fetch(any(), any(), any()))
        .thenAnswer((_) async => body);
  }

  RequestOptions capturedRequest() {
    return verify(() => adapter.fetch(captureAny(), any(), any()))
        .captured
        .single as RequestOptions;
  }

  group('ApiClient', () {
    test('GET 200 retourne le JSON décodé', () async {
      stubResponse(jsonResponse(200, {'id': 1, 'email': 'a@b.c'}));
      final data = await client.get('/auth/me');
      expect(data, {'id': 1, 'email': 'a@b.c'});
    });

    test('GET 200 supporte les réponses liste', () async {
      stubResponse(jsonResponse(200, [
        {'id': 1},
        {'id': 2},
      ]));
      final data = await client.get('/reservations/me');
      expect(data, isA<List<dynamic>>());
      expect((data as List).length, 2);
    });

    test('ajoute Authorization: Bearer quand un token est défini', () async {
      stubResponse(jsonResponse(200, {}));
      client.auth.token = 'jwt-123';
      await client.get('/auth/me');
      expect(capturedRequest().headers['Authorization'], 'Bearer jwt-123');
    });

    test("n'ajoute pas d'en-tête sans token", () async {
      stubResponse(jsonResponse(200, {}));
      await client.get('/daily-menus/week');
      expect(capturedRequest().headers.containsKey('Authorization'), isFalse);
    });

    test('erreur 400 → ApiException avec message du backend', () async {
      stubResponse(jsonResponse(400, {
        'statusCode': 400,
        'message': 'La fenêtre de modification est échue',
        'error': 'Bad Request',
      }));
      expect(
        () => client.patch('/reservations/1', data: {'timeSlotId': 2}),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having(
              (e) => e.message,
              'message',
              'La fenêtre de modification est échue',
            )),
      );
    });

    test('message sous forme de liste (class-validator) → lignes jointes',
        () async {
      stubResponse(jsonResponse(400, {
        'statusCode': 400,
        'message': ['email invalide', 'mot de passe trop court'],
        'error': 'Bad Request',
      }));
      expect(
        () => client.post('/auth/register', data: {}),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          'email invalide\nmot de passe trop court',
        )),
      );
    });

    test('401 → déclenche onUnauthorized puis lève ApiException', () async {
      stubResponse(jsonResponse(401, {
        'statusCode': 401,
        'message': 'Unauthorized',
      }));
      var loggedOut = false;
      client.onUnauthorized = () => loggedOut = true;
      await expectLater(
        () => client.get('/auth/me'),
        throwsA(isA<ApiException>()
            .having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
      );
      expect(loggedOut, isTrue);
    });

    test('erreur réseau → ApiException statusCode 0', () async {
      when(() => adapter.fetch(any(), any(), any()))
          .thenThrow(Exception('connexion refusée'));
      expect(
        () => client.get('/daily-menus/week'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 0)),
      );
    });

    test('erreur 500 → ApiException 500', () async {
      stubResponse(jsonResponse(500, {
        'statusCode': 500,
        'message': 'Internal server error',
      }));
      expect(
        () => client.get('/daily-menus/week'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 500)),
      );
    });
  });
}
