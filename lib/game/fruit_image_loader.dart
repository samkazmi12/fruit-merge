import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../models/fruit_data.dart';

/// Top-level cache that holds the decoded fruit images for the entire app session.
///
/// Populated on the first call to [loadGameImages] (fired by [LoadingScreen]
/// during its startup animation) and returned as-is on every subsequent call.
/// This ensures [GameScreen] always finds the cache warm before it starts
/// rendering, so fruits are drawn with sprites rather than emoji placeholders.
({Map<FruitType, ui.Image> fruitImages, ui.Image? cloudImage, ui.Image? branchImage})?
    _imageCache;

/// Loads all fruit sprites and scene-decoration images from the asset bundle.
///
/// Results are cached after the first call — subsequent calls return immediately
/// with the same [ui.Image] objects without any I/O.  The loading screen fires
/// this during its 4.5 s animation so that [GameScreen] always finds the cache
/// warm by the time the user presses Play.
///
/// Any individual asset that fails to load is silently skipped so the game
/// degrades gracefully when an asset is missing.
Future<({Map<FruitType, ui.Image> fruitImages, ui.Image? cloudImage, ui.Image? branchImage})>
    loadGameImages() async {
  if (_imageCache != null) return _imageCache!;

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

  _imageCache = (
    fruitImages: fruitImages,
    cloudImage: cloudImage,
    branchImage: branchImage,
  );
  return _imageCache!;
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
