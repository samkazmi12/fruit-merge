import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Placeholder ad banner strip pinned to the bottom of the screen.
class AdBanner extends StatelessWidget {
  final double height;

  const AdBanner({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: height,
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Text(
            'AD',
            style: GoogleFonts.fredoka(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 13,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
