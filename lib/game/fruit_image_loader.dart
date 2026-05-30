import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../models/fruit_data.dart';

/// Loads all fruit sprites and scene-decoration images from the asset bundle.
///
/// Returns a record with the fruit-image map and the two scene images.
/// Any individual asset that fails to load is silently skipped so the game
/// degrades gracefully when an asset is missing.
Future<({Map<FruitType, ui.Image> fruitImages, ui.Image? cloudImage, ui.Image? branchImage})>
    loadGameImages() async {
  const sprites = {
    FruitType.cherry: 'assets/images/fruit_cherry.png',
    FruitType.strawberry: 'assets/images/fruit_strawberry.png',
    FruitType.grape: 'assets/images/fruit_grape.png',
    FruitType.orange: 'assets/images/fruit_orange.png',
    FruitType.apple: 'assets/images/fruit_apple.png',
    FruitType.pear: 'assets/images/fruit_pear.png',
    FruitType.peach: 'assets/images/fruit_peach.png',
    FruitType.pineapple: 'assets/images/fruit_pineapple.png',
    FruitType.melon: 'assets/images/fruit_melon.png',
    FruitType.watermelon: 'assets/images/fruit_watermelon.png',
  };

  final fruitImages = <FruitType, ui.Image>{};
  for (final entry in sprites.entries) {
    final img = await _loadImage(entry.value);
    if (img != null) fruitImages[entry.key] = img;
  }

  final cloudImage = await _loadImage('assets/images/asset_cloud.png');
  final branchImage = await _loadImage('assets/images/asset_branch.png');

  return (
    fruitImages: fruitImages,
    cloudImage: cloudImage,
    branchImage: branchImage,
  );
}

Future<ui.Image?> _loadImage(String assetPath) async {
  try {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  } catch (_) {
    return null;
  }
}
