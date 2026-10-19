import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:block_haven/game/models/block_shape.dart';
import 'package:block_haven/game/models/grid_board.dart';
import 'package:block_haven/game/logic/score_calculator.dart';
import 'package:block_haven/game/logic/piece_generator.dart';

void main() {
  group('GridBoard Logic Tests', () {
    late GridBoard board;

    setUp(() {
      board = GridBoard();
    });

    test('Board initializes to empty 8x8 grid', () {
      expect(board.rows, equals(8));
      expect(board.cols, equals(8));
      expect(board.fillPercentage, equals(0.0));
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          expect(board.cells[r][c], isNull);
        }
      }
    });

    test('canPlace accepts valid bounds and rejects occupied or out-of-bounds cells', () {
      final single = BlockShape.catalog.firstWhere((s) => s.id == 'single_1x1');
      final square = BlockShape.catalog.firstWhere((s) => s.id == 'square_2x2');

      // Valid placement at (0, 0)
      expect(board.canPlace(single, 0, 0), isTrue);
      expect(board.canPlace(square, 0, 0), isTrue);

      // Invalid out-of-bounds at (7, 7) for 2x2 square (needs 2x2 space, max row/col is 7)
      expect(board.canPlace(square, 7, 7), isFalse);

      // Place single at (0, 0)
      board.place(single, 0, 0);

      // Single cell (0, 0) is now occupied
      expect(board.cells[0][0], equals(single.color));

      // Overlapping placement at (0, 0) should fail
      expect(board.canPlace(single, 0, 0), isFalse);
      expect(board.canPlace(square, 0, 0), isFalse);
    });

    test('Horizontal line detection and clearing', () {
      final horiz4 = BlockShape.catalog.firstWhere((s) => s.id == 'horiz_4');

      // Fill row 0 with two 4-bars (4 + 4 = 8)
      expect(board.place(horiz4, 0, 0), isTrue);
      expect(board.place(horiz4, 0, 4), isTrue);

      final clearResult = board.checkCompletedLines();
      expect(clearResult.totalLines, equals(1));
      expect(clearResult.rows, contains(0));
      expect(clearResult.cols, isEmpty);

      // Perform clear
      board.clearLines(clearResult.rows, clearResult.cols);

      // Row 0 should now be empty again
      for (var c = 0; c < 8; c++) {
        expect(board.cells[0][c], isNull);
      }
    });

    test('Vertical line detection and clearing', () {
      final vert4 = BlockShape.catalog.firstWhere((s) => s.id == 'vert_4');

      // Fill column 3 with two 4-bars (4 + 4 = 8)
      expect(board.place(vert4, 0, 3), isTrue);
      expect(board.place(vert4, 4, 3), isTrue);

      final clearResult = board.checkCompletedLines();
      expect(clearResult.totalLines, equals(1));
      expect(clearResult.cols, contains(3));

      board.clearLines(clearResult.rows, clearResult.cols);

      for (var r = 0; r < 8; r++) {
        expect(board.cells[r][3], isNull);
      }
    });

    test('Simultaneous multi-line (row + column) detection', () {
      // Manually fill row 2 and col 4
      for (var c = 0; c < 8; c++) {
        board.cells[2][c] = Colors.blue;
      }
      for (var r = 0; r < 8; r++) {
        board.cells[r][4] = Colors.red;
      }

      final clearResult = board.checkCompletedLines();
      expect(clearResult.totalLines, equals(2));
      expect(clearResult.rows, contains(2));
      expect(clearResult.cols, contains(4));
    });
  });

  group('Score Calculator Tests', () {
    test('Placement score for 2x2 square', () {
      final square = BlockShape.catalog.firstWhere((s) => s.id == 'square_2x2');
      final res = ScoreCalculator.calculateScore(
        shape: square,
        linesCleared: 0,
        currentComboStreak: 0,
      );

      expect(res.placementPoints, equals(40)); // 4 blocks * 10
      expect(res.lineClearPoints, equals(0));
      expect(res.comboStreak, equals(0));
      expect(res.totalScoreAdded, equals(40));
    });

    test('Single line clear score with streak increase', () {
      final single = BlockShape.catalog.firstWhere((s) => s.id == 'single_1x1');
      final res = ScoreCalculator.calculateScore(
        shape: single,
        linesCleared: 1,
        currentComboStreak: 1,
      );

      expect(res.comboStreak, equals(2));
      expect(res.multiplier, equals(1.5));
      expect(res.placementPoints, equals(10));
      expect(res.lineClearPoints, equals(100));
      // (10 + 100) * 1.5 = 165
      expect(res.totalScoreAdded, equals(165));
    });
  });

  group('Piece Generator Tests', () {
    test('PieceGenerator creates 3 non-null shapes', () {
      final generator = PieceGenerator();
      final board = GridBoard();
      final pieces = generator.generateThreePieces(board);

      expect(pieces.length, equals(3));
      for (final p in pieces) {
        expect(p, isNotNull);
      }
    });

    test('PieceGenerator guarantees at least 1 valid shape on non-full board', () {
      final generator = PieceGenerator();
      final board = GridBoard();
      final pieces = generator.generateThreePieces(board);

      bool anyValid = false;
      for (final p in pieces) {
        if (board.hasAnyValidMove(p)) {
          anyValid = true;
          break;
        }
      }
      expect(anyValid, isTrue);
    });
  });
}
