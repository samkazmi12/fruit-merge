import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/level_system.dart';
import '../services/storage_service.dart';
import '../models/fruit_data.dart';
import '../utils/responsive.dart';

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
                padding: EdgeInsets.fromLTRB(context.s(16), context.s(16), context.s(16), 0),
                child: Row(
                  children: [
                    _glassBtn(
                      context,
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    SizedBox(width: context.s(14)),
                    Text('My Profile',
                        style: GoogleFonts.fredoka(
                          fontSize: context.sp(26), fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(context.s(20)),
                  child: Column(
                    children: [
                      SizedBox(height: context.s(8)),

                      // ── Avatar + Name ──────────────────────
                      _avatarSection(context),
                      SizedBox(height: context.s(20)),

                      // ── Level card ─────────────────────────
                      _levelCard(context, xpIn, xpNeeded),
                      SizedBox(height: context.s(16)),

                      // ── Stats card ─────────────────────────
                      _statsCard(context, biggestFruit),
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

  Widget _avatarSection(BuildContext context) {
    return Column(
      children: [
        // Avatar circle
        GestureDetector(
          onTap: _pickAvatar,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: context.s(100), height: context.s(100),
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
                    style: TextStyle(fontSize: context.sp(48))),
              ),
              Container(
                padding: EdgeInsets.all(context.s(5)),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7043),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(Icons.edit, size: context.s(12), color: Colors.white),
              ),
            ],
          ),
        ),
        SizedBox(height: context.s(14)),

        // Name (tap to edit)
        GestureDetector(
          onTap: () => setState(() => _editingName = true),
          child: _editingName
              ? SizedBox(
                  width: context.s(200),
                  child: TextField(
                    controller: _nameController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    maxLength: 20,
                    inputFormatters: [LengthLimitingTextInputFormatter(20)],
                    style: GoogleFonts.fredoka(
                        fontSize: context.sp(22), color: Colors.white,
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
                          fontSize: context.sp(24), fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                    SizedBox(width: context.s(6)),
                    Icon(Icons.edit, size: context.s(15),
                        color: Colors.white.withValues(alpha: 0.5)),
                  ],
                ),
        ),
        SizedBox(height: context.s(4)),
        Text(LevelSystem.levelTitle(_level),
            style: GoogleFonts.fredoka(
              fontSize: context.sp(14),
              color: const Color(0xFFFFD600),
            )),
      ],
    );
  }

  Widget _levelCard(BuildContext context, int xpIn, int xpNeeded) {
    return _glassCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('⭐', style: TextStyle(fontSize: context.sp(22))),
              SizedBox(width: context.s(10)),
              Text('Level & XP',
                  style: GoogleFonts.fredoka(
                    fontSize: context.sp(18), fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.s(14), vertical: context.s(5)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFF7043), Color(0xFFFF9800)]),
                  borderRadius: BorderRadius.circular(context.s(20)),
                ),
                child: Text('Lv. $_level',
                    style: GoogleFonts.fredoka(
                      fontSize: context.sp(16), fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
              ),
            ],
          ),
          SizedBox(height: context.s(16)),
          // XP bar
          AnimatedBuilder(
            animation: _xpProgress,
            builder: (_, child) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(context.s(8)),
                  child: LinearProgressIndicator(
                    value: _xpProgress.value,
                    minHeight: context.s(12),
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD600)),
                  ),
                ),
                SizedBox(height: context.s(6)),
                Text('$xpIn / $xpNeeded XP',
                    style: GoogleFonts.fredoka(
                      fontSize: context.sp(12),
                      color: Colors.white.withValues(alpha: 0.7),
                    )),
              ],
            ),
          ),
          SizedBox(height: context.s(8)),
          Text('Total XP: ${s.totalXp}',
              style: GoogleFonts.fredoka(
                fontSize: context.sp(13), color: Colors.white.withValues(alpha: 0.55))),
        ],
      ),
    );
  }

  Widget _statsCard(BuildContext context, FruitData biggestFruit) {
    return _glassCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('📊', style: TextStyle(fontSize: context.sp(22))),
            SizedBox(width: context.s(10)),
            Text('Game Stats', style: GoogleFonts.fredoka(
              fontSize: context.sp(18), fontWeight: FontWeight.bold, color: Colors.white)),
          ]),
          SizedBox(height: context.s(16)),
          _statRow(context, '🏆 Best Score', '${s.highScore}'),
          _statRow(context, '🎮 Games Played', '${s.gamesPlayed}'),
          _statRow(context, '🔄 Total Merges', '${s.totalMerges}'),
          _statRow(context, '📦 Total Drops', '${s.totalDrops}'),
          _statRow(context, '🍓 Biggest Fruit', '${biggestFruit.emoji} ${biggestFruit.name}'),
        ],
      ),
    );
  }

  Widget _statRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.s(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.fredoka(
              fontSize: context.sp(14), color: Colors.white.withValues(alpha: 0.75))),
          Text(value, style: GoogleFonts.fredoka(
              fontSize: context.sp(14), fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _glassCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.s(18)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(context.s(22)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _glassBtn(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: context.s(44), height: context.s(44),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(context.s(14)),
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
      padding: EdgeInsets.all(context.s(20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0533), Color(0xFF0D1B6B)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.s(28))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: context.s(40), height: context.s(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(context.s(2)),
            ),
          ),
          SizedBox(height: context.s(16)),
          Text('Choose Avatar', style: GoogleFonts.fredoka(
              fontSize: context.sp(20), fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: context.s(16)),
          Wrap(
            spacing: context.s(12), runSpacing: context.s(12),
            children: choices.map((e) => GestureDetector(
              onTap: () => Navigator.pop(context, e),
              child: Container(
                width: context.s(56), height: context.s(56),
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
                child: Text(e, style: TextStyle(fontSize: context.sp(28))),
              ),
            )).toList(),
          ),
          SizedBox(height: context.s(16)),
        ],
      ),
    );
  }
}
