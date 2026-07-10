import 'package:flutter_test/flutter_test.dart';
import 'package:mon_repas_client_mobile/core/api/api_config.dart';

void main() {
  group('ApiConfig.resolveMediaUrl', () {
    test("préfixe les chemins relatifs de l'API avec l'URL de base", () {
      expect(
        ApiConfig.resolveMediaUrl('/uploads/images/photo.jpg'),
        '${ApiConfig.baseUrl}/uploads/images/photo.jpg',
      );
    });

    test('laisse passer les URLs absolues (images externes, ex. seed)', () {
      const https = 'https://images.unsplash.com/photo-123?w=800';
      const http = 'http://cdn.example.com/img.png';
      expect(ApiConfig.resolveMediaUrl(https), https);
      expect(ApiConfig.resolveMediaUrl(http), http);
    });
  });
}
