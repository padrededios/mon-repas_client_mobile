enum NotificationType {
  doggybagReminder('doggybag_reminder'),
  eventNew('event_new'),
  mealReminder('meal_reminder'),
  system('system');

  const NotificationType(this.value);

  final String value;

  /// Type inconnu → system (les payloads persistés doivent survivre
  /// aux évolutions de l'app).
  static NotificationType fromValue(String value) =>
      NotificationType.values.firstWhere(
        (t) => t.value == value,
        orElse: () => NotificationType.system,
      );
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
    this.data,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  NotificationItem copyWith({bool? read}) => NotificationItem(
        id: id,
        type: type,
        title: title,
        message: message,
        read: read ?? this.read,
        createdAt: createdAt,
        data: data,
      );

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      type: NotificationType.fromValue(json['type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.value,
        'title': title,
        'message': message,
        'read': read,
        'createdAt': createdAt.toIso8601String(),
        if (data != null) 'data': data,
      };
}
