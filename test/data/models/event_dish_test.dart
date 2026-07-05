import 'package:flutter_test/flutter_test.dart';
import 'package:mon_repas_client_mobile/data/models/event_dish.dart';
import 'package:mon_repas_client_mobile/data/models/event_reservation.dart';
import 'package:mon_repas_client_mobile/data/models/special_event.dart';

Map<String, dynamic> dishJson(int id, String type, String name) => {
      'id': id,
      'name': name,
      'description': null,
      'type': type,
      'specialEventId': 5,
      'createdAt': '2026-07-01T10:00:00.000Z',
    };

void main() {
  group('EventDish', () {
    test('fromJson parse les champs et le type', () {
      final dish = EventDish.fromJson(dishJson(10, 'main_dish', 'Paella'));

      expect(dish.id, 10);
      expect(dish.name, 'Paella');
      expect(dish.type, EventDishType.mainDish);
      expect(dish.specialEventId, 5);
    });

    test('fromJson parse entrée et dessert', () {
      expect(
        EventDish.fromJson(dishJson(1, 'starter', 'Gaspacho')).type,
        EventDishType.starter,
      );
      expect(
        EventDish.fromJson(dishJson(2, 'dessert', 'Churros')).type,
        EventDishType.dessert,
      );
    });
  });

  group('SpecialEvent.dishes', () {
    final json = {
      'id': 5,
      'name': 'Soirée Paella',
      'description': '',
      'eventDate': '2026-07-20',
      'isActive': true,
      'dishes': [
        dishJson(1, 'starter', 'Gaspacho'),
        dishJson(2, 'main_dish', 'Paella fruits de mer'),
        dishJson(3, 'main_dish', 'Paella végétarienne'),
        dishJson(4, 'dessert', 'Churros'),
      ],
    };

    test('fromJson parse la liste des plats et les helpers filtrent', () {
      final event = SpecialEvent.fromJson(json);

      expect(event.dishes, hasLength(4));
      expect(event.starters.map((d) => d.name), ['Gaspacho']);
      expect(event.mainDishes, hasLength(2));
      expect(event.desserts.map((d) => d.name), ['Churros']);
    });

    test('dishes vaut liste vide si absent du JSON', () {
      final event = SpecialEvent.fromJson({
        'id': 5,
        'name': 'Soirée',
        'description': '',
        'eventDate': '2026-07-20',
        'isActive': true,
      });

      expect(event.dishes, isEmpty);
      expect(event.starters, isEmpty);
    });
  });

  group('SpecialEvent — fenêtre de modification/annulation', () {
    test('bornée par la deadline en fin de journée quand elle existe', () {
      final event = SpecialEvent.fromJson({
        'id': 5,
        'name': 'Soirée',
        'description': '',
        'eventDate': '2026-07-20',
        'registrationDeadline': '2026-07-15',
        'isActive': true,
      });

      expect(
        event.isModificationWindowClosed(now: DateTime(2026, 7, 15, 23, 0)),
        isFalse,
      );
      expect(
        event.isModificationWindowClosed(now: DateTime(2026, 7, 16, 0, 1)),
        isTrue,
      );
    });

    test("bornée par la date de l'événement sans deadline", () {
      final event = SpecialEvent.fromJson({
        'id': 5,
        'name': 'Soirée',
        'description': '',
        'eventDate': '2026-07-20',
        'isActive': true,
      });

      expect(
        event.isModificationWindowClosed(now: DateTime(2026, 7, 20, 22, 0)),
        isFalse,
      );
      expect(
        event.isModificationWindowClosed(now: DateTime(2026, 7, 21, 0, 1)),
        isTrue,
      );
    });
  });

  group('EventReservation — choix de plats', () {
    test('fromJson parse les ids et relations des choix', () {
      final reservation = EventReservation.fromJson({
        'id': 12,
        'userId': 3,
        'specialEventId': 5,
        'eventTimeSlotId': 50,
        'starterId': 1,
        'mainDishId': 2,
        'dessertId': null,
        'status': 'confirmed',
        'createdAt': '2026-07-01T10:00:00.000Z',
        'starter': dishJson(1, 'starter', 'Gaspacho'),
        'mainDish': dishJson(2, 'main_dish', 'Paella fruits de mer'),
        'dessert': null,
      });

      expect(reservation.starterId, 1);
      expect(reservation.mainDishId, 2);
      expect(reservation.dessertId, isNull);
      expect(reservation.starter?.name, 'Gaspacho');
      expect(reservation.mainDish?.name, 'Paella fruits de mer');
      expect(reservation.dessert, isNull);
    });

    test('fromJson tolère les réservations sans choix (historique)', () {
      final reservation = EventReservation.fromJson({
        'id': 12,
        'userId': 3,
        'specialEventId': 5,
        'eventTimeSlotId': 50,
        'status': 'confirmed',
        'createdAt': '2026-07-01T10:00:00.000Z',
      });

      expect(reservation.starterId, isNull);
      expect(reservation.mainDishId, isNull);
      expect(reservation.dessertId, isNull);
    });
  });
}
