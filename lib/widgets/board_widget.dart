import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/game_colors.dart';
import '../game/state/game_provider.dart';

class BoardWidget extends StatelessWidget {
  final Function(Rect boardRect, double cellSize) onBoardLayout;

  const BoardWidget({
    super.key,
    required this.onBoardLayout,
  });

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final board = gameProvider.board;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final boardBgColor = isDark ? GameColors.darkBoardBg : GameColors.lightBoardBg;
    final emptyCellColor = isDark ? GameColors.darkCellEmpty : GameColors.lightCellEmpty;

    return AspectRatio(
      aspectRatio: 1.0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boardSize = constraints.maxWidth;
          final cellSize = boardSize / board.cols;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            final renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox != null && renderBox.hasSize) {
              final position = renderBox.localToGlobal(Offset.zero);
              final rect = position & renderBox.size;
              onBoardLayout(rect, cellSize);
            }
          });

          return RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: boardBgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: board.rows * board.cols,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: board.cols,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
              ),
              itemBuilder: (context, index) {
                final r = index ~/ board.cols;
                final c = index % board.cols;

                final cellColor = board.cells[r][c];
                final isAnimatingClear = gameProvider.isClearingAnimationActive &&
                    (gameProvider.animatingRows.contains(r) ||
                        gameProvider.animatingCols.contains(c));

                return _buildCell(
                  color: cellColor,
                  emptyColor: emptyCellColor,
                  isAnimatingClear: isAnimatingClear,
                  cellSize: cellSize,
                );
              },
            ),
          ),
          );
        },
      ),
    );
  }

  Widget _buildCell({
    required Color? color,
    required Color emptyColor,
    required bool isAnimatingClear,
    required double cellSize,
  }) {
    final borderRadius = BorderRadius.circular(cellSize * 0.18);

    if (isAnimatingClear) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
          boxShadow: const [
            BoxShadow(
              color: Colors.white,
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
      );
    }

    if (color != null) {
      return Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.95),
              color,
              Color.alphaBlend(Colors.black.withValues(alpha: 0.3), color),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          margin: EdgeInsets.all(cellSize * 0.08),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cellSize * 0.12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: emptyColor,
        borderRadius: borderRadius,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.04),
          width: 1.0,
        ),
      ),
    );
  }
}
