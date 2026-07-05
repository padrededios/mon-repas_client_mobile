import 'package:flutter_test/flutter_test.dart';
import 'package:mon_repas_client_mobile/data/models/daily_menu.dart';
import 'package:mon_repas_client_mobile/data/models/dish.dart';
import 'package:mon_repas_client_mobile/data/models/reservation.dart';
import 'package:mon_repas_client_mobile/data/models/time_slot.dart';
import 'package:mon_repas_client_mobile/features/dashboard/edit_reservation_draft.dart';

Dish dish(int id, DishType type, {int? availableQuantity, int reserved = 0}) =>
    Dish(
      id: id,
      name: 'Plat-$id',
      type: type,
      isDoggyBagEligible: false,
      availableForDoggyBag: 0,
      reservedForDoggyBag: 0,
      availableQuantity: availableQuantity,
      reservedQuantity: reserved,
      dailyMenuId: 7,
    );

TimeSlot slot(int id) => TimeSlot(
      id: id,
      dailyMenuId: 7,
      startTime: '12:00:00',
      endTime: '12:30:00',
      capacity: 10,
      reservedCount: 2,
    );

void main() {
  final starter1 = dish(1, DishType.starter1);
  final starter2 = dish(2, DishType.starter2);
  final main1 = dish(3, DishType.hotDish1);
  final special = dish(4, DishType.dailySpecial);
  final dessert1 = dish(5, DishType.dessert1);

  final menu = DailyMenu(
    id: 7,
    date: DateTime(2026, 7, 10),
    timeSlotCapacity: 10,
    isActive: true,
    dishes: [starter1, starter2, main1, special, dessert1],
    timeSlots: [slot(100), slot(101)],
  );

  Reservation reservation({int? starterId, int? dessertId}) => Reservation(
        id: 55,
        userId: 3,
        timeSlotId: 100,
        dishId: 3,
        starterId: starterId,
        dessertId: dessertId,
        status: ReservationStatus.confirmed,
        createdAt: DateTime(2026, 7, 8),
      );

  group('fromReservation', () {
    test('résout plat/entrée/dessert/créneau depuis le menu', () {
      final draft = EditReservationDraft.fromReservation(
        reservation(starterId: 1, dessertId: 5),
        menu,
      );
      expect(draft.mainDish?.id, 3);
      expect(draft.starter?.id, 1);
      expect(draft.dessert?.id, 5);
      expect(draft.timeSlot?.id, 100);
    });
  });

  group('hasChanges', () {
    test('faux à l\'ouverture (état resynchronisé)', () {
      final draft = EditReservationDraft.fromReservation(
        reservation(starterId: 1),
        menu,
      );
      expect(draft.hasChanges, isFalse);
    });

    test('vrai après changement de créneau, faux si on revient', () {
      var draft = EditReservationDraft.fromReservation(
        reservation(starterId: 1),
        menu,
      );
      draft = draft.withTimeSlot(slot(101));
      expect(draft.hasChanges, isTrue);
      draft = draft.withTimeSlot(slot(100));
      expect(draft.hasChanges, isFalse);
    });

    test('retirer l\'entrée est un changement', () {
      var draft = EditReservationDraft.fromReservation(
        reservation(starterId: 1),
        menu,
      );
      draft = draft.toggleStarter(starter1); // désélection
      expect(draft.starter, isNull);
      expect(draft.hasChanges, isTrue);
    });
  });

  group('buildPatch — PATCH partiel', () {
    test('seul le créneau modifié est envoyé', () {
      final draft = EditReservationDraft.fromReservation(
        reservation(starterId: 1),
        menu,
      ).withTimeSlot(slot(101));
      expect(draft.buildPatch(), {'timeSlotId': 101});
    });

    test('changement de plat → dishType recalculé', () {
      final draft = EditReservationDraft.fromReservation(
        reservation(starterId: 1),
        menu,
      ).toggleMainDish(special);
      expect(draft.buildPatch(), {'dishType': 'offre_jour'});
    });

    test('entrée retirée → starterId: null explicite', () {
      final draft = EditReservationDraft.fromReservation(
        reservation(starterId: 1),
        menu,
      ).toggleStarter(starter1);
      expect(draft.buildPatch(), {'starterId': null});
    });

    test('entrée remplacée → nouvel id', () {
      final draft = EditReservationDraft.fromReservation(
        reservation(starterId: 1),
        menu,
      ).toggleStarter(starter2);
      expect(draft.buildPatch(), {'starterId': 2});
    });
  });

  group('plat courant épuisé', () {
    test('isCurrentDish permet de le garder sélectionnable', () {
      final soldOutMain = dish(3, DishType.hotDish1,
          availableQuantity: 5, reserved: 5);
      final menuSoldOut = DailyMenu(
        id: 7,
        date: DateTime(2026, 7, 10),
        timeSlotCapacity: 10,
        isActive: true,
        dishes: [soldOutMain, special],
        timeSlots: [slot(100)],
      );
      final draft = EditReservationDraft.fromReservation(
        reservation(),
        menuSoldOut,
      );
      expect(draft.isCurrentDish(soldOutMain), isTrue);
      expect(draft.isCurrentDish(special), isFalse);
    });
  });
}
