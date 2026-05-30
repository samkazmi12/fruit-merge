import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../game/power_up_mode.dart';
import '../../services/storage_service.dart';
import '../../utils/responsive.dart';

/// Bottom strip showing the three power-up cards (Bomb, Shaker, Sniper).
class PowerUpCards extends StatelessWidget {
  final StorageService storage;
  final PowerUpMode powerUpMode;
  final ValueChanged<PowerUpMode> onModeChanged;

  const PowerUpCards({
    super.key,
    required this.storage,
    required this.powerUpMode,
    required this.onModeChanged,
  });

  static const _bombColor = Color(0xFFFF5722);
  static const _shakerColor = Color(0xFF9C27B0);
  static const _sniperColor = Color(0xFF00BCD4);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // ── Background strip ────────────────────────────────────
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF180430).withValues(alpha: 0.3),
                  const Color(0xFF180430).withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
        ),

        // ── Three power-up cards ────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PowerUpCard(
              icon: '💣',
              label: 'Bomb',
              count: storage.bombCount,
              isActive: powerUpMode == PowerUpMode.bomb,
              activeColor: _bombColor,
              onTap: () => onModeChanged(
                powerUpMode == PowerUpMode.bomb
                    ? PowerUpMode.none
                    : PowerUpMode.bomb,
              ),
            ),
            SizedBox(width: context.s(20)),
            _PowerUpCard(
              icon: '🪇',
              label: 'Shaker',
              count: storage.shakerCount,
              isActive: powerUpMode == PowerUpMode.shaker,
              activeColor: _shakerColor,
              onTap: () => onModeChanged(
                powerUpMode == PowerUpMode.shaker
                    ? PowerUpMode.none
                    : PowerUpMode.shaker,
              ),
            ),
            SizedBox(width: context.s(20)),
            _PowerUpCard(
              icon: '🎯',
              label: 'Sniper',
              count: storage.sniperCount,
              isActive: powerUpMode == PowerUpMode.sniper,
              activeColor: _sniperColor,
              onTap: () => onModeChanged(
                powerUpMode == PowerUpMode.sniper
                    ? PowerUpMode.none
                    : PowerUpMode.sniper,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PowerUpCard extends StatelessWidget {
  final String icon;
  final String label;
  final int count;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _PowerUpCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final outOfStock = count <= 0;
    return GestureDetector(
      onTap: outOfStock ? null : onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Card body
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: context.s(54),
            height: context.s(54),
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(context.s(16)),
              border: Border.all(
                color: isActive
                    ? activeColor
                    : Colors.white.withValues(alpha: 0.18),
                width: isActive ? 2.0 : 1.0,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.45),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : const [],
            ),
            child: Center(
              child: Opacity(
                opacity: outOfStock ? 0.25 : 1.0,
                child: Text(icon, style: TextStyle(fontSize: context.sp(26))),
              ),
            ),
          ),

          // Count badge (top-right corner)
          Positioned(
            top: -context.s(5),
            right: -context.s(5),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.s(5),
                vertical: context.s(1),
              ),
              decoration: BoxDecoration(
                color: outOfStock
                    ? Colors.grey.shade800
                    : (isActive ? activeColor : const Color(0xFF2D1A4A)),
                borderRadius: BorderRadius.circular(context.s(10)),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Text(
                '×$count',
                style: GoogleFonts.fredoka(
                  color: outOfStock ? Colors.white30 : Colors.white,
                  fontSize: context.sp(9),
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
