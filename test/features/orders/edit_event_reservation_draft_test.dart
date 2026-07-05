import 'package:flutter_test/flutter_test.dart';
import 'package:mon_repas_client_mobile/data/models/event_dish.dart';
import 'package:mon_repas_client_mobile/data/models/event_reservation.dart';
import 'package:mon_repas_client_mobile/data/models/event_time_slot.dart';
import 'package:mon_repas_client_mobile/data/models/reservation.dart';
import 'package:mon_repas_client_mobile/data/models/special_event.dart';
import 'package:mon_repas_client_mobile/features/orders/edit_event_reservation_draft.dart';

EventDish dish(int id, EventDishType type, String name) => EventDish(
      id: id,
      name: name,
      type: type,
      specialEventId: 5,
    );

final gaspacho = dish(1, EventDishType.starter, 'Gaspacho');
final charcuterie = dish(2, EventDishType.starter, 'Charcuterie');
final paella = dish(3, EventDishType.mainDish, 'Paella');
final paellaVege = dish(4, EventDishType.mainDish, 'Paella végé');
final churros = dish(5, EventDishType.dessert, 'Churros');

const slot1 = EventTimeSlot(
  id: 50,
  specialEventId: 5,
  startTime: '12:00:00',
  endTime: '12:30:00',
  capacity: 60,
  reservedCount: 10,
);
const slot2 = EventTimeSlot(
  id: 51,
  specialEventId: 5,
  startTime: '12:30:00',
  endTime: '13:00:00',
  capacity: 60,
  reservedCount: 60,
);

SpecialEvent event() => SpecialEvent(
      id: 5,
      name: 'Soirée Paella',
      description: '',
      eventDate: DateTime(2026, 7, 20),
      isActive: true,
      dishes: [gaspacho, charcuterie, paella, paellaVege, churros],
      timeSlots: const [slot1, slot2],
    );

EventReservation reservation() => EventReservation(
      id: 12,
      userId: 3,
      specialEventId: 5,
      eventTimeSlotId: 50,
      starterId: 1,
      mainDishId: 3,
      dessertId: 5,
      status: ReservationStatus.confirmed,
      createdAt: DateTime(2026, 7, 1),
    );

void main() {
  group('EditEventReservationDraft.fromReservation', () {
    test('résout les choix et le créneau depuis les ids', () {
      final draft =
          EditEventReservationDraft.fromReservation(reservation(), event());

      expect(draft.starter?.name, 'Gaspacho');
      expect(draft.mainDish?.name, 'Paella');
      expect(draft.dessert?.name, 'Churros');
      expect(draft.timeSlot?.id, 50);
      expect(draft.hasChanges, isFalse);
    });
  });

  group('buildPatch', () {
    test('n\'envoie que les champs modifiés', () {
      var draft =
          EditEventReservationDraft.fromReservation(reservation(), event());
      draft = draft.toggleMainDish(paellaVege);

      expect(draft.hasChanges, isTrue);
      expect(draft.buildPatch(), {'mainDishId': 4});
    });

    test('changement de créneau seul', () {
      var draft =
          EditEventReservationDraft.fromReservation(reservation(), event());
      draft = draft.withTimeSlot(slot2);

      expect(draft.buildPatch(), {'eventTimeSlotId': 51});
    });

    test('retrait d\'un service optionnel → null explicite', () {
      var draft =
          EditEventReservationDraft.fromReservation(reservation(), event());
      draft = draft.toggleStarter(gaspacho); // désélection

      expect(draft.buildPatch(), {'starterId': null});
    });

    test('remplacement d\'une entrée', () {
      var draft =
          EditEventReservationDraft.fromReservation(reservation(), event());
      draft = draft.toggleStarter(charcuterie);

      expect(draft.buildPatch(), {'starterId': 2});
    });

    test('le plat principal ne se désélectionne pas', () {
      var draft =
          EditEventReservationDraft.fromReservation(reservation(), event());
      draft = draft.toggleMainDish(paella); // re-tap sur le plat actuel

      expect(draft.mainDish?.id, 3);
      expect(draft.hasChanges, isFalse);
    });
  });

  group('isValid', () {
    test('valide si un choix par service proposé + créneau', () {
      final draft =
          EditEventReservationDraft.fromReservation(reservation(), event());

      expect(draft.isValid, isTrue);
    });

    test('invalide si un service proposé n\'a plus de choix', () {
      var draft =
          EditEventReservationDraft.fromReservation(reservation(), event());
      draft = draft.toggleDessert(churros); // retire le dessert

      // L'événement propose des desserts : le retrait rend l'envoi invalide
      // (parité avec la création).
      expect(draft.isValid, isFalse);
    });
  });
}
