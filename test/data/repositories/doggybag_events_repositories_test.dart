import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mon_repas_client_mobile/core/api/api_client.dart';
import 'package:mon_repas_client_mobile/data/models/doggybag_reservation.dart';
import 'package:mon_repas_client_mobile/data/models/reservation.dart';
import 'package:mon_repas_client_mobile/data/repositories/doggybag_repository.dart';
import 'package:mon_repas_client_mobile/data/repositories/special_events_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

const dishJson = {
  'id': 42,
  'name': 'Lasagnes',
  'type': 'hot_dish_1',
  'isDoggyBagEligible': true,
  'availableForDoggyBag': 3,
  'reservedForDoggyBag': 1,
  'availableQuantity': null,
  'reservedQuantity': 0,
  'dailyMenuId': 7,
  'dailyMenu': {'doggyBagDeadline': '11:30:00'},
};

const doggyBagReservationJson = {
  'id': 9,
  'userId': 3,
  'dishId': 42,
  'quantity': 2,
  'pickupDate': '2026-07-10',
  'status': 'confirmed',
  'createdAt': '2026-07-08T09:00:00.000Z',
};

const eventJson = {
  'id': 4,
  'name': 'Barbecue',
  'description': 'Grillades',
  'eventDate': '2026-07-15',
  'isActive': true,
};

const eventReservationJson = {
  'id': 12,
  'userId': 3,
  'specialEventId': 4,
  'eventTimeSlotId': 200,
  'status': 'confirmed',
  'createdAt': '2026-07-08T09:00:00.000Z',
};

void main() {
  late MockApiClient api;

  setUp(() {
    api = MockApiClient();
  });

  group('DoggyBagRepository', () {
    test('getAvailableDishes passe la date en query', () async {
      when(() => api.get('/doggybag/available',
              query: {'date': '2026-07-10'}))
          .thenAnswer((_) async => [dishJson]);

      final dishes = await DoggyBagRepository(api)
          .getAvailableDishes(DateTime(2026, 7, 10));

      expect(dishes.single.availableForDoggyBag, 3);
      expect(dishes.single.doggyBagDeadline, '11:30:00');
    });

    test('getMine parse les réservations', () async {
      when(() => api.get('/doggybag-reservations/me'))
          .thenAnswer((_) async => [doggyBagReservationJson]);

      final reservations = await DoggyBagRepository(api).getMine();

      expect(reservations.single.status, DoggyBagStatus.confirmed);
    });

    test('create envoie dishId + quantity', () async {
      when(() => api.post('/doggybag-reservations', data: any(named: 'data')))
          .thenAnswer((_) async => doggyBagReservationJson);

      await DoggyBagRepository(api).create(dishId: 42, quantity: 2);

      verify(() => api.post('/doggybag-reservations',
          data: {'dishId': 42, 'quantity': 2})).called(1);
    });

    test('cancel', () async {
      when(() => api.patch('/doggybag-reservations/9/cancel')).thenAnswer(
          (_) async => {...doggyBagReservationJson, 'status': 'cancelled'});

      final r = await DoggyBagRepository(api).cancel(9);

      expect(r.status, DoggyBagStatus.cancelled);
    });
  });

  group('SpecialEventsRepository', () {
    test('getActive filtre les événements actifs', () async {
      when(() => api.get('/special-events', query: {'active': 'true'}))
          .thenAnswer((_) async => [eventJson]);

      final events = await SpecialEventsRepository(api).getActive();

      expect(events.single.name, 'Barbecue');
    });

    test('getById', () async {
      when(() => api.get('/special-events/4'))
          .thenAnswer((_) async => eventJson);
      final event = await SpecialEventsRepository(api).getById(4);
      expect(event.id, 4);
    });

    test('getMyReservations', () async {
      when(() => api.get('/event-reservations/me'))
          .thenAnswer((_) async => [eventReservationJson]);

      final reservations =
          await SpecialEventsRepository(api).getMyReservations();

      expect(reservations.single.status, ReservationStatus.confirmed);
    });

    test('createReservation envoie les deux ids', () async {
      when(() => api.post('/event-reservations', data: any(named: 'data')))
          .thenAnswer((_) async => eventReservationJson);

      await SpecialEventsRepository(api)
          .createReservation(specialEventId: 4, eventTimeSlotId: 200);

      verify(() => api.post('/event-reservations',
          data: {'specialEventId': 4, 'eventTimeSlotId': 200})).called(1);
    });

    test('cancelReservation', () async {
      when(() => api.patch('/event-reservations/12/cancel')).thenAnswer(
          (_) async => {...eventReservationJson, 'status': 'cancelled'});

      final r = await SpecialEventsRepository(api).cancelReservation(12);

      expect(r.isCancelled, isTrue);
    });
  });
}
