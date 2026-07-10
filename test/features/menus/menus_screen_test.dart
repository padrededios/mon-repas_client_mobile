import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mon_repas_client_mobile/core/theme/app_theme.dart';
import 'package:mon_repas_client_mobile/core/utils/dates.dart';
import 'package:mon_repas_client_mobile/data/models/daily_menu.dart';
import 'package:mon_repas_client_mobile/data/models/dish.dart';
import 'package:mon_repas_client_mobile/data/models/event_reservation.dart';
import 'package:mon_repas_client_mobile/data/models/special_event.dart';
import 'package:mon_repas_client_mobile/data/providers.dart';
import 'package:mon_repas_client_mobile/features/menus/menus_screen.dart';

Dish dish(int id, String name, DishType type, {int? availableQuantity}) =>
    Dish(
      id: id,
      name: name,
      type: type,
      isDoggyBagEligible: false,
      availableForDoggyBag: 0,
      reservedForDoggyBag: 0,
      reservedQuantity: 2,
      availableQuantity: availableQuantity,
      dailyMenuId: 1,
    );

DailyMenu menuFor(DateTime day, int id) => DailyMenu(
      id: id,
      date: day,
      timeSlotCapacity: 10,
      isActive: true,
      dishes: [
        dish(id * 10 + 1, 'Salade verte', DishType.starter1),
        dish(id * 10 + 2, 'Bolognaise', DishType.hotDish1,
            availableQuantity: 5),
        dish(id * 10 + 3, 'Tarte aux pommes', DishType.dessert1),
      ],
    );

Widget buildApp({List<DailyMenu> menus = const []}) {
  return ProviderScope(
    overrides: [
      weekMenusProvider.overrideWith((ref, key) async => menus),
      activeEventsProvider.overrideWith((ref) async => <SpecialEvent>[]),
      myEventReservationsProvider
          .overrideWith((ref) async => <EventReservation>[]),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: MenusScreen()),
    ),
  );
}

/// Menus sur tous les jours de la semaine courante et de la suivante.
List<DailyMenu> twoWeeksOfMenus() {
  final now = DateTime.now();
  final days = [...weekDays(now), ...weekDays(addWeeks(now, 1))];
  return [for (final (i, day) in days.indexed) menuFor(day, i + 1)];
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  testWidgets(
      "l'en-tête affiche le numéro de semaine centré entre les deux flèches",
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Semaine ${isoWeekNumber(DateTime.now())}'),
        findsOneWidget);
    expect(find.text('Semaine actuelle'), findsNothing);
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    // Le titre est bien ENTRE les flèches : ◀ … Semaine N … ▶
    final leftX = tester.getCenter(find.byIcon(Icons.chevron_left)).dx;
    final rightX = tester.getCenter(find.byIcon(Icons.chevron_right)).dx;
    final titleX = tester
        .getCenter(find.text('Semaine ${isoWeekNumber(DateTime.now())}'))
        .dx;
    expect(titleX, greaterThan(leftX));
    expect(titleX, lessThan(rightX));
  });

  testWidgets('les pastilles LUN → VEN de la semaine sont affichées',
      (tester) async {
    await tester.pumpWidget(buildApp(menus: twoWeeksOfMenus()));
    await tester.pumpAndSettle();

    for (final label in ['LUN', 'MAR', 'MER', 'JEU', 'VEN']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets(
      'sélectionner un jour affiche son menu en détail (plats visibles)',
      (tester) async {
    await tester.pumpWidget(buildApp(menus: twoWeeksOfMenus()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('VEN'));
    await tester.pumpAndSettle();

    expect(find.text('ENTRÉES'), findsOneWidget);
    expect(find.text('PLATS'), findsOneWidget);
    expect(find.text('DESSERTS'), findsOneWidget);
    expect(find.text('Salade verte'), findsOneWidget);
    expect(find.text('Bolognaise'), findsOneWidget);
    expect(find.text('Tarte aux pommes'), findsOneWidget);
    // Quantité max fixée sur le plat : le restant est affiché.
    expect(find.text('Reste 3'), findsOneWidget);
  });

  testWidgets(
      'sur une semaine future, le bouton de composition du repas est proposé',
      (tester) async {
    await tester.pumpWidget(buildApp(menus: twoWeeksOfMenus()));
    await tester.pumpAndSettle();

    // Semaine suivante : aucun jour n'est passé.
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('Composer mon repas'), findsOneWidget);
  });

  testWidgets("un jour sans menu affiche « Pas de menu ce jour »",
      (tester) async {
    // Aucun menu publié cette semaine.
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('MER'));
    await tester.pumpAndSettle();

    expect(find.text('Pas de menu ce jour'), findsOneWidget);
  });

  testWidgets(
      "re-sélectionner l'onglet Réserver ramène à la semaine courante",
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final now = DateTime.now();
    await tester.tap(find.byIcon(Icons.chevron_right).first);
    await tester.pumpAndSettle();
    expect(find.text('Semaine ${isoWeekNumber(addWeeks(now, 1))}'),
        findsOneWidget);

    // Passage sur un autre onglet puis retour sur Réserver (index 1).
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MenusScreen)),
    );
    container.read(homeTabIndexProvider.notifier).state = 0;
    await tester.pump();
    container.read(homeTabIndexProvider.notifier).state = 1;
    await tester.pumpAndSettle();

    expect(find.text('Semaine ${isoWeekNumber(now)}'), findsOneWidget);
  });
}
