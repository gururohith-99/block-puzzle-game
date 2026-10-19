import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/game_colors.dart';
import '../game/state/game_provider.dart';
import '../widgets/common_button.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? GameColors.darkSurface : GameColors.lightSurface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: GameColors.primaryAccent, size: 24),
                const SizedBox(width: 10),
                Text(
                  'SETTINGS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildSettingTile(
              context: context,
              icon: Icons.volume_up,
              title: 'Sound Effects',
              value: gameProvider.soundEnabled,
              onChanged: (val) => gameProvider.setSoundEnabled(val),
              isDark: isDark,
            ),
            const Divider(height: 16),

            _buildSettingTile(
              context: context,
              icon: Icons.music_note,
              title: 'Background Music',
              value: gameProvider.musicEnabled,
              onChanged: (val) => gameProvider.setMusicEnabled(val),
              isDark: isDark,
            ),
            const Divider(height: 16),

            _buildSettingTile(
              context: context,
              icon: Icons.vibration,
              title: 'Haptic Feedback',
              value: gameProvider.hapticsEnabled,
              onChanged: (val) => gameProvider.setHapticsEnabled(val),
              isDark: isDark,
            ),
            const Divider(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.dark_mode, size: 22, color: GameColors.primaryAccent),
                  const SizedBox(width: 12),
                  Text(
                    'Theme',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  DropdownButton<String>(
                    value: gameProvider.themeMode,
                    dropdownColor: isDark ? GameColors.darkBoardBg : GameColors.lightBoardBg,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'dark', child: Text('Dark')),
                      DropdownMenuItem(value: 'light', child: Text('Light')),
                    ],
                    onChanged: (val) {
                      if (val != null) gameProvider.setThemeMode(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            CommonButton(
              label: 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 22, color: GameColors.primaryAccent),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          Switch.adaptive(
            value: value,
            activeTrackColor: GameColors.primaryAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
