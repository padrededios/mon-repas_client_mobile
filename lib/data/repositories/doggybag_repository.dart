import '../../core/api/api_client.dart';
import '../../core/utils/dates.dart';
import '../models/dish.dart';
import '../models/doggybag_reservation.dart';

class DoggyBagRepository {
  DoggyBagRepository(this._api);

  final ApiClient _api;

  /// Plats disponibles en doggybag pour un jour donné.
  Future<List<Dish>> getAvailableDishes(DateTime date) async {
    final data = await _api.get(
      '/doggybag/available',
      query: {'date': toIsoDateString(date)},
    ) as List<dynamic>;
    return data.map((e) => Dish.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<DoggyBagReservation>> getMine() async {
    final data = await _api.get('/doggybag-reservations/me') as List<dynamic>;
    return data
        .map((e) => DoggyBagReservation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `pickupDate` est dérivé de la date du menu côté API.
  Future<DoggyBagReservation> create({
    required int dishId,
    required int quantity,
  }) async {
    final data = await _api.post('/doggybag-reservations', data: {
      'dishId': dishId,
      'quantity': quantity,
    }) as Map<String, dynamic>;
    return DoggyBagReservation.fromJson(data);
  }

  Future<DoggyBagReservation> cancel(int id) async {
    final data = await _api.patch('/doggybag-reservations/$id/cancel')
        as Map<String, dynamic>;
    return DoggyBagReservation.fromJson(data);
  }
}
