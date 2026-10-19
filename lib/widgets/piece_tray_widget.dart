import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/state/game_provider.dart';
import 'piece_widget.dart';

class PieceTrayWidget extends StatelessWidget {
  final double boardCellSize;

  const PieceTrayWidget({
    super.key,
    required this.boardCellSize,
  });

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final pieces = gameProvider.currentPieces;

    return RepaintBoundary(
      child: Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF161E2E)
            : const Color(0xFFE8EEF8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
              .withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          final piece = pieces[index];
          final isBeingDragged = gameProvider.activePieceIndex == index;

          if (piece == null || isBeingDragged) {
            return const Expanded(
              child: SizedBox(
                height: 100,
              ),
            );
          }

          final maxDim = piece.rows > piece.cols ? piece.rows : piece.cols;
          final trayCellSize = (72.0 / maxDim).clamp(14.0, 24.0);

          return Expanded(
            child: Listener(
              onPointerDown: (event) {
                gameProvider.startDrag(index, event.position);
              },
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.center,
                child: PieceWidget(
                  shape: piece,
                  cellSize: trayCellSize,
                ),
              ),
            ),
          );
        }),
      ),
      ),
    );
  }
}
