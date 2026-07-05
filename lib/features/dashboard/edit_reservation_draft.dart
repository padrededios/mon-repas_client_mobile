import '../../core/utils/dishes.dart';
import '../../data/models/daily_menu.dart';
import '../../data/models/dish.dart';
import '../../data/models/reservation.dart';
import '../../data/models/time_slot.dart';

/// Brouillon d'édition d'une réservation existante (équivalent de
/// `EditReservationDialog` web) : état resynchronisé à l'ouverture,
/// PATCH partiel n'envoyant que les champs modifiés.
class EditReservationDraft {
  const EditReservationDraft._({
    required this.original,
    required this.menu,
    this.starter,
    this.mainDish,
    this.dessert,
    this.timeSlot,
  });

  final Reservation original;
  final DailyMenu menu;
  final Dish? starter;
  final Dish? mainDish;
  final Dish? dessert;
  final TimeSlot? timeSlot;

  factory EditReservationDraft.fromReservation(
    Reservation reservation,
    DailyMenu menu,
  ) {
    Dish? byId(int? id) {
      if (id == null) return null;
      for (final d in menu.dishes) {
        if (d.id == id) return d;
      }
      return null;
    }

    TimeSlot? slotById(int id) {
      for (final s in menu.timeSlots ?? const <TimeSlot>[]) {
        if (s.id == id) return s;
      }
      return reservation.timeSlot;
    }

    return EditReservationDraft._(
      original: reservation,
      menu: menu,
      starter: byId(reservation.starterId),
      mainDish: byId(reservation.dishId) ?? reservation.dish,
      dessert: byId(reservation.dessertId),
      timeSlot: slotById(reservation.timeSlotId),
    );
  }

  /// Le plat actuellement réservé reste sélectionnable même épuisé.
  bool isCurrentDish(Dish dish) =>
      dish.id == original.dishId ||
      dish.id == original.starterId ||
      dish.id == original.dessertId;

  bool get _mainChanged => mainDish?.id != original.dishId;
  bool get _starterChanged => starter?.id != original.starterId;
  bool get _dessertChanged => dessert?.id != original.dessertId;
  bool get _slotChanged => timeSlot?.id != original.timeSlotId;

  bool get hasChanges =>
      _mainChanged || _starterChanged || _dessertChanged || _slotChanged;

  /// La sélection reste valable pour l'envoi (plat + créneau toujours requis).
  bool get isValid => mainDish != null && timeSlot != null;

  /// Champs modifiés uniquement ; `null` explicite = suppression.
  Map<String, dynamic> buildPatch() {
    return {
      if (_mainChanged) 'dishType': dishMainType(mainDish!.type),
      if (_starterChanged) 'starterId': starter?.id,
      if (_dessertChanged) 'dessertId': dessert?.id,
      if (_slotChanged) 'timeSlotId': timeSlot!.id,
    };
  }

  EditReservationDraft _copy({
    Dish? starter,
    Dish? mainDish,
    Dish? dessert,
    TimeSlot? timeSlot,
    bool clearStarter = false,
    bool clearDessert = false,
  }) {
    return EditReservationDraft._(
      original: original,
      menu: menu,
      starter: clearStarter ? null : (starter ?? this.starter),
      mainDish: mainDish ?? this.mainDish,
      dessert: clearDessert ? null : (dessert ?? this.dessert),
      timeSlot: timeSlot ?? this.timeSlot,
    );
  }

  EditReservationDraft toggleStarter(Dish dish) => starter?.id == dish.id
      ? _copy(clearStarter: true)
      : _copy(starter: dish);

  EditReservationDraft toggleDessert(Dish dish) => dessert?.id == dish.id
      ? _copy(clearDessert: true)
      : _copy(dessert: dish);

  /// Le plat principal reste obligatoire : pas de désélection, seulement
  /// un remplacement.
  EditReservationDraft toggleMainDish(Dish dish) =>
      mainDish?.id == dish.id ? this : _copy(mainDish: dish);

  EditReservationDraft withTimeSlot(TimeSlot slot) => _copy(timeSlot: slot);
}
