import 'slot_capacity.dart';

class EventTimeSlot with SlotCapacity {
  const EventTimeSlot({
    required this.id,
    required this.specialEventId,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.reservedCount,
  });

  final int id;
  final int specialEventId;

  /// "HH:MM:SS"
  final String startTime;
  final String endTime;
  @override
  final int capacity;
  @override
  final int reservedCount;

  factory EventTimeSlot.fromJson(Map<String, dynamic> json) {
    // Tolère les deux variantes de sérialisation de l'API (voir TimeSlot).
    return EventTimeSlot(
      id: (json['id'] as num).toInt(),
      specialEventId: (json['specialEventId'] as num?)?.toInt() ?? 0,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      capacity: ((json['capacity'] ?? json['maxCapacity']) as num).toInt(),
      reservedCount:
          ((json['reservedCount'] ?? json['currentReservations']) as num?)
                  ?.toInt() ??
              0,
    );
  }
}
