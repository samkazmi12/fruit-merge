import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/audio_manager.dart';

class PauseOverlay extends StatelessWidget {
  final AudioManager audio;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  const PauseOverlay({
    super.key,
    required this.audio,
    required this.onResume,
    required this.onRestart,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 36),
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF1A0533), Color(0xFF0D1B6B)],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30, offset: const Offset(0, 14),
            )],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('⏸️ Paused',
                  style: GoogleFonts.fredoka(
                    fontSize: 30, fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),

              const SizedBox(height: 28),

              _btn(label: 'Resume', icon: Icons.play_arrow_rounded,
                  colors: const [Color(0xFF66BB6A), Color(0xFF43A047)],
                  glow: Color(0xFF66BB6A), onTap: onResume),
              const SizedBox(height: 12),
              _btn(label: 'Restart', icon: Icons.refresh_rounded,
                  colors: const [Color(0xFFFFB74D), Color(0xFFFF9800)],
                  glow: Color(0xFFFFB74D), onTap: onRestart),
              const SizedBox(height: 12),
              _btn(label: 'Home', icon: Icons.home_rounded,
                  colors: const [Color(0xFFEF5350), Color(0xFFE53935)],
                  glow: Color(0xFFEF5350), onTap: onHome),

              const SizedBox(height: 22),

              // Sound toggles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _toggle(
                    icon: audio.soundEnabled
                        ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    isActive: audio.soundEnabled,
                    label: 'SFX',
                    onTap: () => audio.toggleSound(),
                  ),
                  const SizedBox(width: 20),
                  _toggle(
                    icon: audio.musicEnabled
                        ? Icons.music_note_rounded : Icons.music_off_rounded,
                    isActive: audio.musicEnabled,
                    label: 'Music',
                    onTap: () => audio.toggleMusic(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn({
    required String label, required IconData icon,
    required List<Color> colors, required Color glow,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
            color: glow.withValues(alpha: 0.35),
            blurRadius: 10, offset: const Offset(0, 4),
          )],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.fredoka(
            fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
        ]),
      ),
    );
  }

  Widget _toggle({
    required IconData icon, required bool isActive,
    required String label, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFFFB74D)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Icon(icon,
              color: isActive ? Colors.white
                  : Colors.white.withValues(alpha: 0.4), size: 24),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.fredoka(
            fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
      ]),
    );
  }
}
