import '../../data/models/notification_item.dart';

/// Notification in-app à créer pour un événement WebSocket donné
/// (null = pas de notification, seulement des invalidations de cache).
({NotificationType type, String title, String message})? notificationForEvent(
  String event,
  dynamic data,
) {
  switch (event) {
    case 'reservation:confirmed':
      return (
        type: NotificationType.mealReminder,
        title: 'Réservation confirmée',
        message: 'Votre repas est bien réservé.',
      );
    case 'doggybag:reservation-updated':
      final status = data is Map<String, dynamic>
          ? ((data['reservation'] as Map<String, dynamic>?)?['status']
              as String?)
          : null;
      if (status != 'confirmed') return null;
      return (
        type: NotificationType.doggybagReminder,
        title: 'DoggyBag confirmé',
        message: 'Votre DoggyBag est réservé.',
      );
    case 'event:created':
      final name = data is Map<String, dynamic>
          ? ((data['event'] as Map<String, dynamic>?)?['name'] as String?)
          : null;
      return (
        type: NotificationType.eventNew,
        title: 'Nouvel événement disponible',
        message: name ?? 'Un nouvel événement vient d\'être publié.',
      );
    case 'event:registration-reminder':
      final message = data is Map<String, dynamic>
          ? data['message'] as String?
          : null;
      return (
        type: NotificationType.eventNew,
        title: 'Inscrivez-vous maintenant !',
        message: message ?? 'La clôture des inscriptions approche.',
      );
    case 'system:notification':
      final message = data is Map<String, dynamic>
          ? data['message'] as String?
          : null;
      return (
        type: NotificationType.system,
        title: 'Information',
        message: message ?? '',
      );
    default:
      return null;
  }
}
