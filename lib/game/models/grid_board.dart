import 'package:flutter/material.dart';
import '../../core/constants/game_constants.dart';
import 'block_shape.dart';

class LineClearResult {
  final List<int> rows;
  final List<int> cols;

  const LineClearResult({required this.rows, required this.cols});

  int get totalLines => rows.length + cols.length;
  bool get hasClears => totalLines > 0;
}

class GridBoard {
  final int rows;
  final int cols;
  final List<List<Color?>> cells;

  GridBoard({
    this.rows = GameConstants.boardSize,
    this.cols = GameConstants.boardSize,
    List<List<Color?>>? initialCells,
  }) : cells = initialCells ??
            List.generate(
              GameConstants.boardSize,
              (_) => List<Color?>.filled(GameConstants.boardSize, null),
            );

  /// Creates a deep copy of the grid board
  GridBoard clone() {
    final copy = List.generate(
      rows,
      (r) => List<Color?>.from(cells[r]),
    );
    return GridBoard(rows: rows, cols: cols, initialCells: copy);
  }

  /// Checks if [shape] can be legally placed with its top-left at ([startRow], [startCol])
  bool canPlace(BlockShape shape, int startRow, int startCol) {
    if (startRow < 0 || startCol < 0) return false;
    if (startRow + shape.rows > rows) return false;
    if (startCol + shape.cols > cols) return false;

    for (var r = 0; r < shape.rows; r++) {
      for (var c = 0; c < shape.cols; c++) {
        if (shape.matrix[r][c]) {
          final targetRow = startRow + r;
          final targetCol = startCol + c;
          if (cells[targetRow][targetCol] != null) {
            return false; // Cell is already occupied!
          }
        }
      }
    }
    return true;
  }

  /// Places [shape] at ([startRow], [startCol])
  bool place(BlockShape shape, int startRow, int startCol) {
    if (!canPlace(shape, startRow, startCol)) return false;

    for (var r = 0; r < shape.rows; r++) {
      for (var c = 0; c < shape.cols; c++) {
        if (shape.matrix[r][c]) {
          cells[startRow + r][startCol + c] = shape.color;
        }
      }
    }
    return true;
  }

  /// Scans the board for completed rows and columns
  LineClearResult checkCompletedLines() {
    final completedRows = <int>[];
    final completedCols = <int>[];

    // Check rows
    for (var r = 0; r < rows; r++) {
      var full = true;
      for (var c = 0; c < cols; c++) {
        if (cells[r][c] == null) {
          full = false;
          break;
        }
      }
      if (full) completedRows.add(r);
    }

    // Check columns
    for (var c = 0; c < cols; c++) {
      var full = true;
      for (var r = 0; r < rows; r++) {
        if (cells[r][c] == null) {
          full = false;
          break;
        }
      }
      if (full) completedCols.add(c);
    }

    return LineClearResult(rows: completedRows, cols: completedCols);
  }

  /// Clears cells corresponding to completed rows and columns
  void clearLines(List<int> completedRows, List<int> completedCols) {
    for (final r in completedRows) {
      for (var c = 0; c < cols; c++) {
        cells[r][c] = null;
      }
    }
    for (final c in completedCols) {
      for (var r = 0; r < rows; r++) {
        cells[r][c] = null;
      }
    }
  }

  /// Checks whether [shape] can be placed ANYWHERE on the board
  bool hasAnyValidMove(BlockShape shape) {
    for (var r = 0; r <= rows - shape.rows; r++) {
      for (var c = 0; c <= cols - shape.cols; c++) {
        if (canPlace(shape, r, c)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Counts how many valid positions exist for [shape] on this board
  int countValidPlacements(BlockShape shape) {
    int count = 0;
    for (var r = 0; r <= rows - shape.rows; r++) {
      for (var c = 0; c <= cols - shape.cols; c++) {
        if (canPlace(shape, r, c)) {
          count++;
        }
      }
    }
    return count;
  }

  /// Calculates how many rows and columns would be completed if [shape]
  /// is placed at ([startRow], [startCol]).
  int linesClearedIfPlaced(BlockShape shape, int startRow, int startCol) {
    if (!canPlace(shape, startRow, startCol)) return 0;
    int cleared = 0;

    // Check affected rows
    for (var dr = 0; dr < shape.rows; dr++) {
      final r = startRow + dr;
      var rowFull = true;
      for (var c = 0; c < cols; c++) {
        final isPieceCell = (c >= startCol && c < startCol + shape.cols && shape.matrix[dr][c - startCol]);
        if (cells[r][c] == null && !isPieceCell) {
          rowFull = false;
          break;
        }
      }
      if (rowFull) cleared++;
    }

    // Check affected columns
    for (var dc = 0; dc < shape.cols; dc++) {
      final c = startCol + dc;
      var colFull = true;
      for (var r = 0; r < rows; r++) {
        final isPieceCell = (r >= startRow && r < startRow + shape.rows && shape.matrix[r - startRow][dc]);
        if (cells[r][c] == null && !isPieceCell) {
          colFull = false;
          break;
        }
      }
      if (colFull) cleared++;
    }

    return cleared;
  }

  /// Finds the maximum number of lines that can be cleared by placing [shape]
  /// anywhere legally on this board. Returns 0 if no placement clears a line.
  int getMaxLinesCleared(BlockShape shape) {
    int maxLines = 0;
    for (var r = 0; r <= rows - shape.rows; r++) {
      for (var c = 0; c <= cols - shape.cols; c++) {
        if (canPlace(shape, r, c)) {
          final lines = linesClearedIfPlaced(shape, r, c);
          if (lines > maxLines) {
            maxLines = lines;
          }
        }
      }
    }
    return maxLines;
  }

  /// Resets board to empty state
  void clearBoard() {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        cells[r][c] = null;
      }
    }
  }

  /// Calculates percentage of board filled (0.0 to 1.0)
  double get fillPercentage {
    int filled = 0;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (cells[r][c] != null) filled++;
      }
    }
    return filled / (rows * cols);
  }
}
