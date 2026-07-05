import 'package:flutter_test/flutter_test.dart';
import 'package:mon_repas_client_mobile/core/utils/dishes.dart';
import 'package:mon_repas_client_mobile/data/models/daily_menu.dart';
import 'package:mon_repas_client_mobile/data/models/dish.dart';

Dish makeDish(
  DishType type, {
  int id = 1,
  int? availableQuantity,
  int reservedQuantity = 0,
}) {
  return Dish(
    id: id,
    name: 'Plat ${type.value}',
    type: type,
    isDoggyBagEligible: false,
    availableForDoggyBag: 0,
    reservedForDoggyBag: 0,
    availableQuantity: availableQuantity,
    reservedQuantity: reservedQuantity,
    dailyMenuId: 1,
  );
}

DailyMenu makeMenu(List<Dish> dishes) {
  return DailyMenu(
    id: 1,
    date: DateTime(2026, 7, 10),
    timeSlotCapacity: 10,
    isActive: true,
    dishes: dishes,
  );
}

void main() {
  group('catégorisation des plats', () {
    final menu = makeMenu([
      makeDish(DishType.starter1),
      makeDish(DishType.starterDaily),
      makeDish(DishType.hotDish1),
      makeDish(DishType.hotDish2),
      makeDish(DishType.dailySpecial),
      makeDish(DishType.dessert1),
      makeDish(DishType.dessertDaily),
    ]);

    test('getStarters retourne uniquement les entrées', () {
      expect(
        getStarters(menu).map((d) => d.type).toList(),
        [DishType.starter1, DishType.starterDaily],
      );
    });

    test('getMainDishes retourne uniquement les plats principaux', () {
      expect(
        getMainDishes(menu).map((d) => d.type).toList(),
        [DishType.hotDish1, DishType.hotDish2, DishType.dailySpecial],
      );
    });

    test('getDesserts retourne uniquement les desserts', () {
      expect(
        getDesserts(menu).map((d) => d.type).toList(),
        [DishType.dessert1, DishType.dessertDaily],
      );
    });

    test('gère un menu sans plats', () {
      final empty = makeMenu([]);
      expect(getStarters(empty), isEmpty);
      expect(getMainDishes(empty), isEmpty);
      expect(getDesserts(empty), isEmpty);
    });
  });

  group('isDailySpecialType', () {
    test('détecte les types offre du jour', () {
      expect(isDailySpecialType(DishType.dailySpecial), isTrue);
      expect(isDailySpecialType(DishType.starterDaily), isTrue);
      expect(isDailySpecialType(DishType.dessertDaily), isTrue);
      expect(isDailySpecialType(DishType.hotDish1), isFalse);
      expect(isDailySpecialType(DishType.starter1), isFalse);
    });
  });

  group('getDishTypeLabel', () {
    test('retourne les libellés français', () {
      expect(getDishTypeLabel(DishType.starter2), 'Entrée');
      expect(getDishTypeLabel(DishType.hotDish1), 'Plat');
      expect(getDishTypeLabel(DishType.dessert3), 'Dessert');
      expect(getDishTypeLabel(DishType.dailySpecial), 'Offre du jour');
      expect(getDishTypeLabel(DishType.starterDaily), 'Offre du jour');
      expect(getDishTypeLabel(DishType.dessertDaily), 'Offre du jour');
    });
  });

  group('dishMainType', () {
    test("mappe le type de plat vers le dishType attendu par l'API", () {
      expect(dishMainType(DishType.hotDish1), 'hot_dish_1');
      expect(dishMainType(DishType.hotDish2), 'hot_dish_2');
      expect(dishMainType(DishType.dailySpecial), 'offre_jour');
    });
  });

  group('getDishAvailability', () {
    test('quantité illimitée (null) → toujours disponible', () {
      final dish = makeDish(DishType.hotDish1,
          availableQuantity: null, reservedQuantity: 42);
      final a = getDishAvailability(dish);
      expect(a.available, isTrue);
      expect(a.remaining, isNull);
    });

    test('calcule le restant quand la quantité est limitée', () {
      final dish = makeDish(DishType.hotDish1,
          availableQuantity: 10, reservedQuantity: 4);
      final a = getDishAvailability(dish);
      expect(a.available, isTrue);
      expect(a.remaining, 6);
    });

    test('épuisé quand tout est réservé', () {
      final dish = makeDish(DishType.hotDish1,
          availableQuantity: 5, reservedQuantity: 5);
      final a = getDishAvailability(dish);
      expect(a.available, isFalse);
      expect(a.remaining, 0);
    });
  });

  group('DishType.fromValue', () {
    test('parse toutes les valeurs API', () {
      expect(DishType.fromValue('starter_1'), DishType.starter1);
      expect(DishType.fromValue('starter_daily'), DishType.starterDaily);
      expect(DishType.fromValue('hot_dish_2'), DishType.hotDish2);
      expect(DishType.fromValue('daily_special'), DishType.dailySpecial);
      expect(DishType.fromValue('dessert_daily'), DishType.dessertDaily);
    });
  });
}
