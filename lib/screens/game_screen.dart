import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/fruit_physics.dart';
import '../game/game_painter.dart';
import '../models/fruit_data.dart';
import '../models/level_system.dart';
import '../services/audio_manager.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import 'overlays/game_over_overlay.dart';
import 'overlays/hud_overlay.dart';
import 'overlays/pause_overlay.dart';
import 'overlays/watermelon_win_overlay.dart';

enum PowerUpMode { none, bomb, sniper, shaker }

class GameScreen extends StatefulWidget {
  final StorageService storage;
  final AudioManager audio;

  const GameScreen({super.key, required this.storage, required this.audio});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // ── Engine ─────────────────────────────────────────────────────
  final ValueNotifier<int> _tickNotifier = ValueNotifier(0);
  // ── Ticker ─────────────────────────────────────────────────────
  late Ticker _ticker;
  Duration _lastTime = Duration.zero;

  // ── Physics ────────────────────────────────────────────────────
  FruitPhysics? _physics;
  final List<FruitParticle> _fruits = [];
  int _nextId = 0;

  // ── Effects ────────────────────────────────────────────────────
  final List<MergeParticle> _particles = [];
  final List<ScorePopup> _popups = [];

  // ── Box layout ─────────────────────────────────────────────────
  double _boxLeft = 0, _boxRight = 0, _boxTop = 0, _boxBottom = 0;
  double _dropY = 0, _gameOverLineY = 0;
  double _cardsH = 0;
  double _adH = 0;
  bool _boxReady = false;

  // ── Drop zone visuals ───────────────────────────────────────────
  ui.Image? _cloudImage;
  ui.Image? _branchImage;
  final List<CloudState> _clouds = [];

  // ── Game state ─────────────────────────────────────────────────
  FruitType _currentType = FruitType.cherry;
  FruitType _nextType = FruitType.cherry;
  double _dropX = 0;
  FruitParticle? _preview;

  int _score = 0;
  int _highScore = 0;
  int _combo = 0;
  double _comboTimer = 0;
  bool _isPaused = false;
  bool _isGameOver = false;
  bool _isWatermelonWin = false;

  // ── XP & Level ─────────────────────────────────────────────────
  int _sessionXp = 0; // XP earned this session
  int _levelAtStart = 1; // level when game started

  // ── Power-Ups ──────────────────────────────────────────────────
  PowerUpMode _powerUpMode = PowerUpMode.none;

  // ── Combo banner ────────────────────────────────────────────────
  double _comboBannerOpacity = 0;
  double _comboBannerScale = 1.0;
  int _lastShownCombo = 0;

  // ── Danger level ────────────────────────────────────────────────
  double _dangerLevel = 0;
  bool _wasInDanger = false;

  // ── Physics alive-list buffer (reused every tick, no per-frame alloc) ──
  final List<FruitParticle> _aliveFruits = [];
  bool _hasDead = false; // set true whenever a fruit's alive → false

  // ── Drop-weight cache (computed once, avoids List.generate per drop) ──
  static final List<double> _dropWeights = () {
    final d = FruitData.droppableFruits;
    return List.generate(d.length, (i) => (d.length - i).toDouble());
  }();
  static final double _dropWeightTotal = _dropWeights.fold(
    0.0,
    (s, w) => s + w,
  );

  // ── Best fruit this session ──────────────────────────────────────
  int _bestFruitIndex = 0; // FruitType.index of best merged/dropped

  // ── Lucky drop ──────────────────────────────────────────────────
  int _dropCount = 0; // counts drops since last lucky
  bool _nextIsLucky = false;

  // ── Drag ───────────────────────────────────────────────────────
  bool _isDragging = false;
  bool _canDrop = true;

  // ── Session stats ───────────────────────────────────────────────
  int _sessionMerges = 0;
  int _sessionDrops = 0;

  final Random _rng = Random();

  // ── Fruit sprites ───────────────────────────────────────────────
  final Map<FruitType, ui.Image> _fruitImages = {};

  static const _comboColors = [
    Color(0xFFFFD600),
    Color(0xFFFF9800),
    Color(0xFFFF5722),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
  ];
  Color get _comboColor =>
      _comboColors[(_combo - 2).clamp(0, _comboColors.length - 1)];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _highScore = widget.storage.highScore;
    _levelAtStart = LevelSystem.levelFromXp(widget.storage.totalXp);
    _ticker = createTicker(_onTick)..start();
    _loadFruitImages();
    // Delay BGM start so Android's audio system is ready before we request focus.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) widget.audio.startGameMusic();
    });
  }

  Future<void> _loadFruitImages() async {
    const sprites = {
      FruitType.cherry: 'assets/images/fruit_cherry.png',
      FruitType.strawberry: 'assets/images/fruit_strawberry.png',
      FruitType.grape: 'assets/images/fruit_grape.png',
      FruitType.orange: 'assets/images/fruit_orange.png',
      FruitType.apple: 'assets/images/fruit_apple.png',
      FruitType.pear: 'assets/images/fruit_pear.png',
      FruitType.peach: 'assets/images/fruit_peach.png',
      FruitType.pineapple: 'assets/images/fruit_pineapple.png',
      FruitType.melon: 'assets/images/fruit_melon.png',
      FruitType.watermelon: 'assets/images/fruit_watermelon.png',
    };
    for (final entry in sprites.entries) {
      try {
        final data = await rootBundle.load(entry.value);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        codec.dispose();
        if (mounted) _fruitImages[entry.key] = frame.image;
      } catch (_) {}
    }
    for (final path in const [
      'assets/images/asset_cloud.png',
      'assets/images/asset_branch.png',
    ]) {
      try {
        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        codec.dispose();
        if (mounted) {
          if (path.contains('cloud')) _cloudImage = frame.image;
          if (path.contains('branch')) _branchImage = frame.image;
        }
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveGameState();
      _flushStats();
      if (!_isGameOver && !_isPaused) {
        setState(() => _isPaused = true);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _tickNotifier.dispose();
    widget.audio.stopBackgroundMusic();
    super.dispose();
  }

  void _initBox(Size size) {
    if (_boxReady) return;
    // Constrain jar max width so it doesn't deform on tablets/landscape
    final effectiveWidth = size.width.clamp(0.0, 450.0);
    final offsetLeft = (size.width - effectiveWidth) / 2;
    // Cap jar height so it doesn't dominate the screen on tall/large devices
    final sf = (size.width / 390).clamp(0.75, 1.35);
    final hudH = 130.0 * sf;
    // _hudH = hudH;
    _cardsH = 64.0 * sf;
    _adH = 60.0;
    const sidePad = 8.0;
    _boxLeft = offsetLeft + sidePad;
    _boxRight = offsetLeft + effectiveWidth - sidePad;
    _boxBottom = size.height - _cardsH * 2 - _adH;
    final jarWidth = _boxRight - _boxLeft;
    _boxTop = (_boxBottom - jarWidth).clamp(hudH + 16, _boxBottom - 80);

    _gameOverLineY = _boxTop + GameConstants.gameOverLineOffsetPx;
    _physics = FruitPhysics(
      boxLeft: _boxLeft,
      boxRight: _boxRight,
      boxTop: _boxTop,
      boxBottom: _boxBottom,
    );
    _boxReady = true;
    _dropX = (_boxLeft + _boxRight) / 2;

    // ── Init clouds in drop zone ──────────────────────────────────
    if (_clouds.isEmpty) {
      final dzTop = hudH + 10;
      final dzH = _boxTop - hudH;
      // fruit diameter range: orange (42px) → watermelon (106px)
      _clouds.addAll([
        CloudState(
          x: _boxLeft + jarWidth * 0.18,
          y: dzTop + dzH * 0.25,
          width: 68,
          speed: 18,
        ),
        CloudState(
          x: _boxLeft + jarWidth * 0.72,
          y: dzTop + dzH * 0.55,
          width: 46,
          speed: -22,
        ),
        CloudState(
          x: _boxLeft + jarWidth * 0.45,
          y: dzTop + dzH * 0.78,
          width: 88,
          speed: 14,
        ),
      ]);
    }

    _nextType = _randomType();
    if (!_tryRestoreGame()) _spawnNext();
  }

  FruitType _randomType({bool lucky = false}) {
    final droppable = FruitData.droppableFruits; // cached — no allocation
    if (lucky) {
      final currentIdx = droppable.indexWhere((f) => f.type == _nextType);
      final luckIdx = (currentIdx + 1).clamp(0, droppable.length - 2);
      return droppable[luckIdx].type;
    }
    var r = _rng.nextDouble() * _dropWeightTotal;
    for (int i = 0; i < droppable.length; i++) {
      r -= _dropWeights[i];
      if (r <= 0) return droppable[i].type;
    }
    return droppable[0].type;
  }

  void _spawnNext() {
    if (_isGameOver || !_boxReady) return;
    _currentType = _nextType;

    _dropCount++;
    if (_dropCount % 10 == 0) {
      _nextIsLucky = true;
      widget.audio.playLuckyDrop();
    }

    _nextType = _nextIsLucky ? _randomType(lucky: true) : _randomType();
    _nextIsLucky = false;

    final data = FruitData.fromType(_currentType);
    _dropY = _boxTop - data.radiusPx - 8;
    _dropX = _dropX.clamp(
      _boxLeft + data.radiusPx + 2,
      _boxRight - data.radiusPx - 2,
    );

    _preview = FruitParticle(
      id: _nextId++,
      type: _currentType,
      x: _dropX,
      y: _dropY,
      radius: data.radiusPx,
      isPreview: true,
    );
    _fruits.add(_preview!);
  }

  bool _tryRestoreGame() {
    final state = widget.storage.loadGameState();
    if (state == null) return false;
    try {
      _score = state['score'] as int;
      _highScore = max(_highScore, _score);
      _currentType = FruitType.values.byName(state['currentType'] as String);
      _nextType = FruitType.values.byName(state['nextType'] as String);
      _dropX = (state['dropX'] as num).toDouble();
      _dropCount = state['dropCount'] as int;
      _nextIsLucky = state['nextIsLucky'] as bool;
      _sessionXp = state['sessionXp'] as int;
      _sessionMerges = state['sessionMerges'] as int;
      _sessionDrops = state['sessionDrops'] as int;
      _bestFruitIndex = state['bestFruitIndex'] as int;
      _nextId = state['nextId'] as int;
      for (final j in state['fruits'] as List<dynamic>) {
        _fruits.add(FruitParticle.fromJson(j as Map<String, dynamic>));
      }
      _spawnPreview();
      return true;
    } catch (_) {
      widget.storage.clearGameState();
      _fruits.clear();
      return false;
    }
  }

  void _spawnPreview() {
    if (_isGameOver || !_boxReady) return;
    final data = FruitData.fromType(_currentType);
    _dropY = _boxTop - data.radiusPx - 8;
    _dropX = _dropX.clamp(
      _boxLeft + data.radiusPx + 2,
      _boxRight - data.radiusPx - 2,
    );
    _preview = FruitParticle(
      id: _nextId++,
      type: _currentType,
      x: _dropX,
      y: _dropY,
      radius: data.radiusPx,
      isPreview: true,
    );
    _fruits.add(_preview!);
  }

  Future<void> _saveGameState() async {
    if (_isGameOver || _isWatermelonWin || !_boxReady) return;
    final fruitsToSave = _fruits
        .where((f) => f.alive && !f.isPreview && !f.isMerging)
        .map((f) => f.toJson())
        .toList();
    await widget.storage.saveGameState({
      'fruits': fruitsToSave,
      'score': _score,
      'currentType': _currentType.name,
      'nextType': _nextType.name,
      'dropX': _dropX,
      'dropCount': _dropCount,
      'nextIsLucky': _nextIsLucky,
      'sessionXp': _sessionXp,
      'sessionMerges': _sessionMerges,
      'sessionDrops': _sessionDrops,
      'bestFruitIndex': _bestFruitIndex,
      'nextId': _nextId,
    });
  }

  void _dropFruit() {
    if (_isGameOver || _isPaused || _isWatermelonWin || !_canDrop) return;
    final p = _preview;
    if (p == null) return;

    if (widget.storage.vibrationEnabled) HapticFeedback.lightImpact();
    widget.audio.playDrop();
    p.isPreview = false;
    p.vy = 60;
    p.angularVel = (_rng.nextDouble() - 0.5) * 4.0;
    _preview = null;
    _canDrop = false;
    _sessionDrops++;

    // XP per drop
    _gainXp(LevelSystem.xpPerDrop);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isGameOver && mounted) {
        _canDrop = true;
        _spawnNext();
      }
    });
  }

  // ── Game loop ──────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    if (!mounted || !_boxReady) return;
    final dt = _lastTime == Duration.zero
        ? 0.016
        : (elapsed - _lastTime).inMicroseconds / 1000000.0;
    _lastTime = elapsed;

    if (_isPaused || _isGameOver || _isWatermelonWin) return;

    // Rebuild alive buffer — reuses the same List object every tick
    _aliveFruits.clear();
    for (final f in _fruits) {
      if (f.alive) _aliveFruits.add(f);
    }

    _physics!.step(_aliveFruits, dt);
    if (_particles.isNotEmpty) {
      _physics!.stepParticles(_particles, dt);
      _particles.removeWhere((p) => !p.alive);
    }
    if (_popups.isNotEmpty) {
      _physics!.stepPopups(_popups, dt);
      _popups.removeWhere((p) => !p.alive);
    }

    // Combo timer
    if (_comboTimer > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) _combo = 0;
    }
    // Combo banner fade
    if (_comboBannerOpacity > 0) {
      _comboBannerOpacity = (_comboBannerOpacity - dt * 1.6).clamp(0, 1);
      _comboBannerScale = (_comboBannerScale - dt * 2.5).clamp(1.0, 2.0);
    }

    final merges = _physics!.detectMerges(_aliveFruits);
    for (final (a, b) in merges) {
      _handleMerge(a, b);
    }

    // Only prune dead fruits when merges (or kills) happened this tick
    if (_hasDead) {
      _fruits.removeWhere((f) => !f.alive);
      _aliveFruits.removeWhere((f) => !f.alive);
      _hasDead = false;
    }

    _updateDangerLevel();
    _checkGameOver();

    // ── Drift clouds left/right, wrap at box edges ────────────────
    for (final c in _clouds) {
      c.x += c.speed * dt;
      final hw = c.width / 2;
      if (c.speed > 0 && c.x - hw > _boxRight) c.x = _boxLeft - hw;
      if (c.speed < 0 && c.x + hw < _boxLeft) c.x = _boxRight + hw;
    }

    _tickNotifier.value++;
  }

  void _handleMerge(FruitParticle a, FruitParticle b) {
    a.isMerging = true;
    b.isMerging = true;

    final data = FruitData.fromType(a.type);
    final mx = (a.x + b.x) / 2;
    final my = (a.y + b.y) / 2;
    final mvx = (a.vx + b.vx) / 2;
    final mvy = (a.vy + b.vy) / 2;

    a.alive = false;
    b.alive = false;
    _hasDead = true;
    _sessionMerges++;
    if (widget.storage.vibrationEnabled) HapticFeedback.mediumImpact();

    // Best fruit update
    if (data.level > _bestFruitIndex + 1) {
      _bestFruitIndex = data.level - 1;
    }

    // Score
    final mult = _combo > 1 ? _combo : 1;
    final gained = data.points * mult;
    _score += gained;

    // Combo
    if (_comboTimer > 0) {
      _combo++;
    } else {
      _combo = 1;
    }
    _comboTimer = GameConstants.comboTimeWindow;

    if (_combo >= 2) {
      _comboBannerOpacity = 1.0;
      _comboBannerScale = 1.55;
      _lastShownCombo = _combo;
    }

    // XP
    int xp = LevelSystem.xpPerMerge + LevelSystem.comboXp(_combo);
    if (data.type == FruitType.watermelon) xp += LevelSystem.xpWatermelon;
    _gainXp(xp);

    // Particles + popup — cap total to prevent GC pressure during cascades
    final burst = _physics!.createMergeBurst(mx, my, data.color, a.radius);
    if (_particles.length + burst.length > 50) {
      final excess = (_particles.length + burst.length - 50).clamp(
        0,
        _particles.length,
      );
      if (excess > 0) _particles.removeRange(0, excess);
    }
    _particles.addAll(burst);
    _popups.add(
      ScorePopup(
        x: mx,
        y: my - a.radius - 10,
        text: '+$gained',
        color: _combo > 1 ? _comboColor : const Color(0xFFFFD600),
      ),
    );

    // Evolved fruit
    if (data.canEvolve) {
      final nextData = FruitData.fromType(data.nextType!);
      final initSpin = (_rng.nextDouble() - 0.5) * 6.0;
      _fruits.add(
        FruitParticle(
          id: _nextId++,
          type: data.nextType!,
          x: mx,
          y: my,
          vx: mvx,
          vy: mvy - 90,
          radius: nextData.radiusPx,
          angularVel: initSpin,
          spawnScale: 0.1,
          mergeGlow: 1.0,
        ),
      );
    } else {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _triggerWatermelonWin();
      });
    }

    if (_score > _highScore) {
      _highScore = _score;
      widget.storage.setHighScore(_highScore);
    }
    widget.audio.playMergeForLevel(data.level);
    if (_combo >= 2) widget.audio.playCombo();
  }

  void _triggerWatermelonWin() {
    if (_isWatermelonWin || _isGameOver) return;
    _isWatermelonWin = true;
    const bonusScore = 500;
    _score += bonusScore;
    _gainXp(LevelSystem.xpWatermelon * 2);
    if (_score > _highScore) {
      _highScore = _score;
      widget.storage.setHighScore(_highScore);
    }
    if (widget.storage.vibrationEnabled) HapticFeedback.heavyImpact();
    widget.storage.clearGameState();
    _flushStats();
    widget.audio.playWin();
    setState(() {});
  }

  void _gainXp(int xp) {
    _sessionXp += xp;
  }

  void _updateDangerLevel() {
    double highestY = _boxBottom;
    for (final f in _aliveFruits) {
      if (f.isPreview) continue;
      if (f.y - f.radius < _boxTop) continue;
      if (f.vy > 50) continue;
      final topEdge = f.y - f.radius;
      if (topEdge < highestY) highestY = topEdge;
    }
    final boxH = _boxBottom - _boxTop;
    final filled = (_boxBottom - highestY) / boxH;
    _dangerLevel = ((filled - 0.5) / 0.5).clamp(0.0, 1.0);
    final nowInDanger = _dangerLevel > 0;
    if (nowInDanger && !_wasInDanger) widget.audio.playDanger();
    _wasInDanger = nowInDanger;
  }

  void _checkGameOver() {
    for (final f in _aliveFruits) {
      if (f.isPreview || f.isMerging) continue;
      if (f.y - f.radius < _gameOverLineY &&
          f.vy.abs() < 30 &&
          f.vx.abs() < 30) {
        _triggerGameOver();
        return;
      }
    }
  }

  void _triggerGameOver() {
    if (_isGameOver || _isWatermelonWin) return;
    _isGameOver = true;
    // End-of-game XP from score
    _gainXp(LevelSystem.xpFromScore(_score));
    final newCoins = _score ~/ 50;
    widget.storage.addCoins(newCoins);
    widget.storage.clearGameState();
    _flushStats();
    widget.audio.playGameOver();
  }

  Future<void> _flushStats() async {
    // Snapshot before any await so a concurrent _restartGame reset can't zero
    // out session fields while this chain is still running.
    final xp = _sessionXp;
    final merges = _sessionMerges;
    final drops = _sessionDrops;
    final bestFruit = _bestFruitIndex;
    final highScore = _highScore;
    await widget.storage.addXp(xp);
    await widget.storage.incrementGamesPlayed();
    await widget.storage.addMerges(merges);
    await widget.storage.addDrops(drops);
    await widget.storage.updateBiggestFruit(bestFruit);
    await widget.storage.setHighScore(highScore);
  }

  void _restartGame() {
    widget.storage.clearGameState();
    setState(() {
      _fruits.clear();
      _particles.clear();
      _popups.clear();
      _aliveFruits.clear();
      _hasDead = false;
      _preview = null;
      _isDragging = false;
      _score = 0;
      _combo = 0;
      _comboTimer = 0;
      _comboBannerOpacity = 0;
      _dangerLevel = 0;
      _wasInDanger = false;
      _isPaused = false;
      _isGameOver = false;
      _isWatermelonWin = false;
      _canDrop = true;
      _lastTime = Duration.zero;
      _sessionXp = 0;
      _sessionMerges = 0;
      _sessionDrops = 0;
      _bestFruitIndex = 0;
      _dropCount = 0;
      _nextType = _randomType();
    });
    _levelAtStart = LevelSystem.levelFromXp(widget.storage.totalXp);
    _spawnNext();
  }

  // ── Input ──────────────────────────────────────────────────────
  void _onPanStart(DragStartDetails d) {
    if (_isGameOver || _isPaused || _isWatermelonWin) return;
    if (_powerUpMode != PowerUpMode.none) return;
    _isDragging = true;
    _moveDrop(d.localPosition.dx);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_isDragging || _isGameOver || _isPaused) return;
    if (_powerUpMode != PowerUpMode.none) return;
    _moveDrop(d.localPosition.dx);
  }

  void _onPanEnd(DragEndDetails _) {
    if (!_isDragging) return;
    if (_powerUpMode != PowerUpMode.none) return;
    _isDragging = false;
    _dropFruit();
  }

  void _onTapUp(TapUpDetails d) {
    if (_isGameOver || _isPaused || _isWatermelonWin) return;
    if (_powerUpMode != PowerUpMode.none) {
      if (_powerUpMode == PowerUpMode.shaker) {
        _activateShaker();
        setState(() => _powerUpMode = PowerUpMode.none);
      } else {
        _applyPowerUp(d.localPosition);
      }
      return;
    }
    if (_isDragging) return;
    _moveDrop(d.localPosition.dx);
    _dropFruit();
  }

  void _applyPowerUp(Offset pos) {
    if (_powerUpMode == PowerUpMode.none) return;
    // Find tapped fruit
    final alive = _fruits
        .where((f) => f.alive && !f.isPreview && f.y > _boxTop)
        .toList();
    FruitParticle? target;
    for (final f in alive) {
      final dx = f.x - pos.dx;
      final dy = f.y - pos.dy;
      if (dx * dx + dy * dy <= f.radius * f.radius * 1.5) {
        target = f;
        break;
      }
    }

    if (_powerUpMode == PowerUpMode.bomb) {
      if (target != null) {
        _useBomb(target, pos);
      } else {
        // Tapped empty space, cancel
        setState(() => _powerUpMode = PowerUpMode.none);
      }
    } else if (_powerUpMode == PowerUpMode.sniper) {
      if (target != null) {
        _useSniper(target);
      } else {
        setState(() => _powerUpMode = PowerUpMode.none);
      }
    }
  }

  void _useBomb(FruitParticle target, Offset hitPos) {
    widget.storage.consumeBomb();
    final blastRadius = 120.0;
    final alive = _fruits.where((f) => f.alive && !f.isPreview).toList();
    for (final f in alive) {
      final dx = f.x - hitPos.dx;
      final dy = f.y - hitPos.dy;
      if (dx * dx + dy * dy <= blastRadius * blastRadius) {
        f.alive = false;
        // spawn particles
        final data = FruitData.fromType(f.type);
        for (int i = 0; i < 5; i++) {
          _particles.add(
            MergeParticle(
              x: f.x,
              y: f.y,
              color: data.color,
              radius: 8,
              vx: (f.x - hitPos.dx) * 2 + (_rng.nextDouble() - 0.5) * 100,
              vy: (f.y - hitPos.dy) * 2 + (_rng.nextDouble() - 0.5) * 100,
            ),
          );
        }
      }
    }
    _hasDead = true;
    widget.audio.playBomb();
    setState(() => _powerUpMode = PowerUpMode.none);
  }

  void _useSniper(FruitParticle target) {
    final data = FruitData.fromType(target.type);
    if (data.level < 10) {
      // Max level is watermelon (level 11) but array is 0-indexed, wait: All fruits length is 11, so level 10 is max generic.
      widget.storage.consumeSniper();
      final dropList = FruitData.allFruits;
      final nextData = dropList.firstWhere((d) => d.level == data.level + 1);
      target.type = nextData.type;
      target.radius = nextData.radiusPx;

      for (int i = 0; i < 8; i++) {
        _particles.add(
          MergeParticle(
            x: target.x,
            y: target.y,
            color: nextData.color,
            radius: 10,
            vx: (_rng.nextDouble() - 0.5) * 200,
            vy: (_rng.nextDouble() - 0.5) * 200,
          ),
        );
      }
      widget.audio.playSniper();
    }
    setState(() => _powerUpMode = PowerUpMode.none);
  }

  void _activateShaker() {
    widget.storage.consumeShaker();
    final alive = _fruits.where((f) => f.alive && !f.isPreview).toList();
    for (final f in alive) {
      f.vy -= 250 + _rng.nextDouble() * 150;
      f.vx += (_rng.nextDouble() - 0.5) * 200;
    }
    widget.audio.playShaker();
  }

  void _moveDrop(double screenX) {
    if (_preview == null) return;
    final r = _preview!.radius;
    _dropX = screenX.clamp(_boxLeft + r + 2, _boxRight - r - 2);
    _preview!.x = _dropX;
  }

  // ── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFDDE5B6),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              _initBox(size);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onTapUp: _onTapUp,
                child: AnimatedBuilder(
                  animation: _tickNotifier,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        // ── Canvas ─────────────────────────────────
                        Positioned.fill(
                          child: _boxReady
                              ? RepaintBoundary(
                                  child: CustomPaint(
                                    painter: GamePainter(
                                      fruits: _aliveFruits,
                                      particles: _particles,
                                      boxLeft: _boxLeft,
                                      boxRight: _boxRight,
                                      boxTop: _boxTop,
                                      boxBottom: _boxBottom,
                                      gameOverLineY: _gameOverLineY,
                                      dangerLevel: _dangerLevel,
                                      fruitImages: _fruitImages,
                                      clouds: _clouds,
                                      cloudImage: _cloudImage,
                                      branchImage: _branchImage,
                                      dropX: _dropX,
                                      dropY: _dropY,
                                      dropFruitRadius: _preview?.radius ?? 20,
                                      showDropper:
                                          _boxReady &&
                                          !_isGameOver &&
                                          !_isPaused,
                                    ),
                                    size: size,
                                  ),
                                )
                              : const SizedBox(),
                        ),

                        // ── Ad banner placeholder ─────────────────────
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: _adH,
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.55),
                            child: Center(
                              child: Text(
                                'AD',
                                style: GoogleFonts.fredoka(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  fontSize: 13,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ── Evolution progress strip ──────────────────
                        Positioned(
                          bottom: _adH + _cardsH,
                          left: 0,
                          right: 0,
                          height: _cardsH,
                          child: RepaintBoundary(child: _evolutionBar(context)),
                        ),

                        // ── Combo banner ────────────────────────────
                        if (_comboBannerOpacity > 0 && _combo >= 2)
                          Positioned(
                            top: _boxTop + 22,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              child: Center(
                                child: Transform.scale(
                                  scale: _comboBannerScale,
                                  child: Opacity(
                                    opacity: _comboBannerOpacity,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: context.s(22),
                                        vertical: context.s(8),
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            _comboColor,
                                            _comboColor.withValues(alpha: 0.7),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          context.s(30),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _comboColor.withValues(
                                              alpha: 0.6,
                                            ),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        '${_lastShownCombo}x COMBO! 🔥',
                                        style: GoogleFonts.fredoka(
                                          fontSize: context.sp(26),
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // ── Native Overlay Score Popups ─────────────────
                        ..._popups.map(
                          (p) => Positioned(
                            left: p.x - 40, // rough centering
                            top: p.y - 20,
                            child: IgnorePointer(
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
                          ),
                        ),

                        // ── HUD (RepaintBoundary so score doesn't ──
                        // trigger canvas repaint)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: RepaintBoundary(
                            child: HudOverlay(
                              score: _score,
                              highScore: _highScore,
                              combo: _combo,
                              nextFruit: _nextType,
                              bestFruitIndex: _bestFruitIndex,
                              currentLevel: _levelAtStart,
                              onPause: () {
                                widget.audio
                                    .stopBackgroundMusic(); // pauses, keeps position
                                setState(() => _isPaused = true);
                              },
                            ),
                          ),
                        ),

                        // ── Power-Up Cards ─────────────────────────────
                        if (_boxReady && !_isGameOver && !_isPaused)
                          Positioned(
                            bottom: _adH,
                            left: 0,
                            right: 0,
                            height: _cardsH,
                            child: _powerUpCards(context),
                          ),

                        if (_isPaused)
                          PauseOverlay(
                            audio: widget.audio,
                            onResume: () {
                              widget.audio.resumeGameMusic();
                              setState(() => _isPaused = false);
                            },
                            onRestart: () {
                              setState(() => _isPaused = false);
                              _restartGame();
                            },
                            onHome: () => Navigator.pop(context),
                          ),

                        if (_isGameOver)
                          GameOverOverlay(
                            score: _score,
                            highScore: _highScore,
                            isNewHighScore: _score > 0 && _score >= _highScore,
                            sessionXp: _sessionXp,
                            onPlayAgain: _restartGame,
                            onHome: () => Navigator.pop(context),
                          ),

                        if (_isWatermelonWin)
                          WatermelonWinOverlay(
                            score: _score,
                            highScore: _highScore,
                            isNewHighScore: _score > 0 && _score >= _highScore,
                            sessionXp: _sessionXp,
                            onPlayAgain: _restartGame,
                            onHome: () => Navigator.pop(context),
                          ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _evolutionBar(BuildContext context) {
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
          final unlocked = e.key <= _bestFruitIndex;
          // Highlight the very next fruit to unlock
          final isNext = e.key == _bestFruitIndex + 1;
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
              child: Text(
                e.value.emoji,
                style: TextStyle(
                  fontSize: context.sp(unlocked ? 18 : (isNext ? 15 : 12)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _powerUpCards(BuildContext context) {
    const bombColor = Color(0xFFFF5722);
    const shakerColor = Color(0xFF9C27B0);
    const sniperColor = Color(0xFF00BCD4);

    return Stack(
      alignment: Alignment.center,
      children: [
        // ── Background strip ──────────────────────────────────
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

        // ── Three power-up cards ──────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _powerUpCard(
              context: context,
              icon: '💣',
              label: 'Bomb',
              count: widget.storage.bombCount,
              isActive: _powerUpMode == PowerUpMode.bomb,
              activeColor: bombColor,
              onTap: () => setState(
                () => _powerUpMode = (_powerUpMode == PowerUpMode.bomb)
                    ? PowerUpMode.none
                    : PowerUpMode.bomb,
              ),
            ),
            SizedBox(width: context.s(20)),
            _powerUpCard(
              context: context,
              icon: '🪇',
              label: 'Shaker',
              count: widget.storage.shakerCount,
              isActive: _powerUpMode == PowerUpMode.shaker,
              activeColor: shakerColor,
              onTap: () => setState(
                () => _powerUpMode = (_powerUpMode == PowerUpMode.shaker)
                    ? PowerUpMode.none
                    : PowerUpMode.shaker,
              ),
            ),
            SizedBox(width: context.s(20)),
            _powerUpCard(
              context: context,
              icon: '🎯',
              label: 'Sniper',
              count: widget.storage.sniperCount,
              isActive: _powerUpMode == PowerUpMode.sniper,
              activeColor: sniperColor,
              onTap: () => setState(
                () => _powerUpMode = (_powerUpMode == PowerUpMode.sniper)
                    ? PowerUpMode.none
                    : PowerUpMode.sniper,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _powerUpCard({
    required BuildContext context,
    required String icon,
    required String label,
    required int count,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
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
