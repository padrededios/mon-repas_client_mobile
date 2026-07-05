import 'package:flutter_test/flutter_test.dart';
import 'package:mon_repas_client_mobile/data/models/daily_menu.dart';
import 'package:mon_repas_client_mobile/data/models/doggybag_reservation.dart';
import 'package:mon_repas_client_mobile/data/models/event_reservation.dart';
import 'package:mon_repas_client_mobile/data/models/reservation.dart';
import 'package:mon_repas_client_mobile/data/models/special_event.dart';
import 'package:mon_repas_client_mobile/features/dashboard/week_agenda.dart';

final monday = DateTime(2026, 7, 6);
final tuesday = DateTime(2026, 7, 7);

Reservation meal({
  int id = 1,
  DateTime? menuDate,
  ReservationStatus status = ReservationStatus.confirmed,
  bool withMenu = true,
}) =>
    Reservation(
      id: id,
      userId: 3,
      timeSlotId: 100,
      dishId: 10,
      status: status,
      createdAt: DateTime(2026, 7, 1),
      dailyMenu: withMenu
          ? DailyMenu(
              id: 7,
              date: menuDate ?? monday,
              timeSlotCapacity: 10,
              isActive: true,
            )
          : null,
    );

DoggyBagReservation bag({
  int id = 1,
  DateTime? pickupDate,
  DoggyBagStatus status = DoggyBagStatus.confirmed,
}) =>
    DoggyBagReservation(
      id: id,
      userId: 3,
      dishId: 10,
      quantity: 2,
      pickupDate: pickupDate ?? monday,
      status: status,
      createdAt: DateTime(2026, 7, 1),
    );

EventReservation eventRes({
  int id = 1,
  DateTime? eventDate,
  ReservationStatus status = ReservationStatus.confirmed,
  bool withEvent = true,
}) =>
    EventReservation(
      id: id,
      userId: 3,
      specialEventId: 5,
      eventTimeSlotId: 50,
      status: status,
      createdAt: DateTime(2026, 7, 1),
      specialEvent: withEvent
          ? SpecialEvent(
              id: 5,
              name: 'Soirée Tacos',
              description: '',
              eventDate: eventDate ?? monday,
              isActive: true,
            )
          : null,
    );

void main() {
  group('agendaForDay — mode repas & événements', () {
    test('retourne les repas et événements du jour, jamais les doggybags', () {
      final agenda = agendaForDay(
        day: monday,
        mode: DashboardMode.mealsAndEvents,
        meals: [meal()],
        doggyBags: [bag()],
        events: [eventRes()],
      );

      expect(agenda.meals, hasLength(1));
      expect(agenda.events, hasLength(1));
      expect(agenda.doggyBags, isEmpty);
      expect(agenda.isEmpty, isFalse);
    });

    test('exclut les repas et événements des autres jours', () {
      final agenda = agendaForDay(
        day: tuesday,
        mode: DashboardMode.mealsAndEvents,
        meals: [meal(menuDate: monday)],
        doggyBags: const [],
        events: [eventRes(eventDate: monday)],
      );

      expect(agenda.isEmpty, isTrue);
    });

    test('exclut les réservations annulées', () {
      final agenda = agendaForDay(
        day: monday,
        mode: DashboardMode.mealsAndEvents,
        meals: [meal(status: ReservationStatus.cancelled)],
        doggyBags: const [],
        events: [eventRes(status: ReservationStatus.cancelled)],
      );

      expect(agenda.isEmpty, isTrue);
    });

    test('ignore les éléments sans relation chargée (pas de date connue)', () {
      final agenda = agendaForDay(
        day: monday,
        mode: DashboardMode.mealsAndEvents,
        meals: [meal(withMenu: false)],
        doggyBags: const [],
        events: [eventRes(withEvent: false)],
      );

      expect(agenda.isEmpty, isTrue);
    });
  });

  group('agendaForDay — mode doggybags', () {
    test('retourne uniquement les doggybags confirmés du jour', () {
      final agenda = agendaForDay(
        day: monday,
        mode: DashboardMode.doggyBags,
        meals: [meal()],
        doggyBags: [
          bag(id: 1),
          bag(id: 2, pickupDate: tuesday),
          bag(id: 3, status: DoggyBagStatus.cancelled),
          bag(id: 4, status: DoggyBagStatus.pickedUp),
        ],
        events: [eventRes()],
      );

      expect(agenda.doggyBags.map((b) => b.id), [1]);
      expect(agenda.meals, isEmpty);
      expect(agenda.events, isEmpty);
    });

    test('jour sans doggybag → agenda vide', () {
      final agenda = agendaForDay(
        day: tuesday,
        mode: DashboardMode.doggyBags,
        meals: const [],
        doggyBags: [bag(pickupDate: monday)],
        events: const [],
      );

      expect(agenda.isEmpty, isTrue);
    });
  });
}
