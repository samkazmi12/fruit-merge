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
    final showCombo = combo >= 2;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A0533).withValues(alpha: 0.85),
            const Color(0xFF1A0533).withValues(alpha: 0.0),
          ],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          context.s(12), context.s(10), context.s(12), context.s(10)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Row 1: pause · score · next ──────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pause button
              GestureDetector(
                onTap: onPause,
                child: Container(
                  width: context.s(42), height: context.s(42),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7043), Color(0xFFFF9800)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(context.s(13)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7043).withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Icon(Icons.pause_rounded,
                      color: Colors.white, size: context.s(22)),
                ),
              ),
              SizedBox(width: context.s(8)),

              // Score card
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.s(14), vertical: context.s(8)),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(context.s(16)),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$score',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.fredoka(
                              fontSize: context.sp(28),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                          SizedBox(height: context.s(2)),
                          Text(
                            'Best  $highScore',
                            style: GoogleFonts.fredoka(
                              fontSize: context.sp(11),
                              color: Colors.white.withValues(alpha: 0.5),
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                      // Combo badge — only visible when combo ≥ 2
                      if (showCombo)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: context.s(8),
                              vertical: context.s(3)),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF9800),
                                Color(0xFFE91E63)
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(context.s(12)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF9800)
                                    .withValues(alpha: 0.5),
                                blurRadius: 8,
                              )
                            ],
                          ),
                          child: Text(
                            '×$combo',
                            style: GoogleFonts.fredoka(
                              fontSize: context.sp(13),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: context.s(8)),

              // Next fruit card
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.s(10), vertical: context.s(6)),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(context.s(14)),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'NEXT',
                      style: GoogleFonts.fredoka(
                        fontSize: context.sp(9),
                        color: Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 0.8,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: context.s(4)),
                    Image.asset(
                      'assets/images/fruit_${nextData.name.toLowerCase()}.png',
                      width: context.s(36),
                      height: context.s(36),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Text(nextData.emoji,
                          style:
                              TextStyle(fontSize: context.sp(22))),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: context.s(8)),

          // ── Row 2: level · best fruit ─────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Level badge
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.s(12), vertical: context.s(4)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFF3F51B5)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(context.s(20)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9C27B0).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Text(
                  '⭐  Lv.$currentLevel',
                  style: GoogleFonts.fredoka(
                    fontSize: context.sp(13),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ),

              // Best fruit badge
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.s(10), vertical: context.s(4)),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(context.s(20)),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🏆',
                        style: TextStyle(fontSize: context.sp(13))),
                    SizedBox(width: context.s(5)),
                    Image.asset(
                      'assets/images/fruit_${bestData.name.toLowerCase()}.png',
                      width: context.s(20),
                      height: context.s(20),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Text(bestData.emoji,
                          style:
                              TextStyle(fontSize: context.sp(13))),
                    ),
                    SizedBox(width: context.s(4)),
                    Text(
                      bestData.name,
                      style: GoogleFonts.fredoka(
                        fontSize: context.sp(12),
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.0,
                      ),
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
