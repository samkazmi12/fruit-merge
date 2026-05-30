import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/audio_manager.dart';
import '../../utils/responsive.dart';

class PauseOverlay extends StatelessWidget {
  final AudioManager audio;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onHome;
  final VoidCallback onToggleSound;
  final VoidCallback onToggleMusic;

  const PauseOverlay({
    super.key,
    required this.audio,
    required this.onResume,
    required this.onRestart,
    required this.onHome,
    required this.onToggleSound,
    required this.onToggleMusic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: context.s(36)),
          padding: EdgeInsets.symmetric(
              vertical: context.s(28), horizontal: context.s(24)),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF1A0533), Color(0xFF0D1B6B)],
            ),
            borderRadius: BorderRadius.circular(context.s(30)),
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
                    fontSize: context.sp(30), fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),

              SizedBox(height: context.s(28)),

              _btn(context, label: 'Resume', icon: Icons.play_arrow_rounded,
                  colors: const [Color(0xFF66BB6A), Color(0xFF43A047)],
                  glow: const Color(0xFF66BB6A), onTap: onResume),
              SizedBox(height: context.s(12)),
              _btn(context, label: 'Restart', icon: Icons.refresh_rounded,
                  colors: const [Color(0xFFFFB74D), Color(0xFFFF9800)],
                  glow: const Color(0xFFFFB74D), onTap: onRestart),
              SizedBox(height: context.s(12)),
              _btn(context, label: 'Home', icon: Icons.home_rounded,
                  colors: const [Color(0xFFEF5350), Color(0xFFE53935)],
                  glow: const Color(0xFFEF5350), onTap: onHome),

              SizedBox(height: context.s(22)),

              // Sound toggles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _toggle(context,
                    icon: audio.soundEnabled
                        ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    isActive: audio.soundEnabled,
                    label: 'SFX',
                    onTap: onToggleSound,
                  ),
                  SizedBox(width: context.s(20)),
                  _toggle(context,
                    icon: audio.musicEnabled
                        ? Icons.music_note_rounded : Icons.music_off_rounded,
                    isActive: audio.musicEnabled,
                    label: 'Music',
                    onTap: onToggleMusic,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(BuildContext context, {
    required String label, required IconData icon,
    required List<Color> colors, required Color glow,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: context.s(13)),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(context.s(18)),
          boxShadow: [BoxShadow(
            color: glow.withValues(alpha: 0.35),
            blurRadius: 10, offset: const Offset(0, 4),
          )],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: context.s(22)),
          SizedBox(width: context.s(8)),
          Text(label, style: GoogleFonts.fredoka(
            fontSize: context.sp(17), fontWeight: FontWeight.w600,
            color: Colors.white)),
        ]),
      ),
    );
  }

  Widget _toggle(BuildContext context, {
    required IconData icon, required bool isActive,
    required String label, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: context.s(50), height: context.s(50),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFFFB74D)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(context.s(16)),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Icon(icon,
              color: isActive ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
              size: context.s(24)),
        ),
        SizedBox(height: context.s(4)),
        Text(label, style: GoogleFonts.fredoka(
            fontSize: context.sp(11),
            color: Colors.white.withValues(alpha: 0.6))),
      ]),
    );
  }
}
