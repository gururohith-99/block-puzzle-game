import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/game_colors.dart';
import '../game/state/game_provider.dart';

class ComboBannerWidget extends StatelessWidget {
  const ComboBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final combo = gameProvider.comboStreak;

    if (combo <= 1) {
      return const SizedBox(height: 32);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: child,
        );
      },
      child: Container(
        key: ValueKey<int>(combo),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: GameColors.warningAccent.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt, color: Colors.white, size: 18),
            const SizedBox(width: 4),
            Text(
              'COMBO x$combo!',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
