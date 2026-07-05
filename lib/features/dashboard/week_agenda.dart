import '../../core/utils/dates.dart';
import '../../data/models/doggybag_reservation.dart';
import '../../data/models/event_reservation.dart';
import '../../data/models/reservation.dart';

/// Les deux vues du calendrier hebdomadaire de l'accueil :
/// repas + événements (par défaut) ou doggybags (bouton bascule).
enum DashboardMode { mealsAndEvents, doggyBags }

/// Contenu d'un jour du calendrier, déjà filtré selon la vue active.
class DayAgenda {
  const DayAgenda({
    this.meals = const [],
    this.events = const [],
    this.doggyBags = const [],
  });

  final List<Reservation> meals;
  final List<EventReservation> events;
  final List<DoggyBagReservation> doggyBags;

  bool get isEmpty => meals.isEmpty && events.isEmpty && doggyBags.isEmpty;
}

/// Filtre les réservations d'un jour donné selon la vue active.
/// Les annulés sont exclus ; un repas/événement sans relation chargée n'a
/// pas de date connue et est ignoré.
DayAgenda agendaForDay({
  required DateTime day,
  required DashboardMode mode,
  required List<Reservation> meals,
  required List<DoggyBagReservation> doggyBags,
  required List<EventReservation> events,
}) {
  if (mode == DashboardMode.doggyBags) {
    return DayAgenda(
      doggyBags: doggyBags
          .where((b) =>
              b.status == DoggyBagStatus.confirmed &&
              isSameDay(b.pickupDate, day))
          .toList(),
    );
  }
  return DayAgenda(
    meals: meals
        .where((r) =>
            !r.isCancelled &&
            r.dailyMenu != null &&
            isSameDay(r.dailyMenu!.date, day))
        .toList(),
    events: events
        .where((e) =>
            !e.isCancelled &&
            e.specialEvent != null &&
            isSameDay(e.specialEvent!.eventDate, day))
        .toList(),
  );
}
