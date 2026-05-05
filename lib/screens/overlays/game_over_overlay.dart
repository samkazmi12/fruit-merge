import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GameOverOverlay extends StatefulWidget {
  final int score;
  final int highScore;
  final bool isNewHighScore;
  final int sessionXp;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  const GameOverOverlay({
    super.key,
    required this.score,
    required this.highScore,
    required this.isNewHighScore,
    required this.onPlayAgain,
    required this.onHome,
    this.sessionXp = 0,
  });

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Container(
        color: Colors.black.withValues(alpha: 0.75 * _fade.value),
        child: Center(
          child: Transform.scale(
            scale: _scale.value,
            child: Opacity(opacity: _fade.value, child: _card()),
          ),
        ),
      ),
    );
  }

  Widget _card() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
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
          Text('😵 Game Over',
              style: GoogleFonts.fredoka(
                fontSize: 30, fontWeight: FontWeight.bold,
                color: const Color(0xFFFF5370),
              )),

          const SizedBox(height: 20),

          // Score
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Column(children: [
              Text('Score', style: GoogleFonts.fredoka(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.55))),
              Text('${widget.score}', style: GoogleFonts.fredoka(
                fontSize: 48, fontWeight: FontWeight.bold,
                color: Colors.white,
              )),
            ]),
          ),

          const SizedBox(height: 10),

          // Best + XP row
          Row(children: [
            Expanded(
              child: _infoChip(
                icon: '🏆',
                label: 'Best',
                value: '${widget.highScore}',
                badge: widget.isNewHighScore ? 'NEW!' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _infoChip(
                icon: '⭐',
                label: 'XP Earned',
                value: '+${widget.sessionXp}',
              ),
            ),
          ]),

          const SizedBox(height: 22),

          // Play Again
          _actionBtn(
            label: 'Play Again',
            icon: Icons.replay_rounded,
            colors: const [Color(0xFF66BB6A), Color(0xFF43A047)],
            glowColor: Color(0xFF66BB6A),
            onTap: widget.onPlayAgain,
          ),
          const SizedBox(height: 10),
          _actionBtn(
            label: 'Home',
            icon: Icons.home_rounded,
            colors: [
              Colors.white.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.08),
            ],
            onTap: widget.onHome,
          ),
        ],
      ),
    );
  }

  Widget _infoChip({
    required String icon,
    required String label,
    required String value,
    String? badge,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(children: [
        Text('$icon $label', style: GoogleFonts.fredoka(
            fontSize: 11, color: Colors.white.withValues(alpha: 0.55))),
        const SizedBox(height: 2),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value, style: GoogleFonts.fredoka(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          if (badge != null) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD600),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(badge, style: GoogleFonts.fredoka(
                  fontSize: 9, fontWeight: FontWeight.bold,
                  color: Colors.black)),
            ),
          ],
        ]),
      ]),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required List<Color> colors,
    Color? glowColor,
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
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          boxShadow: glowColor != null ? [BoxShadow(
            color: glowColor.withValues(alpha: 0.4),
            blurRadius: 12, offset: const Offset(0, 4),
          )] : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.fredoka(
            fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
        ]),
      ),
    );
  }
}
