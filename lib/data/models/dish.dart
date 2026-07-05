enum DishType {
  starter1('starter_1'),
  starter2('starter_2'),
  starter3('starter_3'),
  starterDaily('starter_daily'),
  hotDish1('hot_dish_1'),
  hotDish2('hot_dish_2'),
  dailySpecial('daily_special'),
  dessert1('dessert_1'),
  dessert2('dessert_2'),
  dessert3('dessert_3'),
  dessertDaily('dessert_daily');

  const DishType(this.value);

  final String value;

  static DishType fromValue(String value) =>
      DishType.values.firstWhere((t) => t.value == value);
}

class Dish {
  const Dish({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.isDoggyBagEligible,
    required this.availableForDoggyBag,
    required this.reservedForDoggyBag,
    this.availableQuantity,
    required this.reservedQuantity,
    required this.dailyMenuId,
    this.doggyBagDeadline,
  });

  final int id;
  final String name;
  final String? description;
  final DishType type;
  final bool isDoggyBagEligible;
  final int availableForDoggyBag;
  final int reservedForDoggyBag;

  /// null = quantité illimitée.
  final int? availableQuantity;
  final int reservedQuantity;
  final int dailyMenuId;

  /// Deadline doggybag (HH:MM:SS) remontée par `GET /doggybag/available`
  /// via le menu imbriqué.
  final String? doggyBagDeadline;

  factory Dish.fromJson(Map<String, dynamic> json) {
    final nestedMenu = json['dailyMenu'];
    return Dish(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      type: DishType.fromValue(json['type'] as String),
      isDoggyBagEligible: json['isDoggyBagEligible'] as bool? ?? false,
      availableForDoggyBag: (json['availableForDoggyBag'] as num?)?.toInt() ?? 0,
      reservedForDoggyBag: (json['reservedForDoggyBag'] as num?)?.toInt() ?? 0,
      availableQuantity: (json['availableQuantity'] as num?)?.toInt(),
      reservedQuantity: (json['reservedQuantity'] as num?)?.toInt() ?? 0,
      dailyMenuId: (json['dailyMenuId'] as num?)?.toInt() ?? 0,
      doggyBagDeadline: nestedMenu is Map<String, dynamic>
          ? nestedMenu['doggyBagDeadline'] as String?
          : null,
    );
  }
}
