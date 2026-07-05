import 'package:dio/dio.dart';

import 'api_config.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

/// Wrapper Dio : JSON, timeout 10 s, Bearer token, erreurs → [ApiException].
/// Les 4xx ne lèvent pas de DioException (validateStatus < 500) : ils sont
/// convertis explicitement, et un 401 déclenche [onUnauthorized] (logout).
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

  /// Appelé sur toute réponse 401 (session expirée) — branché par l'auth.
  void Function()? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) {
    return _request(() => dio.get<dynamic>(path, queryParameters: query));
  }

  Future<dynamic> post(String path, {Object? data}) {
    return _request(
      () => dio.post<dynamic>(path, data: data ?? const <String, dynamic>{}),
    );
  }

  Future<dynamic> patch(String path, {Object? data}) {
    return _request(
      () => dio.patch<dynamic>(path, data: data ?? const <String, dynamic>{}),
    );
  }

  Future<dynamic> _request(Future<Response<dynamic>> Function() send) async {
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
    if (status >= 400) {
      if (status == 401) onUnauthorized?.call();
      throw ApiException.fromBody(status, response.data);
    }
    return response.data;
  }
}
