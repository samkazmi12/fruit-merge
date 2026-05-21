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
  double angle;
  double angularVel;
  bool isPreview;
  bool isMerging;
  double mergeGlow;
  double spawnScale;
  bool alive;
  double blinkTimer;   // > 0 while eyes are closed, counts down to 0
  double nextBlinkIn;  // seconds until next blink starts

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
    this.blinkTimer = 0,
    double? nextBlinkIn,
  }) : nextBlinkIn = nextBlinkIn ?? (1.5 + (id * 0.618033988749895) % 4.5);

  // Physics sleep: counts frames of low-velocity rest (> 20 → sleeping)
  int sleepCounter = 0;

  bool get isBlinking => blinkTimer > 0 && !isPreview;

  FruitData get data => FruitData.fromType(type);
  Offset get center => Offset(x, y);

  Map<String, dynamic> toJson() => {
    'id': id, 'type': type.name,
    'x': x, 'y': y, 'vx': vx, 'vy': vy,
    'radius': radius, 'angle': angle, 'angularVel': angularVel,
    'isPreview': isPreview, 'isMerging': isMerging,
    'mergeGlow': mergeGlow, 'spawnScale': spawnScale, 'alive': alive,
    'blinkTimer': blinkTimer, 'nextBlinkIn': nextBlinkIn,
  };

  factory FruitParticle.fromJson(Map<String, dynamic> j) => FruitParticle(
    id: j['id'] as int,
    type: FruitType.values.byName(j['type'] as String),
    x: (j['x'] as num).toDouble(), y: (j['y'] as num).toDouble(),
    vx: (j['vx'] as num).toDouble(), vy: (j['vy'] as num).toDouble(),
    radius: (j['radius'] as num).toDouble(),
    angle: (j['angle'] as num).toDouble(),
    angularVel: (j['angularVel'] as num).toDouble(),
    isPreview: j['isPreview'] as bool, isMerging: j['isMerging'] as bool,
    mergeGlow: (j['mergeGlow'] as num).toDouble(),
    spawnScale: (j['spawnScale'] as num).toDouble(),
    alive: j['alive'] as bool,
    blinkTimer: (j['blinkTimer'] as num?)?.toDouble() ?? 0.0,
    nextBlinkIn: (j['nextBlinkIn'] as num?)?.toDouble(),
  );
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

  final Random _rng = Random();

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

      // ── Sleeping path: fruit is settled; skip expensive physics ──
      if (f.sleepCounter > 20) {
        // Only update blink so eyes still animate while resting
        if (f.blinkTimer > 0) {
          f.blinkTimer -= dt;
          if (f.blinkTimer < 0) f.blinkTimer = 0;
        } else {
          f.nextBlinkIn -= dt;
          if (f.nextBlinkIn <= 0) {
            f.blinkTimer = 0.12 + _rng.nextDouble() * 0.06;
            f.nextBlinkIn = 3.0 + _rng.nextDouble() * 5.0;
          }
        }
        continue;
      }

      // ── Active path: full physics ─────────────────────────────
      f.vy += gravity * dt;
      f.x += f.vx * dt;
      f.y += f.vy * dt;

      f.angularVel *= 0.94;
      if (f.angularVel.abs() < 0.005) f.angularVel = 0;
      f.angle += f.angularVel * dt;
      f.angle = f.angle.clamp(-0.26, 0.26);

      if (f.spawnScale < 1.0) {
        f.spawnScale = (f.spawnScale + dt * 6.0).clamp(0.0, 1.0);
      }
      if (f.mergeGlow > 0) {
        f.mergeGlow = (f.mergeGlow - dt * 2.5).clamp(0.0, 1.0);
      }

      if (f.blinkTimer > 0) {
        f.blinkTimer -= dt;
        if (f.blinkTimer < 0) f.blinkTimer = 0;
      } else {
        f.nextBlinkIn -= dt;
        if (f.nextBlinkIn <= 0) {
          f.blinkTimer = 0.12 + _rng.nextDouble() * 0.06;
          f.nextBlinkIn = 3.0 + _rng.nextDouble() * 5.0;
        }
      }

      _resolveWalls(f);

      // ── Sleep counter: count frames of low-velocity rest ───────
      if (f.spawnScale >= 1.0 && f.mergeGlow <= 0.0 &&
          f.vx.abs() < 6.0 && f.vy.abs() < 6.0) {
        if (f.sleepCounter < 30) f.sleepCounter++;
      } else {
        f.sleepCounter = 0;
      }
    }

    final iters = fruits.length > 35 ? 3 : (fruits.length > 15 ? 4 : 6);
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
      // Sleeping fruits skip being the "pusher" — they're still resolved as
      // obstacles when active fruits (outer) check against them (inner j).
      if (a.sleepCounter > 20) continue;

      for (int j = i + 1; j < fruits.length; j++) {
        final b = fruits[j];
        if (!b.alive || b.isPreview) continue;

        final ra = a.radius * a.spawnScale;
        final rb = b.radius * b.spawnScale;
        final dx = b.x - a.x;
        final minDist = ra + rb;

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

          // Wake sleeping fruit when pushed significantly
          if (overlap > 1.0) {
            a.sleepCounter = 0;
            b.sleepCounter = 0;
          }

          final dvx = b.vx - a.vx;
          final dvy = b.vy - a.vy;
          final dot = dvx * nx + dvy * ny;

          if (dot < 0) {
            final impulse = dot * damping;
            a.vx += impulse * nx;
            a.vy += impulse * ny;
            b.vx -= impulse * nx;
            b.vy -= impulse * ny;
            a.angularVel += impulse * 0.05;
            b.angularVel -= impulse * 0.05;
            // Always wake on velocity exchange
            a.sleepCounter = 0;
            b.sleepCounter = 0;
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

  // Reused Set to avoid per-tick allocation in detectMerges
  final _mergeChecked = <int>{};

  List<(FruitParticle, FruitParticle)> detectMerges(
      List<FruitParticle> fruits) {
    final merges = <(FruitParticle, FruitParticle)>[];
    _mergeChecked.clear();

    for (int i = 0; i < fruits.length; i++) {
      final a = fruits[i];
      if (!a.alive || a.isPreview || a.isMerging) continue;
      if (_mergeChecked.contains(a.id)) continue;

      for (int j = i + 1; j < fruits.length; j++) {
        final b = fruits[j];
        if (!b.alive || b.isPreview || b.isMerging) continue;
        if (_mergeChecked.contains(b.id)) continue;
        if (a.type != b.type) continue;

        final touch = (a.radius + b.radius) * 1.05;

        final dx = b.x - a.x;
        if (dx.abs() > touch) continue;
        final dy = b.y - a.y;
        if (dy.abs() > touch) continue;

        final dist = sqrt(dx * dx + dy * dy);

        if (dist <= touch) {
          merges.add((a, b));
          _mergeChecked.add(a.id);
          _mergeChecked.add(b.id);
          break;
        }
      }
    }
    return merges;
  }

  /// Create burst particles at merge position — uses instance _rng (no allocation)
  List<MergeParticle> createMergeBurst(
      double x, double y, Color color, double radius) {
    final count = 10 + (radius / 10).round().clamp(4, 14);
    return List.generate(count, (i) {
      final angle = (i / count) * 2 * pi + _rng.nextDouble() * 0.4;
      final speed = 120 + _rng.nextDouble() * 180;
      final size = 3.0 + _rng.nextDouble() * 5;
      return MergeParticle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        radius: size,
        color: Color.lerp(color, Colors.white, 0.3 + _rng.nextDouble() * 0.3)!,
        life: 0.7 + _rng.nextDouble() * 0.3,
        maxLife: 1.0,
      );
    });
  }
}
