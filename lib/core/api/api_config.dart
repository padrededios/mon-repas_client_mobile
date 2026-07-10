/// Configuration d'environnement, injectée à la compilation :
/// `flutter run --dart-define=MONREPAS_API_URL=http://192.168.x.x:3502`
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'MONREPAS_API_URL',
    defaultValue: 'http://localhost:3502',
  );

  /// URL Socket.IO — namespace `/events`, dérivée de [baseUrl]
  /// (la webapp la codait en dur, on corrige ici).
  static const String wsUrl = '$baseUrl/events';

  static const int timeoutMs = 10000;

  /// Résout une URL de média renvoyée par l'API : les chemins relatifs
  /// (`/uploads/...`) sont préfixés par [baseUrl], les URLs absolues
  /// (images externes) passent telles quelles.
  static String resolveMediaUrl(String url) {
    return url.startsWith('http') ? url : '$baseUrl$url';
  }
}
