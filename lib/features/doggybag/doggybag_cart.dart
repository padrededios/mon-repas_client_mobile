import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/dates.dart';
import '../../data/models/dish.dart';

class DoggyBagCartItem {
  const DoggyBagCartItem({
    required this.dish,
    required this.date,
    required this.quantity,
  });

  final Dish dish;

  /// Jour de retrait (jour du menu).
  final DateTime date;
  final int quantity;

  DoggyBagCartItem copyWith({int? quantity}) => DoggyBagCartItem(
        dish: dish,
        date: date,
        quantity: quantity ?? this.quantity,
      );
}

/// Panier doggybag local : quantité par plat plafonnée à min(5, dispo),
/// retrait automatique à quantité 0.
class DoggyBagCartNotifier extends StateNotifier<List<DoggyBagCartItem>> {
  DoggyBagCartNotifier() : super(const []);

  static int maxFor(Dish dish) =>
      dish.availableForDoggyBag < 5 ? dish.availableForDoggyBag : 5;

  void add(Dish dish, DateTime date) {
    final index = state.indexWhere((i) => i.dish.id == dish.id);
    if (index == -1) {
      if (maxFor(dish) < 1) return;
      state = [...state, DoggyBagCartItem(dish: dish, date: date, quantity: 1)];
      return;
    }
    increment(dish.id);
  }

  void increment(int dishId) {
    state = [
      for (final item in state)
        if (item.dish.id == dishId)
          item.copyWith(
            quantity: item.quantity < maxFor(item.dish)
                ? item.quantity + 1
                : item.quantity,
          )
        else
          item,
    ];
  }

  void decrement(int dishId) {
    state = [
      for (final item in state)
        if (item.dish.id == dishId)
          if (item.quantity > 1) item.copyWith(quantity: item.quantity - 1)
          else
            ...[]
        else
          item,
    ];
  }

  void remove(int dishId) {
    state = state.where((i) => i.dish.id != dishId).toList();
  }

  void clear() => state = const [];

  int quantityOf(int dishId) {
    for (final item in state) {
      if (item.dish.id == dishId) return item.quantity;
    }
    return 0;
  }

  int get totalItems => state.fold(0, (sum, i) => sum + i.quantity);

  /// Groupé par jour de retrait (pour l'affichage du panier).
  Map<DateTime, List<DoggyBagCartItem>> groupedByDate() {
    final map = <DateTime, List<DoggyBagCartItem>>{};
    for (final item in state) {
      map.putIfAbsent(item.date, () => []).add(item);
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }
}

/// Libellé de deadline « Avant HH:MM ».
String deadlineLabel(String deadline) => 'Avant ${formatTimeHm(deadline)}';
