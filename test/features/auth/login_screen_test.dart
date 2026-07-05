import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mon_repas_client_mobile/core/api/api_exception.dart';
import 'package:mon_repas_client_mobile/core/theme/app_theme.dart';
import 'package:mon_repas_client_mobile/data/models/user.dart';
import 'package:mon_repas_client_mobile/data/providers.dart';
import 'package:mon_repas_client_mobile/data/repositories/auth_repository.dart';
import 'package:mon_repas_client_mobile/features/auth/login_screen.dart';

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

  setUp(() {
    repo = MockAuthRepository();
  });

  Widget buildApp() {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(
          path: '/register',
          builder: (_, _) => const Scaffold(body: Text('register-page')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  testWidgets('champs vides → messages de validation, pas d\'appel API',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('Email requis'), findsOneWidget);
    expect(find.text('Mot de passe requis'), findsOneWidget);
    verifyNever(() => repo.login(any(), any()));
  });

  testWidgets('email invalide et mot de passe court → messages dédiés',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'pas-un-email',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mot de passe'),
      'court',
    );
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('Email invalide'), findsOneWidget);
    expect(
      find.text('Le mot de passe doit contenir au moins 8 caractères'),
      findsOneWidget,
    );
    verifyNever(() => repo.login(any(), any()));
  });

  testWidgets('identifiants valides → appel au repository', (tester) async {
    when(() => repo.login('client@mon-repas.com', 'password123'))
        .thenAnswer((_) async => client);

    await tester.pumpWidget(buildApp());
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'client@mon-repas.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mot de passe'),
      'password123',
    );
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    verify(() => repo.login('client@mon-repas.com', 'password123')).called(1);
  });

  testWidgets('échec de connexion → snackbar avec le message serveur',
      (tester) async {
    when(() => repo.login(any(), any())).thenThrow(
      const ApiException(statusCode: 401, message: 'Identifiants invalides'),
    );

    await tester.pumpWidget(buildApp());
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'client@mon-repas.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mot de passe'),
      'mauvais-mdp',
    );
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('Identifiants invalides'), findsOneWidget);
  });

  testWidgets('lien « Créer un compte » → page register', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.textContaining('Créer un compte'));
    await tester.pumpAndSettle();

    expect(find.text('register-page'), findsOneWidget);
  });
}
