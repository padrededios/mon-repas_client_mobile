import '../../core/api/api_client.dart';
import '../models/daily_menu.dart';

class DailyMenusRepository {
  DailyMenusRepository(this._api);

  final ApiClient _api;

  /// `GET /daily-menus/week?week=&year=` — semaine ISO.
  /// Un 404 signifie « menu pas encore publié » (état normal côté UI).
  Future<List<DailyMenu>> getWeek(int week, int year) async {
    final data = await _api.get(
      '/daily-menus/week',
      query: {'week': week, 'year': year},
    ) as List<dynamic>;
    return data
        .map((e) => DailyMenu.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DailyMenu> getById(int id) async {
    final data = await _api.get('/daily-menus/$id') as Map<String, dynamic>;
    return DailyMenu.fromJson(data);
  }
}
