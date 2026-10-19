import 'package:flutter/material.dart';
import '../game/models/block_shape.dart';

class PieceWidget extends StatelessWidget {
  final BlockShape shape;
  final double cellSize;
  final double scale;

  const PieceWidget({
    super.key,
    required this.shape,
    required this.cellSize,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveCellSize = cellSize * scale;
    final gridWidth = shape.cols * effectiveCellSize;
    final gridHeight = shape.rows * effectiveCellSize;

    return SizedBox(
      width: gridWidth,
      height: gridHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(shape.rows, (r) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(shape.cols, (c) {
              final isFilled = shape.matrix[r][c];
              return Container(
                width: effectiveCellSize,
                height: effectiveCellSize,
                padding: EdgeInsets.all(effectiveCellSize * 0.08),
                child: isFilled
                    ? _buildBlockCell(shape.color, effectiveCellSize)
                    : const SizedBox.shrink(),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildBlockCell(Color color, double size) {
    final borderRadius = size * 0.22;
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.95),
            color,
            Color.alphaBlend(Colors.black.withValues(alpha: 0.25), color),
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
        margin: EdgeInsets.all(size * 0.12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius * 0.7),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
      ),
    );
  }
}
