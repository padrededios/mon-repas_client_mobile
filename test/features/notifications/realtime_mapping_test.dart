import 'package:flutter_test/flutter_test.dart';
import 'package:mon_repas_client_mobile/data/models/notification_item.dart';
import 'package:mon_repas_client_mobile/features/notifications/realtime_mapping.dart';

void main() {
  test('reservation:confirmed → meal_reminder', () {
    final n = notificationForEvent('reservation:confirmed', {});
    expect(n?.type, NotificationType.mealReminder);
    expect(n?.title, 'Réservation confirmée');
  });

  test('doggybag:reservation-updated confirmé → doggybag_reminder', () {
    final n = notificationForEvent('doggybag:reservation-updated', {
      'reservation': {'status': 'confirmed'},
    });
    expect(n?.type, NotificationType.doggybagReminder);
  });

  test('doggybag:reservation-updated annulé → aucune notification', () {
    final n = notificationForEvent('doggybag:reservation-updated', {
      'reservation': {'status': 'cancelled'},
    });
    expect(n, isNull);
  });

  test('event:created → event_new avec le nom de l\'événement', () {
    final n = notificationForEvent('event:created', {
      'event': {'name': 'Barbecue d\'été'},
    });
    expect(n?.type, NotificationType.eventNew);
    expect(n?.message, 'Barbecue d\'été');
  });

  test('event:registration-reminder → message du serveur', () {
    final n = notificationForEvent('event:registration-reminder', {
      'message': 'Plus que 2 jours !',
    });
    expect(n?.type, NotificationType.eventNew);
    expect(n?.message, 'Plus que 2 jours !');
  });

  test('system:notification → system', () {
    final n = notificationForEvent('system:notification', {'message': 'Info'});
    expect(n?.type, NotificationType.system);
  });

  test('événements de pure invalidation → null', () {
    expect(notificationForEvent('menu:updated', {}), isNull);
    expect(notificationForEvent('reservation:new', {}), isNull);
    expect(notificationForEvent('doggybag:availability-updated', {}), isNull);
    expect(notificationForEvent('event:timeslot-updated', {}), isNull);
  });
}
