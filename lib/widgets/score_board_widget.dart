import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/game_colors.dart';
import '../game/state/game_provider.dart';

class ScoreBoardWidget extends StatelessWidget {
  const ScoreBoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _buildScoreCard(
            context: context,
            title: 'SCORE',
            score: gameProvider.score,
            icon: Icons.auto_awesome,
            color: GameColors.primaryAccent,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildScoreCard(
            context: context,
            title: 'BEST',
            score: gameProvider.bestScore,
            icon: Icons.emoji_events,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
            isBest: gameProvider.isNewHighScore,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard({
    required BuildContext context,
    required String title,
    required int score,
    required IconData icon,
    required Color color,
    required bool isDark,
    bool isBest = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? GameColors.darkSurface : GameColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBest ? color.withValues(alpha: 0.6) : (isDark ? Colors.white10 : Colors.black12),
          width: isBest ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isBest ? color : Colors.black).withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: (isDark ? Colors.white60 : Colors.black54),
                ),
              ),
              if (isBest) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ]
            ],
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: score.toDouble()),
            duration: const Duration(milliseconds: 300),
            builder: (context, val, child) {
              return Text(
                val.toInt().toString(),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
