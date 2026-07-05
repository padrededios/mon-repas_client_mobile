import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mon_repas_client_mobile/core/theme/app_theme.dart';
import 'package:mon_repas_client_mobile/data/models/event_dish.dart';
import 'package:mon_repas_client_mobile/data/models/event_reservation.dart';
import 'package:mon_repas_client_mobile/data/models/event_time_slot.dart';
import 'package:mon_repas_client_mobile/data/models/special_event.dart';
import 'package:mon_repas_client_mobile/data/providers.dart';
import 'package:mon_repas_client_mobile/features/events/event_detail_screen.dart';

final tomorrow = DateTime.now().add(const Duration(days: 1));

SpecialEvent event({List<EventDish> dishes = const []}) => SpecialEvent(
      id: 5,
      name: 'Soirée Paella',
      description: 'Grande paella',
      eventDate: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
      isActive: true,
      dishes: dishes,
      timeSlots: const [
        EventTimeSlot(
          id: 50,
          specialEventId: 5,
          startTime: '12:00:00',
          endTime: '12:30:00',
          capacity: 60,
          reservedCount: 10,
        ),
      ],
    );

EventDish dish(int id, EventDishType type, String name) => EventDish(
      id: id,
      name: name,
      type: type,
      specialEventId: 5,
    );

Widget buildApp(SpecialEvent e) {
  return ProviderScope(
    overrides: [
      specialEventProvider.overrideWith((ref, id) async => e),
      myEventReservationsProvider
          .overrideWith((ref) async => <EventReservation>[]),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const EventDetailScreen(eventId: 5),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  testWidgets('les plats du menu sont proposés au choix', (tester) async {
    await tester.pumpWidget(buildApp(event(dishes: [
      dish(1, EventDishType.starter, 'Gaspacho'),
      dish(2, EventDishType.mainDish, 'Paella fruits de mer'),
      dish(3, EventDishType.mainDish, 'Paella végétarienne'),
      dish(4, EventDishType.dessert, 'Churros'),
    ])));
    await tester.pumpAndSettle();

    expect(find.text('Composez votre menu'), findsOneWidget);
    expect(find.text('Gaspacho'), findsOneWidget);
    expect(find.text('Paella fruits de mer'), findsOneWidget);
    expect(find.text('Paella végétarienne'), findsOneWidget);
    expect(find.text('Churros'), findsOneWidget);
  });

  testWidgets(
      'le bouton confirmer reste désactivé tant que le menu est incomplet',
      (tester) async {
    // Surface haute : menu + créneaux + bouton visibles sans scroll.
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp(event(dishes: [
      dish(1, EventDishType.starter, 'Gaspacho'),
      dish(2, EventDishType.mainDish, 'Paella fruits de mer'),
      dish(4, EventDishType.dessert, 'Churros'),
    ])));
    await tester.pumpAndSettle();

    // Sélection du créneau seul → bouton visible mais désactivé.
    await tester.tap(find.text('12:00 – 12:30'));
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Confirmer la réservation'),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Choisissez votre menu pour confirmer.'), findsOneWidget);

    // Sélection complète → bouton actif. (Un pump entre chaque tap : les
    // callbacks capturent la sélection du build courant.)
    await tester.tap(find.text('Gaspacho'));
    await tester.pump();
    await tester.tap(find.text('Paella fruits de mer'));
    await tester.pump();
    await tester.tap(find.text('Churros'));
    await tester.pumpAndSettle();

    final enabled = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Confirmer la réservation'),
    );
    expect(enabled.onPressed, isNotNull);
  });

  testWidgets('un événement sans menu se réserve avec le créneau seul',
      (tester) async {
    await tester.pumpWidget(buildApp(event()));
    await tester.pumpAndSettle();

    expect(find.text('Composez votre menu'), findsNothing);

    await tester.tap(find.text('12:00 – 12:30'));
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Confirmer la réservation'),
    );
    expect(button.onPressed, isNotNull);
  });
}
