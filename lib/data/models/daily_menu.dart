import '../../core/utils/dates.dart';
import 'dish.dart';
import 'time_slot.dart';

class DailyMenu {
  const DailyMenu({
    required this.id,
    required this.date,
    required this.timeSlotCapacity,
    required this.isActive,
    this.doggyBagDeadline,
    this.dishes = const [],
    this.timeSlots,
  });

  final int id;

  /// Jour du menu (heure locale, minuit).
  final DateTime date;
  final int timeSlotCapacity;
  final bool isActive;

  /// "HH:MM:SS"
  final String? doggyBagDeadline;
  final List<Dish> dishes;
  final List<TimeSlot>? timeSlots;

  factory DailyMenu.fromJson(Map<String, dynamic> json) {
    return DailyMenu(
      id: (json['id'] as num).toInt(),
      date: parseDay(json['date'] as String),
      timeSlotCapacity: (json['timeSlotCapacity'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      doggyBagDeadline: json['doggyBagDeadline'] as String?,
      dishes: (json['dishes'] as List<dynamic>? ?? [])
          .map((d) => Dish.fromJson(d as Map<String, dynamic>))
          .toList(),
      timeSlots: (json['timeSlots'] as List<dynamic>?)
          ?.map((s) => TimeSlot.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
