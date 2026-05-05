import 'dart:math';
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
  final double dangerLevel; // 0..1  — how full the box is

  GamePainter({
    required this.fruits,
    required this.particles,
    required this.boxLeft,
    required this.boxRight,
    required this.boxTop,
    required this.boxBottom,
    required this.gameOverLineY,
    this.dangerLevel = 0,
  });

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
    final bgPaint = Paint()..color = const Color(0xFFE8DFD5).withValues(alpha: 0.88);
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(boxLeft, boxTop, boxRight, boxBottom,
          bottomLeft: const Radius.circular(14),
          bottomRight: const Radius.circular(14)),
      bgPaint,
    );

    // Inner shadow at top
    canvas.drawRect(
      Rect.fromLTWH(boxLeft, boxTop, w, 28),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.08), Colors.transparent],
        ).createShader(Rect.fromLTWH(boxLeft, boxTop, w, 28)),
    );

    // Centre divider line
    canvas.drawLine(
      Offset(boxLeft + w / 2, boxTop),
      Offset(boxLeft + w / 2, boxBottom),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..strokeWidth = 2.0,
    );

    // ── Danger glow on walls when box is filling up ──────────────
    if (dangerLevel > 0) {
      final glowAlpha = (dangerLevel.clamp(0.0, 1.0) * 0.55);
      final glowColor = Color.lerp(
        const Color(0xFFFFB74D), // orange warning
        const Color(0xFFE53935), // red danger
        dangerLevel,
      )!.withValues(alpha: glowAlpha);

      final glowPaint = Paint()
        ..color = glowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

      // Left wall glow
      canvas.drawLine(
        Offset(boxLeft, boxTop), Offset(boxLeft, boxBottom), glowPaint..strokeWidth = 18);
      // Right wall glow
      canvas.drawLine(
        Offset(boxRight, boxTop), Offset(boxRight, boxBottom), glowPaint);
    }

    // ── Danger / game-over dashed line ─────────────────────────
    final dangerPaint = Paint()
      ..color = const Color(0xBBE53935)
      ..strokeWidth = 1.8;
    const dash = 12.0, gap = 7.0;
    var x = boxLeft + 4.0;
    while (x < boxRight - 4.0) {
      final xEnd = (x + dash).clamp(boxLeft, boxRight - 4.0);
      canvas.drawLine(Offset(x, gameOverLineY), Offset(xEnd, gameOverLineY), dangerPaint);
      x += dash + gap;
    }

    // ── Walls (drawn on top of glow) ───────────────────────────
    final wallPaint = Paint()
      ..color = const Color(0xFFBBAAA0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(boxLeft, boxTop - 10), Offset(boxLeft, boxBottom), wallPaint);
    canvas.drawLine(Offset(boxRight, boxTop - 10), Offset(boxRight, boxBottom), wallPaint);
    canvas.drawLine(Offset(boxLeft, boxBottom), Offset(boxRight, boxBottom), wallPaint);

    // Glass shine strip
    canvas.drawLine(
      Offset(boxLeft + 4, boxTop),
      Offset(boxLeft + 4, boxBottom - 12),
      Paint()..color = Colors.white.withValues(alpha: 0.28)..strokeWidth = 3.5,
    );
  }

  // ── Merge particles ──────────────────────────────────────────────
  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      if (!p.alive) continue;
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.radius,
        Paint()..color = p.color.withValues(alpha: alpha),
      );
    }
  }

  // ── Fruits ───────────────────────────────────────────────────────
  void _drawFruits(Canvas canvas) {
    final regular = fruits.where((f) => f.alive && !f.isPreview);
    final preview = fruits.where((f) => f.alive && f.isPreview);

    for (final f in regular) {
      _drawFruit(canvas, f);
    }
    for (final f in preview) {
      _drawFruit(canvas, f);
      _drawDropGuide(canvas, f);
    }
  }

  void _drawFruit(Canvas canvas, FruitParticle f) {
    final data = f.data;
    final r = f.radius * f.spawnScale;
    if (r < 1.0) return;

    final cx = f.x;
    final cy = f.y;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(f.angle); // ← SPIN ROTATION

    final center = Offset.zero;

    // Drop shadow
    canvas.drawCircle(
      Offset(r * 0.06, r * 0.1),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.20)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.28),
    );

    // Main gradient
    final gradient = RadialGradient(
      center: const Alignment(-0.35, -0.38),
      radius: 1.0,
      colors: [
        Color.lerp(data.color, Colors.white, 0.48)!,
        data.color,
        Color.lerp(data.color, Colors.black, 0.20)!,
      ],
      stops: const [0.0, 0.62, 1.0],
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: r),
        ),
    );

    // Preview dashed outline
    if (f.isPreview) {
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = data.color.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    }

    // Merge glow ring
    if (f.mergeGlow > 0) {
      canvas.drawCircle(
        center,
        r * 1.28,
        Paint()
          ..color = Colors.white.withValues(alpha: f.mergeGlow * 0.5)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.4),
      );
    }

    // Specular highlight (top left)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-r * 0.35, -r * 0.4),
        width: r * 0.5,
        height: r * 0.25,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.15),
    );

    // Organic details (stem, leaf, seeds, patterns)
    // Rotate back slightly so stems aren't perfectly aligned with physics rotation
    // making them feel more natural.
    _drawOrganicDetails(canvas, center, r, data);

    canvas.restore();
  }

  void _drawOrganicDetails(Canvas canvas, Offset c, double r, FruitData data) {
    final t = data.type;
    
    // ── Skin patterns ────────────────────────────────────────────────────────
    if (t == FruitType.watermelon) {
      // Dark green stripes
      final stripePaint = Paint()
        ..color = const Color(0xFF1B5E20).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.15
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.05);
      
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
      for (int i = -2; i <= 2; i++) {
        final path = Path();
        path.moveTo(c.dx + i * r * 0.45, c.dy - r);
        path.quadraticBezierTo(
          c.dx + i * r * 0.6, c.dy,
          c.dx + i * r * 0.45, c.dy + r,
        );
        canvas.drawPath(path, stripePaint);
      }
      canvas.restore();
      return; // no stem/leaf for watermelon
    }

    if (t == FruitType.pineapple) {
      // Crosshatch pattern
      final hatchPaint = Paint()
        ..color = const Color(0xFFF57F17).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.04;
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
      for (double i = -r; i < r; i += r * 0.3) {
        canvas.drawLine(Offset(c.dx - r, c.dy + i), Offset(c.dx + r, c.dy + i + r), hatchPaint);
        canvas.drawLine(Offset(c.dx + r, c.dy + i), Offset(c.dx - r, c.dy + i + r), hatchPaint);
      }
      canvas.restore();
    }

    if (t == FruitType.strawberry) {
      // Seeds
      final seedPaint = Paint()..color = const Color(0xFFFFD54F);
      for (int i = 0; i < 15; i++) {
        final sx = c.dx + (cos(i * 1.5) * r * 0.6);
        final sy = c.dy + (sin(i * 2.3) * r * 0.6);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(sx, sy), width: r * 0.06, height: r * 0.1),
          seedPaint,
        );
      }
    }

    // ── Stem ────────────────────────────────────────────────────────────────
    final hasStem = t != FruitType.melon && t != FruitType.pineapple;
    if (hasStem) {
      final stemPaint = Paint()
        ..color = const Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.08
        ..strokeCap = StrokeCap.round;
      
      final stemPath = Path();
      stemPath.moveTo(c.dx, c.dy - r * 0.95);
      stemPath.quadraticBezierTo(
        c.dx + r * 0.1, c.dy - r * 1.2,
        c.dx + r * 0.2, c.dy - r * 1.3,
      );
      canvas.drawPath(stemPath, stemPaint);
      
      // Stem base dimple
      canvas.drawOval(
        Rect.fromCenter(center: Offset(c.dx, c.dy - r * 0.95), width: r * 0.3, height: r * 0.1),
        Paint()..color = Colors.black.withValues(alpha: 0.3)..maskFilter = MaskFilter.blur(BlurStyle.normal, r*0.05),
      );
    }

    // ── Leaves ──────────────────────────────────────────────────────────────
    final hasLeaf = t == FruitType.cherry || t == FruitType.strawberry || 
                    t == FruitType.apple || t == FruitType.peach || 
                    t == FruitType.orange || t == FruitType.pineapple;
    if (hasLeaf) {
      final leafPaint = Paint()..color = const Color(0xFF43A047);
      final leafBorder = Paint()
        ..color = const Color(0xFF1B5E20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.02;

      if (t == FruitType.pineapple) {
        // Crown of leaves
        for (int i = -1; i <= 1; i++) {
          final lp = Path();
          lp.moveTo(c.dx, c.dy - r * 0.9);
          lp.quadraticBezierTo(c.dx + i * r * 0.5, c.dy - r * 1.6, c.dx + i * r * 0.8, c.dy - r * 1.8);
          lp.quadraticBezierTo(c.dx + i * r * 0.2, c.dy - r * 1.3, c.dx, c.dy - r * 0.9);
          canvas.drawPath(lp, leafPaint);
          canvas.drawPath(lp, leafBorder);
        }
      } else if (t == FruitType.strawberry) {
        // Strawberry calyx (green cap)
        for (double i = -0.5; i <= 0.5; i += 0.5) {
          final lp = Path();
          lp.moveTo(c.dx, c.dy - r * 0.9);
          lp.lineTo(c.dx + i * r, c.dy - r * 1.1);
          lp.lineTo(c.dx + i * r * 0.5, c.dy - r * 0.85);
          canvas.drawPath(lp, leafPaint);
        }
      } else {
        // Standard single leaf
        final leafPath = Path();
        leafPath.moveTo(c.dx + r * 0.05, c.dy - r * 1.05); // attach to stem
        leafPath.quadraticBezierTo(c.dx - r * 0.5, c.dy - r * 1.4, c.dx - r * 0.6, c.dy - r * 0.9);
        leafPath.quadraticBezierTo(c.dx - r * 0.2, c.dy - r * 0.8, c.dx + r * 0.05, c.dy - r * 1.05);
        canvas.drawPath(leafPath, leafPaint);
        canvas.drawPath(leafPath, leafBorder);
        
        // Leaf vein
        final veinPaint = Paint()
          ..color = const Color(0xFF1B5E20).withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.02;
        final veinPath = Path();
        veinPath.moveTo(c.dx + r * 0.05, c.dy - r * 1.05);
        veinPath.quadraticBezierTo(c.dx - r * 0.3, c.dy - r * 1.1, c.dx - r * 0.55, c.dy - r * 0.95);
        canvas.drawPath(veinPath, veinPaint);
      }
    }
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
