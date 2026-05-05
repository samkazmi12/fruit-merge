import 'dart:math';
import 'package:flutter/material.dart';
import '../models/fruit_data.dart';

/// A single fruit particle in the simulation
class FruitParticle {
  final int id;
  FruitType type;
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  double angle;           // rotation angle in radians  ← NEW
  double angularVel;      // spin speed rad/s           ← NEW
  bool isPreview;
  bool isMerging;
  double mergeGlow;
  double spawnScale;
  bool alive;

  FruitParticle({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    this.vx = 0,
    this.vy = 0,
    required this.radius,
    this.angle = 0,
    this.angularVel = 0,
    this.isPreview = false,
    this.isMerging = false,
    this.mergeGlow = 0,
    this.spawnScale = 1.0,
    this.alive = true,
  });

  FruitData get data => FruitData.fromType(type);
  Offset get center => Offset(x, y);
}

// ── Merge particle for burst effect ─────────────────────────────
class MergeParticle {
  double x, y;
  double vx, vy;
  double radius;
  Color color;
  double life;       // 0..1  (1 = fully alive, 0 = dead)
  double maxLife;

  MergeParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.color,
    this.life = 1.0,
    this.maxLife = 1.0,
  });

  bool get alive => life > 0;
}

// ── Floating score popup ─────────────────────────────────────────
class ScorePopup {
  double x, y;
  final String text;
  final Color color;
  double life;    // 0..1

  ScorePopup({
    required this.x,
    required this.y,
    required this.text,
    required this.color,
    this.life = 1.0,
  });

  bool get alive => life > 0;
}

/// Physics engine for the fruit merge game
class FruitPhysics {
  final double boxLeft;
  final double boxRight;
  final double boxTop;
  final double boxBottom;

  static const double gravity = 1800.0;
  static const double damping = 0.55;
  static const double friction = 0.92;
  static const double angularDamping = 0.88;   // ← spin slows over time
  static const double sleepThreshold = 10.0;
  static const int maxIterations = 6;

  FruitPhysics({
    required this.boxLeft,
    required this.boxRight,
    required this.boxTop,
    required this.boxBottom,
  });

  void step(List<FruitParticle> fruits, double dt) {
    dt = dt.clamp(0, 0.033);

    for (final f in fruits) {
      if (!f.alive || f.isPreview) continue;

      // Gravity
      f.vy += gravity * dt;

      // Integrate position
      f.x += f.vx * dt;
      f.y += f.vy * dt;

      // ── Rotation: spin based on horizontal velocity ──────────
      // Derive angular velocity from horizontal motion (rolling feel)
      final targetSpin = f.vx / (f.radius.clamp(10, 100)) * 1.2;
      f.angularVel = f.angularVel * 0.85 + targetSpin * 0.15;
      f.angle += f.angularVel * dt;
      // Slow spin when nearly stopped
      if (f.vy.abs() < sleepThreshold && f.vx.abs() < sleepThreshold) {
        f.angularVel *= angularDamping;
      }

      // Spawn scale animation
      if (f.spawnScale < 1.0) {
        f.spawnScale = (f.spawnScale + dt * 6.0).clamp(0.0, 1.0);
      }

      // Merge glow fade
      if (f.mergeGlow > 0) {
        f.mergeGlow = (f.mergeGlow - dt * 2.5).clamp(0.0, 1.0);
      }

      _resolveWalls(f);
    }

    int iters = fruits.length > 35 ? 3 : (fruits.length > 15 ? 4 : 6);
    for (int iter = 0; iter < iters; iter++) {
      _resolveCircleCollisions(fruits);
    }
  }

  void _resolveWalls(FruitParticle f) {
    final r = f.radius * f.spawnScale;

    // Floor
    if (f.y + r > boxBottom) {
      f.y = boxBottom - r;
      f.vy = -f.vy.abs() * damping;
      f.vx *= friction;
      // Floor friction adds opposite spin
      f.angularVel -= f.vx * 0.004;
      if (f.vy.abs() < sleepThreshold) f.vy = 0;
    }
    // Left wall
    if (f.x - r < boxLeft) {
      f.x = boxLeft + r;
      f.vx = f.vx.abs() * damping;
      f.angularVel = f.vx.abs() * 0.015;
    }
    // Right wall
    if (f.x + r > boxRight) {
      f.x = boxRight - r;
      f.vx = -f.vx.abs() * damping;
      f.angularVel = -f.vx.abs() * 0.015;
    }
  }

  void _resolveCircleCollisions(List<FruitParticle> fruits) {
    for (int i = 0; i < fruits.length; i++) {
      final a = fruits[i];
      if (!a.alive || a.isPreview) continue;

      for (int j = i + 1; j < fruits.length; j++) {
        final b = fruits[j];
        if (!b.alive || b.isPreview) continue;

        final ra = a.radius * a.spawnScale;
        final rb = b.radius * b.spawnScale;
        final dx = b.x - a.x;
        final minDist = ra + rb;
        
        // Fast AABB check to skip sqrt
        if (dx.abs() > minDist) continue;
        
        final dy = b.y - a.y;
        if (dy.abs() > minDist) continue;

        final dist = sqrt(dx * dx + dy * dy);

        if (dist < minDist && dist > 0.001) {
          final overlap = minDist - dist;
          final nx = dx / dist;
          final ny = dy / dist;

          final totalR = ra + rb;
          final pushA = rb / totalR;
          final pushB = ra / totalR;

          a.x -= nx * overlap * pushA;
          a.y -= ny * overlap * pushA;
          b.x += nx * overlap * pushB;
          b.y += ny * overlap * pushB;

          final dvx = b.vx - a.vx;
          final dvy = b.vy - a.vy;
          final dot = dvx * nx + dvy * ny;

          if (dot < 0) {
            final impulse = dot * damping;
            a.vx += impulse * nx;
            a.vy += impulse * ny;
            b.vx -= impulse * nx;
            b.vy -= impulse * ny;
            // Collision spins them
            a.angularVel += impulse * 0.05;
            b.angularVel -= impulse * 0.05;
          }
        }
      }
    }
  }

  /// Step merge particles (gravity + life drain)
  void stepParticles(List<MergeParticle> particles, double dt) {
    for (final p in particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 400 * dt; // slight gravity on particles
      p.life -= dt * 2.2;
      p.radius *= 0.97;
    }
  }

  /// Step score popups (float upward + fade)
  void stepPopups(List<ScorePopup> popups, double dt) {
    for (final p in popups) {
      p.y -= 120 * dt; // float upward
      p.life -= dt * 1.4;
    }
  }

  List<(FruitParticle, FruitParticle)> detectMerges(
      List<FruitParticle> fruits) {
    final merges = <(FruitParticle, FruitParticle)>[];
    final checked = <int>{};

    for (int i = 0; i < fruits.length; i++) {
      final a = fruits[i];
      if (!a.alive || a.isPreview || a.isMerging) continue;
      if (checked.contains(a.id)) continue;

      for (int j = i + 1; j < fruits.length; j++) {
        final b = fruits[j];
        if (!b.alive || b.isPreview || b.isMerging) continue;
        if (checked.contains(b.id)) continue;
        if (a.type != b.type) continue;

        final touch = (a.radius + b.radius) * 1.05;
        
        // Fast AABB check
        final dx = b.x - a.x;
        if (dx.abs() > touch) continue;
        final dy = b.y - a.y;
        if (dy.abs() > touch) continue;

        final dist = sqrt(dx * dx + dy * dy);

        if (dist <= touch) {
          merges.add((a, b));
          checked.add(a.id);
          checked.add(b.id);
          break;
        }
      }
    }
    return merges;
  }

  /// Create burst particles at merge position
  static List<MergeParticle> createMergeBurst(
      double x, double y, Color color, double radius) {
    final rng = Random();
    final count = 10 + (radius / 10).round().clamp(4, 14);
    return List.generate(count, (i) {
      final angle = (i / count) * 2 * pi + rng.nextDouble() * 0.4;
      final speed = 120 + rng.nextDouble() * 180;
      final size = 3.0 + rng.nextDouble() * 5;
      return MergeParticle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        radius: size,
        color: Color.lerp(color, Colors.white, 0.3 + rng.nextDouble() * 0.3)!,
        life: 0.7 + rng.nextDouble() * 0.3,
        maxLife: 1.0,
      );
    });
  }
}
