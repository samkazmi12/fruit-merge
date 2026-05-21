import 'dart:math' show pi;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/fruit_data.dart';
import 'fruit_physics.dart';

class GamePainter extends CustomPainter {
  final List<FruitParticle> fruits;
  final List<MergeParticle> particles;
  final double boxLeft;
  final double boxRight;
  final double boxTop;
  final double boxBottom;
  final double gameOverLineY;
  final double dangerLevel;
  final Map<FruitType, ui.Image> fruitImages;

  GamePainter({
    required this.fruits,
    required this.particles,
    required this.boxLeft,
    required this.boxRight,
    required this.boxTop,
    required this.boxBottom,
    required this.gameOverLineY,
    this.dangerLevel = 0,
    this.fruitImages = const {},
  });

  // ── Pre-allocated Paints (created once, reused every frame) ──────
  static final Paint _bgPaint = Paint()
    ..color = const Color(0xE0E8DFD5);
  static final Paint _innerShadowPaint = Paint();
  static final Paint _dividerPaint = Paint()
    ..color = const Color(0x2EFFFFFF)
    ..strokeWidth = 2.0;
  static final Paint _glowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
    ..strokeWidth = 18;
  static final Paint _dangerLinePaint = Paint()
    ..color = const Color(0xBBE53935)
    ..strokeWidth = 1.8;
  static final Paint _wallPaint = Paint()
    ..color = const Color(0xFFBBAAA0)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.5
    ..strokeCap = StrokeCap.round;
  static final Paint _shinePaint = Paint()
    ..color = const Color(0x47FFFFFF)
    ..strokeWidth = 3.5;
  static final Paint _particlePaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    _drawContainer(canvas);
    _drawParticles(canvas);
    _drawFruits(canvas);
  }

  // ── Container ────────────────────────────────────────────────────
  void _drawContainer(Canvas canvas) {
    final w = boxRight - boxLeft;

    // Background
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(boxLeft, boxTop, boxRight, boxBottom,
          bottomLeft: const Radius.circular(14),
          bottomRight: const Radius.circular(14)),
      _bgPaint,
    );

    // Inner shadow at top (const gradient avoids allocation; only createShader allocates)
    final shadowRect = Rect.fromLTWH(boxLeft, boxTop, w, 28);
    _innerShadowPaint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x14000000), Colors.transparent],
    ).createShader(shadowRect);
    canvas.drawRect(shadowRect, _innerShadowPaint);

    // Centre divider line
    canvas.drawLine(
      Offset(boxLeft + w / 2, boxTop),
      Offset(boxLeft + w / 2, boxBottom),
      _dividerPaint,
    );

    // ── Danger glow on walls ──────────────────────────────────────
    if (dangerLevel > 0) {
      _glowPaint.color = Color.lerp(
        const Color(0xFFFFB74D),
        const Color(0xFFE53935),
        dangerLevel,
      )!.withValues(alpha: dangerLevel.clamp(0.0, 1.0) * 0.55);
      canvas.drawLine(Offset(boxLeft, boxTop), Offset(boxLeft, boxBottom), _glowPaint);
      canvas.drawLine(Offset(boxRight, boxTop), Offset(boxRight, boxBottom), _glowPaint);
    }

    // ── Danger / game-over dashed line ────────────────────────────
    const dash = 12.0, gap = 7.0;
    var x = boxLeft + 4.0;
    while (x < boxRight - 4.0) {
      final xEnd = (x + dash).clamp(boxLeft, boxRight - 4.0);
      canvas.drawLine(Offset(x, gameOverLineY), Offset(xEnd, gameOverLineY), _dangerLinePaint);
      x += dash + gap;
    }

    // ── Walls ─────────────────────────────────────────────────────
    canvas.drawLine(Offset(boxLeft, boxTop - 10), Offset(boxLeft, boxBottom), _wallPaint);
    canvas.drawLine(Offset(boxRight, boxTop - 10), Offset(boxRight, boxBottom), _wallPaint);
    canvas.drawLine(Offset(boxLeft, boxBottom), Offset(boxRight, boxBottom), _wallPaint);

    // Glass shine strip
    canvas.drawLine(
      Offset(boxLeft + 4, boxTop),
      Offset(boxLeft + 4, boxBottom - 12),
      _shinePaint,
    );
  }

  // ── Merge particles ──────────────────────────────────────────────
  void _drawParticles(Canvas canvas) {
    if (particles.isEmpty) return;
    for (final p in particles) {
      if (!p.alive) continue;
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      _particlePaint.color = p.color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(p.x, p.y), p.radius, _particlePaint);
    }
  }

  // ── Fruits ───────────────────────────────────────────────────────
  void _drawFruits(Canvas canvas) {
    // Single pass: draw regular fruits first, defer preview to draw last (on top)
    FruitParticle? previewFruit;
    for (final f in fruits) {
      if (f.isPreview) {
        previewFruit = f;
      } else {
        _drawFruit(canvas, f);
      }
    }
    if (previewFruit != null) {
      _drawFruit(canvas, previewFruit);
      _drawDropGuide(canvas, previewFruit);
    }
  }

  void _drawFruit(Canvas canvas, FruitParticle f) {
    final r = f.radius * f.spawnScale;
    if (r < 1.0) return;

    final center = Offset(f.x, f.y);

    // Merge glow
    if (f.mergeGlow > 0) {
      canvas.drawCircle(
        center,
        r * 1.25,
        Paint()
          ..color = Colors.white.withValues(alpha: f.mergeGlow * 0.5)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.4),
      );
    }

    // Preview drop indicator — subtle dashed ring only
    if (f.isPreview) {
      canvas.drawCircle(
        center, r,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    if (f.spawnScale > 0.3) {
      final img = fruitImages[f.type];
      if (img != null) {
        _drawSprite(canvas, center, r, img, f.angle);
      } else {
        _drawEmoji(canvas, center, r, f.data.emoji);
      }
      if (f.isBlinking) _drawBlink(canvas, f);
    }
  }

  // Normalized eye positions per fruit type: (xSpacing, yOffset, arcWidth) as fraction of radius.
  // xSpacing: horizontal distance from center to each eye
  // yOffset: vertical offset from center (positive = lower)
  // arcWidth: width of each closed-eye arc
  static const Map<FruitType, (double, double, double)> _eyeData = {
    FruitType.cherry:     (0.20, 0.08, 0.30),
    FruitType.strawberry: (0.18, 0.08, 0.28),
    FruitType.grape:      (0.20, 0.06, 0.28),
    FruitType.orange:     (0.22, 0.06, 0.32),
    FruitType.apple:      (0.22, 0.10, 0.32),
    FruitType.pear:       (0.20, 0.14, 0.30),
    FruitType.peach:      (0.20, 0.08, 0.30),
    FruitType.pineapple:  (0.22, 0.06, 0.32),
    FruitType.melon:      (0.22, 0.06, 0.32),
    FruitType.watermelon: (0.24, 0.06, 0.34),
  };

  void _drawBlink(Canvas canvas, FruitParticle f) {
    final r = f.radius * f.spawnScale;
    final t = f.blinkTimer;
    // Triangle-wave alpha: rises 0→1 in first half, falls 1→0 in second half
    final half = 0.09;
    final alpha = ((t > half ? (0.18 - t) : t) / half).clamp(0.0, 1.0);
    if (alpha <= 0) return;

    final ed = _eyeData[f.type] ?? (0.20, 0.08, 0.30);
    final xSpacing = ed.$1 * r;
    final yOffset = ed.$2 * r;
    final arcW = ed.$3 * r;
    final arcH = arcW * 0.48;

    final paint = Paint()
      ..color = const Color(0xFF2D1A00).withValues(alpha: alpha * 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (r * 0.075).clamp(1.5, 5.0)
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(f.x, f.y);
    canvas.rotate(f.angle);

    for (final sign in [-1.0, 1.0]) {
      // Arc from right (0) sweeping counterclockwise 180° → traces top = ∩ = closed eye
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(sign * xSpacing, yOffset),
          width: arcW,
          height: arcH,
        ),
        0,
        -pi,
        false,
        paint,
      );
    }

    canvas.restore();
  }

  void _drawSprite(Canvas canvas, Offset center, double r, ui.Image img, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 2),
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  void _drawEmoji(Canvas canvas, Offset center, double r, String emoji) {
    final tp = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(fontSize: r * 1.25, height: 1.0),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawDropGuide(Canvas canvas, FruitParticle f) {
    final linePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.28)
      ..strokeWidth = 1.5;
    const dashH = 9.0, gapH = 5.0;
    var y = f.y + f.radius + 2;
    while (y < boxBottom - 4) {
      final yEnd = (y + dashH).clamp(f.y + f.radius, boxBottom - 4);
      canvas.drawLine(Offset(f.x, y), Offset(f.x, yEnd), linePaint);
      y += dashH + gapH;
    }
  }

  // Score popups are now natively rendered via GameScreen Stack instead of canvas
  // to prevent expensive TextPainter layout evaluations every frame.

  @override
  bool shouldRepaint(GamePainter old) => true;
}
