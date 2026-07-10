import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mon_repas_client_mobile/core/api/api_client.dart';
import 'package:mon_repas_client_mobile/core/storage/session_storage.dart';
import 'package:mon_repas_client_mobile/core/theme/app_theme.dart';
import 'package:mon_repas_client_mobile/data/providers.dart';
import 'package:mon_repas_client_mobile/data/repositories/auth_repository.dart';
import 'package:mon_repas_client_mobile/features/auth/auth_notifier.dart';
import 'package:mon_repas_client_mobile/features/auth/login_screen.dart';
import 'package:mon_repas_client_mobile/features/splash/splash_screen.dart';
import 'package:mon_repas_client_mobile/routing/app_router.dart';

/// Session restaurée : initialisé mais non connecté.
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier() : super(AuthRepository(ApiClient(), SessionStorage())) {
    state = const AuthState(isInitialized: true);
  }
}

Widget buildSplash() {
  return const ProviderScope(
    child: MaterialApp(home: SplashScreen()),
  );
}

// Le halo pulse en boucle : jamais de pumpAndSettle ici, uniquement des
// pump à durée fixe.
void main() {
  testWidgets('le logo entre progressivement puis le titre se révèle',
      (tester) async {
    await tester.pumpWidget(buildSplash());

    // Première frame : logo présent mais encore invisible (opacité ~0).
    final logo = find.byKey(SplashScreen.logoKey);
    expect(logo, findsOneWidget);
    double logoOpacity() =>
        tester.widget<Opacity>(find.ancestor(
          of: logo,
          matching: find.byType(Opacity),
        ).first).opacity;
    expect(logoOpacity(), lessThan(0.1));

    // Fin de l'intro : logo pleinement visible + titre révélé.
    await tester.pump(const Duration(milliseconds: 1900));
    expect(logoOpacity(), closeTo(1, 0.01));
    expect(find.text('Mon Repas'), findsOneWidget);
  });

  testWidgets("l'intro terminée marque le splash comme terminé",
      (tester) async {
    await tester.pumpWidget(buildSplash());
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SplashScreen)),
    );

    expect(container.read(splashCompletedProvider), isFalse);

    await tester.pump(const Duration(milliseconds: 1900));
    expect(container.read(splashCompletedProvider), isTrue);
  });

  testWidgets(
      'le router reste sur le splash pendant l\'animation puis redirige',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier()),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: ref.watch(appRouterProvider),
          ),
        ),
      ),
    );
    await tester.pump();

    // Session déjà initialisée, mais l'animation n'est pas finie :
    // on reste sur le splash.
    expect(find.byType(SplashScreen), findsOneWidget);

    // Intro terminée → redirection vers la connexion.
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pump();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
