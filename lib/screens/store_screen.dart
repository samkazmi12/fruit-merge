import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';

class StoreScreen extends StatefulWidget {
  final StorageService storage;
  const StoreScreen({super.key, required this.storage});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0533), Color(0xFF0D1B6B), Color(0xFF0A2744)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── App bar ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '🛒 Store',
                      style: GoogleFonts.fredoka(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD600).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFD600)),
                      ),
                      child: Row(
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.storage.coins}',
                            style: GoogleFonts.fredoka(
                              color: const Color(0xFFFFD600),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Coming soon banner ───────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD600), Color(0xFFFF9800)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD600).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🚧', style: TextStyle(fontSize: 30)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Coming Soon!',
                            style: GoogleFonts.fredoka(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3E2723),
                            ),
                          ),
                          Text(
                            'Fruit skins & themes on the way!',
                            style: GoogleFonts.fredoka(
                              fontSize: 12,
                              color: const Color(0xFF5D4037),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Grid ─────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.88,
                    children: [
                      _buildPowerUpCard(
                        title: 'Bomb x3',
                        emoji: '💣',
                        desc: 'Destroy tight clusters',
                        price: 150,
                        currentCount: widget.storage.bombCount,
                        onBuy: () async {
                          if (widget.storage.coins >= 150) {
                            await widget.storage.addCoins(-150);
                            await widget.storage.addBombs(3);
                            setState(() {});
                          }
                        },
                      ),
                      _buildPowerUpCard(
                        title: 'Shaker x3',
                        emoji: '🪇',
                        desc: 'Shake up the jar',
                        price: 100,
                        currentCount: widget.storage.shakerCount,
                        onBuy: () async {
                          if (widget.storage.coins >= 100) {
                            await widget.storage.addCoins(-100);
                            await widget.storage.addShakers(3);
                            setState(() {});
                          }
                        },
                      ),
                      _buildPowerUpCard(
                        title: 'Sniper x3',
                        emoji: '🎯',
                        desc: 'Instantly upgrade a fruit',
                        price: 200,
                        currentCount: widget.storage.sniperCount,
                        onBuy: () async {
                          if (widget.storage.coins >= 200) {
                            await widget.storage.addCoins(-200);
                            await widget.storage.addSnipers(3);
                            setState(() {});
                          }
                        },
                      ),
                      _buildThemeCard('Neon Theme', '✨', 'Coming Soon'),
                      _buildThemeCard('Galaxy Theme', '🌌', 'Coming Soon'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPowerUpCard({
    required String title,
    required String emoji,
    required String desc,
    required int price,
    required int currentCount,
    required VoidCallback onBuy,
  }) {
    final canAfford = widget.storage.coins >= price;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 42)),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.fredoka(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Owned: $currentCount',
            style: GoogleFonts.fredoka(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: canAfford ? onBuy : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: canAfford ? const Color(0xFF4CAF50) : Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    '$price',
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(String title, String emoji, String desc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.fredoka(fontSize: 14, color: Colors.white54),
              ),
            ],
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Icon(
              Icons.lock_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
