import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mon_repas_client_mobile/core/api/api_client.dart';
import 'package:mon_repas_client_mobile/core/storage/session_storage.dart';
import 'package:mon_repas_client_mobile/core/theme/app_theme.dart';
import 'package:mon_repas_client_mobile/core/utils/dates.dart';
import 'package:mon_repas_client_mobile/data/models/daily_menu.dart';
import 'package:mon_repas_client_mobile/data/models/dish.dart';
import 'package:mon_repas_client_mobile/data/models/doggybag_reservation.dart';
import 'package:mon_repas_client_mobile/data/models/event_reservation.dart';
import 'package:mon_repas_client_mobile/data/models/reservation.dart';
import 'package:mon_repas_client_mobile/data/models/special_event.dart';
import 'package:mon_repas_client_mobile/data/models/user.dart';
import 'package:mon_repas_client_mobile/data/providers.dart';
import 'package:mon_repas_client_mobile/data/repositories/auth_repository.dart';
import 'package:mon_repas_client_mobile/features/auth/auth_notifier.dart';
import 'package:mon_repas_client_mobile/features/dashboard/dashboard_screen.dart';

/// Notifier pré-hydraté : évite tout appel réseau/stockage dans les tests.
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier() : super(AuthRepository(ApiClient(), SessionStorage())) {
    state = const AuthState(
      user: User(
        id: 3,
        email: 'client@mon-repas.com',
        firstName: 'Camille',
        lastName: 'Client',
        isAdmin: false,
        isRestaurant: false,
        isActive: true,
      ),
      isInitialized: true,
    );
  }
}

/// Lundi de la semaine affichée par défaut (ancrée sur aujourd'hui).
final monday = weekDays(DateTime.now()).first;

Dish dish(int id, String name) => Dish(
      id: id,
      name: name,
      type: DishType.hotDish1,
      isDoggyBagEligible: false,
      availableForDoggyBag: 0,
      reservedForDoggyBag: 0,
      reservedQuantity: 0,
      dailyMenuId: 7,
    );

Reservation meal() => Reservation(
      id: 55,
      userId: 3,
      timeSlotId: 100,
      dishId: 10,
      status: ReservationStatus.confirmed,
      createdAt: DateTime(2026, 7, 1),
      dish: dish(10, 'Bolognaise'),
      dailyMenu: DailyMenu(
        id: 7,
        date: monday,
        timeSlotCapacity: 10,
        isActive: true,
      ),
    );

DoggyBagReservation bag() => DoggyBagReservation(
      id: 9,
      userId: 3,
      dishId: 11,
      quantity: 2,
      pickupDate: monday,
      status: DoggyBagStatus.confirmed,
      createdAt: DateTime(2026, 7, 1),
      dish: dish(11, 'Lasagnes'),
    );

EventReservation eventRes() => EventReservation(
      id: 12,
      userId: 3,
      specialEventId: 5,
      eventTimeSlotId: 50,
      status: ReservationStatus.confirmed,
      createdAt: DateTime(2026, 7, 1),
      specialEvent: SpecialEvent(
        id: 5,
        name: 'Soirée Tacos',
        description: '',
        eventDate: monday,
        isActive: true,
      ),
    );

Widget buildApp() {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => _FakeAuthNotifier()),
      myReservationsProvider.overrideWith((ref) async => [meal()]),
      myDoggyBagReservationsProvider.overrideWith((ref) async => [bag()]),
      myEventReservationsProvider.overrideWith((ref) async => [eventRes()]),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: DashboardScreen()),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  testWidgets('vue par défaut : repas et événements, pas les doggybags',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Bolognaise'), findsOneWidget);
    expect(find.text('Soirée Tacos'), findsOneWidget);
    expect(find.text('Lasagnes'), findsNothing);
    expect(find.text('Mes repas & événements'), findsOneWidget);
  });

  testWidgets('le bouton DoggyBags bascule la vue, puis revient',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Bascule vers les doggybags.
    await tester.tap(find.widgetWithText(FilterChip, 'DoggyBags'));
    await tester.pumpAndSettle();

    expect(find.text('Lasagnes'), findsOneWidget);
    expect(find.text('Quantité ×2'), findsOneWidget);
    expect(find.text('Bolognaise'), findsNothing);
    expect(find.text('Soirée Tacos'), findsNothing);
    expect(find.text('Mes doggybags'), findsOneWidget);

    // Re-clic : retour aux repas & événements.
    await tester.tap(find.widgetWithText(FilterChip, 'DoggyBags'));
    await tester.pumpAndSettle();

    expect(find.text('Bolognaise'), findsOneWidget);
    expect(find.text('Soirée Tacos'), findsOneWidget);
    expect(find.text('Lasagnes'), findsNothing);
  });

  testWidgets("l'accueil affiche la semaine, pas la date du jour",
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Semaine ${isoWeekNumber(DateTime.now())}'),
        findsOneWidget);
    expect(find.text('Cette semaine'), findsOneWidget);
    expect(find.text('Bonjour Camille !'), findsOneWidget);
  });
}
