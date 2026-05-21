import 'package:audioplayers/audioplayers.dart';
import '../services/storage_service.dart';

class AudioManager {
  final StorageService _storage;

  bool _soundEnabled = true;
  bool _musicEnabled = true;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;

  // BGM uses a single persistent player (looping track).
  // SFX each get a short-lived player that self-disposes on completion,
  // allowing concurrent sounds without one cutting off another.
  final AudioPlayer _bgmPlayer = AudioPlayer();

  AudioManager(this._storage) {
    _soundEnabled = _storage.soundEnabled;
    _musicEnabled = _storage.musicEnabled;
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    await _storage.setSoundEnabled(_soundEnabled);
    // In-flight SFX players are short-lived and will finish on their own.
  }

  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;
    await _storage.setMusicEnabled(_musicEnabled);
    if (!_musicEnabled) {
      await _bgmPlayer.stop();
    } else {
      await startGameMusic();
    }
  }

  // Each SFX gets its own short-lived player with audioFocus:none so it
  // never fires AUDIOFOCUS_LOSS at the BGM player. Disposes itself on completion.
  Future<void> _playSfx(String path) async {
    if (!_soundEnabled) return;
    final player = AudioPlayer();
    try {
      await player.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          audioFocus: AndroidAudioFocus.none,
          usageType: AndroidUsageType.game,
          contentType: AndroidContentType.sonification,
        ),
      ));
      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(AssetSource(path));
      await player.onPlayerComplete.first;
    } catch (_) {
      // play failed or stream errored
    } finally {
      player.dispose();
    }
  }

  Future<void> _playBgm(String path) async {
    if (!_musicEnabled) return;
    try {
      await _bgmPlayer.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          audioFocus: AndroidAudioFocus.gain,
          usageType: AndroidUsageType.game,
          contentType: AndroidContentType.music,
        ),
      ));
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.4);
      await _bgmPlayer.play(AssetSource(path));
    } catch (_) {}
  }

  // ── SFX ───────────────────────────────────────────────────────

  void playDrop()       => _playSfx('audio/sfx_drop.mp3');
  void playMerge()      => _playSfx('audio/sfx_merge_small.mp3');
  void playCombo()      => _playSfx('audio/sfx_combo.mp3');
  void playGameOver()   => _playSfx('audio/sfx_game_over.mp3');
  void playWin()        => _playSfx('audio/sfx_win.mp3');
  void playButtonTap()  => _playSfx('audio/sfx_button.mp3');
  void playBomb()       => _playSfx('audio/sfx_bomb.mp3');
  void playShaker()     => _playSfx('audio/sfx_shaker.mp3');
  void playSniper()     => _playSfx('audio/sfx_sniper.mp3');
  void playLuckyDrop()  => _playSfx('audio/sfx_lucky.mp3');
  void playDanger()     => _playSfx('audio/sfx_danger.mp3');

  void playMergeForLevel(int level) {
    if (level <= 3) {
      _playSfx('audio/sfx_merge_small.mp3');
    } else if (level <= 6) {
      _playSfx('audio/sfx_merge-medium.mp3');
    } else if (level <= 9) {
      _playSfx('audio/sfx_merge_large.mp3');
    } else {
      _playSfx('audio/sfx_merge-watermelon.mp3');
    }
  }

  // ── BGM ───────────────────────────────────────────────────────

  static const _bgmPath = 'audio/Apricot Market Morning_bgm.mp3';

  Future<void> startMenuMusic() => _startBgmWithRetry();

  Future<void> startGameMusic() => _startBgmWithRetry();

  // Plays BGM and retries once after 700ms if Android audio wasn't ready yet.
  Future<void> _startBgmWithRetry() async {
    await _playBgm(_bgmPath);
    await Future.delayed(const Duration(milliseconds: 700));
    if (_musicEnabled && _bgmPlayer.state != PlayerState.playing) {
      await _playBgm(_bgmPath);
    }
  }

  // Use after pause — resumes from where the track left off.
  Future<void> resumeGameMusic() async {
    if (!_musicEnabled) return;
    try { await _bgmPlayer.resume(); } catch (_) {}
  }

  void startBackgroundMusic() => startGameMusic();

  Future<void> stopBackgroundMusic() async {
    try { await _bgmPlayer.pause(); } catch (_) {}
  }

  void dispose() {
    _bgmPlayer.dispose();
  }
}
