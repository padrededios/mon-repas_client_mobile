import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mon_repas_client_mobile/core/theme/app_theme.dart';
import 'package:mon_repas_client_mobile/core/utils/dates.dart';
import 'package:mon_repas_client_mobile/data/models/daily_menu.dart';
import 'package:mon_repas_client_mobile/data/models/event_reservation.dart';
import 'package:mon_repas_client_mobile/data/models/special_event.dart';
import 'package:mon_repas_client_mobile/data/providers.dart';
import 'package:mon_repas_client_mobile/features/menus/menus_screen.dart';

Widget buildApp() {
  return ProviderScope(
    overrides: [
      weekMenusProvider.overrideWith((ref, key) async => <DailyMenu>[]),
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

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  testWidgets(
      "l'en-tête affiche le numéro de semaine et ses dates, sans bouton texte",
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Semaine ${isoWeekNumber(DateTime.now())}'),
        findsOneWidget);
    expect(find.text('Semaine actuelle'), findsNothing);
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    // Le chevron droit apparaît aussi sur les cartes jour : au moins celui
    // de la navigation est présent.
    expect(find.byIcon(Icons.chevron_right), findsWidgets);
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
