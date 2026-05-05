import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_merge/models/fruit_data.dart';

void main() {
  test('Fruit evolution chain is complete', () {
    final allFruits = FruitData.allFruits;
    expect(allFruits.length, 10);
    expect(allFruits.first.type, FruitType.cherry);
    expect(allFruits.last.type, FruitType.watermelon);
  });

  test('Each fruit has increasing radius', () {
    final allFruits = FruitData.allFruits;
    for (int i = 1; i < allFruits.length; i++) {
      expect(allFruits[i].radius, greaterThan(allFruits[i - 1].radius));
    }
  });

  test('Watermelon cannot evolve', () {
    final watermelon = FruitData.fromType(FruitType.watermelon);
    expect(watermelon.canEvolve, false);
    expect(watermelon.nextType, null);
  });

  test('Cherry evolves to strawberry', () {
    final cherry = FruitData.fromType(FruitType.cherry);
    expect(cherry.canEvolve, true);
    expect(cherry.nextType, FruitType.strawberry);
  });

  test('Only first 5 fruits are droppable', () {
    final droppable = FruitData.droppableFruits;
    expect(droppable.length, 5);
    expect(droppable.last.type, FruitType.apple);
  });
}
