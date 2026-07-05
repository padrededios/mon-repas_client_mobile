import 'package:flutter_test/flutter_test.dart';
import 'package:mon_repas_client_mobile/data/models/daily_menu.dart';
import 'package:mon_repas_client_mobile/data/models/dish.dart';
import 'package:mon_repas_client_mobile/data/models/doggybag_reservation.dart';
import 'package:mon_repas_client_mobile/data/models/notification_item.dart';
import 'package:mon_repas_client_mobile/data/models/reservation.dart';
import 'package:mon_repas_client_mobile/features/notifications/notifications_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late NotificationsNotifier notifier;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    notifier = NotificationsNotifier();
    await notifier.hydrate();
  });

  group('add', () {
    test('ajoute en tête et compte les non-lues', () async {
      await notifier.add(
        type: NotificationType.mealReminder,
        title: 'A',
        message: 'a',
      );
      await notifier.add(
        type: NotificationType.system,
        title: 'B',
        message: 'b',
      );
      expect(notifier.state.items, hasLength(2));
      expect(notifier.state.items.first.title, 'B');
      expect(notifier.unreadCount, 2);
    });

    test('respecte les préférences (type désactivé → ignoré)', () async {
      await notifier.setPreference(NotificationType.eventNew, false);
      await notifier.add(
        type: NotificationType.eventNew,
        title: 'Event',
        message: 'x',
      );
      expect(notifier.state.items, isEmpty);
    });

    test('plafonné à 50 notifications (les plus anciennes sortent)', () async {
      for (var i = 0; i < 55; i++) {
        await notifier.add(
          type: NotificationType.system,
          title: 'N$i',
          message: 'm',
        );
      }
      expect(notifier.state.items, hasLength(50));
      expect(notifier.state.items.first.title, 'N54');
      expect(notifier.state.items.last.title, 'N5');
    });
  });

  group('lecture / suppression', () {
    test('markAllRead et markRead', () async {
      await notifier.add(
        type: NotificationType.system,
        title: 'A',
        message: 'a',
      );
      await notifier.add(
        type: NotificationType.system,
        title: 'B',
        message: 'b',
      );
      final id = notifier.state.items.first.id;
      await notifier.markRead(id);
      expect(notifier.unreadCount, 1);
      await notifier.markAllRead();
      expect(notifier.unreadCount, 0);
    });

    test('remove et clearAll', () async {
      await notifier.add(
        type: NotificationType.system,
        title: 'A',
        message: 'a',
      );
      final id = notifier.state.items.single.id;
      await notifier.remove(id);
      expect(notifier.state.items, isEmpty);
      await notifier.add(
        type: NotificationType.system,
        title: 'B',
        message: 'b',
      );
      await notifier.clearAll();
      expect(notifier.state.items, isEmpty);
    });
  });

  group('persistance', () {
    test('les notifications et préférences survivent à un re-hydrate',
        () async {
      await notifier.setPreference(NotificationType.system, false);
      await notifier.add(
        type: NotificationType.mealReminder,
        title: 'Persistée',
        message: 'm',
      );

      final restored = NotificationsNotifier();
      await restored.hydrate();
      expect(restored.state.items.single.title, 'Persistée');
      expect(
        restored.state.preferences.isEnabled(NotificationType.system),
        isFalse,
      );
    });
  });

  group('rappels au démarrage', () {
    final now = DateTime(2026, 7, 10, 9, 0);

    Reservation mealToday() => Reservation(
          id: 1,
          userId: 3,
          timeSlotId: 100,
          dishId: 42,
          status: ReservationStatus.confirmed,
          createdAt: DateTime(2026, 7, 8),
          dailyMenu: DailyMenu(
            id: 7,
            date: DateTime(2026, 7, 10),
            timeSlotCapacity: 10,
            isActive: true,
          ),
        );

    DoggyBagReservation bagToday() => DoggyBagReservation(
          id: 9,
          userId: 3,
          dishId: 42,
          quantity: 2,
          pickupDate: DateTime(2026, 7, 10),
          status: DoggyBagStatus.confirmed,
          createdAt: DateTime(2026, 7, 8),
          dish: const Dish(
            id: 42,
            name: 'Lasagnes',
            type: DishType.hotDish1,
            isDoggyBagEligible: true,
            availableForDoggyBag: 3,
            reservedForDoggyBag: 1,
            reservedQuantity: 0,
            dailyMenuId: 7,
          ),
        );

    test('émet un rappel repas et un rappel doggybag pour aujourd\'hui',
        () async {
      await notifier.emitStartupReminders(
        meals: [mealToday()],
        doggyBags: [bagToday()],
        now: now,
      );
      expect(notifier.state.items, hasLength(2));
      expect(
        notifier.state.items.map((n) => n.type),
        containsAll([
          NotificationType.mealReminder,
          NotificationType.doggybagReminder,
        ]),
      );
    });

    test('déduplication quotidienne : pas de doublon le même jour', () async {
      await notifier.emitStartupReminders(
        meals: [mealToday()],
        doggyBags: [],
        now: now,
      );
      await notifier.emitStartupReminders(
        meals: [mealToday()],
        doggyBags: [],
        now: now,
      );
      expect(notifier.state.items, hasLength(1));
    });

    test('un autre jour ré-émet (purge de l\'ancienne clé)', () async {
      await notifier.emitStartupReminders(
        meals: [mealToday()],
        doggyBags: [],
        now: now,
      );
      final tomorrowMeal = Reservation(
        id: 2,
        userId: 3,
        timeSlotId: 100,
        dishId: 42,
        status: ReservationStatus.confirmed,
        createdAt: DateTime(2026, 7, 8),
        dailyMenu: DailyMenu(
          id: 8,
          date: DateTime(2026, 7, 11),
          timeSlotCapacity: 10,
          isActive: true,
        ),
      );
      await notifier.emitStartupReminders(
        meals: [tomorrowMeal],
        doggyBags: [],
        now: DateTime(2026, 7, 11, 9, 0),
      );
      expect(notifier.state.items, hasLength(2));
    });

    test('rien pour les repas annulés ou d\'un autre jour', () async {
      final cancelled = Reservation(
        id: 3,
        userId: 3,
        timeSlotId: 100,
        dishId: 42,
        status: ReservationStatus.cancelled,
        createdAt: DateTime(2026, 7, 8),
        dailyMenu: DailyMenu(
          id: 7,
          date: DateTime(2026, 7, 10),
          timeSlotCapacity: 10,
          isActive: true,
        ),
      );
      await notifier.emitStartupReminders(
        meals: [cancelled],
        doggyBags: [],
        now: now,
      );
      expect(notifier.state.items, isEmpty);
    });
  });
}
