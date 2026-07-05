import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  final User? user;
  final bool isLoading;
  final String? error;

  /// false tant que la restauration de session (splash) n'est pas terminée.
  final bool isInitialized;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  Future<void> hydrate() async {
    try {
      final user = await _repository.restoreSession();
      state = AuthState(user: user, isInitialized: true);
    } catch (_) {
      state = const AuthState(isInitialized: true);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.login(email, password);
      state = AuthState(user: user, isInitialized: true);
      return true;
    } on ApiException catch (e) {
      state = AuthState(error: e.message, isInitialized: true);
      return false;
    } catch (_) {
      state = const AuthState(
        error: 'Une erreur est survenue',
        isInitialized: true,
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(isInitialized: true);
  }

  /// Handler 401 global : purge locale sans rappeler l'API.
  Future<void> forceLogout() async {
    await _repository.clearLocalSession();
    state = const AuthState(isInitialized: true);
  }
}
