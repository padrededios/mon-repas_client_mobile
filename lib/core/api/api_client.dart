import 'package:dio/dio.dart';

import 'api_config.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

/// Wrapper Dio : JSON, timeout 10 s, Bearer token, erreurs → [ApiException].
/// Les 4xx ne lèvent pas de DioException (validateStatus < 500) : ils sont
/// convertis explicitement. Sur un 401, la session est d'abord rafraîchie
/// ([refreshSession], une seule fois pour les requêtes simultanées) puis la
/// requête rejouée ; si c'est impossible, [onUnauthorized] (logout).
class ApiClient {
  ApiClient({Dio? dio, AuthInterceptor? authInterceptor})
      : dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: const Duration(milliseconds: ApiConfig.timeoutMs),
                sendTimeout: const Duration(milliseconds: ApiConfig.timeoutMs),
                receiveTimeout:
                    const Duration(milliseconds: ApiConfig.timeoutMs),
                contentType: 'application/json',
                responseType: ResponseType.json,
                validateStatus: (s) => s != null && s < 500,
              ),
            ),
        auth = authInterceptor ?? AuthInterceptor() {
    this.dio.interceptors.add(auth);
  }

  final Dio dio;
  final AuthInterceptor auth;

  /// Appelé quand la session est irrécupérable (401 sans refresh possible).
  void Function()? onUnauthorized;

  /// Rafraîchit les jetons (refresh token) ; true si [auth] porte un nouveau
  /// jeton valide. Branché par l'auth.
  Future<bool> Function()? refreshSession;

  Future<bool>? _pendingRefresh;

  /// Routes où un 401 signifie « identifiants refusés », pas « session expirée ».
  static final _authRoute =
      RegExp(r'^/auth/(login|refresh|forgot-password|reset-password)$');

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) {
    return _request(
      path,
      () => dio.get<dynamic>(path, queryParameters: query),
    );
  }

  Future<dynamic> post(String path, {Object? data}) {
    return _request(
      path,
      () => dio.post<dynamic>(path, data: data ?? const <String, dynamic>{}),
    );
  }

  Future<dynamic> patch(String path, {Object? data}) {
    return _request(
      path,
      () => dio.patch<dynamic>(path, data: data ?? const <String, dynamic>{}),
    );
  }

  Future<dynamic> _request(
    String path,
    Future<Response<dynamic>> Function() send, {
    bool isRetry = false,
  }) async {
    Response<dynamic> response;
    try {
      response = await send();
    } on DioException catch (e) {
      final r = e.response;
      if (r == null) {
        throw const ApiException(
          statusCode: 0,
          message:
              'Impossible de contacter le serveur. Vérifiez votre connexion.',
        );
      }
      response = r;
    }
    final status = response.statusCode ?? 0;
    if (status == 401 && !_authRoute.hasMatch(path)) {
      // Le jeton est relu par l'intercepteur : rejouer suffit.
      if (!isRetry && await _refreshOnce()) {
        return _request(path, send, isRetry: true);
      }
      onUnauthorized?.call();
    }
    if (status >= 400) {
      throw ApiException.fromBody(status, response.data);
    }
    return response.data;
  }

  Future<bool> _refreshOnce() {
    final refresh = refreshSession;
    if (refresh == null) return Future.value(false);
    return _pendingRefresh ??= refresh()
        .catchError((Object _) => false)
        .whenComplete(() => _pendingRefresh = null);
  }
}
