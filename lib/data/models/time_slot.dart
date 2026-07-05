import 'slot_capacity.dart';

class TimeSlot with SlotCapacity {
  const TimeSlot({
    required this.id,
    required this.dailyMenuId,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.reservedCount,
  });

  final int id;
  final int dailyMenuId;

  /// "HH:MM:SS"
  final String startTime;
  final String endTime;
  @override
  final int capacity;
  @override
  final int reservedCount;

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: (json['id'] as num).toInt(),
      dailyMenuId: (json['dailyMenuId'] as num).toInt(),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      capacity: (json['capacity'] as num).toInt(),
      reservedCount: (json['reservedCount'] as num?)?.toInt() ?? 0,
    );
  }
}
