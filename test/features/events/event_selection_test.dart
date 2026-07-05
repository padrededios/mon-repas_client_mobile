import 'package:flutter_test/flutter_test.dart';
import 'package:mon_repas_client_mobile/data/models/event_dish.dart';
import 'package:mon_repas_client_mobile/data/models/event_time_slot.dart';
import 'package:mon_repas_client_mobile/data/models/special_event.dart';
import 'package:mon_repas_client_mobile/features/events/event_selection.dart';

EventDish dish(int id, EventDishType type, String name) => EventDish(
      id: id,
      name: name,
      type: type,
      specialEventId: 5,
    );

const slot = EventTimeSlot(
  id: 50,
  specialEventId: 5,
  startTime: '12:00:00',
  endTime: '12:30:00',
  capacity: 60,
  reservedCount: 10,
);

final gaspacho = dish(1, EventDishType.starter, 'Gaspacho');
final paella = dish(2, EventDishType.mainDish, 'Paella');
final churros = dish(3, EventDishType.dessert, 'Churros');

SpecialEvent event({List<EventDish> dishes = const []}) => SpecialEvent(
      id: 5,
      name: 'Soirée Paella',
      description: '',
      eventDate: DateTime(2026, 7, 20),
      isActive: true,
      dishes: dishes,
    );

void main() {
  group('EventSelection.isCompleteFor', () {
    test('créneau seul suffit pour un événement sans menu', () {
      const selection = EventSelection(timeSlot: slot);

      expect(selection.isCompleteFor(event()), isTrue);
    });

    test('un choix est requis pour chaque service proposé', () {
      final e = event(dishes: [gaspacho, paella, churros]);

      expect(EventSelection(timeSlot: slot).isCompleteFor(e), isFalse);
      expect(
        EventSelection(timeSlot: slot, starter: gaspacho, mainDish: paella)
            .isCompleteFor(e),
        isFalse,
      );
      expect(
        EventSelection(
          timeSlot: slot,
          starter: gaspacho,
          mainDish: paella,
          dessert: churros,
        ).isCompleteFor(e),
        isTrue,
      );
    });

    test('un service non proposé ne bloque pas', () {
      final e = event(dishes: [paella]); // plats seulement

      expect(
        EventSelection(timeSlot: slot, mainDish: paella).isCompleteFor(e),
        isTrue,
      );
    });

    test('incomplet sans créneau', () {
      expect(
        EventSelection(starter: gaspacho, mainDish: paella, dessert: churros)
            .isCompleteFor(event(dishes: [gaspacho, paella, churros])),
        isFalse,
      );
    });
  });

  group('EventSelection.toCreatePayload', () {
    test('payload complet avec les ids des choix', () {
      final payload = EventSelection(
        timeSlot: slot,
        starter: gaspacho,
        mainDish: paella,
        dessert: churros,
      ).toCreatePayload(event(dishes: [gaspacho, paella, churros]));

      expect(payload, {
        'specialEventId': 5,
        'eventTimeSlotId': 50,
        'starterId': 1,
        'mainDishId': 2,
        'dessertId': 3,
      });
    });

    test('payload minimal sans menu', () {
      final payload =
          const EventSelection(timeSlot: slot).toCreatePayload(event());

      expect(payload, {
        'specialEventId': 5,
        'eventTimeSlotId': 50,
      });
    });
  });

  group('EventSelection toggles', () {
    test('toggle sélectionne puis désélectionne', () {
      var selection = const EventSelection();
      selection = selection.toggleStarter(gaspacho);
      expect(selection.starter, gaspacho);

      selection = selection.toggleStarter(gaspacho);
      expect(selection.starter, isNull);
    });

    test('toggle remplace le choix du même service', () {
      final paellaVege = dish(4, EventDishType.mainDish, 'Paella végé');
      var selection = const EventSelection().toggleMainDish(paella);
      selection = selection.toggleMainDish(paellaVege);

      expect(selection.mainDish, paellaVege);
    });
  });
}
