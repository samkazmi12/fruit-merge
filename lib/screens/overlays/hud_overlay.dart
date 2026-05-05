import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/fruit_data.dart';

class HudOverlay extends StatelessWidget {
  final int score;
  final int highScore;
  final int combo;
  final FruitType nextFruit;
  final int bestFruitIndex;
  final int currentLevel;
  final VoidCallback onPause;

  const HudOverlay({
    super.key,
    required this.score,
    required this.highScore,
    required this.combo,
    required this.nextFruit,
    required this.onPause,
    this.bestFruitIndex = 0,
    this.currentLevel = 1,
  });

  @override
  Widget build(BuildContext context) {
    final nextData = FruitData.fromType(nextFruit);
    final bestData = FruitData.allFruits[bestFruitIndex.clamp(0, 9)];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Pause button ──────────────────────────────
              GestureDetector(
                onTap: onPause,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7043), Color(0xFFFF9800)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                      color: const Color(0xFFFF7043).withValues(alpha: 0.5),
                      blurRadius: 8, offset: const Offset(0, 3),
                    )],
                  ),
                  child: const Icon(Icons.pause_rounded,
                      color: Colors.white, size: 24),
                ),
              ),

              const SizedBox(width: 8),

              // ── Score card ────────────────────────────────
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Text('$score',
                          style: GoogleFonts.fredoka(
                            fontSize: 26, fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )),
                      Text('Best: $highScore',
                          style: GoogleFonts.fredoka(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.6),
                          )),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // ── Next fruit ────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Next',
                        style: GoogleFonts.fredoka(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.6),
                        )),
                    Text(nextData.emoji,
                        style: const TextStyle(fontSize: 22)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ── Level + Best fruit row ─────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Level badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFF3F51B5)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('⭐ Lv.$currentLevel',
                    style: GoogleFonts.fredoka(
                      fontSize: 12, fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
              ),
              // Best fruit badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text('Best: ${bestData.emoji}',
                        style: GoogleFonts.fredoka(
                          fontSize: 12, color: Colors.white,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
