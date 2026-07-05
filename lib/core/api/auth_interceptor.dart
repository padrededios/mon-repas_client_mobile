import 'package:dio/dio.dart';

/// Ajoute `Authorization: Bearer <token>` à chaque requête.
/// Le token est tenu en mémoire par l'AuthNotifier (source : secure storage).
class AuthInterceptor extends Interceptor {
  String? token;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final t = token;
    if (t != null && t.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $t';
    }
    handler.next(options);
  }
}
