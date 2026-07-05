import '../../core/api/api_client.dart';
import '../models/time_slot.dart';

class TimeSlotsRepository {
  TimeSlotsRepository(this._api);

  final ApiClient _api;

  Future<List<TimeSlot>> getByMenuId(int menuId) async {
    final data = await _api.get('/time-slots/menu/$menuId') as List<dynamic>;
    return data
        .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
