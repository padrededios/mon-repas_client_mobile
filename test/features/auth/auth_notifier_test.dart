import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mon_repas_client_mobile/core/api/api_exception.dart';
import 'package:mon_repas_client_mobile/data/models/user.dart';
import 'package:mon_repas_client_mobile/data/repositories/auth_repository.dart';
import 'package:mon_repas_client_mobile/features/auth/auth_notifier.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const client = User(
  id: 3,
  email: 'client@mon-repas.com',
  firstName: 'Claire',
  lastName: 'Martin',
  isAdmin: false,
  isRestaurant: false,
  isActive: true,
);

void main() {
  late MockAuthRepository repo;
  late AuthNotifier notifier;

  setUp(() {
    repo = MockAuthRepository();
    notifier = AuthNotifier(repo);
  });

  group('hydrate', () {
    test('session restaurée → user défini et initialisé', () async {
      when(() => repo.restoreSession()).thenAnswer((_) async => client);
      await notifier.hydrate();
      expect(notifier.state.user, client);
      expect(notifier.state.isInitialized, isTrue);
    });

    test('pas de session → initialisé sans user', () async {
      when(() => repo.restoreSession()).thenAnswer((_) async => null);
      await notifier.hydrate();
      expect(notifier.state.user, isNull);
      expect(notifier.state.isInitialized, isTrue);
    });

    test('erreur inattendue → initialisé quand même (pas de splash bloqué)',
        () async {
      when(() => repo.restoreSession()).thenThrow(Exception('boom'));
      await notifier.hydrate();
      expect(notifier.state.user, isNull);
      expect(notifier.state.isInitialized, isTrue);
    });
  });

  group('login', () {
    test('succès → user défini, pas d\'erreur', () async {
      when(() => repo.login('client@mon-repas.com', 'password123'))
          .thenAnswer((_) async => client);
      final ok = await notifier.login('client@mon-repas.com', 'password123');
      expect(ok, isTrue);
      expect(notifier.state.user, client);
      expect(notifier.state.error, isNull);
      expect(notifier.state.isLoading, isFalse);
    });

    test('échec API → erreur exposée, pas de user', () async {
      when(() => repo.login(any(), any())).thenThrow(
        const ApiException(statusCode: 401, message: 'Identifiants invalides'),
      );
      final ok = await notifier.login('client@mon-repas.com', 'mauvais');
      expect(ok, isFalse);
      expect(notifier.state.user, isNull);
      expect(notifier.state.error, 'Identifiants invalides');
      expect(notifier.state.isLoading, isFalse);
    });

    test('compte admin/restaurateur refusé par le repository → erreur dédiée',
        () async {
      when(() => repo.login(any(), any())).thenThrow(
        const ApiException(
          statusCode: 403,
          message: 'Cette application est réservée aux clients',
        ),
      );
      final ok = await notifier.login('admin@mon-repas.com', 'password123');
      expect(ok, isFalse);
      expect(
        notifier.state.error,
        'Cette application est réservée aux clients',
      );
    });
  });

  group('logout', () {
    test('vide la session', () async {
      when(() => repo.restoreSession()).thenAnswer((_) async => client);
      when(() => repo.logout()).thenAnswer((_) async {});
      await notifier.hydrate();
      await notifier.logout();
      expect(notifier.state.user, isNull);
      verify(() => repo.logout()).called(1);
    });
  });
}
