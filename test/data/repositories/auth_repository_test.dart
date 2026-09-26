import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mon_repas_client_mobile/core/api/api_client.dart';
import 'package:mon_repas_client_mobile/core/api/api_exception.dart';
import 'package:mon_repas_client_mobile/core/api/auth_interceptor.dart';
import 'package:mon_repas_client_mobile/core/storage/session_storage.dart';
import 'package:mon_repas_client_mobile/data/repositories/auth_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockSessionStorage extends Mock implements SessionStorage {}

const clientJson = {
  'id': 3,
  'email': 'client@mon-repas.com',
  'firstName': 'Claire',
  'lastName': 'Martin',
  'isAdmin': false,
  'isRestaurant': false,
  'isActive': true,
};

void main() {
  late MockApiClient api;
  late MockSessionStorage storage;
  late AuthInterceptor interceptor;
  late AuthRepository repo;

  setUp(() {
    api = MockApiClient();
    storage = MockSessionStorage();
    interceptor = AuthInterceptor();
    when(() => api.auth).thenReturn(interceptor);
    when(() => storage.saveSession(
          token: any(named: 'token'),
          userJson: any(named: 'userJson'),
        )).thenAnswer((_) async {});
    when(() => storage.clear()).thenAnswer((_) async {});
    when(() => storage.saveTokens(
          token: any(named: 'token'),
          refreshToken: any(named: 'refreshToken'),
        )).thenAnswer((_) async {});
    when(() => storage.readRefreshToken()).thenAnswer((_) async => 'rt-1');
    repo = AuthRepository(api, storage);
  });

  group('login', () {
    test('client : persiste la session et branche le token', () async {
      when(() => api.post('/auth/login', data: any(named: 'data')))
          .thenAnswer((_) async => {
                'access_token': 'jwt-123',
                'user': clientJson,
              });

      final user = await repo.login('client@mon-repas.com', 'password123');

      expect(user.email, 'client@mon-repas.com');
      expect(interceptor.token, 'jwt-123');
      verify(() => storage.saveSession(
            token: 'jwt-123',
            userJson: any(named: 'userJson'),
          )).called(1);
    });

    test('stocke le refresh token renvoyé par l’API', () async {
      when(() => api.post('/auth/login', data: any(named: 'data')))
          .thenAnswer((_) async => {
                'access_token': 'jwt-123',
                'refresh_token': 'rt-123',
                'user': clientJson,
              });

      await repo.login('client@mon-repas.com', 'password123');

      verify(() => storage.saveTokens(token: 'jwt-123', refreshToken: 'rt-123'))
          .called(1);
    });

    test('admin/restaurateur : refusé, rien n\'est persisté', () async {
      when(() => api.post('/auth/login', data: any(named: 'data')))
          .thenAnswer((_) async => {
                'access_token': 'jwt-admin',
                'user': {...clientJson, 'isAdmin': true},
              });

      await expectLater(
        () => repo.login('admin@mon-repas.com', 'password123'),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('réservée aux clients'),
        )),
      );
      expect(interceptor.token, isNull);
      verifyNever(() => storage.saveSession(
            token: any(named: 'token'),
            userJson: any(named: 'userJson'),
          ));
    });
  });

  group('restoreSession', () {
    test('pas de token → null sans appel réseau', () async {
      when(() => storage.readToken()).thenAnswer((_) async => null);
      expect(await repo.restoreSession(), isNull);
      verifyNever(() => api.get(any()));
    });

    test('token valide → GET /auth/me et user rafraîchi', () async {
      when(() => storage.readToken()).thenAnswer((_) async => 'jwt-123');
      when(() => api.get('/auth/me')).thenAnswer((_) async => clientJson);

      final user = await repo.restoreSession();

      expect(user?.id, 3);
      expect(interceptor.token, 'jwt-123');
      verify(() => storage.saveSession(
            token: 'jwt-123',
            userJson: any(named: 'userJson'),
          )).called(1);
    });

    test('token expiré (401) → session purgée, null', () async {
      when(() => storage.readToken()).thenAnswer((_) async => 'jwt-vieux');
      when(() => api.get('/auth/me')).thenThrow(
        const ApiException(statusCode: 401, message: 'Unauthorized'),
      );

      expect(await repo.restoreSession(), isNull);
      expect(interceptor.token, isNull);
      verify(() => storage.clear()).called(1);
    });

    test('erreur réseau → user en cache conservé (mode dégradé)', () async {
      when(() => storage.readToken()).thenAnswer((_) async => 'jwt-123');
      when(() => storage.readUserJson())
          .thenAnswer((_) async => '{"id":3,"email":"client@mon-repas.com",'
              '"firstName":"Claire","lastName":"Martin","isAdmin":false,'
              '"isRestaurant":false,"isActive":true}');
      when(() => api.get('/auth/me')).thenThrow(
        const ApiException(statusCode: 0, message: 'Réseau indisponible'),
      );

      final user = await repo.restoreSession();
      expect(user?.email, 'client@mon-repas.com');
    });
  });

  group('refreshSession', () {
    test('échange le refresh token, stocke la nouvelle paire et branche le jeton',
        () async {
      when(() => api.post('/auth/refresh', data: {'refresh_token': 'rt-1'}))
          .thenAnswer((_) async => {
                'access_token': 'jwt-2',
                'refresh_token': 'rt-2',
              });

      expect(await repo.refreshSession(), isTrue);
      expect(interceptor.token, 'jwt-2');
      verify(() => storage.saveTokens(token: 'jwt-2', refreshToken: 'rt-2'))
          .called(1);
    });

    test('refus de l’API → false', () async {
      when(() => api.post('/auth/refresh', data: any(named: 'data'))).thenThrow(
        const ApiException(statusCode: 401, message: 'Session expirée'),
      );

      expect(await repo.refreshSession(), isFalse);
    });

    test('sans refresh token stocké → false sans appel réseau', () async {
      when(() => storage.readRefreshToken()).thenAnswer((_) async => null);

      expect(await repo.refreshSession(), isFalse);
      verifyNever(() => api.post(any(), data: any(named: 'data')));
    });
  });

  group('logout', () {
    test('révoque le refresh token côté API puis purge', () async {
      when(() => api.post('/auth/logout', data: any(named: 'data')))
          .thenAnswer((_) async => {'message': 'ok'});

      await repo.logout();

      verify(() => api.post('/auth/logout', data: {'refresh_token': 'rt-1'}))
          .called(1);
      verify(() => storage.clear()).called(1);
    });

    test('purge locale même si l\'API échoue', () async {
      when(() => api.post('/auth/logout', data: any(named: 'data'))).thenThrow(
        const ApiException(statusCode: 0, message: 'Réseau indisponible'),
      );
      interceptor.token = 'jwt-123';

      await repo.logout();

      expect(interceptor.token, isNull);
      verify(() => storage.clear()).called(1);
    });
  });

  group('register', () {
    test('renvoie le message du backend, sans authentifier', () async {
      when(() => api.post('/users/register', data: any(named: 'data')))
          .thenAnswer((_) async => {'message': 'Compte créé'});

      final message = await repo.register(
        firstName: 'Claire',
        lastName: 'Martin',
        email: 'claire@ex.fr',
        password: 'password123',
      );

      expect(message, 'Compte créé');
      expect(interceptor.token, isNull);
    });
  });
}
