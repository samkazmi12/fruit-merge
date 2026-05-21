import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent storage — game settings, scores, profile, XP, stats
class StorageService {
  // Keys
  static const _highScoreKey   = 'high_score';
  static const _soundKey       = 'sound_enabled';
  static const _musicKey       = 'music_enabled';
  static const _vibrationKey   = 'vibration_enabled';

  // Profile
  static const _playerNameKey  = 'player_name';
  static const _avatarEmojiKey = 'avatar_emoji';

  // XP / Level
  static const _totalXpKey     = 'total_xp';

  // Stats
  static const _gamesPlayedKey = 'games_played';
  static const _totalMergesKey = 'total_merges';
  static const _biggestFruitKey= 'biggest_fruit_index'; // FruitType.index
  static const _totalDropsKey  = 'total_drops';

  // Currency & Power-Ups
  static const _coinsKey       = 'coins';
  static const _bombCountKey   = 'bomb_count';
  static const _shakerCountKey = 'shaker_count';
  static const _sniperCountKey = 'sniper_count';

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── High Score ─────────────────────────────────────────────────
  int get highScore => _prefs.getInt(_highScoreKey) ?? 0;
  Future<void> setHighScore(int score) async {
    if (score > highScore) await _prefs.setInt(_highScoreKey, score);
  }
  Future<void> resetHighScore() async => _prefs.setInt(_highScoreKey, 0);

  // ── Sound / Music / Vibration ──────────────────────────────────
  bool get soundEnabled     => _prefs.getBool(_soundKey)     ?? true;
  bool get musicEnabled     => _prefs.getBool(_musicKey)     ?? true;
  bool get vibrationEnabled => _prefs.getBool(_vibrationKey) ?? true;

  Future<void> setSoundEnabled(bool v)     async => _prefs.setBool(_soundKey, v);
  Future<void> setMusicEnabled(bool v)     async => _prefs.setBool(_musicKey, v);
  Future<void> setVibrationEnabled(bool v) async => _prefs.setBool(_vibrationKey, v);

  // ── Profile ────────────────────────────────────────────────────
  String get playerName   => _prefs.getString(_playerNameKey)  ?? 'Fruit Master';
  String get avatarEmoji  => _prefs.getString(_avatarEmojiKey) ?? '🍉';

  Future<void> setPlayerName(String name) async =>
      _prefs.setString(_playerNameKey, name.trim().isEmpty ? 'Fruit Master' : name.trim());
  Future<void> setAvatarEmoji(String emoji) async =>
      _prefs.setString(_avatarEmojiKey, emoji);

  // ── XP ─────────────────────────────────────────────────────────
  int get totalXp => _prefs.getInt(_totalXpKey) ?? 0;
  Future<void> addXp(int xp) async {
    await _prefs.setInt(_totalXpKey, totalXp + xp);
  }

  // ── Stats ──────────────────────────────────────────────────────
  int get gamesPlayed    => _prefs.getInt(_gamesPlayedKey) ?? 0;
  int get totalMerges    => _prefs.getInt(_totalMergesKey) ?? 0;
  int get totalDrops     => _prefs.getInt(_totalDropsKey)  ?? 0;
  int get biggestFruitIndex => _prefs.getInt(_biggestFruitKey) ?? 0;

  Future<void> incrementGamesPlayed() async =>
      _prefs.setInt(_gamesPlayedKey, gamesPlayed + 1);
  Future<void> addMerges(int count) async =>
      _prefs.setInt(_totalMergesKey, totalMerges + count);
  Future<void> addDrops(int count) async =>
      _prefs.setInt(_totalDropsKey, totalDrops + count);
  Future<void> updateBiggestFruit(int fruitIndex) async {
    if (fruitIndex > biggestFruitIndex) {
      await _prefs.setInt(_biggestFruitKey, fruitIndex);
    }
  }

  // ── Currency & Power-Ups ───────────────────────────────────────
  int get coins       => _prefs.getInt(_coinsKey)       ?? 0;
  int get bombCount   => _prefs.getInt(_bombCountKey)   ?? 3; // Start with 3 free
  int get shakerCount => _prefs.getInt(_shakerCountKey) ?? 3;
  int get sniperCount => _prefs.getInt(_sniperCountKey) ?? 3;

  Future<void> addCoins(int amount) async {
    await _prefs.setInt(_coinsKey, coins + amount);
  }
  Future<void> addBombs(int amount) async {
    await _prefs.setInt(_bombCountKey, bombCount + amount);
  }
  Future<void> addShakers(int amount) async {
    await _prefs.setInt(_shakerCountKey, shakerCount + amount);
  }
  Future<void> addSnipers(int amount) async {
    await _prefs.setInt(_sniperCountKey, sniperCount + amount);
  }
  
  // Combine uses for easier API
  Future<void> consumeBomb() async { if (bombCount > 0) await _prefs.setInt(_bombCountKey, bombCount - 1); }
  Future<void> consumeShaker() async { if (shakerCount > 0) await _prefs.setInt(_shakerCountKey, shakerCount - 1); }
  Future<void> consumeSniper() async { if (sniperCount > 0) await _prefs.setInt(_sniperCountKey, sniperCount - 1); }

  // ── Saved game state ───────────────────────────────────────────
  static const _savedGameKey = 'saved_game';

  bool get hasSavedGame => _prefs.containsKey(_savedGameKey);

  Map<String, dynamic>? loadGameState() {
    final s = _prefs.getString(_savedGameKey);
    if (s == null) return null;
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      _prefs.remove(_savedGameKey);
      return null;
    }
  }

  Future<void> saveGameState(Map<String, dynamic> state) async =>
      _prefs.setString(_savedGameKey, jsonEncode(state));

  Future<void> clearGameState() async => _prefs.remove(_savedGameKey);
}
