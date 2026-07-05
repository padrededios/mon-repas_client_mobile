/// Erreur API normalisée. Le backend NestJS renvoie
/// `{ statusCode, message: string | string[], error }`.
class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message});

  /// 0 = erreur réseau (serveur injoignable).
  final int statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isNetworkError => statusCode == 0;

  factory ApiException.fromBody(int statusCode, dynamic body) {
    String message = 'Une erreur est survenue';
    if (body is Map<String, dynamic>) {
      final m = body['message'];
      if (m is String && m.isNotEmpty) {
        message = m;
      } else if (m is List) {
        message = m.join('\n');
      } else if (body['error'] is String) {
        message = body['error'] as String;
      }
    }
    return ApiException(statusCode: statusCode, message: message);
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
