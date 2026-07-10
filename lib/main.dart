import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'data/providers.dart';
import 'routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');

  final container = ProviderContainer();
  // Restauration en arrière-plan : le splash attend isInitialized via le
  // redirect du router, sans bloquer le démarrage sur le réseau.
  container.read(notificationsProvider.notifier).hydrate();
  container.read(authProvider.notifier).hydrate();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MonRepasApp(),
    ),
  );
}

class MonRepasApp extends ConsumerWidget {
  const MonRepasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Mon Repas',
      debugShowCheckedModeBanner: false,
      // Thème unique : le clair est le seul validé visuellement.
      theme: AppTheme.light,
      routerConfig: router,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
