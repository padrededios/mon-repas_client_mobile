import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mon_repas_client_mobile/core/theme/app_theme.dart';
import 'package:mon_repas_client_mobile/data/providers.dart';
import 'package:mon_repas_client_mobile/data/repositories/auth_repository.dart';
import 'package:mon_repas_client_mobile/features/auth/register_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  setUp(() {
    repo = MockAuthRepository();
  });

  Widget buildApp() {
    final router = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('login-page')),
        ),
        GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      ],
    );
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  Future<void> fillForm(
    WidgetTester tester, {
    String confirm = 'password123',
  }) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Prénom'),
      'Claire',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Nom'), 'Martin');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'claire@exemple.fr',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mot de passe'),
      'password123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmer le mot de passe'),
      confirm,
    );
  }

  testWidgets('prénom trop court → message min 2 caractères', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.enterText(find.widgetWithText(TextFormField, 'Prénom'), 'J');
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(
      find.text('Prénom doit contenir au moins 2 caractères'),
      findsOneWidget,
    );
    verifyNever(() => repo.register(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ));
  });

  testWidgets('mots de passe différents → message webapp', (tester) async {
    await tester.pumpWidget(buildApp());
    await fillForm(tester, confirm: 'autre-mot-de-passe');
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(
      find.text('Les mots de passe ne correspondent pas'),
      findsOneWidget,
    );
    verifyNever(() => repo.register(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ));
  });

  testWidgets(
      'succès → message d\'attente d\'activation et retour au login '
      '(pas de login auto)', (tester) async {
    when(() => repo.register(
          firstName: 'Claire',
          lastName: 'Martin',
          email: 'claire@exemple.fr',
          password: 'password123',
        )).thenAnswer((_) async => 'Compte créé');

    await tester.pumpWidget(buildApp());
    await fillForm(tester);
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('En attente d\'activation par un administrateur'),
      findsOneWidget,
    );
    expect(find.text('login-page'), findsOneWidget);
  });
}
