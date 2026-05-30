import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../game/fruit_physics.dart';
import '../../game/game_painter.dart';
import '../../models/fruit_data.dart';

/// Wraps the game [CustomPaint] canvas in a [RepaintBoundary] so that
/// physics repaints are isolated from the rest of the widget tree.
class GameCanvasStage extends StatelessWidget {
  final List<FruitParticle> fruits;
  final List<MergeParticle> particles;
  final double boxLeft;
  final double boxRight;
  final double boxTop;
  final double boxBottom;
  final double gameOverLineY;
  final double dangerLevel;
  final Map<FruitType, ui.Image> fruitImages;
  final List<CloudState> clouds;
  final ui.Image? cloudImage;
  final ui.Image? branchImage;
  final double dropX;
  final double dropY;
  final double dropFruitRadius;
  final bool showDropper;
  final Size size;
  final bool boxReady;

  const GameCanvasStage({
    super.key,
    required this.fruits,
    required this.particles,
    required this.boxLeft,
    required this.boxRight,
    required this.boxTop,
    required this.boxBottom,
    required this.gameOverLineY,
    required this.dangerLevel,
    required this.fruitImages,
    required this.clouds,
    this.cloudImage,
    this.branchImage,
    required this.dropX,
    required this.dropY,
    required this.dropFruitRadius,
    required this.showDropper,
    required this.size,
    required this.boxReady,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: boxReady
          ? RepaintBoundary(
              child: CustomPaint(
                painter: GamePainter(
                  fruits: fruits,
                  particles: particles,
                  boxLeft: boxLeft,
                  boxRight: boxRight,
                  boxTop: boxTop,
                  boxBottom: boxBottom,
                  gameOverLineY: gameOverLineY,
                  dangerLevel: dangerLevel,
                  fruitImages: fruitImages,
                  clouds: clouds,
                  cloudImage: cloudImage,
                  branchImage: branchImage,
                  dropX: dropX,
                  dropY: dropY,
                  dropFruitRadius: dropFruitRadius,
                  showDropper: showDropper,
                ),
                size: size,
              ),
            )
          : const SizedBox(),
    );
  }
}
