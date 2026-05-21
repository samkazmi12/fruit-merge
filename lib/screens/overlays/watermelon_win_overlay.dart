import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/responsive.dart';

class WatermelonWinOverlay extends StatefulWidget {
  final int score;
  final int highScore;
  final bool isNewHighScore;
  final int sessionXp;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  const WatermelonWinOverlay({
    super.key,
    required this.score,
    required this.highScore,
    required this.isNewHighScore,
    required this.sessionXp,
    required this.onPlayAgain,
    required this.onHome,
  });

  @override
  State<WatermelonWinOverlay> createState() => _WatermelonWinOverlayState();
}

class _WatermelonWinOverlayState extends State<WatermelonWinOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scale = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Container(
        color: Colors.black.withValues(alpha: 0.82 * _fade.value),
        child: Center(
          child: Transform.scale(
            scale: _scale.value,
            child: Opacity(opacity: _fade.value, child: _card(context)),
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.s(28)),
      padding: EdgeInsets.symmetric(
          vertical: context.s(28), horizontal: context.s(24)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4332), Color(0xFF0D3B1A)],
        ),
        borderRadius: BorderRadius.circular(context.s(30)),
        border: Border.all(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.35),
            blurRadius: 40,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🍉', style: TextStyle(fontSize: context.sp(64))),
          SizedBox(height: context.s(6)),
          Text(
            'YOU WIN!',
            style: GoogleFonts.fredoka(
              fontSize: context.sp(36),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF69F0AE),
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.8),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          Text(
            'Watermelons Merged!',
            style: GoogleFonts.fredoka(
              fontSize: context.sp(14),
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: context.s(20)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: context.s(14)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(context.s(16)),
              border: Border.all(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              Text('Score',
                  style: GoogleFonts.fredoka(
                      fontSize: context.sp(13),
                      color: Colors.white.withValues(alpha: 0.55))),
              Text(
                '${widget.score}',
                style: GoogleFonts.fredoka(
                  fontSize: context.sp(48),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF69F0AE),
                ),
              ),
            ]),
          ),
          SizedBox(height: context.s(10)),
          Row(children: [
            Expanded(
              child: _infoChip(context,
                icon: '🏆',
                label: 'Best',
                value: '${widget.highScore}',
                badge: widget.isNewHighScore ? 'NEW!' : null,
              ),
            ),
            SizedBox(width: context.s(10)),
            Expanded(
              child: _infoChip(context,
                icon: '⭐',
                label: 'XP Earned',
                value: '+${widget.sessionXp}',
              ),
            ),
          ]),
          SizedBox(height: context.s(22)),
          _actionBtn(context,
            label: 'Play Again',
            icon: Icons.replay_rounded,
            colors: const [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            glowColor: const Color(0xFF4CAF50),
            onTap: widget.onPlayAgain,
          ),
          SizedBox(height: context.s(10)),
          _actionBtn(context,
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

  Widget _infoChip(BuildContext context, {
    required String icon,
    required String label,
    required String value,
    String? badge,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: context.s(10), horizontal: context.s(12)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(context.s(14)),
        border: Border.all(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Text('$icon $label',
            style: GoogleFonts.fredoka(
                fontSize: context.sp(11),
                color: Colors.white.withValues(alpha: 0.55))),
        SizedBox(height: context.s(2)),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value,
              style: GoogleFonts.fredoka(
                  fontSize: context.sp(18),
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          if (badge != null) ...[
            SizedBox(width: context.s(5)),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: context.s(6), vertical: context.s(1)),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD600),
                borderRadius: BorderRadius.circular(context.s(6)),
              ),
              child: Text(badge,
                  style: GoogleFonts.fredoka(
                      fontSize: context.sp(9),
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
            ),
          ],
        ]),
      ]),
    );
  }

  Widget _actionBtn(BuildContext context, {
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
        padding: EdgeInsets.symmetric(vertical: context.s(13)),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(context.s(18)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          boxShadow: glowColor != null
              ? [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: context.s(22)),
          SizedBox(width: context.s(8)),
          Text(label,
              style: GoogleFonts.fredoka(
                  fontSize: context.sp(18),
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ]),
      ),
    );
  }
}
