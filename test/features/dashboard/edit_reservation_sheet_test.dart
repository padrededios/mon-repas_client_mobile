import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mon_repas_client_mobile/core/theme/app_theme.dart';
import 'package:mon_repas_client_mobile/data/models/daily_menu.dart';
import 'package:mon_repas_client_mobile/data/models/dish.dart';
import 'package:mon_repas_client_mobile/data/models/reservation.dart';
import 'package:mon_repas_client_mobile/data/models/time_slot.dart';
import 'package:mon_repas_client_mobile/data/providers.dart';
import 'package:mon_repas_client_mobile/features/dashboard/edit_reservation_sheet.dart';

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
      dailyMenuId: 7,
    );

TimeSlot slot(int id, {int reserved = 2}) => TimeSlot(
      id: id,
      dailyMenuId: 7,
      startTime: id == 100 ? '12:00:00' : '12:30:00',
      endTime: id == 100 ? '12:30:00' : '13:00:00',
      capacity: 10,
      reservedCount: reserved,
    );

final tomorrow = DateTime.now().add(const Duration(days: 1));

DailyMenu buildMenu(List<Dish> dishes) => DailyMenu(
      id: 7,
      date: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
      timeSlotCapacity: 10,
      isActive: true,
      dishes: dishes,
      timeSlots: [slot(100), slot(101)],
    );

Reservation reservation() => Reservation(
      id: 55,
      userId: 3,
      timeSlotId: 100,
      dishId: 3,
      status: ReservationStatus.confirmed,
      createdAt: DateTime(2026, 7, 8),
      timeSlot: slot(100),
    );

Widget buildApp(DailyMenu menu) {
  return ProviderScope(
    overrides: [
      dailyMenuProvider.overrideWith((ref, id) async => menu),
      menuTimeSlotsProvider.overrideWith(
        (ref, id) async => [slot(100), slot(101)],
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: EditReservationSheet(reservation: reservation()),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  testWidgets('« Enregistrer » désactivé tant que rien n\'a changé',
      (tester) async {
    final menu = buildMenu([dish(3, DishType.hotDish1)]);
    await tester.pumpWidget(buildApp(menu));
    await tester.pumpAndSettle();

    final saveButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Enregistrer'),
    );
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('changer de créneau active « Enregistrer »', (tester) async {
    final menu = buildMenu([dish(3, DishType.hotDish1)]);
    await tester.pumpWidget(buildApp(menu));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('12:30 – 13:00'), 200);
    await tester.tap(find.text('12:30 – 13:00'));
    await tester.pumpAndSettle();

    final saveButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Enregistrer'),
    );
    expect(saveButton.onPressed, isNotNull);
  });

  testWidgets(
      'le plat réservé reste sélectionné et affiché même épuisé '
      '(pas de badge bloquant la sélection)', (tester) async {
    final soldOutCurrent =
        dish(3, DishType.hotDish1, availableQuantity: 5, reserved: 5);
    final other = dish(4, DishType.hotDish2);
    final menu = buildMenu([soldOutCurrent, other]);
    await tester.pumpWidget(buildApp(menu));
    await tester.pumpAndSettle();

    // Le plat courant épuisé porte bien le badge, mais reste re-sélectionnable :
    expect(find.text('Épuisé'), findsOneWidget);

    // On passe sur l'autre plat, puis on revient sur le plat épuisé.
    await tester.tap(find.text('Plat-4'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plat-3'));
    await tester.pumpAndSettle();

    // Retour à l'état initial : rien à enregistrer.
    final saveButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Enregistrer'),
    );
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('bouton Supprimer ouvre la confirmation', (tester) async {
    final menu = buildMenu([dish(3, DishType.hotDish1)]);
    await tester.pumpWidget(buildApp(menu));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer cette réservation ?'), findsOneWidget);
    expect(find.text('Cette action est définitive.'), findsOneWidget);
  });
}
