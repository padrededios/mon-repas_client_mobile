import 'event_dish.dart';
import 'event_time_slot.dart';
import 'reservation.dart';
import 'special_event.dart';

class EventReservation {
  const EventReservation({
    required this.id,
    required this.userId,
    required this.specialEventId,
    required this.eventTimeSlotId,
    this.starterId,
    this.mainDishId,
    this.dessertId,
    required this.status,
    required this.createdAt,
    this.specialEvent,
    this.eventTimeSlot,
    this.starter,
    this.mainDish,
    this.dessert,
  });

  final int id;
  final int userId;
  final int specialEventId;
  final int eventTimeSlotId;

  /// Choix du participant parmi les plats de l'événement (null si le
  /// service n'est pas proposé ou réservation antérieure à la fonctionnalité).
  final int? starterId;
  final int? mainDishId;
  final int? dessertId;
  final ReservationStatus status;
  final DateTime createdAt;
  final SpecialEvent? specialEvent;
  final EventTimeSlot? eventTimeSlot;
  final EventDish? starter;
  final EventDish? mainDish;
  final EventDish? dessert;

  bool get isCancelled => status == ReservationStatus.cancelled;

  factory EventReservation.fromJson(Map<String, dynamic> json) {
    EventDish? dish(Object? value) => value is Map<String, dynamic>
        ? EventDish.fromJson(value)
        : null;

    return EventReservation(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      specialEventId: (json['specialEventId'] as num).toInt(),
      eventTimeSlotId: (json['eventTimeSlotId'] as num).toInt(),
      starterId: (json['starterId'] as num?)?.toInt(),
      mainDishId: (json['mainDishId'] as num?)?.toInt(),
      dessertId: (json['dessertId'] as num?)?.toInt(),
      status: ReservationStatus.fromValue(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      specialEvent: json['specialEvent'] is Map<String, dynamic>
          ? SpecialEvent.fromJson(json['specialEvent'] as Map<String, dynamic>)
          : null,
      eventTimeSlot: json['eventTimeSlot'] is Map<String, dynamic>
          ? EventTimeSlot.fromJson(
              json['eventTimeSlot'] as Map<String, dynamic>)
          : null,
      starter: dish(json['starter']),
      mainDish: dish(json['mainDish']),
      dessert: dish(json['dessert']),
    );
  }
}
