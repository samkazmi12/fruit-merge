import 'package:flutter/material.dart';

import '../../models/fruit_data.dart';
import '../../utils/responsive.dart';

/// Horizontal strip that shows all fruit types in order, highlighting
/// which ones have been unlocked/merged during the current session.
class EvolutionBar extends StatelessWidget {
  final int bestFruitIndex;

  const EvolutionBar({super.key, required this.bestFruitIndex});

  String _assetPathFor(FruitData fruit) =>
      'assets/images/fruit_${fruit.name.toLowerCase()}.png';

  @override
  Widget build(BuildContext context) {
    final all = FruitData.allFruits;
    return Container(
      margin: EdgeInsets.fromLTRB(
        context.s(14),
        context.s(10),
        context.s(14),
        context.s(10),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.s(10),
        vertical: context.s(7),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(context.s(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: all.asMap().entries.map((e) {
          final unlocked = e.key <= bestFruitIndex;
          final isNext = e.key == bestFruitIndex + 1;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: isNext ? EdgeInsets.all(context.s(3)) : EdgeInsets.zero,
            decoration: isNext
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  )
                : const BoxDecoration(),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: unlocked ? 1.0 : (isNext ? 0.55 : 0.22),
              child: SizedBox(
                width: context.s(unlocked ? 24 : (isNext ? 20 : 16)),
                height: context.s(unlocked ? 24 : (isNext ? 20 : 16)),
                child: Image.asset(
                  _assetPathFor(e.value),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.24),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
