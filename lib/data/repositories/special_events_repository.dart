import '../../core/api/api_client.dart';
import '../models/event_reservation.dart';
import '../models/special_event.dart';

class SpecialEventsRepository {
  SpecialEventsRepository(this._api);

  final ApiClient _api;

  Future<List<SpecialEvent>> getActive() async {
    final data = await _api.get(
      '/special-events',
      query: {'active': 'true'},
    ) as List<dynamic>;
    return data
        .map((e) => SpecialEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SpecialEvent> getById(int id) async {
    final data = await _api.get('/special-events/$id') as Map<String, dynamic>;
    return SpecialEvent.fromJson(data);
  }

  Future<List<EventReservation>> getMyReservations() async {
    final data = await _api.get('/event-reservations/me') as List<dynamic>;
    return data
        .map((e) => EventReservation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EventReservation> createReservation({
    required int specialEventId,
    required int eventTimeSlotId,
  }) async {
    final data = await _api.post('/event-reservations', data: {
      'specialEventId': specialEventId,
      'eventTimeSlotId': eventTimeSlotId,
    }) as Map<String, dynamic>;
    return EventReservation.fromJson(data);
  }

  Future<EventReservation> cancelReservation(int id) async {
    final data = await _api.patch('/event-reservations/$id/cancel')
        as Map<String, dynamic>;
    return EventReservation.fromJson(data);
  }
}
