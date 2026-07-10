import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mon_repas_client_mobile/core/api/api_client.dart';
import 'package:mon_repas_client_mobile/core/api/api_exception.dart';
import 'package:mon_repas_client_mobile/core/storage/session_storage.dart';
import 'package:mon_repas_client_mobile/core/theme/app_theme.dart';
import 'package:mon_repas_client_mobile/core/theme/theme_choice_notifier.dart';
import 'package:mon_repas_client_mobile/data/models/user.dart';
import 'package:mon_repas_client_mobile/data/providers.dart';
import 'package:mon_repas_client_mobile/data/repositories/auth_repository.dart';
import 'package:mon_repas_client_mobile/features/auth/auth_notifier.dart';
import 'package:mon_repas_client_mobile/features/profile/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier() : super(AuthRepository(ApiClient(), SessionStorage())) {
    state = const AuthState(
      user: User(
        id: 3,
        email: 'client@mon-repas.com',
        firstName: 'Camille',
        lastName: 'Client',
        isAdmin: false,
        isRestaurant: false,
        isActive: true,
      ),
      isInitialized: true,
    );
  }
}

/// Repository factice : enregistre les appels de changement de mot de passe.
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super(ApiClient(), SessionStorage());

  final calls = <(String, String)>[];
  ApiException? nextError;

  @override
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final error = nextError;
    if (error != null) throw error;
    calls.add((currentPassword, newPassword));
    return 'Mot de passe mis à jour avec succès';
  }
}

late FakeAuthRepository fakeRepository;

Widget buildApp() {
  fakeRepository = FakeAuthRepository();
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => _FakeAuthNotifier()),
      authRepositoryProvider.overrideWithValue(fakeRepository),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const ProfileScreen(),
    ),
  );
}

Future<void> pumpProfile(WidgetTester tester) async {
  // Surface haute : toutes les sections du ListView sont construites et
  // atteignables sans scroll (le ListView ne construit que le visible).
  await tester.binding.setSurfaceSize(const Size(800, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(buildApp());
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets("affiche l'identité et toutes les sections", (tester) async {
    await pumpProfile(tester);

    expect(find.text('Camille Client'), findsOneWidget);
    expect(find.text('client@mon-repas.com'), findsOneWidget);
    expect(find.text('Sécurité'), findsOneWidget);
    expect(find.text('Changer mon mot de passe'), findsOneWidget);
    expect(find.text('Notifications push'), findsOneWidget);
    expect(find.text('Notifications mail'), findsOneWidget);
    expect(find.text('Bientôt disponible'), findsOneWidget);
    expect(find.text("Thème de l'application"), findsOneWidget);
    expect(find.text('Se déconnecter'), findsOneWidget);
  });

  testWidgets('propose les 4 thèmes dont le thème BD', (tester) async {
    await pumpProfile(tester);

    expect(find.text('Thème clair'), findsOneWidget);
    expect(find.text('Thème sombre'), findsOneWidget);
    expect(find.text('Thème BD'), findsOneWidget);
    expect(find.text('Thème système'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ProfileScreen)),
    );
    expect(container.read(themeChoiceProvider), AppThemeChoice.system);

    await tester.tap(find.text('Thème BD'));
    await tester.pumpAndSettle();
    expect(container.read(themeChoiceProvider), AppThemeChoice.comic);
  });

  testWidgets('les toggles mail sont désactivés (bientôt disponible)',
      (tester) async {
    await pumpProfile(tester);

    final switches = tester
        .widgetList<SwitchListTile>(find.byType(SwitchListTile))
        .where((s) => s.onChanged == null);
    expect(switches.length, 2);
  });

  testWidgets('désactiver une préférence push met à jour le notifier',
      (tester) async {
    await pumpProfile(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ProfileScreen)),
    );

    await tester.tap(
      find.ancestor(
        of: find.text('Rappel de repas'),
        matching: find.byType(SwitchListTile),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      container.read(notificationsProvider).preferences.mealReminder,
      isFalse,
    );
  });

  testWidgets('changement de mot de passe : validation puis appel API',
      (tester) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Changer mon mot de passe'));
    await tester.pumpAndSettle();

    // Nouveau mot de passe trop court → erreur de validation, pas d'appel.
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe actuel'), 'ancien');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nouveau mot de passe'), 'court');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmer le nouveau mot de passe'),
        'court');
    await tester.tap(find.text('Modifier le mot de passe'));
    await tester.pumpAndSettle();
    expect(find.text('Minimum 8 caractères'), findsOneWidget);
    expect(fakeRepository.calls, isEmpty);

    // Saisie valide → appel API et fermeture de la feuille.
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nouveau mot de passe'),
        'nouveau-mdp');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmer le nouveau mot de passe'),
        'nouveau-mdp');
    await tester.tap(find.text('Modifier le mot de passe'));
    await tester.pumpAndSettle();

    expect(fakeRepository.calls, [('ancien', 'nouveau-mdp')]);
    expect(find.text('Mot de passe mis à jour avec succès'), findsOneWidget);
  });

  testWidgets('mot de passe actuel incorrect : erreur affichée dans la feuille',
      (tester) async {
    await pumpProfile(tester);
    fakeRepository.nextError = const ApiException(
      statusCode: 401,
      message: 'Unauthorized',
    );

    await tester.tap(find.text('Changer mon mot de passe'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe actuel'), 'mauvais');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nouveau mot de passe'),
        'nouveau-mdp');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmer le nouveau mot de passe'),
        'nouveau-mdp');
    await tester.tap(find.text('Modifier le mot de passe'));
    await tester.pumpAndSettle();

    expect(find.text('Mot de passe actuel incorrect'), findsOneWidget);
    expect(fakeRepository.calls, isEmpty);
  });
}
