import '../../core/utils/dates.dart';
import 'event_time_slot.dart';

class SpecialEvent {
  const SpecialEvent({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.eventDate,
    required this.isActive,
    this.registrationDeadline,
    this.starter1,
    this.starter2,
    this.mainDish1,
    this.mainDish2,
    this.dessert1,
    this.dessert2,
    this.timeSlots,
  });

  final int id;
  final String name;
  final String description;
  final String? imageUrl;

  /// Jour de l'événement (heure locale, minuit).
  final DateTime eventDate;
  final bool isActive;

  /// Dernier jour d'inscription (inclus : clôture en fin de journée).
  final DateTime? registrationDeadline;
  final String? starter1;
  final String? starter2;
  final String? mainDish1;
  final String? mainDish2;
  final String? dessert1;
  final String? dessert2;
  final List<EventTimeSlot>? timeSlots;

  /// Les inscriptions ferment après la fin de journée (23:59:59) de la deadline.
  bool isRegistrationClosed({DateTime? now}) {
    final deadline = registrationDeadline;
    if (deadline == null) return false;
    final ref = now ?? DateTime.now();
    final endOfDay =
        DateTime(deadline.year, deadline.month, deadline.day, 23, 59, 59);
    return ref.isAfter(endOfDay);
  }

  factory SpecialEvent.fromJson(Map<String, dynamic> json) {
    final deadline = json['registrationDeadline'] as String?;
    return SpecialEvent(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      eventDate: parseDay(json['eventDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
      registrationDeadline: deadline != null ? parseDay(deadline) : null,
      starter1: json['starter1'] as String?,
      starter2: json['starter2'] as String?,
      mainDish1: json['mainDish1'] as String?,
      mainDish2: json['mainDish2'] as String?,
      dessert1: json['dessert1'] as String?,
      dessert2: json['dessert2'] as String?,
      timeSlots: (json['timeSlots'] as List<dynamic>?)
          ?.map((s) => EventTimeSlot.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
