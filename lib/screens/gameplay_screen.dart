import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/game_colors.dart';
import '../game/state/game_provider.dart';
import '../widgets/board_widget.dart';
import '../widgets/combo_banner_widget.dart';
import '../widgets/common_button.dart';
import '../widgets/drag_layer_widget.dart';
import '../widgets/piece_tray_widget.dart';
import '../widgets/score_board_widget.dart';
import 'game_over_dialog.dart';
import 'settings_dialog.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  Rect _boardRect = Rect.zero;
  double _boardCellSize = 36.0;

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check Game Over Dialog trigger
    if (gameProvider.isGameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => GameOverDialog(
            onPlayAgain: () {
              Navigator.of(context).pop();
              gameProvider.startNewGame();
            },
            onMainMenu: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to Main Menu
            },
          ),
        );
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          gameProvider.togglePause();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? GameColors.darkBackground : GameColors.lightBackground,
        body: Listener(
          onPointerMove: (event) {
            if (gameProvider.activePieceIndex != null) {
              gameProvider.updateDrag(
                globalPos: event.position,
                boardRect: _boardRect,
                cellSize: _boardCellSize,
              );
            }
          },
          onPointerUp: (_) {
            if (gameProvider.activePieceIndex != null) {
              gameProvider.endDrag();
            }
          },
          onPointerCancel: (_) {
            if (gameProvider.activePieceIndex != null) {
              gameProvider.endDrag();
            }
          },
          child: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            color: isDark ? Colors.white70 : Colors.black87,
                            onPressed: () {
                              gameProvider.togglePause();
                            },
                          ),
                          Text(
                            'BLOCK HAVEN',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_rounded),
                            color: isDark ? Colors.white70 : Colors.black87,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const SettingsDialog(),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      const ScoreBoardWidget(),
                      const SizedBox(height: 8),

                      const ComboBannerWidget(),
                      const SizedBox(height: 8),

                      Expanded(
                        child: Center(
                          child: BoardWidget(
                            onBoardLayout: (rect, cellSize) {
                              _boardRect = rect;
                              _boardCellSize = cellSize;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      PieceTrayWidget(boardCellSize: _boardCellSize),
                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? Colors.white24 : Colors.black26,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'AD SPACE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              DragLayerWidget(
                boardRect: _boardRect,
                boardCellSize: _boardCellSize,
              ),

              if (gameProvider.isPaused) ...[
                Container(
                  color: Colors.black.withValues(alpha: 0.65),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: isDark ? GameColors.darkSurface : GameColors.lightSurface,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'GAME PAUSED',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: CommonButton(
                              label: 'Resume Game',
                              icon: Icons.play_arrow_rounded,
                              onPressed: () => gameProvider.togglePause(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: CommonButton(
                              label: 'Restart',
                              icon: Icons.replay,
                              isSecondary: true,
                              onPressed: () {
                                gameProvider.togglePause();
                                gameProvider.startNewGame();
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: CommonButton(
                              label: 'Main Menu',
                              icon: Icons.home_rounded,
                              isSecondary: true,
                              onPressed: () {
                                gameProvider.togglePause();
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
