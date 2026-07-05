import 'package:flutter_test/flutter_test.dart';
import 'package:mon_repas_client_mobile/data/models/daily_menu.dart';
import 'package:mon_repas_client_mobile/data/models/dish.dart';
import 'package:mon_repas_client_mobile/data/models/doggybag_reservation.dart';
import 'package:mon_repas_client_mobile/data/models/event_reservation.dart';
import 'package:mon_repas_client_mobile/data/models/notification_item.dart';
import 'package:mon_repas_client_mobile/data/models/reservation.dart';
import 'package:mon_repas_client_mobile/data/models/special_event.dart';
import 'package:mon_repas_client_mobile/data/models/time_slot.dart';
import 'package:mon_repas_client_mobile/data/models/user.dart';

void main() {
  group('User', () {
    final json = {
      'id': 3,
      'email': 'client@mon-repas.com',
      'firstName': 'Claire',
      'lastName': 'Martin',
      'isAdmin': false,
      'isRestaurant': false,
      'isActive': true,
      'createdAt': '2026-01-05T10:00:00.000Z',
    };

    test('fromJson', () {
      final user = User.fromJson(json);
      expect(user.id, 3);
      expect(user.email, 'client@mon-repas.com');
      expect(user.firstName, 'Claire');
      expect(user.isAdmin, isFalse);
      expect(user.isRestaurant, isFalse);
      expect(user.isActive, isTrue);
    });

    test('toJson → fromJson round-trip (persistance secure storage)', () {
      final user = User.fromJson(json);
      final restored = User.fromJson(user.toJson());
      expect(restored.id, user.id);
      expect(restored.email, user.email);
      expect(restored.firstName, user.firstName);
      expect(restored.lastName, user.lastName);
      expect(restored.isAdmin, user.isAdmin);
      expect(restored.isRestaurant, user.isRestaurant);
      expect(restored.isActive, user.isActive);
    });

    test('isClient : ni admin ni restaurateur', () {
      expect(User.fromJson(json).isClient, isTrue);
      expect(User.fromJson({...json, 'isAdmin': true}).isClient, isFalse);
      expect(User.fromJson({...json, 'isRestaurant': true}).isClient, isFalse);
    });
  });

  group('Dish', () {
    test('fromJson complet avec deadline du menu imbriqué', () {
      final dish = Dish.fromJson({
        'id': 42,
        'name': 'Lasagnes',
        'description': 'Maison',
        'type': 'hot_dish_1',
        'isDoggyBagEligible': true,
        'availableForDoggyBag': 3,
        'reservedForDoggyBag': 1,
        'availableQuantity': 20,
        'reservedQuantity': 5,
        'dailyMenuId': 7,
        'dailyMenu': {'doggyBagDeadline': '11:30:00'},
      });
      expect(dish.id, 42);
      expect(dish.type, DishType.hotDish1);
      expect(dish.availableQuantity, 20);
      expect(dish.doggyBagDeadline, '11:30:00');
    });

    test('fromJson minimal : nulls tolérés', () {
      final dish = Dish.fromJson({
        'id': 1,
        'name': 'Salade',
        'type': 'starter_1',
        'isDoggyBagEligible': false,
        'availableForDoggyBag': 0,
        'reservedForDoggyBag': 0,
        'availableQuantity': null,
        'reservedQuantity': 0,
        'dailyMenuId': 7,
      });
      expect(dish.description, isNull);
      expect(dish.availableQuantity, isNull);
      expect(dish.doggyBagDeadline, isNull);
    });
  });

  group('DailyMenu', () {
    test('fromJson avec plats et créneaux', () {
      final menu = DailyMenu.fromJson({
        'id': 7,
        'date': '2026-07-10T00:00:00.000Z',
        'timeSlotCapacity': 10,
        'isActive': true,
        'doggyBagDeadline': '11:30:00',
        'dishes': [
          {
            'id': 1,
            'name': 'Salade',
            'type': 'starter_1',
            'isDoggyBagEligible': false,
            'availableForDoggyBag': 0,
            'reservedForDoggyBag': 0,
            'availableQuantity': null,
            'reservedQuantity': 0,
            'dailyMenuId': 7,
          },
        ],
        'timeSlots': [
          {
            'id': 100,
            'dailyMenuId': 7,
            'startTime': '12:00:00',
            'endTime': '12:30:00',
            'capacity': 10,
            'reservedCount': 9,
          },
        ],
      });
      expect(menu.id, 7);
      expect(menu.date, DateTime(2026, 7, 10));
      expect(menu.dishes, hasLength(1));
      expect(menu.timeSlots, hasLength(1));
      expect(menu.doggyBagDeadline, '11:30:00');
    });

    test('fromJson sans dishes ni timeSlots', () {
      final menu = DailyMenu.fromJson({
        'id': 7,
        'date': '2026-07-10',
        'timeSlotCapacity': 10,
        'isActive': true,
      });
      expect(menu.dishes, isEmpty);
      expect(menu.timeSlots, isNull);
    });
  });

  group('TimeSlot — capacités', () {
    TimeSlot slot(int capacity, int reserved) => TimeSlot.fromJson({
          'id': 1,
          'dailyMenuId': 7,
          'startTime': '12:00:00',
          'endTime': '12:30:00',
          'capacity': capacity,
          'reservedCount': reserved,
        });

    test('places restantes = capacity - reservedCount', () {
      expect(slot(10, 4).remainingSpots, 6);
    });

    test('COMPLET si 0 place restante', () {
      expect(slot(10, 10).isFull, isTrue);
      expect(slot(10, 9).isFull, isFalse);
    });

    test('« Bientôt complet » si remplissage ≥ 90%', () {
      expect(slot(10, 9).isAlmostFull, isTrue);
      expect(slot(10, 8).isAlmostFull, isFalse);
      expect(slot(10, 10).isAlmostFull, isTrue);
    });
  });

  group('Reservation', () {
    test('fromJson avec relations', () {
      final r = Reservation.fromJson({
        'id': 55,
        'userId': 3,
        'timeSlotId': 100,
        'dishId': 42,
        'starterId': 1,
        'dessertId': null,
        'status': 'confirmed',
        'createdAt': '2026-07-08T09:00:00.000Z',
        'timeSlot': {
          'id': 100,
          'dailyMenuId': 7,
          'startTime': '12:00:00',
          'endTime': '12:30:00',
          'capacity': 10,
          'reservedCount': 5,
        },
        'dailyMenu': {
          'id': 7,
          'date': '2026-07-10',
          'timeSlotCapacity': 10,
          'isActive': true,
        },
        'dish': {
          'id': 42,
          'name': 'Lasagnes',
          'type': 'hot_dish_1',
          'isDoggyBagEligible': false,
          'availableForDoggyBag': 0,
          'reservedForDoggyBag': 0,
          'availableQuantity': null,
          'reservedQuantity': 0,
          'dailyMenuId': 7,
        },
        'starter': null,
        'dessert': null,
      });
      expect(r.id, 55);
      expect(r.status, ReservationStatus.confirmed);
      expect(r.isCancelled, isFalse);
      expect(r.timeSlot?.startTime, '12:00:00');
      expect(r.dailyMenu?.date, DateTime(2026, 7, 10));
      expect(r.dish?.name, 'Lasagnes');
      expect(r.starter, isNull);
      expect(r.dessert, isNull);
    });

    test('statut cancelled', () {
      final r = Reservation.fromJson({
        'id': 55,
        'userId': 3,
        'timeSlotId': 100,
        'dishId': 42,
        'status': 'cancelled',
        'createdAt': '2026-07-08T09:00:00.000Z',
      });
      expect(r.isCancelled, isTrue);
    });
  });

  group('DoggyBagReservation', () {
    test('fromJson et statuts', () {
      final r = DoggyBagReservation.fromJson({
        'id': 9,
        'userId': 3,
        'dishId': 42,
        'quantity': 2,
        'pickupDate': '2026-07-10',
        'status': 'picked_up',
        'createdAt': '2026-07-08T09:00:00.000Z',
      });
      expect(r.quantity, 2);
      expect(r.pickupDate, DateTime(2026, 7, 10));
      expect(r.status, DoggyBagStatus.pickedUp);
    });
  });

  group('SpecialEvent', () {
    final json = {
      'id': 4,
      'name': 'Barbecue d\'été',
      'description': 'Grillades au jardin',
      'imageUrl': null,
      'eventDate': '2026-07-15T00:00:00.000Z',
      'isActive': true,
      'registrationDeadline': '2026-07-12',
      'starter1': 'Melon',
      'starter2': null,
      'mainDish1': 'Brochettes',
      'mainDish2': 'Poisson grillé',
      'dessert1': 'Glace',
      'dessert2': null,
      'timeSlots': [
        {
          'id': 200,
          'specialEventId': 4,
          'startTime': '12:00:00',
          'endTime': '13:00:00',
          'capacity': 30,
          'reservedCount': 30,
        },
      ],
    };

    test('fromJson', () {
      final e = SpecialEvent.fromJson(json);
      expect(e.name, 'Barbecue d\'été');
      expect(e.eventDate, DateTime(2026, 7, 15));
      expect(e.registrationDeadline, DateTime(2026, 7, 12));
      expect(e.mainDish2, 'Poisson grillé');
      expect(e.timeSlots?.single.isFull, isTrue);
    });

    test('clôture des inscriptions : après la FIN de journée de la deadline',
        () {
      final e = SpecialEvent.fromJson(json);
      // Le 12 à 23h00 : encore ouvert (fin de journée pas atteinte).
      expect(
        e.isRegistrationClosed(now: DateTime(2026, 7, 12, 23, 0)),
        isFalse,
      );
      // Le 13 à 00h01 : clôturé.
      expect(
        e.isRegistrationClosed(now: DateTime(2026, 7, 13, 0, 1)),
        isTrue,
      );
    });

    test('sans deadline : jamais clôturé', () {
      final e = SpecialEvent.fromJson({...json, 'registrationDeadline': null});
      expect(
        e.isRegistrationClosed(now: DateTime(2030, 1, 1)),
        isFalse,
      );
    });
  });

  group('EventReservation', () {
    test('fromJson avec relations', () {
      final r = EventReservation.fromJson({
        'id': 12,
        'userId': 3,
        'specialEventId': 4,
        'eventTimeSlotId': 200,
        'status': 'confirmed',
        'createdAt': '2026-07-08T09:00:00.000Z',
        'eventTimeSlot': {
          'id': 200,
          'specialEventId': 4,
          'startTime': '12:00:00',
          'endTime': '13:00:00',
          'capacity': 30,
          'reservedCount': 12,
        },
      });
      expect(r.specialEventId, 4);
      expect(r.status, ReservationStatus.confirmed);
      expect(r.eventTimeSlot?.remainingSpots, 18);
    });
  });

  group('NotificationItem', () {
    test('round-trip JSON (persistance locale)', () {
      final item = NotificationItem(
        id: 'abc',
        type: NotificationType.mealReminder,
        title: 'Réservation confirmée',
        message: 'Votre repas de midi est réservé',
        read: false,
        createdAt: DateTime(2026, 7, 10, 9, 30),
      );
      final restored = NotificationItem.fromJson(item.toJson());
      expect(restored.id, 'abc');
      expect(restored.type, NotificationType.mealReminder);
      expect(restored.read, isFalse);
      expect(restored.createdAt, DateTime(2026, 7, 10, 9, 30));
    });

    test('type inconnu → system', () {
      final restored = NotificationItem.fromJson({
        'id': 'x',
        'type': 'plus_tard_peut_etre',
        'title': 't',
        'message': 'm',
        'read': true,
        'createdAt': '2026-07-10T09:30:00.000',
      });
      expect(restored.type, NotificationType.system);
    });
  });
}
