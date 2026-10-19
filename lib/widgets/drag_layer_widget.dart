import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/game_colors.dart';
import '../game/models/block_shape.dart';
import '../game/state/drag_state.dart';
import '../game/state/game_provider.dart';
import 'piece_widget.dart';

class DragLayerWidget extends StatelessWidget {
  final Rect boardRect;
  final double boardCellSize;

  const DragLayerWidget({
    super.key,
    required this.boardRect,
    required this.boardCellSize,
  });

  @override
  Widget build(BuildContext context) {
    // We only need the provider to get the notifier and currentPieces, 
    // but we don't want to rebuild on every game provider change if we can help it.
    // However, context.read is enough since we will use ValueListenableBuilder.
    final gameProvider = context.read<GameProvider>();

    return ValueListenableBuilder<DragStateData?>(
      valueListenable: gameProvider.dragNotifier,
      builder: (context, dragData, child) {
        if (dragData == null) {
          return const SizedBox.shrink();
        }

        final shape = gameProvider.currentPieces[dragData.activePieceIndex];
        if (shape == null) return const SizedBox.shrink();

        final pieceWidth = shape.cols * boardCellSize;
        final pieceHeight = shape.rows * boardCellSize;
        final pos = dragData.globalPosition;

        final widgets = <Widget>[];

        // 1. Draw Ghost Preview
        if (dragData.hoveredRow != null && dragData.hoveredCol != null) {
          final top = boardRect.top + dragData.hoveredRow! * boardCellSize;
          final left = boardRect.left + dragData.hoveredCol! * boardCellSize;
          
          final isGhostValid = dragData.isPlacementValid;
          final highlightColor = isGhostValid
              ? shape.color.withValues(alpha: 0.55)
              : GameColors.warningAccent.withValues(alpha: 0.45);
              
          final borderColor = isGhostValid ? GameColors.validHighlight : GameColors.warningAccent;
          final shadowColor = isGhostValid
              ? GameColors.validHighlight.withValues(alpha: 0.4)
              : GameColors.warningAccent.withValues(alpha: 0.3);

          widgets.add(
            Positioned(
              left: left,
              top: top,
              child: IgnorePointer(
                child: _buildGhostPiece(
                  shape: shape,
                  cellSize: boardCellSize,
                  highlightColor: highlightColor,
                  borderColor: borderColor,
                  shadowColor: shadowColor,
                ),
              ),
            ),
          );
        }

        // 2. Draw Dragged Piece
        // The finger offset is applied in updateDrag for the targetPos, but for drawing, 
        // we might want the piece to be slightly above the finger so it's not obscured.
        // The original code did: top: pos.dy - (pieceHeight / 2) - (_boardCellSize * 2.0)
        widgets.add(
          Positioned(
            left: pos.dx - (pieceWidth / 2),
            top: pos.dy - (pieceHeight / 2) - (boardCellSize * 2.0),
            child: IgnorePointer(
              child: Material(
                color: Colors.transparent,
                elevation: 12,
                shadowColor: shape.color.withValues(alpha: 0.5),
                child: PieceWidget(
                  shape: shape,
                  cellSize: boardCellSize,
                  scale: 1.05,
                ),
              ),
            ),
          ),
        );

        return Stack(
          children: widgets,
        );
      },
    );
  }

  Widget _buildGhostPiece({
    required BlockShape shape,
    required double cellSize,
    required Color highlightColor,
    required Color borderColor,
    required Color shadowColor,
  }) {
    // Instead of using PieceWidget which is fully opaque, we build a custom ghost widget
    return SizedBox(
      width: shape.cols * cellSize,
      height: shape.rows * cellSize,
      child: Stack(
        children: [
          for (int r = 0; r < shape.rows; r++)
            for (int c = 0; c < shape.cols; c++)
              if (shape.matrix[r][c])
                Positioned(
                  left: c * cellSize,
                  top: r * cellSize,
                  width: cellSize,
                  height: cellSize,
                  child: Container(
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: BorderRadius.circular(cellSize * 0.18),
                      border: Border.all(
                        color: borderColor,
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
