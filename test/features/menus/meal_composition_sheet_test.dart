import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mon_repas_client_mobile/core/theme/app_theme.dart';
import 'package:mon_repas_client_mobile/data/models/daily_menu.dart';
import 'package:mon_repas_client_mobile/data/models/dish.dart';
import 'package:mon_repas_client_mobile/data/models/time_slot.dart';
import 'package:mon_repas_client_mobile/data/providers.dart';
import 'package:mon_repas_client_mobile/features/menus/meal_composition_sheet.dart';

Dish dish(int id, DishType type, {int? availableQuantity, int reserved = 0}) =>
    Dish(
      id: id,
      name: 'Plat-$id',
      type: type,
      isDoggyBagEligible: false,
      availableForDoggyBag: 0,
      reservedForDoggyBag: 0,
      availableQuantity: availableQuantity,
      reservedQuantity: reserved,
      dailyMenuId: 1,
    );

final tomorrow = DateTime.now().add(const Duration(days: 1));

DailyMenu buildMenu(List<Dish> dishes) => DailyMenu(
      id: 1,
      date: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
      timeSlotCapacity: 10,
      isActive: true,
      dishes: dishes,
    );

const slot = TimeSlot(
  id: 100,
  dailyMenuId: 1,
  startTime: '12:00:00',
  endTime: '12:30:00',
  capacity: 10,
  reservedCount: 2,
);

Widget buildApp(DailyMenu menu) {
  return ProviderScope(
    overrides: [
      menuTimeSlotsProvider.overrideWith((ref, menuId) async => [slot]),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: MealCompositionSheet(menu: menu)),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  testWidgets(
      'le bouton Confirmer n\'apparaît que quand la sélection est complète '
      '(plat + entrée + dessert + créneau)', (tester) async {
    final menu = buildMenu([
      dish(1, DishType.starter1),
      dish(2, DishType.hotDish1),
      dish(3, DishType.dessert1),
    ]);
    await tester.pumpWidget(buildApp(menu));
    await tester.pumpAndSettle();

    expect(find.text('Confirmer la réservation'), findsNothing);

    // Plat seul : entrée et dessert existent → toujours incomplet.
    await tester.tap(find.text('Plat-2'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmer la réservation'), findsNothing);

    await tester.tap(find.text('Plat-1'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Plat-3'), 200);
    await tester.tap(find.text('Plat-3'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmer la réservation'), findsNothing);

    // Créneau → sélection complète.
    await tester.scrollUntilVisible(find.text('12:00 – 12:30'), 200);
    await tester.tap(find.text('12:00 – 12:30'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmer la réservation'), findsOneWidget);
  });

  testWidgets('menu sans entrées ni desserts : plat + créneau suffisent',
      (tester) async {
    final menu = buildMenu([dish(2, DishType.hotDish1)]);
    await tester.pumpWidget(buildApp(menu));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plat-2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('12:00 – 12:30'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmer la réservation'), findsOneWidget);
  });

  testWidgets('un plat épuisé est affiché mais non sélectionnable',
      (tester) async {
    final menu = buildMenu([
      dish(2, DishType.hotDish1, availableQuantity: 5, reserved: 5),
    ]);
    await tester.pumpWidget(buildApp(menu));
    await tester.pumpAndSettle();

    expect(find.text('Épuisé'), findsOneWidget);

    await tester.tap(find.text('Plat-2'));
    await tester.pumpAndSettle();

    // Pas de section créneau : le plat n'a pas été sélectionné.
    expect(find.text('Créneau'), findsNothing);
  });

  testWidgets('badge « N restants » quand le stock est ≤ 5', (tester) async {
    final menu = buildMenu([
      dish(2, DishType.hotDish1, availableQuantity: 10, reserved: 7),
    ]);
    await tester.pumpWidget(buildApp(menu));
    await tester.pumpAndSettle();

    expect(find.text('3 restants'), findsOneWidget);
  });

  testWidgets('badge « Spécial » sur l\'offre du jour', (tester) async {
    final menu = buildMenu([dish(2, DishType.dailySpecial)]);
    await tester.pumpWidget(buildApp(menu));
    await tester.pumpAndSettle();

    expect(find.text('Spécial'), findsOneWidget);
  });
}
