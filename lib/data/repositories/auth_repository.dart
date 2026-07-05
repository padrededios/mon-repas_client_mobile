import 'dart:convert';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/storage/session_storage.dart';
import '../models/user.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage);

  final ApiClient _api;
  final SessionStorage _storage;

  /// `POST /auth/login` — refuse les comptes admin/restaurateur AVANT toute
  /// persistance : l'app est réservée aux clients.
  Future<User> login(String email, String password) async {
    final data = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    if (!user.isClient) {
      throw const ApiException(
        statusCode: 403,
        message: 'Cette application est réservée aux clients',
      );
    }
    final token = data['access_token'] as String;
    await _persist(token, user);
    return user;
  }

  /// `POST /auth/register` — pas de login auto : le compte attend
  /// l'activation par un administrateur.
  Future<String> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final data = await _api.post('/auth/register', data: {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
    });
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Compte créé avec succès !';
  }

  /// Restauration au démarrage : token stocké → `GET /auth/me`.
  /// 401/403 → session purgée ; erreur réseau → user en cache (mode dégradé,
  /// les requêtes suivantes afficheront leurs erreurs).
  Future<User?> restoreSession() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return null;
    _api.auth.token = token;
    try {
      final data = await _api.get('/auth/me') as Map<String, dynamic>;
      final user = User.fromJson(data);
      if (!user.isClient) {
        await _clearLocal();
        return null;
      }
      await _persist(token, user);
      return user;
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        final cached = await _storage.readUserJson();
        if (cached != null) {
          return User.fromJson(jsonDecode(cached) as Map<String, dynamic>);
        }
      }
      await _clearLocal();
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } on ApiException {
      // La purge locale suffit : le JWT expirera côté serveur.
    }
    await _clearLocal();
  }

  /// Purge locale seule — utilisée par le handler 401 global pour ne pas
  /// rappeler l'API avec un token déjà invalide.
  Future<void> clearLocalSession() => _clearLocal();

  Future<void> _persist(String token, User user) async {
    _api.auth.token = token;
    await _storage.saveSession(
      token: token,
      userJson: jsonEncode(user.toJson()),
    );
  }

  Future<void> _clearLocal() async {
    _api.auth.token = null;
    await _storage.clear();
  }
}
