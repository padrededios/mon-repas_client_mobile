import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../features/auth/auth_notifier.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/events/event_detail_screen.dart';
import '../features/home/home_shell.dart';
import '../features/splash/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Chaque changement d'état d'auth relance le redirect.
  final refresh = ValueNotifier(0);
  ref.listen<AuthState>(authProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final location = state.matchedLocation;
      final onAuthPage = location == '/login' || location == '/register';

      if (!auth.isInitialized) {
        return location == '/splash' ? null : '/splash';
      }
      if (!auth.isAuthenticated) {
        return onAuthPage ? null : '/login';
      }
      if (onAuthPage || location == '/splash') return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: '/events/:id',
        builder: (context, state) => EventDetailScreen(
          eventId: int.parse(state.pathParameters['id']!),
        ),
      ),
    ],
  );
});
