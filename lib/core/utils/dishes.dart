import '../../data/models/daily_menu.dart';
import '../../data/models/dish.dart';

/// Portage de `mon-repas_client/src/lib/utils/dishes.ts`.

const _starterTypes = {
  DishType.starter1,
  DishType.starter2,
  DishType.starter3,
  DishType.starterDaily,
};

const _mainTypes = {
  DishType.hotDish1,
  DishType.hotDish2,
  DishType.dailySpecial,
};

const _dessertTypes = {
  DishType.dessert1,
  DishType.dessert2,
  DishType.dessert3,
  DishType.dessertDaily,
};

List<Dish> getStarters(DailyMenu menu) =>
    menu.dishes.where((d) => _starterTypes.contains(d.type)).toList();

List<Dish> getMainDishes(DailyMenu menu) =>
    menu.dishes.where((d) => _mainTypes.contains(d.type)).toList();

List<Dish> getDesserts(DailyMenu menu) =>
    menu.dishes.where((d) => _dessertTypes.contains(d.type)).toList();

bool isDailySpecialType(DishType type) =>
    type == DishType.dailySpecial ||
    type == DishType.starterDaily ||
    type == DishType.dessertDaily;

String getDishTypeLabel(DishType type) {
  if (isDailySpecialType(type)) return 'Offre du jour';
  if (_starterTypes.contains(type)) return 'Entrée';
  if (_mainTypes.contains(type)) return 'Plat';
  return 'Dessert';
}

/// Valeur `dishType` attendue par `POST /reservations`.
String dishMainType(DishType type) {
  if (type == DishType.hotDish2) return 'hot_dish_2';
  if (type == DishType.dailySpecial) return 'offre_jour';
  return 'hot_dish_1';
}

class DishAvailability {
  const DishAvailability({required this.available, this.remaining});

  final bool available;

  /// null = quantité illimitée.
  final int? remaining;
}

DishAvailability getDishAvailability(Dish dish) {
  final quantity = dish.availableQuantity;
  if (quantity == null) return const DishAvailability(available: true);
  final remaining = quantity - dish.reservedQuantity;
  return DishAvailability(available: remaining > 0, remaining: remaining);
}
