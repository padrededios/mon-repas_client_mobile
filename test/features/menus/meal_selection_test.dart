import 'package:flutter_test/flutter_test.dart';
import 'package:mon_repas_client_mobile/data/models/daily_menu.dart';
import 'package:mon_repas_client_mobile/data/models/dish.dart';
import 'package:mon_repas_client_mobile/data/models/time_slot.dart';
import 'package:mon_repas_client_mobile/features/menus/meal_selection.dart';

Dish dish(int id, DishType type) => Dish(
      id: id,
      name: 'Plat $id',
      type: type,
      isDoggyBagEligible: false,
      availableForDoggyBag: 0,
      reservedForDoggyBag: 0,
      reservedQuantity: 0,
      dailyMenuId: 1,
    );

const slot = TimeSlot(
  id: 100,
  dailyMenuId: 1,
  startTime: '12:00:00',
  endTime: '12:30:00',
  capacity: 10,
  reservedCount: 0,
);

DailyMenu menuWith(List<Dish> dishes) => DailyMenu(
      id: 1,
      date: DateTime(2026, 7, 10),
      timeSlotCapacity: 10,
      isActive: true,
      dishes: dishes,
    );

void main() {
  final starter = dish(1, DishType.starter1);
  final main1 = dish(2, DishType.hotDish1);
  final special = dish(3, DishType.dailySpecial);
  final dessert = dish(4, DishType.dessert1);

  group('isCompleteFor — règles de complétude de la webapp', () {
    test('menu complet : plat + entrée + dessert + créneau requis', () {
      final menu = menuWith([starter, main1, dessert]);
      expect(const MealSelection().isCompleteFor(menu), isFalse);
      expect(
        MealSelection(mainDish: main1, timeSlot: slot).isCompleteFor(menu),
        isFalse, // entrée et dessert existent → obligatoires
      );
      expect(
        MealSelection(
          mainDish: main1,
          starter: starter,
          dessert: dessert,
          timeSlot: slot,
        ).isCompleteFor(menu),
        isTrue,
      );
    });

    test('menu sans entrées ni desserts : plat + créneau suffisent', () {
      final menu = menuWith([main1]);
      expect(
        MealSelection(mainDish: main1, timeSlot: slot).isCompleteFor(menu),
        isTrue,
      );
    });

    test('créneau manquant → incomplet', () {
      final menu = menuWith([main1]);
      expect(MealSelection(mainDish: main1).isCompleteFor(menu), isFalse);
    });
  });

  group('toCreatePayload', () {
    test('mappe dishMainType et inclut entrée/dessert choisis', () {
      final selection = MealSelection(
        mainDish: special,
        starter: starter,
        dessert: dessert,
        timeSlot: slot,
      );
      expect(selection.toCreatePayload(), {
        'timeSlotId': 100,
        'dishType': 'offre_jour',
        'starterId': 1,
        'dessertId': 4,
      });
    });

    test('sans entrée ni dessert : champs omis', () {
      final selection = MealSelection(mainDish: main1, timeSlot: slot);
      expect(selection.toCreatePayload(), {
        'timeSlotId': 100,
        'dishType': 'hot_dish_1',
      });
    });
  });

  group('copyWith / toggle', () {
    test('re-taper le même plat le désélectionne', () {
      var s = const MealSelection();
      s = s.toggleMainDish(main1);
      expect(s.mainDish, main1);
      s = s.toggleMainDish(main1);
      expect(s.mainDish, isNull);
    });

    test('changer de plat conserve entrée/dessert/créneau', () {
      var s = MealSelection(
        mainDish: main1,
        starter: starter,
        dessert: dessert,
        timeSlot: slot,
      );
      s = s.toggleMainDish(special);
      expect(s.mainDish, special);
      expect(s.starter, starter);
      expect(s.timeSlot, slot);
    });
  });
}
