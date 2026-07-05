import 'daily_menu.dart';
import 'dish.dart';
import 'time_slot.dart';

enum ReservationStatus {
  confirmed('confirmed'),
  cancelled('cancelled');

  const ReservationStatus(this.value);

  final String value;

  static ReservationStatus fromValue(String value) =>
      ReservationStatus.values.firstWhere((s) => s.value == value);
}

class Reservation {
  const Reservation({
    required this.id,
    required this.userId,
    required this.timeSlotId,
    required this.dishId,
    this.starterId,
    this.dessertId,
    required this.status,
    required this.createdAt,
    this.timeSlot,
    this.dailyMenu,
    this.dish,
    this.starter,
    this.dessert,
  });

  final int id;
  final int userId;
  final int timeSlotId;
  final int dishId;
  final int? starterId;
  final int? dessertId;
  final ReservationStatus status;
  final DateTime createdAt;
  final TimeSlot? timeSlot;
  final DailyMenu? dailyMenu;
  final Dish? dish;
  final Dish? starter;
  final Dish? dessert;

  bool get isCancelled => status == ReservationStatus.cancelled;

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      timeSlotId: (json['timeSlotId'] as num).toInt(),
      dishId: (json['dishId'] as num).toInt(),
      starterId: (json['starterId'] as num?)?.toInt(),
      dessertId: (json['dessertId'] as num?)?.toInt(),
      status: ReservationStatus.fromValue(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      timeSlot: json['timeSlot'] is Map<String, dynamic>
          ? TimeSlot.fromJson(json['timeSlot'] as Map<String, dynamic>)
          : null,
      dailyMenu: json['dailyMenu'] is Map<String, dynamic>
          ? DailyMenu.fromJson(json['dailyMenu'] as Map<String, dynamic>)
          : null,
      dish: json['dish'] is Map<String, dynamic>
          ? Dish.fromJson(json['dish'] as Map<String, dynamic>)
          : null,
      starter: json['starter'] is Map<String, dynamic>
          ? Dish.fromJson(json['starter'] as Map<String, dynamic>)
          : null,
      dessert: json['dessert'] is Map<String, dynamic>
          ? Dish.fromJson(json['dessert'] as Map<String, dynamic>)
          : null,
    );
  }
}
