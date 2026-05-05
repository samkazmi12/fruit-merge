import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/level_system.dart';
import '../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storage;
  const HomeScreen({super.key, required this.storage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _titleCtrl, _fruitCtrl;
  late Animation<double> _titleBounce, _fruitRot;
  final List<_FloatingFruit> _floating = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _titleCtrl = AnimationController(
        duration: const Duration(milliseconds: 1400), vsync: this)
      ..repeat(reverse: true);
    _titleBounce = Tween<double>(begin: 0, end: -10)
        .animate(CurvedAnimation(parent: _titleCtrl, curve: Curves.easeInOut));

    _fruitCtrl = AnimationController(
        duration: const Duration(seconds: 18), vsync: this)
      ..repeat();
    _fruitRot = Tween<double>(begin: 0, end: 2 * pi).animate(_fruitCtrl);

    const emojis = ['🍒','🍓','🍇','🍊','🍎','🍐','🍑','🍍','🍈','🍉'];
    for (int i = 0; i < 14; i++) {
      _floating.add(_FloatingFruit(
        emoji: emojis[_rng.nextInt(emojis.length)],
        x: _rng.nextDouble(), y: _rng.nextDouble(),
        size: 18 + _rng.nextDouble() * 28,
        speed: 0.25 + _rng.nextDouble() * 0.7,
        phase: _rng.nextDouble() * 2 * pi,
      ));
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _fruitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = LevelSystem.levelFromXp(widget.storage.totalXp);

    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1A0533), Color(0xFF0D1B6B), Color(0xFF0A2744)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Floating background fruits
              ..._buildFloating(),

              // Main
              Column(
                children: [
                  // ── Top bar: Profile button ────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await Navigator.pushNamed(context, '/profile');
                            setState(() {}); // refresh level after return
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(widget.storage.avatarEmoji,
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(widget.storage.playerName,
                                        style: GoogleFonts.fredoka(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        )),
                                    Text('Lv.$level',
                                        style: GoogleFonts.fredoka(
                                          fontSize: 11,
                                          color: const Color(0xFFFFD600),
                                        )),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Logo ──────────────────────────────────
                  AnimatedBuilder(
                    animation: _titleBounce,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, _titleBounce.value), child: child),
                    child: Column(
                      children: [
                        const Text('🍉', style: TextStyle(fontSize: 80)),
                        const SizedBox(height: 6),
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [Color(0xFFFF6EC7), Color(0xFFFFD600),
                              Color(0xFF00E5FF)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ).createShader(b),
                          child: Text('Fruit Merge',
                              style: GoogleFonts.fredoka(
                                fontSize: 44, fontWeight: FontWeight.bold,
                                color: Colors.white, letterSpacing: 1.5,
                              )),
                        ),
                        Text('PUZZLE',
                            style: GoogleFonts.fredoka(
                              fontSize: 16, letterSpacing: 9,
                              color: Colors.white.withValues(alpha: 0.5),
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── High score pill ────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events,
                            color: Color(0xFFFFD600), size: 18),
                        const SizedBox(width: 6),
                        Text('Best: ${widget.storage.highScore}',
                            style: GoogleFonts.fredoka(
                              fontSize: 15, color: Colors.white,
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Play button ────────────────────────────
                  _mainBtn(
                    label: 'PLAY',
                    icon: Icons.play_arrow_rounded,
                    colors: const [Color(0xFFFF6EC7), Color(0xFFFF7043)],
                    onTap: () => Navigator.pushNamed(context, '/game')
                        .then((_) => setState(() {})),
                  ),

                  const SizedBox(height: 16),

                  // ── Secondary buttons ──────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _smallBtn(
                          icon: Icons.store_rounded, label: 'Store',
                          onTap: () => Navigator.pushNamed(context, '/store')),
                      const SizedBox(width: 16),
                      _smallBtn(
                          icon: Icons.settings_rounded, label: 'Settings',
                          onTap: () => Navigator.pushNamed(context, '/settings')),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // ── Evolution chain ────────────────────────
                  _evolutionChain(),

                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFloating() {
    return _floating.map((f) => AnimatedBuilder(
      animation: _fruitRot,
      builder: (ctx, _) {
        final sw = MediaQuery.of(ctx).size.width;
        final sh = MediaQuery.of(ctx).size.height;
        return Positioned(
          left: f.x * sw + cos(_fruitRot.value * f.speed + f.phase) * 12,
          top:  f.y * sh + sin(_fruitRot.value * f.speed * 0.8 + f.phase) * 20,
          child: Opacity(opacity: 0.12,
              child: Text(f.emoji, style: TextStyle(fontSize: f.size))),
        );
      },
    )).toList();
  }

  Widget _mainBtn({
    required String label, required IconData icon,
    required List<Color> colors, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors,
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(
            color: colors.last.withValues(alpha: 0.5),
            blurRadius: 20, offset: const Offset(0, 8),
          )],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.fredoka(
            fontSize: 24, fontWeight: FontWeight.bold,
            color: Colors.white, letterSpacing: 3,
          )),
        ]),
      ),
    );
  }

  Widget _smallBtn({
    required IconData icon, required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: const Color(0xFFFF7043), size: 26),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.fredoka(
              fontSize: 12, color: Colors.white,
              fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _evolutionChain() {
    const emojis = ['🍒','🍓','🍇','🍊','🍎','🍐','🍑','🍍','🍈','🍉'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: emojis.asMap().entries.map((e) => Text(
          e.value, style: TextStyle(fontSize: 14 + e.key.toDouble() * 0.8),
        )).toList(),
      ),
    );
  }
}

class _FloatingFruit {
  final String emoji;
  final double x, y, size, speed, phase;
  const _FloatingFruit({
    required this.emoji, required this.x, required this.y,
    required this.size, required this.speed, required this.phase,
  });
}
