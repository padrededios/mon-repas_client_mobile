import 'notification_item.dart';

/// Préférences par type de notification (tous actifs par défaut, comme la
/// webapp).
class NotificationPreferences {
  const NotificationPreferences({
    this.doggybagReminder = true,
    this.eventNew = true,
    this.mealReminder = true,
    this.system = true,
  });

  final bool doggybagReminder;
  final bool eventNew;
  final bool mealReminder;
  final bool system;

  bool isEnabled(NotificationType type) => switch (type) {
        NotificationType.doggybagReminder => doggybagReminder,
        NotificationType.eventNew => eventNew,
        NotificationType.mealReminder => mealReminder,
        NotificationType.system => system,
      };

  NotificationPreferences withType(NotificationType type, bool enabled) {
    return NotificationPreferences(
      doggybagReminder: type == NotificationType.doggybagReminder
          ? enabled
          : doggybagReminder,
      eventNew: type == NotificationType.eventNew ? enabled : eventNew,
      mealReminder:
          type == NotificationType.mealReminder ? enabled : mealReminder,
      system: type == NotificationType.system ? enabled : system,
    );
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      doggybagReminder: json['doggybag_reminder'] as bool? ?? true,
      eventNew: json['event_new'] as bool? ?? true,
      mealReminder: json['meal_reminder'] as bool? ?? true,
      system: json['system'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'doggybag_reminder': doggybagReminder,
        'event_new': eventNew,
        'meal_reminder': mealReminder,
        'system': system,
      };
}

const notificationLabels = {
  NotificationType.doggybagReminder: 'Rappel DoggyBag',
  NotificationType.eventNew: 'Nouveaux événements',
  NotificationType.mealReminder: 'Rappel de repas',
  NotificationType.system: 'Notifications système',
};

const notificationDescriptions = {
  NotificationType.doggybagReminder:
      'Me rappeler de récupérer mon DoggyBag avant la limite',
  NotificationType.eventNew: "M'alerter des nouveaux événements disponibles",
  NotificationType.mealReminder:
      'Me rappeler de mes réservations de repas du jour',
  NotificationType.system: 'Recevoir les notifications système importantes',
};
