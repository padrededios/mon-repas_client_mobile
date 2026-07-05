import '../../core/utils/dates.dart';
import 'dish.dart';

enum DoggyBagStatus {
  confirmed('confirmed'),
  cancelled('cancelled'),
  pickedUp('picked_up');

  const DoggyBagStatus(this.value);

  final String value;

  static DoggyBagStatus fromValue(String value) =>
      DoggyBagStatus.values.firstWhere((s) => s.value == value);
}

class DoggyBagReservation {
  const DoggyBagReservation({
    required this.id,
    required this.userId,
    required this.dishId,
    required this.quantity,
    required this.pickupDate,
    required this.status,
    required this.createdAt,
    this.dish,
  });

  final int id;
  final int userId;
  final int dishId;
  final int quantity;

  /// Jour de retrait (heure locale, minuit).
  final DateTime pickupDate;
  final DoggyBagStatus status;
  final DateTime createdAt;
  final Dish? dish;

  factory DoggyBagReservation.fromJson(Map<String, dynamic> json) {
    return DoggyBagReservation(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      dishId: (json['dishId'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      pickupDate: parseDay(json['pickupDate'] as String),
      status: DoggyBagStatus.fromValue(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      dish: json['dish'] is Map<String, dynamic>
          ? Dish.fromJson(json['dish'] as Map<String, dynamic>)
          : null,
    );
  }
}
