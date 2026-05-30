import 'package:flutter/material.dart';

import '../../game/fruit_physics.dart';
import '../../utils/responsive.dart';

/// Transparent overlay that renders all floating score-popup labels.
/// Fills the available space and ignores pointer events.
class ScorePopupsLayer extends StatelessWidget {
  final List<ScorePopup> popups;

  const ScorePopupsLayer({super.key, required this.popups});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: popups
              .map(
                (p) => Positioned(
                  left: p.x - 40,
                  top: p.y - 20,
                  child: Opacity(
                    opacity: p.life.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.6 + p.life.clamp(0.0, 1.0) * 0.4,
                      child: Text(
                        p.text,
                        style: TextStyle(
                          fontSize: context.sp(22),
                          fontWeight: FontWeight.w900,
                          color: p.color,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(
                                alpha: p.life.clamp(0.0, 1.0) * 0.4,
                              ),
                              offset: const Offset(1, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
