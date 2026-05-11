import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_manager.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService storage;
  final AudioManager audio;

  const SettingsScreen({
    super.key,
    required this.storage,
    required this.audio,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB8C6DB),
              Color(0xFFF5F0E8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: EdgeInsets.all(context.s(16)),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: context.s(44),
                        height: context.s(44),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(context.s(14)),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    SizedBox(width: context.s(16)),
                    Text(
                      '⚙️ Settings',
                      style: GoogleFonts.fredoka(
                        fontSize: context.sp(28),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: context.s(16)),

              // Settings Items
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.s(20)),
                  child: Column(
                    children: [
                      _buildSettingTile(
                        context,
                        icon: Icons.volume_up_rounded,
                        label: 'Sound Effects',
                        value: widget.audio.soundEnabled,
                        onChanged: (val) async {
                          await widget.audio.toggleSound();
                          setState(() {});
                        },
                      ),

                      SizedBox(height: context.s(12)),

                      _buildSettingTile(
                        context,
                        icon: Icons.music_note_rounded,
                        label: 'Music',
                        value: widget.audio.musicEnabled,
                        onChanged: (val) async {
                          await widget.audio.toggleMusic();
                          setState(() {});
                        },
                      ),

                      SizedBox(height: context.s(12)),

                      _buildSettingTile(
                        context,
                        icon: Icons.vibration_rounded,
                        label: 'Vibration',
                        value: widget.storage.vibrationEnabled,
                        onChanged: (val) async {
                          await widget.storage.setVibrationEnabled(val);
                          setState(() {});
                        },
                      ),

                      SizedBox(height: context.s(32)),

                      // Reset high score
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(
                                'Reset High Score?',
                                style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
                              ),
                              content: Text(
                                'This will reset your high score to 0.',
                                style: GoogleFonts.fredoka(),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text('Cancel', style: GoogleFonts.fredoka()),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await widget.storage.resetHighScore();
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  },
                                  child: Text(
                                    'Reset',
                                    style: GoogleFonts.fredoka(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: context.s(14)),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(context.s(16)),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red.shade400),
                              SizedBox(width: context.s(8)),
                              Text(
                                'Reset High Score',
                                style: GoogleFonts.fredoka(
                                  fontSize: context.sp(16),
                                  color: Colors.red.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Credits
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(context.s(16)),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(context.s(16)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '🍉 Fruit Merge Puzzle',
                              style: GoogleFonts.fredoka(
                                fontSize: context.sp(16),
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            SizedBox(height: context.s(4)),
                            Text(
                              'Version 1.0.0',
                              style: GoogleFonts.fredoka(
                                fontSize: context.sp(12),
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: context.s(20)),
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

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(14)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(context.s(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: context.s(40),
            height: context.s(40),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0B2),
              borderRadius: BorderRadius.circular(context.s(12)),
            ),
            child: Icon(icon, color: const Color(0xFFFF8A65), size: context.s(22)),
          ),
          SizedBox(width: context.s(14)),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: context.sp(16),
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFFFF7043),
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
