import '../../core/utils/dishes.dart';
import '../../data/models/daily_menu.dart';
import '../../data/models/dish.dart';
import '../../data/models/time_slot.dart';

/// Sélection en cours pour composer un repas (entrée + plat + dessert +
/// créneau). Portage des règles de complétude de la webapp.
class MealSelection {
  const MealSelection({
    this.starter,
    this.mainDish,
    this.dessert,
    this.timeSlot,
  });

  final Dish? starter;
  final Dish? mainDish;
  final Dish? dessert;
  final TimeSlot? timeSlot;

  /// Plat + créneau obligatoires ; entrée obligatoire si le menu propose des
  /// entrées ; dessert idem.
  bool isCompleteFor(DailyMenu menu) {
    if (mainDish == null || timeSlot == null) return false;
    if (getStarters(menu).isNotEmpty && starter == null) return false;
    if (getDesserts(menu).isNotEmpty && dessert == null) return false;
    return true;
  }

  /// Payload `POST /reservations`.
  Map<String, dynamic> toCreatePayload() {
    final main = mainDish!;
    return {
      'timeSlotId': timeSlot!.id,
      'dishType': dishMainType(main.type),
      if (starter != null) 'starterId': starter!.id,
      if (dessert != null) 'dessertId': dessert!.id,
    };
  }

  MealSelection toggleStarter(Dish dish) => MealSelection(
        starter: starter?.id == dish.id ? null : dish,
        mainDish: mainDish,
        dessert: dessert,
        timeSlot: timeSlot,
      );

  MealSelection toggleMainDish(Dish dish) => MealSelection(
        starter: starter,
        mainDish: mainDish?.id == dish.id ? null : dish,
        dessert: dessert,
        timeSlot: timeSlot,
      );

  MealSelection toggleDessert(Dish dish) => MealSelection(
        starter: starter,
        mainDish: mainDish,
        dessert: dessert?.id == dish.id ? null : dish,
        timeSlot: timeSlot,
      );

  MealSelection withTimeSlot(TimeSlot slot) => MealSelection(
        starter: starter,
        mainDish: mainDish,
        dessert: dessert,
        timeSlot: slot,
      );
}
