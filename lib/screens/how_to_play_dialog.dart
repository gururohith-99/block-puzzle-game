import 'package:flutter/material.dart';
import '../core/theme/game_colors.dart';
import '../widgets/common_button.dart';

class HowToPlayDialog extends StatelessWidget {
  const HowToPlayDialog({super.key});

  @override
  Widget build(BuildContext context) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, color: GameColors.primaryAccent, size: 24),
                const SizedBox(width: 10),
                Text(
                  'HOW TO PLAY',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRule(
              step: '1',
              title: 'Drag & Place Blocks',
              desc: 'Drag pieces from the tray onto the 9x9 board grid.',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildRule(
              step: '2',
              title: 'Clear Rows & Columns',
              desc: 'Fill complete horizontal rows or vertical columns to clear them and score points.',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildRule(
              step: '3',
              title: 'Build Combos',
              desc: 'Clear multiple lines at once or in consecutive moves to trigger high-score multiplier combos!',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildRule(
              step: '4',
              title: 'Game Over',
              desc: 'The game ends when no legal moves remain for any available tray piece.',
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            Center(
              child: CommonButton(
                label: 'Got It!',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRule({
    required String step,
    required String title,
    required String desc,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: GameColors.primaryAccent,
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
