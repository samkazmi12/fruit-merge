import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/level_system.dart';
import '../services/storage_service.dart';
import '../models/fruit_data.dart';

class ProfileScreen extends StatefulWidget {
  final StorageService storage;
  const ProfileScreen({super.key, required this.storage});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  bool _editingName = false;
  late AnimationController _xpAnim;
  late Animation<double> _xpProgress;

  static const _avatarChoices = [
    '🍉','🍒','🍇','🍊','🍎','🐸','🦁','🐯','🐼','🦊',
    '🐸','🦋','🐧','🦄','🐵','🤖','👾','🎮',
  ];

  StorageService get s => widget.storage;

  int get _level => LevelSystem.levelFromXp(s.totalXp);
  double get _progress => LevelSystem.levelProgress(s.totalXp);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: s.playerName);

    _xpAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _xpProgress = Tween<double>(begin: 0, end: _progress).animate(
      CurvedAnimation(parent: _xpAnim, curve: Curves.easeOutCubic),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _xpAnim.forward();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _xpAnim.dispose();
    super.dispose();
  }

  Future<void> _saveName(String name) async {
    await s.setPlayerName(name);
    setState(() => _editingName = false);
  }

  Future<void> _pickAvatar() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AvatarPicker(choices: _avatarChoices, current: s.avatarEmoji),
    );
    if (chosen != null) {
      await s.setAvatarEmoji(chosen);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final xpIn = LevelSystem.xpInCurrentLevel(s.totalXp);
    final xpNeeded = LevelSystem.xpNeededForCurrentLevel(s.totalXp);
    final biggestFruit = FruitData.allFruits[s.biggestFruitIndex.clamp(0, 9)];

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
          child: Column(
            children: [
              // ── App bar ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    _glassBtn(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 14),
                    Text('My Profile',
                        style: GoogleFonts.fredoka(
                          fontSize: 26, fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // ── Avatar + Name ──────────────────────
                      _avatarSection(),
                      const SizedBox(height: 20),

                      // ── Level card ─────────────────────────
                      _levelCard(xpIn, xpNeeded),
                      const SizedBox(height: 16),

                      // ── Stats card ─────────────────────────
                      _statsCard(biggestFruit),
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

  Widget _avatarSection() {
    return Column(
      children: [
        // Avatar circle
        GestureDetector(
          onTap: _pickAvatar,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFF3F51B5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF9C27B0).withValues(alpha: 0.5),
                        blurRadius: 20, spreadRadius: 2),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(s.avatarEmoji,
                    style: const TextStyle(fontSize: 48)),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7043),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.edit, size: 12, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Name (tap to edit)
        GestureDetector(
          onTap: () => setState(() => _editingName = true),
          child: _editingName
              ? SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _nameController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    maxLength: 20,
                    inputFormatters: [LengthLimitingTextInputFormatter(20)],
                    style: GoogleFonts.fredoka(
                        fontSize: 22, color: Colors.white,
                        fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: '',
                      border: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.5))),
                      focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                    ),
                    onSubmitted: _saveName,
                    onEditingComplete: () => _saveName(_nameController.text),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.playerName,
                        style: GoogleFonts.fredoka(
                          fontSize: 24, fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                    const SizedBox(width: 6),
                    Icon(Icons.edit, size: 15,
                        color: Colors.white.withValues(alpha: 0.5)),
                  ],
                ),
        ),
        const SizedBox(height: 4),
        Text(LevelSystem.levelTitle(_level),
            style: GoogleFonts.fredoka(
              fontSize: 14,
              color: const Color(0xFFFFD600),
            )),
      ],
    );
  }

  Widget _levelCard(int xpIn, int xpNeeded) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⭐', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text('Level & XP',
                  style: GoogleFonts.fredoka(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFF7043), Color(0xFFFF9800)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Lv. $_level',
                    style: GoogleFonts.fredoka(
                      fontSize: 16, fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // XP bar
          AnimatedBuilder(
            animation: _xpProgress,
            builder: (_, child) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _xpProgress.value,
                    minHeight: 12,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD600)),
                  ),
                ),
                const SizedBox(height: 6),
                Text('$xpIn / $xpNeeded XP',
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Total XP: ${s.totalXp}',
              style: GoogleFonts.fredoka(
                fontSize: 13, color: Colors.white.withValues(alpha: 0.55))),
        ],
      ),
    );
  }

  Widget _statsCard(FruitData biggestFruit) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('📊', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Text('Game Stats', style: GoogleFonts.fredoka(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ]),
          const SizedBox(height: 16),
          _statRow('🏆 Best Score', '${s.highScore}'),
          _statRow('🎮 Games Played', '${s.gamesPlayed}'),
          _statRow('🔄 Total Merges', '${s.totalMerges}'),
          _statRow('📦 Total Drops', '${s.totalDrops}'),
          _statRow('🍓 Biggest Fruit', '${biggestFruit.emoji} ${biggestFruit.name}'),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.fredoka(
              fontSize: 14, color: Colors.white.withValues(alpha: 0.75))),
          Text(value, style: GoogleFonts.fredoka(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _glassBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

// ── Avatar picker bottom sheet ─────────────────────────────────────
class _AvatarPicker extends StatelessWidget {
  final List<String> choices;
  final String current;
  const _AvatarPicker({required this.choices, required this.current});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0533), Color(0xFF0D1B6B)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Choose Avatar', style: GoogleFonts.fredoka(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: choices.map((e) => GestureDetector(
              onTap: () => Navigator.pop(context, e),
              child: Container(
                width: 56, height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: e == current
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                  border: e == current
                      ? Border.all(color: const Color(0xFFFFD600), width: 2)
                      : null,
                ),
                child: Text(e, style: const TextStyle(fontSize: 28)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
