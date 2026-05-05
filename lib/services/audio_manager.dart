import '../services/storage_service.dart';

/// Audio manager for game sounds and music.
/// 
/// Currently a stub that tracks mute state.
/// Sound effect playback calls are placed throughout the game code
/// so adding real audio files later is trivial.
class AudioManager {
  final StorageService _storage;

  bool _soundEnabled = true;
  bool _musicEnabled = true;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;

  AudioManager(this._storage) {
    _soundEnabled = _storage.soundEnabled;
    _musicEnabled = _storage.musicEnabled;
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    await _storage.setSoundEnabled(_soundEnabled);
  }

  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;
    await _storage.setMusicEnabled(_musicEnabled);
  }

  // --- Sound effect stubs ---
  void playDrop() {
    if (!_soundEnabled) return;
    // TODO: Add actual drop sound
  }

  void playMerge() {
    if (!_soundEnabled) return;
    // TODO: Add actual merge pop sound
  }

  void playCombo() {
    if (!_soundEnabled) return;
    // TODO: Add actual combo celebration sound
  }

  void playGameOver() {
    if (!_soundEnabled) return;
    // TODO: Add actual game over sound
  }

  void playButtonTap() {
    if (!_soundEnabled) return;
    // TODO: Add actual button tap sound
  }

  void startBackgroundMusic() {
    if (!_musicEnabled) return;
    // TODO: Add background music
  }

  void stopBackgroundMusic() {
    // TODO: Stop background music
  }

  void dispose() {
    stopBackgroundMusic();
  }
}
