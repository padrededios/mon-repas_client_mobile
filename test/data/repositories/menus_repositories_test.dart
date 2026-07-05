import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mon_repas_client_mobile/core/api/api_client.dart';
import 'package:mon_repas_client_mobile/data/models/reservation.dart';
import 'package:mon_repas_client_mobile/data/repositories/daily_menus_repository.dart';
import 'package:mon_repas_client_mobile/data/repositories/reservations_repository.dart';
import 'package:mon_repas_client_mobile/data/repositories/time_slots_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

const menuJson = {
  'id': 7,
  'date': '2026-07-10',
  'timeSlotCapacity': 10,
  'isActive': true,
  'dishes': <Map<String, dynamic>>[],
};

const slotJson = {
  'id': 100,
  'dailyMenuId': 7,
  'startTime': '12:00:00',
  'endTime': '12:30:00',
  'capacity': 10,
  'reservedCount': 3,
};

const reservationJson = {
  'id': 55,
  'userId': 3,
  'timeSlotId': 100,
  'dishId': 42,
  'status': 'confirmed',
  'createdAt': '2026-07-08T09:00:00.000Z',
};

void main() {
  late MockApiClient api;

  setUp(() {
    api = MockApiClient();
  });

  group('DailyMenusRepository', () {
    test('getWeek passe week/year et parse la liste', () async {
      when(() => api.get('/daily-menus/week', query: {'week': 28, 'year': 2026}))
          .thenAnswer((_) async => [menuJson]);

      final menus = await DailyMenusRepository(api).getWeek(28, 2026);

      expect(menus.single.id, 7);
      expect(menus.single.date, DateTime(2026, 7, 10));
    });

    test('getById parse le menu complet', () async {
      when(() => api.get('/daily-menus/7')).thenAnswer((_) async => menuJson);
      final menu = await DailyMenusRepository(api).getById(7);
      expect(menu.id, 7);
    });
  });

  group('TimeSlotsRepository', () {
    test('getByMenuId parse les créneaux', () async {
      when(() => api.get('/time-slots/menu/7'))
          .thenAnswer((_) async => [slotJson]);
      final slots = await TimeSlotsRepository(api).getByMenuId(7);
      expect(slots.single.remainingSpots, 7);
    });
  });

  group('ReservationsRepository', () {
    test('getMine parse la liste', () async {
      when(() => api.get('/reservations/me'))
          .thenAnswer((_) async => [reservationJson]);
      final reservations = await ReservationsRepository(api).getMine();
      expect(reservations.single.status, ReservationStatus.confirmed);
    });

    test('create envoie le payload tel quel', () async {
      when(() => api.post('/reservations', data: any(named: 'data')))
          .thenAnswer((_) async => reservationJson);

      await ReservationsRepository(api).create({
        'timeSlotId': 100,
        'dishType': 'offre_jour',
        'starterId': 1,
      });

      verify(() => api.post('/reservations', data: {
            'timeSlotId': 100,
            'dishType': 'offre_jour',
            'starterId': 1,
          })).called(1);
    });

    test('update PATCH partiel', () async {
      when(() => api.patch('/reservations/55', data: any(named: 'data')))
          .thenAnswer((_) async => reservationJson);

      await ReservationsRepository(api).update(55, {'timeSlotId': 101});

      verify(() => api.patch('/reservations/55', data: {'timeSlotId': 101}))
          .called(1);
    });

    test('cancel PATCH /reservations/:id/cancel', () async {
      when(() => api.patch('/reservations/55/cancel'))
          .thenAnswer((_) async => {...reservationJson, 'status': 'cancelled'});

      final r = await ReservationsRepository(api).cancel(55);

      expect(r.isCancelled, isTrue);
    });
  });
}
