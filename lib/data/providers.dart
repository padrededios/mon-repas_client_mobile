import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/storage/session_storage.dart';
import '../core/theme/theme_mode_notifier.dart';
import '../features/auth/auth_notifier.dart';
import 'repositories/auth_repository.dart';

/// Tous les providers Riverpod de l'app, centralisés (pattern stepzy_mobile).

// Types explicites : apiClientProvider et authProvider se référencent
// mutuellement (handler 401), l'inférence seule serait circulaire.
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  // Session expirée (401) → purge locale + retour login via le redirect.
  client.onUnauthorized = () {
    ref.read(authProvider.notifier).forceLogout();
  };
  return client;
});

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SessionStorage();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(sessionStorageProvider),
  );
});

final StateNotifierProvider<AuthNotifier, AuthState> authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
