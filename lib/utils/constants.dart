import 'dart:ui';

/// Game design constants
class GameConstants {
  // Physics (pixel-based, no Forge2D)
  static const double gravity = 1800.0;     // px/s²
  static const double bounceDamping = 0.45;
  static const double friction = 0.90;

  // Gameplay
  static const double comboTimeWindow = 1.5; // seconds
  static const int maxDropFruitLevel = 5;    // cherry..apple can be dropped
  static const double gameOverLineOffsetPx = 55.0; // px below box top = danger line

  // Legacy (kept for constants used in other places)
  static const double containerWidthRatio = 0.85;
  static const double containerHeightRatio = 0.60;
}

/// App color palette
class AppColors {
  static const Color primaryLight = Color(0xFFFFF3E0);
  static const Color primaryWarm = Color(0xFFFFCC80);
  static const Color primaryDark = Color(0xFFFF8A65);

  static const Color bgGradientTop = Color(0xFF78909C);
  static const Color bgGradientBottom = Color(0xFF546E7A);

  static const Color containerBg = Color(0xFFE8DFD5);
  static const Color containerBorder = Color(0xFFBBAAA0);

  static const Color gameOverLine = Color(0xFFE53935);
  static const Color scoreText = Color(0xFF5D4037);
  static const Color comboGold = Color(0xFFFFD600);

  static const Color buttonPrimary = Color(0xFFFF7043);
  static const Color buttonSecondary = Color(0xFFFFA726);
  static const Color cardBg = Color(0xFFFFF8E1);
  static const Color textDark = Color(0xFF3E2723);
  static const Color textLight = Color(0xFF8D6E63);
  static const Color overlay = Color(0xCC000000);

  // Fruit colors
  static const List<Color> fruitColors = [
    Color(0xFFE53935), // Cherry
    Color(0xFFE91E63), // Strawberry
    Color(0xFF7B1FA2), // Grape
    Color(0xFFFF9800), // Orange
    Color(0xFF4CAF50), // Apple - green
    Color(0xFF8BC34A), // Pear
    Color(0xFFFFCC80), // Peach
    Color(0xFFFFC107), // Pineapple
    Color(0xFF66BB6A), // Melon
    Color(0xFF388E3C), // Watermelon
  ];
}
