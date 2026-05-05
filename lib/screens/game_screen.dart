import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/fruit_data.dart';
import '../models/level_system.dart';
import '../services/audio_manager.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../game/fruit_physics.dart';
import '../game/game_painter.dart';
import 'overlays/hud_overlay.dart';
import 'overlays/pause_overlay.dart';
import 'overlays/game_over_overlay.dart';

enum PowerUpMode { none, bomb, sniper }

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
  bool _boxReady = false;

  // ── Game state ─────────────────────────────────────────────────
  FruitType _currentType = FruitType.cherry;
  FruitType _nextType    = FruitType.cherry;
  double _dropX = 0;
  FruitParticle? _preview;

  int _score      = 0;
  int _highScore  = 0;
  int _combo      = 0;
  double _comboTimer = 0;
  bool _isPaused   = false;
  bool _isGameOver = false;

  // ── XP & Level ─────────────────────────────────────────────────
  int _sessionXp        = 0;   // XP earned this session
  int  _levelAtStart     = 1;   // level when game started

  // ── Power-Ups ──────────────────────────────────────────────────
  PowerUpMode _powerUpMode = PowerUpMode.none;

  // ── Combo banner ────────────────────────────────────────────────
  double _comboBannerOpacity = 0;
  double _comboBannerScale   = 1.0;
  int    _lastShownCombo     = 0;

  // ── Danger level ────────────────────────────────────────────────
  double _dangerLevel = 0;

  // ── Best fruit this session ──────────────────────────────────────
  int _bestFruitIndex = 0;   // FruitType.index of best merged/dropped

  // ── Lucky drop ──────────────────────────────────────────────────
  int _dropCount = 0;       // counts drops since last lucky
  bool _nextIsLucky = false;

  // ── Drag ───────────────────────────────────────────────────────
  bool _isDragging = false;
  bool _canDrop    = true;

  // ── Session stats ───────────────────────────────────────────────
  int _sessionMerges = 0;
  int _sessionDrops  = 0;

  final Random _rng = Random();

  static const _comboColors = [
    Color(0xFFFFD600), Color(0xFFFF9800),
    Color(0xFFFF5722), Color(0xFFE91E63), Color(0xFF9C27B0),
  ];
  Color get _comboColor =>
      _comboColors[(_combo - 2).clamp(0, _comboColors.length - 1)];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _highScore    = widget.storage.highScore;
    _levelAtStart = LevelSystem.levelFromXp(widget.storage.totalXp);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
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
    super.dispose();
  }

  void _initBox(Size size) {
    if (_boxReady) return;
    // Constrain jar max width so it doesn't deform on tablets/landscape
    final effectiveWidth = size.width.clamp(0.0, 450.0);
    final offsetLeft = (size.width - effectiveWidth) / 2;
    // Constrain jar max height relative to width so it's not super tall on iPads
    final maxJarHeight = effectiveWidth * 1.8; // Standard 16:9 vertical feel
    
    // Narrower jar + higher botPad for power-up toolbar
    const hudH = 165.0, sidePad = 40.0, botPad = 100.0;
    _boxLeft      = offsetLeft + sidePad;
    _boxRight     = offsetLeft + effectiveWidth - sidePad;
    _boxTop       = hudH;
    
    double proposedBottom = size.height - botPad;
    if (proposedBottom - _boxTop > maxJarHeight) {
      proposedBottom = _boxTop + maxJarHeight;
    }
    _boxBottom = proposedBottom;
    
    _gameOverLineY = _boxTop + GameConstants.gameOverLineOffsetPx;
    _physics = FruitPhysics(
      boxLeft: _boxLeft, boxRight: _boxRight,
      boxTop: _boxTop, boxBottom: _boxBottom,
    );
    _boxReady = true;
    _dropX    = (_boxLeft + _boxRight) / 2;
    _nextType = _randomType();
    _spawnNext();
  }

  FruitType _randomType({bool lucky = false}) {
    final droppable = FruitData.droppableFruits;
    if (lucky) {
      // Give next tier fruit (cap at level 4 = apple)
      final currentIdx = droppable.indexWhere((f) => f.type == _nextType);
      final luckIdx = (currentIdx + 1).clamp(0, droppable.length - 1);
      return droppable[luckIdx].type;
    }
    final wts = List.generate(
        droppable.length, (i) => (droppable.length - i).toDouble());
    final total = wts.reduce((a, b) => a + b);
    var r = _rng.nextDouble() * total;
    for (int i = 0; i < droppable.length; i++) {
      r -= wts[i];
      if (r <= 0) return droppable[i].type;
    }
    return droppable[0].type;
  }

  void _spawnNext() {
    if (_isGameOver || !_boxReady) return;
    _currentType = _nextType;

    // Lucky drop every 10 drops (silent)
    _dropCount++;
    if (_dropCount % 10 == 0) {
      _nextIsLucky = true;
    }

    _nextType = _nextIsLucky ? _randomType(lucky: true) : _randomType();
    _nextIsLucky = false;

    final data = FruitData.fromType(_currentType);
    _dropY  = _boxTop - data.radiusPx - 8;
    _dropX  = _dropX.clamp(
        _boxLeft + data.radiusPx + 2, _boxRight - data.radiusPx - 2);

    _preview = FruitParticle(
      id: _nextId++, type: _currentType,
      x: _dropX, y: _dropY, radius: data.radiusPx, isPreview: true,
    );
    _fruits.add(_preview!);
  }

  void _dropFruit() {
    if (_isGameOver || _isPaused || !_canDrop) return;
    final p = _preview;
    if (p == null) return;

    p.isPreview  = false;
    p.vy         = 60;
    p.angularVel = (_rng.nextDouble() - 0.5) * 4.0;
    _preview     = null;
    _canDrop     = false;
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

    if (_isPaused || _isGameOver) return;

    _physics!.step(_fruits.where((f) => f.alive).toList(), dt);
    _physics!.stepParticles(_particles, dt);
    _physics!.stepPopups(_popups, dt);

    _particles.removeWhere((p) => !p.alive);
    _popups.removeWhere((p) => !p.alive);

    // Combo timer
    if (_comboTimer > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) _combo = 0;
    }
    // Combo banner fade
    if (_comboBannerOpacity > 0) {
      _comboBannerOpacity = (_comboBannerOpacity - dt * 1.6).clamp(0, 1);
      _comboBannerScale   = (_comboBannerScale - dt * 2.5).clamp(1.0, 2.0);
    }
    // Level up banner was removed as XP is now granted at game over

    final alive = _fruits.where((f) => f.alive).toList();
    final merges = _physics!.detectMerges(alive);
    for (final (a, b) in merges) { _handleMerge(a, b); }

    _fruits.removeWhere((f) => !f.alive);
    _updateDangerLevel();
    _checkGameOver();
    _tickNotifier.value++;
  }



  void _handleMerge(FruitParticle a, FruitParticle b) {
    a.isMerging = true;
    b.isMerging = true;

    final data = FruitData.fromType(a.type);
    final mx   = (a.x + b.x) / 2;
    final my   = (a.y + b.y) / 2;
    final mvx  = (a.vx + b.vx) / 2;
    final mvy  = (a.vy + b.vy) / 2;

    a.alive = false;
    b.alive = false;
    _sessionMerges++;

    // Best fruit update
    if (data.level > _bestFruitIndex + 1) {
      _bestFruitIndex = data.level - 1;
    }

    // Score
    final mult   = _combo > 1 ? _combo : 1;
    final gained = data.points * mult;
    _score += gained;

    // Combo
    if (_comboTimer > 0) { _combo++; } else { _combo = 1; }
    _comboTimer = GameConstants.comboTimeWindow;

    if (_combo >= 2) {
      _comboBannerOpacity = 1.0;
      _comboBannerScale   = 1.55;
      _lastShownCombo     = _combo;
    }

    // XP
    int xp = LevelSystem.xpPerMerge + LevelSystem.comboXp(_combo);
    if (data.type == FruitType.watermelon) xp += LevelSystem.xpWatermelon;
    _gainXp(xp);

    // Particles + popup
    _particles.addAll(
        FruitPhysics.createMergeBurst(mx, my, data.color, a.radius));
    _popups.add(ScorePopup(
      x: mx, y: my - a.radius - 10,
      text: '+$gained',
      color: _combo > 1 ? _comboColor : const Color(0xFFFFD600),
    ));

    // Evolved fruit
    if (data.canEvolve) {
      final nextData  = FruitData.fromType(data.nextType!);
      final initSpin  = (_rng.nextDouble() - 0.5) * 6.0;
      _fruits.add(FruitParticle(
        id: _nextId++, type: data.nextType!,
        x: mx, y: my, vx: mvx, vy: mvy - 90,
        radius: nextData.radiusPx, angularVel: initSpin,
        spawnScale: 0.1, mergeGlow: 1.0,
      ));
    }

    if (_score > _highScore) {
      _highScore = _score;
      widget.storage.setHighScore(_highScore);
    }
    widget.audio.playMerge();
  }

  void _gainXp(int xp) {
    _sessionXp += xp;
  }

  void _updateDangerLevel() {
    double highestY = _boxBottom;
    for (final f in _fruits) {
      if (!f.alive || f.isPreview) continue;
      if (f.y - f.radius < highestY) highestY = f.y - f.radius;
    }
    final boxH  = _boxBottom - _boxTop;
    final filled = (_boxBottom - highestY) / boxH;
    _dangerLevel = ((filled - 0.5) / 0.5).clamp(0.0, 1.0);
  }

  void _checkGameOver() {
    for (final f in _fruits) {
      if (!f.alive || f.isPreview || f.isMerging) continue;
      if (f.y - f.radius < _gameOverLineY &&
          f.vy.abs() < 30 && f.vx.abs() < 30) {
        _triggerGameOver();
        return;
      }
    }
  }

  void _triggerGameOver() {
    if (_isGameOver) return;
    _isGameOver = true;
    // End-of-game XP from score
    _gainXp(LevelSystem.xpFromScore(_score));
    
    // Grant coins (1 coin per 50 points)
    final newCoins = _score ~/ 50;
    widget.storage.addCoins(newCoins);
    
    // Persist everything
    _flushStats();
    widget.audio.playGameOver();
  }

  Future<void> _flushStats() async {
    await widget.storage.addXp(_sessionXp);
    await widget.storage.incrementGamesPlayed();
    await widget.storage.addMerges(_sessionMerges);
    await widget.storage.addDrops(_sessionDrops);
    await widget.storage.updateBiggestFruit(_bestFruitIndex);
    await widget.storage.setHighScore(_score);
  }

  void _restartGame() {
    setState(() {
      _fruits.clear(); _particles.clear(); _popups.clear();
      _preview = null; _score = 0; _combo = 0; _comboTimer = 0;
      _comboBannerOpacity = 0; _dangerLevel = 0;
      _isPaused = false; _isGameOver = false;
      _canDrop  = true; _lastTime = Duration.zero;
      _sessionXp = 0; _sessionMerges = 0; _sessionDrops = 0;
      _bestFruitIndex = 0; _dropCount = 0;
    });
    _levelAtStart = LevelSystem.levelFromXp(widget.storage.totalXp);
    _spawnNext();
  }

  // ── Input ──────────────────────────────────────────────────────
  void _onPanStart(DragStartDetails d) {
    if (_isGameOver || _isPaused) return;
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
    if (_isGameOver || _isPaused) return;
    if (_powerUpMode != PowerUpMode.none) {
      _applyPowerUp(d.localPosition);
      return;
    }
    if (_isDragging) return;
    _moveDrop(d.localPosition.dx);
    _dropFruit();
  }

  void _applyPowerUp(Offset pos) {
    if (_powerUpMode == PowerUpMode.none) return;
    // Find tapped fruit
    final alive = _fruits.where((f) => f.alive && !f.isPreview && f.y > _boxTop).toList();
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
          _particles.add(MergeParticle(
            x: f.x, y: f.y, color: data.color, radius: 8,
            vx: (f.x - hitPos.dx) * 2 + (_rng.nextDouble() - 0.5) * 100,
            vy: (f.y - hitPos.dy) * 2 + (_rng.nextDouble() - 0.5) * 100,
          ));
        }
      }
    }
    widget.audio.playMerge(); // Use merge sound for bomb explosion
    setState(() => _powerUpMode = PowerUpMode.none);
  }

  void _useSniper(FruitParticle target) {
    final data = FruitData.fromType(target.type);
    if (data.level < 10) { // Max level is watermelon (level 11) but array is 0-indexed, wait: All fruits length is 11, so level 10 is max generic. 
      widget.storage.consumeSniper();
      final dropList = FruitData.allFruits;
      final nextData = dropList.firstWhere((d) => d.level == data.level + 1);
      target.type = nextData.type;
      target.radius = nextData.radiusPx;
      
      for (int i = 0; i < 8; i++) {
        _particles.add(MergeParticle(
          x: target.x, y: target.y, color: nextData.color, radius: 10,
          vx: (_rng.nextDouble() - 0.5) * 200, vy: (_rng.nextDouble() - 0.5) * 200,
        ));
      }
      widget.audio.playMerge();
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
    widget.audio.playDrop(); // Feedback sound
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0533), Color(0xFF0D1B6B), Color(0xFF0A2744)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            _initBox(size);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: _onPanStart, onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd, onTapUp: _onTapUp,
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
                                fruits:   _fruits.where((f) => f.alive).toList(),
                                particles: List.from(_particles),
                                boxLeft: _boxLeft, boxRight: _boxRight,
                                boxTop: _boxTop, boxBottom: _boxBottom,
                                gameOverLineY: _gameOverLineY,
                                dangerLevel: _dangerLevel,
                              ),
                              size: size,
                            ),
                          )
                        : const SizedBox(),
                  ),

                  // ── Evolution progress bar ──────────────────
                  if (_boxReady)
                    Positioned(
                      top: _boxTop - 6,
                      left: _boxLeft, right: _boxRight,
                      child: RepaintBoundary(child: _evolutionBar()),
                    ),

                  // ── Combo banner ────────────────────────────
                  if (_comboBannerOpacity > 0 && _combo >= 2)
                    Positioned(
                      top: _boxTop + 22, left: 0, right: 0,
                      child: IgnorePointer(
                        child: Center(
                          child: Transform.scale(
                            scale: _comboBannerScale,
                            child: Opacity(
                              opacity: _comboBannerOpacity,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 22, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_comboColor,
                                      _comboColor.withValues(alpha: 0.7)],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [BoxShadow(
                                    color: _comboColor.withValues(alpha: 0.6),
                                    blurRadius: 20, spreadRadius: 2,
                                  )],
                                ),
                                child: Text('${_lastShownCombo}x COMBO! 🔥',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white, letterSpacing: 1.2,
                                    )),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ── Native Overlay Score Popups ─────────────────
                  ..._popups.map((p) => Positioned(
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
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: p.color,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: p.life.clamp(0.0, 1.0) * 0.4),
                                  offset: const Offset(1, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )),

                  // ── HUD (RepaintBoundary so score doesn't ──
                  // trigger canvas repaint)
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: RepaintBoundary(
                      child: HudOverlay(
                        score: _score,
                        highScore: _highScore,
                        combo: _combo,
                        nextFruit: _nextType,
                        bestFruitIndex: _bestFruitIndex,
                        currentLevel: _levelAtStart,
                        onPause: () => setState(() => _isPaused = true),
                      ),
                    ),
                  ),

                  // ── Power-Ups Toolbar ─────────────────────────
                  if (_boxReady && !_isGameOver && !_isPaused)
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      height: 100,
                      child: SafeArea(
                        child: _powerUpToolbar(),
                      ),
                    ),

                  if (_isPaused)
                    PauseOverlay(
                      audio: widget.audio,
                      onResume: () => setState(() => _isPaused = false),
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
                  ],
                  );
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _evolutionBar() {
    final all = FruitData.allFruits;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: all.asMap().entries.map((e) {
          final unlocked = e.key <= _bestFruitIndex;
          return Opacity(
            opacity: unlocked ? 1.0 : 0.3,
            child: Text(e.value.emoji,
                style: TextStyle(fontSize: unlocked ? 14 : 11)),
          );
        }).toList(),
      ),
    );
  }

  Widget _powerUpToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0533).withValues(alpha: 0.8),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _powerUpBtn(
                icon: '💣',
                label: 'Bomb',
                count: widget.storage.bombCount,
                isActive: _powerUpMode == PowerUpMode.bomb,
                onTap: () {
                  if (widget.storage.bombCount > 0) {
                    setState(() => _powerUpMode = (_powerUpMode == PowerUpMode.bomb) ? PowerUpMode.none : PowerUpMode.bomb);
                  }
                },
              ),
              _powerUpBtn(
                icon: '🪇',
                label: 'Shaker',
                count: widget.storage.shakerCount,
                isActive: false,
                onTap: () {
                  if (widget.storage.shakerCount > 0) {
                    _activateShaker();
                  }
                },
              ),
              _powerUpBtn(
                icon: '🎯',
                label: 'Sniper',
                count: widget.storage.sniperCount,
                isActive: _powerUpMode == PowerUpMode.sniper,
                onTap: () {
                  if (widget.storage.sniperCount > 0) {
                    setState(() => _powerUpMode = (_powerUpMode == PowerUpMode.sniper) ? PowerUpMode.none : PowerUpMode.sniper);
                  }
                },
              ),
            ],
          ),
          if (_powerUpMode != PowerUpMode.none)
            Positioned(
              top: -40,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD600),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _powerUpMode == PowerUpMode.bomb ? 'Tap a fruit to explode!' : 'Tap a fruit to upgrade!',
                  style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _powerUpBtn({required String icon, required String label, required int count, required bool isActive, required VoidCallback onTap}) {
    final bool outOfStock = count <= 0;
    return GestureDetector(
      onTap: outOfStock ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFFFD600).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? const Color(0xFFFFD600) : Colors.white.withValues(alpha: 0.2),
                width: isActive ? 2 : 1,
              ),
            ),
            child: Opacity(
              opacity: outOfStock ? 0.4 : 1.0,
              child: Text(icon, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(height: 4),
          Text(outOfStock ? '0' : '$label x$count', style: GoogleFonts.fredoka(
            color: isActive ? const Color(0xFFFFD600) : Colors.white70,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          )),
        ],
      ),
    );
  }
}
