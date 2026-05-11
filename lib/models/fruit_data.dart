import 'dart:ui';
import '../utils/constants.dart';

/// Fruit evolution levels
enum FruitType {
  cherry,
  strawberry,
  grape,
  orange,
  apple,
  pear,
  peach,
  pineapple,
  melon,
  watermelon,
}

/// Data class holding all properties for a fruit type
class FruitData {
  final FruitType type;
  final int level;
  final String name;
  final String emoji;
  final double radiusPx; // radius in SCREEN PIXELS
  final double mass;
  final int points;
  final Color color;

  const FruitData({
    required this.type,
    required this.level,
    required this.name,
    required this.emoji,
    required this.radiusPx,
    required this.mass,
    required this.points,
    required this.color,
  });

  // Keep 'radius' as alias for backward compat
  double get radius => radiusPx;

  /// Whether this fruit can evolve further
  bool get canEvolve => type != FruitType.watermelon;

  /// Get the next fruit in the evolution chain
  FruitType? get nextType {
    if (!canEvolve) return null;
    return FruitType.values[type.index + 1];
  }

  /// Get FruitData for the evolved fruit
  FruitData? get evolvedFruit {
    if (nextType == null) return null;
    return FruitData.fromType(nextType!);
  }

  /// Factory to create FruitData from a FruitType
  factory FruitData.fromType(FruitType type) => _fruitDataMap[type]!;

  /// All fruit data in evolution order
  static final Map<FruitType, FruitData> _fruitDataMap = {
    FruitType.cherry: FruitData(
      type: FruitType.cherry,
      level: 1,
      name: 'Cherry',
      emoji: '🍒',
      radiusPx: 12,
      mass: 1.0,
      points: 1,
      color: AppColors.fruitColors[0],
    ),
    FruitType.strawberry: FruitData(
      type: FruitType.strawberry,
      level: 2,
      name: 'Strawberry',
      emoji: '🍓',
      radiusPx: 16,
      mass: 2.0,
      points: 3,
      color: AppColors.fruitColors[1],
    ),
    FruitType.grape: FruitData(
      type: FruitType.grape,
      level: 3,
      name: 'Grape',
      emoji: '🍇',
      radiusPx: 20,
      mass: 3.0,
      points: 6,
      color: AppColors.fruitColors[2],
    ),
    FruitType.orange: FruitData(
      type: FruitType.orange,
      level: 4,
      name: 'Orange',
      emoji: '🍊',
      radiusPx: 25,
      mass: 5.0,
      points: 10,
      color: AppColors.fruitColors[3],
    ),
    FruitType.apple: FruitData(
      type: FruitType.apple,
      level: 5,
      name: 'Apple',
      emoji: '🍎',
      radiusPx: 30,
      mass: 7.0,
      points: 15,
      color: AppColors.fruitColors[4],
    ),
    FruitType.pear: FruitData(
      type: FruitType.pear,
      level: 6,
      name: 'Pear',
      emoji: '🍐',
      radiusPx: 36,
      mass: 10.0,
      points: 21,
      color: AppColors.fruitColors[5],
    ),
    FruitType.peach: FruitData(
      type: FruitType.peach,
      level: 7,
      name: 'Peach',
      emoji: '🍑',
      radiusPx: 42,
      mass: 13.0,
      points: 28,
      color: AppColors.fruitColors[6],
    ),
    FruitType.pineapple: FruitData(
      type: FruitType.pineapple,
      level: 8,
      name: 'Pineapple',
      emoji: '🍍',
      radiusPx: 48,
      mass: 17.0,
      points: 36,
      color: AppColors.fruitColors[7],
    ),
    FruitType.melon: FruitData(
      type: FruitType.melon,
      level: 9,
      name: 'Melon',
      emoji: '🍈',
      radiusPx: 55,
      mass: 22.0,
      points: 45,
      color: AppColors.fruitColors[8],
    ),
    FruitType.watermelon: FruitData(
      type: FruitType.watermelon,
      level: 10,
      name: 'Watermelon',
      emoji: '🍉',
      radiusPx: 62,
      mass: 28.0,
      points: 55,
      color: AppColors.fruitColors[9],
    ),
  };

  /// Get all fruits in evolution order
  static List<FruitData> get allFruits =>
      FruitType.values.map((t) => FruitData.fromType(t)).toList();

  /// Get only droppable fruits (first N types)
  static List<FruitData> get droppableFruits =>
      allFruits.where((f) => f.level <= GameConstants.maxDropFruitLevel).toList();
}
