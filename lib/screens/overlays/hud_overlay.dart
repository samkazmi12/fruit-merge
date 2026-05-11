import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/fruit_data.dart';
import '../../utils/responsive.dart';

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
      padding: EdgeInsets.fromLTRB(
          context.s(12), context.s(10), context.s(12), context.s(6)),
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
                  width: context.s(44), height: context.s(44),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7043), Color(0xFFFF9800)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(context.s(14)),
                    boxShadow: [BoxShadow(
                      color: const Color(0xFFFF7043).withValues(alpha: 0.5),
                      blurRadius: 8, offset: const Offset(0, 3),
                    )],
                  ),
                  child: Icon(Icons.pause_rounded,
                      color: Colors.white, size: context.s(24)),
                ),
              ),

              SizedBox(width: context.s(8)),

              // ── Score card ────────────────────────────────
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.s(14), vertical: context.s(8)),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(context.s(18)),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Text('$score',
                          style: GoogleFonts.fredoka(
                            fontSize: context.sp(26), fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )),
                      Text('Best: $highScore',
                          style: GoogleFonts.fredoka(
                            fontSize: context.sp(11),
                            color: Colors.white.withValues(alpha: 0.6),
                          )),
                    ],
                  ),
                ),
              ),

              SizedBox(width: context.s(8)),

              // ── Next fruit ────────────────────────────────
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.s(10), vertical: context.s(8)),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(context.s(16)),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Next',
                        style: GoogleFonts.fredoka(
                          fontSize: context.sp(10),
                          color: Colors.white.withValues(alpha: 0.6),
                        )),
                    Image.asset(
                      'assets/images/fruit_${nextData.name.toLowerCase()}.png',
                      width: context.s(36), height: context.s(36),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, _) =>
                          Text(nextData.emoji,
                              style: TextStyle(fontSize: context.sp(22))),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: context.s(6)),

          // ── Level + Best fruit row ─────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Level badge
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.s(10), vertical: context.s(3)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFF3F51B5)],
                  ),
                  borderRadius: BorderRadius.circular(context.s(20)),
                ),
                child: Text('⭐ Lv.$currentLevel',
                    style: GoogleFonts.fredoka(
                      fontSize: context.sp(12), fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
              ),
              // Best fruit badge
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.s(10), vertical: context.s(3)),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(context.s(20)),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🏆', style: TextStyle(fontSize: context.sp(12))),
                    SizedBox(width: context.s(4)),
                    Image.asset(
                      'assets/images/fruit_${bestData.name.toLowerCase()}.png',
                      width: context.s(20), height: context.s(20),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, _) =>
                          Text(bestData.emoji,
                              style: TextStyle(fontSize: context.sp(12))),
                    ),
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
