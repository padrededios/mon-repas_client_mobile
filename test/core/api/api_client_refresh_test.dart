import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mon_repas_client_mobile/core/api/api_client.dart';
import 'package:mon_repas_client_mobile/core/api/api_exception.dart';

/// Faux serveur : 200 si le jeton présenté est [validToken], 401 sinon.
class FakeServer implements HttpClientAdapter {
  FakeServer(this.validToken);

  String validToken;
  final calls = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final auth = options.headers['Authorization'];
    calls.add('${options.path} $auth');
    final ok = auth == 'Bearer $validToken';
    return ResponseBody.fromString(
      jsonEncode(ok ? {'path': options.path} : {'statusCode': 401}),
      ok ? 200 : 401,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late FakeServer server;
  late ApiClient client;
  late int refreshCalls;
  late int logouts;

  setUp(() {
    server = FakeServer('new-access');
    client = ApiClient()..auth.token = 'old-access';
    client.dio.httpClientAdapter = server;
    refreshCalls = 0;
    logouts = 0;
    client.onUnauthorized = () => logouts++;
    client.refreshSession = () async {
      refreshCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      client.auth.token = 'new-access';
      return true;
    };
  });

  group('ApiClient — rafraîchissement de session', () {
    test('sur 401, rafraîchit puis rejoue la requête', () async {
      final data = await client.get('/reservations/me');

      expect(data, {'path': '/reservations/me'});
      expect(refreshCalls, 1);
      expect(logouts, 0);
      expect(server.calls.last, '/reservations/me Bearer new-access');
    });

    test('un seul rafraîchissement pour plusieurs requêtes simultanées',
        () async {
      final results = await Future.wait([
        client.get('/a'),
        client.get('/b'),
        client.get('/c'),
      ]);

      expect(results.length, 3);
      expect(refreshCalls, 1);
    });

    test('rafraîchissement refusé → déconnexion et erreur 401', () async {
      client.refreshSession = () async {
        refreshCalls++;
        return false;
      };

      await expectLater(
        () => client.get('/reservations/me'),
        throwsA(isA<ApiException>()
            .having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
      );
      expect(logouts, 1);
    });

    test('pas de boucle si la requête rejouée reçoit encore 401', () async {
      server.validToken = 'jamais';

      await expectLater(
        () => client.get('/reservations/me'),
        throwsA(isA<ApiException>()),
      );
      expect(refreshCalls, 1);
      expect(logouts, 1);
    });

    test('401 sur une route d’authentification : ni refresh ni déconnexion',
        () async {
      await expectLater(
        () => client.post('/auth/login', data: {}),
        throwsA(isA<ApiException>()),
      );
      expect(refreshCalls, 0);
      expect(logouts, 0);
    });
  });
}
