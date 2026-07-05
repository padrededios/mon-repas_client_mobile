import '../../core/api/api_client.dart';
import '../models/reservation.dart';

class ReservationsRepository {
  ReservationsRepository(this._api);

  final ApiClient _api;

  Future<List<Reservation>> getMine() async {
    final data = await _api.get('/reservations/me') as List<dynamic>;
    return data
        .map((e) => Reservation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /reservations` — payload construit par [MealSelection.toCreatePayload].
  Future<Reservation> create(Map<String, dynamic> payload) async {
    final data =
        await _api.post('/reservations', data: payload) as Map<String, dynamic>;
    return Reservation.fromJson(data);
  }

  /// PATCH partiel : n'envoyer que les champs modifiés.
  Future<Reservation> update(int id, Map<String, dynamic> changes) async {
    final data = await _api.patch('/reservations/$id', data: changes)
        as Map<String, dynamic>;
    return Reservation.fromJson(data);
  }

  Future<Reservation> cancel(int id) async {
    final data =
        await _api.patch('/reservations/$id/cancel') as Map<String, dynamic>;
    return Reservation.fromJson(data);
  }
}
