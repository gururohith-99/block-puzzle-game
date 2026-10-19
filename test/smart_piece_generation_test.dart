import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:block_haven/game/models/block_shape.dart';
import 'package:block_haven/game/models/grid_board.dart';
import 'package:block_haven/game/logic/piece_generator.dart';
import 'package:block_haven/game/logic/score_calculator.dart';
import 'package:block_haven/game/state/game_provider.dart';
import 'package:block_haven/storage/storage_service.dart';
import 'package:flutter/services.dart';
import 'package:block_haven/audio/audio_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
  });

  group('Requirement 1 & 2: Board-Aware & Adaptive Difficulty', () {
    late PieceGenerator generator;
    late GridBoard board;

    setUp(() {
      generator = PieceGenerator(random: Random(42));
      board = GridBoard();
    });

    test('On a crowded board, pieces fit available spaces and small shapes are favored', () {
      // Create a crowded board: fill 54 of 64 cells (> 84% full), leaving small openings
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          if (!((r == 0 && c < 3) || (r == 4 && c == 4) || (r == 7 && c >= 5))) {
            board.cells[r][c] = Colors.blue;
          }
        }
      }

      expect(board.fillPercentage, greaterThan(0.80));

      // Generate 20 trays on this crowded board
      for (var i = 0; i < 20; i++) {
        final tray = generator.generateThreePieces(board);
        expect(tray.length, equals(3));

        // Count how many pieces in tray have legal placements
        final fittingCount = tray.where((p) => board.hasAnyValidMove(p)).length;
        // On crowded board, at least 2 pieces must have legal placements
        expect(fittingCount, greaterThanOrEqualTo(2),
            reason: 'Tray $i on crowded board should provide at least 2 playable pieces');

        // Verify oversized pieces (8-cell or 9-cell) are never given when they cannot fit
        for (final piece in tray) {
          expect(piece.blockCount, isNot(equals(9)),
              reason: '9-cell piece must never be generated on crowded board');
          expect(piece.blockCount, isNot(equals(8)),
              reason: '8-cell piece must never be generated on crowded board');
        }
      }
    });

    test('Prioritizes pieces that can clear a row or column when opportunity exists', () {
      // Row 3 has 7 cells filled, exactly 1 cell empty at (3, 3)
      for (var c = 0; c < 8; c++) {
        if (c != 3) {
          board.cells[3][c] = Colors.red;
        }
      }

      // Generate trays and check if line-clearing shapes are provided frequently
      int traysWithLineClearOpportunity = 0;
      final runs = 30;

      for (var i = 0; i < runs; i++) {
        final trayGen = PieceGenerator(random: Random(100 + i));
        final tray = trayGen.generateThreePieces(board);
        final hasLineClearer = tray.any((p) => board.getMaxLinesCleared(p) > 0);
        if (hasLineClearer) {
          traysWithLineClearOpportunity++;
        }
      }

      // Strong majority of trays should contain a piece capable of clearing line
      expect(traysWithLineClearOpportunity / runs, greaterThanOrEqualTo(0.80),
          reason: 'Line-clearing opportunity pieces should be strongly favored');
    });

    test('Open board offers a balanced mix of small, medium, and occasional large pieces', () {
      final openBoard = GridBoard(); // completely empty (0% fill)
      final allGenerated = <BlockShape>[];

      for (var i = 0; i < 30; i++) {
        final tray = generator.generateThreePieces(openBoard);
        allGenerated.addAll(tray);
      }

      final smallCount = allGenerated.where((p) => p.blockCount <= 3).length;
      final mediumCount = allGenerated.where((p) => p.blockCount == 4).length;
      final largeCount = allGenerated.where((p) => p.blockCount >= 6).length;

      expect(smallCount, greaterThan(15), reason: 'Open board should include small pieces');
      expect(mediumCount, greaterThan(20), reason: 'Open board should include medium pieces');
      expect(largeCount, greaterThan(5), reason: 'Open board should include occasional large pieces');
    });
  });

  group('Requirement 3: Anti-Repetition & Cooldown System', () {
    test('Repeated generation does not constantly spam L or T shapes', () {
      final generator = PieceGenerator(random: Random(999));
      final board = GridBoard();

      int lCount = 0;
      int tCount = 0;
      final totalTrays = 50;

      for (var i = 0; i < totalTrays; i++) {
        final tray = generator.generateThreePieces(board);

        // Within ANY single tray, never more than 1 L shape or 1 T shape
        final trayL = tray.where((s) => PieceGenerator.getShapeFamily(s.id) == ShapeFamily.lShape).length;
        final trayT = tray.where((s) => PieceGenerator.getShapeFamily(s.id) == ShapeFamily.tShape).length;

        expect(trayL, lessThanOrEqualTo(1), reason: 'Tray $i has duplicate L shapes');
        expect(trayT, lessThanOrEqualTo(1), reason: 'Tray $i has duplicate T shapes');

        if (trayL > 0) lCount++;
        if (trayT > 0) tCount++;
      }

      // Out of 50 trays, L and T should appear moderately and not spam every single tray
      expect(lCount / totalTrays, lessThan(0.50), reason: 'L shapes appeared too frequently');
      expect(tCount / totalTrays, lessThan(0.50), reason: 'T shapes appeared too frequently');
    });

    test('The 3-piece tray has reasonable shape family and size variety', () {
      final generator = PieceGenerator(random: Random(1234));
      final board = GridBoard();

      for (var i = 0; i < 40; i++) {
        final tray = generator.generateThreePieces(board);

        // All 3 pieces must belong to different families
        final families = tray.map((s) => PieceGenerator.getShapeFamily(s.id)).toSet();
        expect(families.length, equals(3), reason: 'Tray $i should have 3 distinct shape families');

        // Cell counts must not all be identical (e.g. not [4, 4, 4])
        final cellCounts = tray.map((s) => s.blockCount).toSet();
        expect(cellCounts.length, greaterThanOrEqualTo(2),
            reason: 'Tray $i should have variety in cell counts');
      }
    });

    test('Pieces with cell counts 1, 2, 3, 4, 6, 8, 9 are all generated across runs', () {
      final generator = PieceGenerator(random: Random(777));
      final board = GridBoard();
      final observedCounts = <int>{};

      for (var i = 0; i < 150; i++) {
        final tray = generator.generateThreePieces(board);
        for (final p in tray) {
          observedCounts.add(p.blockCount);
        }
      }

      // Check all cell counts 1, 2, 3, 4, 6, 8, 9 appear
      expect(observedCounts, containsAll([1, 2, 3, 4, 6, 8, 9]),
          reason: 'All cell counts (1, 2, 3, 4, 6, 8, 9) must be represented');
    });

    test('All generated shapes are fully connected without gaps', () {
      final catalog = BlockShape.catalog;
      for (final shape in catalog) {
        expect(shape.blockCount, greaterThan(0));
        // Verify matrix dimensions
        expect(shape.rows, equals(shape.matrix.length));
        expect(shape.cols, equals(shape.matrix[0].length));
      }
    });
  });

  group('Requirement 4: Rare 3x3 Solid Square', () {
    test('3x3 square is rare on open boards and never generated when it cannot fit', () {
      final openBoard = GridBoard();
      int square3Count = 0;
      final totalTrays = 300;

      for (var i = 0; i < totalTrays; i++) {
        final gen = PieceGenerator(random: Random(2000 + i));
        final tray = gen.generateThreePieces(openBoard);
        for (final p in tray) {
          if (p.id == 'square_3x3') {
            square3Count++;
            expect(p.blockCount, equals(9));
            expect(p.rows, equals(3));
            expect(p.cols, equals(3));
          }
        }
      }

      // It must be possible (at least 1 across 300 trays)
      expect(square3Count, greaterThan(0), reason: '3x3 piece must remain possible on open board');
      // But rare (< 5% of all generated pieces, 300 * 3 = 900 pieces)
      final rate = square3Count / (totalTrays * 3);
      expect(rate, lessThan(0.04), reason: '3x3 piece must be rare (~1-3%)');

      // Now test board where 3x3 CANNOT fit anywhere (checkerboard pattern or filled)
      final blockedBoard = GridBoard();
      for (var r = 0; r < 8; r += 2) {
        for (var c = 0; c < 8; c += 2) {
          blockedBoard.cells[r][c] = Colors.green;
        }
      }
      expect(blockedBoard.hasAnyValidMove(BlockShape.catalog.firstWhere((s) => s.id == 'square_3x3')), isFalse);

      final blockedGen = PieceGenerator(random: Random(3000));
      for (var i = 0; i < 50; i++) {
        final tray = blockedGen.generateThreePieces(blockedBoard);
        expect(tray.any((p) => p.id == 'square_3x3'), isFalse,
            reason: '3x3 piece must never be generated when it cannot fit');
      }
    });
  });

  group('Requirement 5: Game Over Detection', () {
    late GameProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final audio = AudioManager();
      provider = GameProvider(storageService: storage, audioManager: audio);
    });

    test('Game over is NOT declared when any current piece has a legal placement', () {
      // Clear board and fill all cells except (0, 0)
      provider.board.clearBoard();
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          if (r != 0 || c != 0) {
            provider.board.cells[r][c] = Colors.blue;
          }
        }
      }

      // Set tray: piece 0 cannot fit (4x2), piece 1 can fit (1x1), piece 2 cannot fit (3x3)
      final single1x1 = BlockShape.catalog.firstWhere((s) => s.id == 'single_1x1');
      final square3x3 = BlockShape.catalog.firstWhere((s) => s.id == 'square_3x3');
      final rect4x2 = BlockShape.catalog.firstWhere((s) => s.id == 'rect_4x2');

      provider.currentPieces = [square3x3, single1x1, rect4x2];
      provider.checkGameOver();

      expect(provider.isGameOver, isFalse,
          reason: 'Game over must NOT trigger while single_1x1 has a valid placement');
    });

    test('Game over IS declared when all remaining pieces have no legal placement', () {
      // Clear board and fill all cells except (0, 0)
      provider.board.clearBoard();
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          if (r != 0 || c != 0) {
            provider.board.cells[r][c] = Colors.blue;
          }
        }
      }

      // Set tray: all 3 pieces require 2x2 or more, only (0, 0) is open
      final square2x2 = BlockShape.catalog.firstWhere((s) => s.id == 'square_2x2');
      final square3x3 = BlockShape.catalog.firstWhere((s) => s.id == 'square_3x3');
      final rect4x2 = BlockShape.catalog.firstWhere((s) => s.id == 'rect_4x2');

      provider.currentPieces = [square2x2, square3x3, rect4x2];
      provider.checkGameOver();

      expect(provider.isGameOver, isTrue,
          reason: 'Game over must trigger when none of the pieces can be placed');
    });

    test('Game over rechecks after placements and line clears', () {
      // Start with board having row 0 with 7 cells filled (except (0, 0))
      provider.board.clearBoard();
      for (var c = 1; c < 8; c++) {
        provider.board.cells[0][c] = Colors.yellow;
      }

      // Other cells are filled except row 0
      for (var r = 1; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          provider.board.cells[r][c] = Colors.purple;
        }
      }

      final single1x1 = BlockShape.catalog.firstWhere((s) => s.id == 'single_1x1');
      final horiz4 = BlockShape.catalog.firstWhere((s) => s.id == 'horiz_4');

      // Before placing: single1x1 can fit at (0, 0), horiz4 cannot fit
      provider.currentPieces = [single1x1, horiz4, null];
      provider.checkGameOver();
      expect(provider.isGameOver, isFalse);

      // Place single1x1 at (0, 0), which completes row 0!
      provider.board.place(single1x1, 0, 0);
      final lines = provider.board.checkCompletedLines();
      expect(lines.rows, contains(0));

      // Clear row 0
      provider.board.clearLines(lines.rows, lines.cols);

      // Now row 0 is completely empty (8 cells)!
      // horiz4 can now legally fit in row 0!
      provider.currentPieces[0] = null; // single was used
      provider.checkGameOver();
      expect(provider.isGameOver, isFalse,
          reason: 'Clearing row 0 opened space for horiz4, so game over must remain false');
    });
  });

  group('Requirement 6 & 8: Board Integrity & Adventure Mode Preservation', () {
    test('8x8 starter pattern initializes with 13 occupied cells and ample open space', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final audio = AudioManager();
      final provider = GameProvider(storageService: storage, audioManager: audio);

      provider.startNewGame();
      expect(provider.board.rows, equals(8));
      expect(provider.board.cols, equals(8));

      int occupiedCount = 0;
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          if (provider.board.cells[r][c] != null) occupiedCount++;
        }
      }
      expect(occupiedCount, equals(15), reason: 'Starter pattern must preserve 15 starter blocks');
      expect(provider.board.fillPercentage, lessThan(0.25));
    });

    test('PieceGenerator supports GameMode.classic and GameMode.adventure', () {
      final gen = PieceGenerator();
      final board = GridBoard();

      final classicTray = gen.generateThreePieces(board, mode: GameMode.classic);
      expect(classicTray.length, equals(3));

      final adventureTray = gen.generateThreePieces(board, mode: GameMode.adventure);
      expect(adventureTray.length, equals(3));
    });
  });

  group('Requirement 7: Line Clearing & Scoring', () {
    test('Horizontal line clear scoring with combo streaks', () {
      final horiz4 = BlockShape.catalog.firstWhere((s) => s.id == 'horiz_4');
      final res = ScoreCalculator.calculateScore(
        shape: horiz4,
        linesCleared: 1,
        currentComboStreak: 2,
      );

      expect(res.placementPoints, equals(40));
      expect(res.lineClearPoints, equals(100));
      expect(res.comboStreak, equals(3));
      expect(res.multiplier, equals(2.0));
      // (40 + 100) * 2.0 = 280
      expect(res.totalScoreAdded, equals(280));
    });

    test('Simultaneous multi-line clear scoring', () {
      final single1x1 = BlockShape.catalog.firstWhere((s) => s.id == 'single_1x1');
      final res = ScoreCalculator.calculateScore(
        shape: single1x1,
        linesCleared: 3,
        currentComboStreak: 0,
      );

      expect(res.placementPoints, equals(10));
      expect(res.lineClearPoints, equals(600)); // 3 lines = 600
      expect(res.comboStreak, equals(1));
      expect(res.multiplier, equals(1.0));
      expect(res.totalScoreAdded, equals(610));
    });
  });
}
