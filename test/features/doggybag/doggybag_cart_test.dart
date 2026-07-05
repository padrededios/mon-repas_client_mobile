import 'package:flutter_test/flutter_test.dart';
import 'package:mon_repas_client_mobile/data/models/dish.dart';
import 'package:mon_repas_client_mobile/features/doggybag/doggybag_cart.dart';

Dish dish(int id, {int available = 10}) => Dish(
      id: id,
      name: 'Plat-$id',
      type: DishType.hotDish1,
      isDoggyBagEligible: true,
      availableForDoggyBag: available,
      reservedForDoggyBag: 0,
      reservedQuantity: 0,
      dailyMenuId: 7,
    );

final day = DateTime(2026, 7, 10);

void main() {
  late DoggyBagCartNotifier cart;

  setUp(() {
    cart = DoggyBagCartNotifier();
  });

  test('add ajoute un item quantité 1, add répété incrémente', () {
    final d = dish(42);
    cart.add(d, day);
    expect(cart.state.single.quantity, 1);
    cart.add(d, day);
    expect(cart.state.single.quantity, 2);
  });

  test('quantité plafonnée à min(5, dispo) — cas dispo abondante', () {
    final d = dish(42, available: 10);
    for (var i = 0; i < 8; i++) {
      cart.add(d, day);
    }
    expect(cart.state.single.quantity, 5);
  });

  test('quantité plafonnée à min(5, dispo) — cas dispo faible', () {
    final d = dish(42, available: 3);
    for (var i = 0; i < 8; i++) {
      cart.add(d, day);
    }
    expect(cart.state.single.quantity, 3);
  });

  test('decrement retire l\'item à 0', () {
    final d = dish(42);
    cart.add(d, day);
    cart.decrement(42);
    expect(cart.state, isEmpty);
  });

  test('remove supprime l\'item quelle que soit la quantité', () {
    final d = dish(42);
    cart.add(d, day);
    cart.add(d, day);
    cart.remove(42);
    expect(cart.state, isEmpty);
  });

  test('items distincts par plat, groupés par date à l\'affichage', () {
    cart.add(dish(1), day);
    cart.add(dish(2), day);
    cart.add(dish(3), DateTime(2026, 7, 11));
    expect(cart.state, hasLength(3));
    final grouped = cart.groupedByDate();
    expect(grouped.keys, hasLength(2));
    expect(grouped[day], hasLength(2));
  });

  test('totalItems et clear', () {
    cart.add(dish(1), day);
    cart.add(dish(1), day);
    cart.add(dish(2), day);
    expect(cart.totalItems, 3);
    cart.clear();
    expect(cart.state, isEmpty);
  });

  test('quantityOf renvoie 0 pour un plat absent', () {
    expect(cart.quantityOf(99), 0);
  });
}
