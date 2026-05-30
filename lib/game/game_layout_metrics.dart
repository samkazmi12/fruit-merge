/// Immutable snapshot of the computed game-jar layout dimensions.
///
/// Consolidates the six positional doubles that describe the game jar into a
/// single typed object, reducing parameter lists when passing layout data
/// into helper methods and extracted widgets.
///
/// Instantiate from [_GameScreenState] after the box is computed in
/// `_initBox`, then thread the single [GameLayoutMetrics] reference instead
/// of individual doubles.
class GameLayoutMetrics {
  final double boxLeft;
  final double boxRight;
  final double boxTop;
  final double boxBottom;
  final double dropY;
  final double gameOverLineY;
  final double hudH;
  final double cardsH;
  final double adH;

  const GameLayoutMetrics({
    required this.boxLeft,
    required this.boxRight,
    required this.boxTop,
    required this.boxBottom,
    required this.dropY,
    required this.gameOverLineY,
    required this.hudH,
    required this.cardsH,
    required this.adH,
  });

  double get boxWidth => boxRight - boxLeft;
  double get boxHeight => boxBottom - boxTop;
  double get centerX => (boxLeft + boxRight) / 2;
}
