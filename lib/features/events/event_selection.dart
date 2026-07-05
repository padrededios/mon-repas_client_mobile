import '../../data/models/event_dish.dart';
import '../../data/models/event_time_slot.dart';
import '../../data/models/special_event.dart';

/// Sélection en cours pour s'inscrire à un événement spécial : un choix par
/// service proposé + créneau (équivalent événementiel de [MealSelection]).
class EventSelection {
  const EventSelection({
    this.starter,
    this.mainDish,
    this.dessert,
    this.timeSlot,
  });

  final EventDish? starter;
  final EventDish? mainDish;
  final EventDish? dessert;
  final EventTimeSlot? timeSlot;

  /// Créneau obligatoire ; un choix requis pour chaque service que
  /// l'événement propose (parité API).
  bool isCompleteFor(SpecialEvent event) {
    if (timeSlot == null) return false;
    if (event.starters.isNotEmpty && starter == null) return false;
    if (event.mainDishes.isNotEmpty && mainDish == null) return false;
    if (event.desserts.isNotEmpty && dessert == null) return false;
    return true;
  }

  /// Payload `POST /event-reservations`.
  Map<String, dynamic> toCreatePayload(SpecialEvent event) {
    return {
      'specialEventId': event.id,
      'eventTimeSlotId': timeSlot!.id,
      if (starter != null) 'starterId': starter!.id,
      if (mainDish != null) 'mainDishId': mainDish!.id,
      if (dessert != null) 'dessertId': dessert!.id,
    };
  }

  EventSelection toggleStarter(EventDish dish) => EventSelection(
        starter: starter?.id == dish.id ? null : dish,
        mainDish: mainDish,
        dessert: dessert,
        timeSlot: timeSlot,
      );

  EventSelection toggleMainDish(EventDish dish) => EventSelection(
        starter: starter,
        mainDish: mainDish?.id == dish.id ? null : dish,
        dessert: dessert,
        timeSlot: timeSlot,
      );

  EventSelection toggleDessert(EventDish dish) => EventSelection(
        starter: starter,
        mainDish: mainDish,
        dessert: dessert?.id == dish.id ? null : dish,
        timeSlot: timeSlot,
      );

  EventSelection withTimeSlot(EventTimeSlot? slot) => EventSelection(
        starter: starter,
        mainDish: mainDish,
        dessert: dessert,
        timeSlot: slot,
      );
}
