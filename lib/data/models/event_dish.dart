/// Service auquel appartient un plat d'événement spécial.
enum EventDishType {
  starter('starter'),
  mainDish('main_dish'),
  dessert('dessert');

  const EventDishType(this.value);
  final String value;

  static EventDishType fromValue(String value) =>
      EventDishType.values.firstWhere((t) => t.value == value);
}

/// Plat proposé au choix dans le menu d'un événement spécial (équivalent
/// événementiel de [Dish], sans gestion de quantités).
class EventDish {
  const EventDish({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.specialEventId,
  });

  final int id;
  final String name;
  final String? description;
  final EventDishType type;
  final int specialEventId;

  factory EventDish.fromJson(Map<String, dynamic> json) {
    return EventDish(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      type: EventDishType.fromValue(json['type'] as String),
      specialEventId: (json['specialEventId'] as num?)?.toInt() ?? 0,
    );
  }
}
