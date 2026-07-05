import 'event_time_slot.dart';
import 'reservation.dart';
import 'special_event.dart';

class EventReservation {
  const EventReservation({
    required this.id,
    required this.userId,
    required this.specialEventId,
    required this.eventTimeSlotId,
    required this.status,
    required this.createdAt,
    this.specialEvent,
    this.eventTimeSlot,
  });

  final int id;
  final int userId;
  final int specialEventId;
  final int eventTimeSlotId;
  final ReservationStatus status;
  final DateTime createdAt;
  final SpecialEvent? specialEvent;
  final EventTimeSlot? eventTimeSlot;

  bool get isCancelled => status == ReservationStatus.cancelled;

  factory EventReservation.fromJson(Map<String, dynamic> json) {
    return EventReservation(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      specialEventId: (json['specialEventId'] as num).toInt(),
      eventTimeSlotId: (json['eventTimeSlotId'] as num).toInt(),
      status: ReservationStatus.fromValue(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      specialEvent: json['specialEvent'] is Map<String, dynamic>
          ? SpecialEvent.fromJson(json['specialEvent'] as Map<String, dynamic>)
          : null,
      eventTimeSlot: json['eventTimeSlot'] is Map<String, dynamic>
          ? EventTimeSlot.fromJson(
              json['eventTimeSlot'] as Map<String, dynamic>)
          : null,
    );
  }
}
