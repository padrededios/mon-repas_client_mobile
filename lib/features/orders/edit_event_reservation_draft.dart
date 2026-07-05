import '../../data/models/event_dish.dart';
import '../../data/models/event_reservation.dart';
import '../../data/models/event_time_slot.dart';
import '../../data/models/special_event.dart';

/// Brouillon d'édition d'une réservation d'événement (équivalent
/// événementiel de [EditReservationDraft]) : PATCH partiel n'envoyant que
/// les champs modifiés.
class EditEventReservationDraft {
  const EditEventReservationDraft._({
    required this.original,
    required this.event,
    this.starter,
    this.mainDish,
    this.dessert,
    this.timeSlot,
  });

  final EventReservation original;
  final SpecialEvent event;
  final EventDish? starter;
  final EventDish? mainDish;
  final EventDish? dessert;
  final EventTimeSlot? timeSlot;

  factory EditEventReservationDraft.fromReservation(
    EventReservation reservation,
    SpecialEvent event,
  ) {
    EventDish? byId(int? id) {
      if (id == null) return null;
      for (final d in event.dishes) {
        if (d.id == id) return d;
      }
      return null;
    }

    EventTimeSlot? slotById(int id) {
      for (final s in event.timeSlots ?? const <EventTimeSlot>[]) {
        if (s.id == id) return s;
      }
      return reservation.eventTimeSlot;
    }

    return EditEventReservationDraft._(
      original: reservation,
      event: event,
      starter: byId(reservation.starterId) ?? reservation.starter,
      mainDish: byId(reservation.mainDishId) ?? reservation.mainDish,
      dessert: byId(reservation.dessertId) ?? reservation.dessert,
      timeSlot: slotById(reservation.eventTimeSlotId),
    );
  }

  bool get _starterChanged => starter?.id != original.starterId;
  bool get _mainChanged => mainDish?.id != original.mainDishId;
  bool get _dessertChanged => dessert?.id != original.dessertId;
  bool get _slotChanged => timeSlot?.id != original.eventTimeSlotId;

  bool get hasChanges =>
      _starterChanged || _mainChanged || _dessertChanged || _slotChanged;

  /// Parité avec la création : un choix requis pour chaque service proposé,
  /// créneau obligatoire.
  bool get isValid {
    if (timeSlot == null) return false;
    if (event.starters.isNotEmpty && starter == null) return false;
    if (event.mainDishes.isNotEmpty && mainDish == null) return false;
    if (event.desserts.isNotEmpty && dessert == null) return false;
    return true;
  }

  /// Champs modifiés uniquement ; `null` explicite = suppression.
  Map<String, dynamic> buildPatch() {
    return {
      if (_starterChanged) 'starterId': starter?.id,
      if (_mainChanged) 'mainDishId': mainDish?.id,
      if (_dessertChanged) 'dessertId': dessert?.id,
      if (_slotChanged) 'eventTimeSlotId': timeSlot!.id,
    };
  }

  EditEventReservationDraft _copy({
    EventDish? starter,
    EventDish? mainDish,
    EventDish? dessert,
    EventTimeSlot? timeSlot,
    bool clearStarter = false,
    bool clearDessert = false,
  }) {
    return EditEventReservationDraft._(
      original: original,
      event: event,
      starter: clearStarter ? null : (starter ?? this.starter),
      mainDish: mainDish ?? this.mainDish,
      dessert: clearDessert ? null : (dessert ?? this.dessert),
      timeSlot: timeSlot ?? this.timeSlot,
    );
  }

  EditEventReservationDraft toggleStarter(EventDish dish) =>
      starter?.id == dish.id ? _copy(clearStarter: true) : _copy(starter: dish);

  EditEventReservationDraft toggleDessert(EventDish dish) =>
      dessert?.id == dish.id ? _copy(clearDessert: true) : _copy(dessert: dish);

  /// Le plat principal reste obligatoire : pas de désélection, seulement un
  /// remplacement.
  EditEventReservationDraft toggleMainDish(EventDish dish) =>
      mainDish?.id == dish.id ? this : _copy(mainDish: dish);

  EditEventReservationDraft withTimeSlot(EventTimeSlot slot) =>
      _copy(timeSlot: slot);
}
