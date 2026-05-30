import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/responsive.dart';

/// Animated combo banner that floats above the game jar when a combo is active.
/// Should only be added to the widget tree when [opacity] > 0 and combo >= 2.
class ComboBanner extends StatelessWidget {
  final double opacity;
  final double scale;
  final int lastShownCombo;
  final Color comboColor;
  final double boxTop;

  const ComboBanner({
    super.key,
    required this.opacity,
    required this.scale,
    required this.lastShownCombo,
    required this.comboColor,
    required this.boxTop,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: boxTop + 22,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.s(22),
                  vertical: context.s(8),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      comboColor,
                      comboColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(context.s(30)),
                  boxShadow: [
                    BoxShadow(
                      color: comboColor.withValues(alpha: 0.6),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  '${lastShownCombo}x COMBO! 🔥',
                  style: GoogleFonts.fredoka(
                    fontSize: context.sp(26),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
