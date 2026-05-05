/// XP & Level system with non-linear progression curve
/// Early levels are fast, later levels get progressively harder
class LevelSystem {
  /// XP required to advance FROM level [level] to [level+1]
  /// Formula: 100*L + 35*L² → fast early, slow late
  static int xpForLevel(int level) {
    return (100 * level + 35 * level * level).toInt();
  }

  /// Total cumulative XP to reach [targetLevel] from level 0
  static int totalXpForLevel(int targetLevel) {
    int total = 0;
    for (int l = 1; l < targetLevel; l++) {
      total += xpForLevel(l);
    }
    return total;
  }

  /// Given total accumulated XP, return the current level
  static int levelFromXp(int totalXp) {
    int level = 1;
    while (totalXp >= totalXpForLevel(level + 1)) {
      level++;
      if (level >= 999) break;
    }
    return level;
  }

  /// XP within the current level (progress toward next)
  static int xpInCurrentLevel(int totalXp) {
    final level = levelFromXp(totalXp);
    return totalXp - totalXpForLevel(level);
  }

  /// XP needed to complete current level
  static int xpNeededForCurrentLevel(int totalXp) {
    final level = levelFromXp(totalXp);
    return xpForLevel(level);
  }

  /// 0.0..1.0 progress through current level
  static double levelProgress(int totalXp) {
    final earned = xpInCurrentLevel(totalXp);
    final needed = xpNeededForCurrentLevel(totalXp);
    if (needed == 0) return 1.0;
    return (earned / needed).clamp(0.0, 1.0);
  }

  // ── XP rewards ──────────────────────────────────────────────
  static const int xpPerDrop = 2;
  static const int xpPerMerge = 10;
  static const int xpComboX2 = 20;
  static const int xpComboX3 = 40;
  static const int xpComboX4Plus = 80;
  static const int xpWatermelon = 300;

  /// XP reward at end of game based on score
  static int xpFromScore(int score) => (score / 10).round();

  /// Combo bonus XP
  static int comboXp(int combo) {
    if (combo >= 4) return xpComboX4Plus;
    if (combo == 3) return xpComboX3;
    if (combo == 2) return xpComboX2;
    return 0;
  }

  /// Human-readable level title
  static String levelTitle(int level) {
    if (level < 5)  return 'Rookie';
    if (level < 10) return 'Fruit Fan';
    if (level < 20) return 'Merge Master';
    if (level < 35) return 'Fruit Expert';
    if (level < 50) return 'Juice Lord';
    return 'Watermelon King 👑';
  }
}
