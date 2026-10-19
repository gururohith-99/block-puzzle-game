import 'dart:math';
import '../models/block_shape.dart';
import '../models/grid_board.dart';

/// Semantic classification of block shapes for cooldown and anti-repetition.
enum ShapeFamily {
  single,
  line2,
  line3,
  line4,
  lShape,
  tShape,
  square2,
  skew,
  rect6,
  rect8,
  square3,
}

/// Optional game mode to allow future separation between Classic and Adventure modes.
enum GameMode {
  classic,
  adventure,
}

class PieceGenerator {
  final Random _random;

  // History tracking for anti-repetition and cooldowns
  final List<ShapeFamily> _recentFamilies = [];
  int _lCooldown = 0;
  int _tCooldown = 0;
  int _rareSquareCooldown = 0;

  PieceGenerator({Random? random}) : _random = random ?? Random();

  /// Resets generator state and cooldowns for a fresh game.
  void reset() {
    _recentFamilies.clear();
    _lCooldown = 0;
    _tCooldown = 0;
    _rareSquareCooldown = 0;
  }

  /// Returns the semantic family for any given shape ID.
  static ShapeFamily getShapeFamily(String id) {
    if (id.startsWith('single')) return ShapeFamily.single;
    if (id.startsWith('horiz_2') || id.startsWith('vert_2')) return ShapeFamily.line2;
    if (id.startsWith('horiz_3') || id.startsWith('vert_3')) return ShapeFamily.line3;
    if (id.startsWith('horiz_4') || id.startsWith('vert_4')) return ShapeFamily.line4;
    // Both small L (3 cells) and large L (4 cells) belong to lShape
    if (id.startsWith('l_small') || id.startsWith('l_4')) return ShapeFamily.lShape;
    // All 4 orientations of T belong to tShape
    if (id.startsWith('t_')) return ShapeFamily.tShape;
    if (id.startsWith('square_2x2')) return ShapeFamily.square2;
    if (id.startsWith('s_') || id.startsWith('z_')) return ShapeFamily.skew;
    if (id.startsWith('rect_2x3') || id.startsWith('rect_3x2')) return ShapeFamily.rect6;
    if (id.startsWith('rect_2x4') || id.startsWith('rect_4x2')) return ShapeFamily.rect8;
    if (id.startsWith('square_3x3')) return ShapeFamily.square3;
    return ShapeFamily.single;
  }

  /// Generates a fair, smart tray of 3 pieces tailored to the current [board] state.
  List<BlockShape> generateThreePieces(
    GridBoard board, {
    GameMode mode = GameMode.classic,
  }) {
    final catalog = BlockShape.catalog;
    final fill = board.fillPercentage;

    // 1. Analyze every catalog shape against the current board state
    final shapeAnalysis = <BlockShape, ({int validPlacements, int maxLinesCleared})>{};
    for (final shape in catalog) {
      final validCount = board.countValidPlacements(shape);
      final maxClears = validCount > 0 ? board.getMaxLinesCleared(shape) : 0;
      shapeAnalysis[shape] = (validPlacements: validCount, maxLinesCleared: maxClears);
    }

    // 2. Attempt weighted generation with whole-tray validation
    List<BlockShape>? bestTray;
    for (var attempt = 0; attempt < 25; attempt++) {
      final candidate = _tryGenerateCandidateTray(
        catalog: catalog,
        board: board,
        fill: fill,
        shapeAnalysis: shapeAnalysis,
      );

      if (candidate != null &&
          _isTrayFairAndPlayable(
            tray: candidate,
            board: board,
            fill: fill,
            shapeAnalysis: shapeAnalysis,
          )) {
        bestTray = candidate;
        break;
      }
    }

    // 3. Fallback / deterministic repair if random attempts failed
    bestTray ??= _createRepairedTray(
      catalog: catalog,
      board: board,
      fill: fill,
      shapeAnalysis: shapeAnalysis,
    );

    // 4. Update cooldowns and recent history based on accepted tray
    _updateHistoryAndCooldowns(bestTray);

    // 5. Shuffle so the tray doesn't have a predictable position pattern
    final result = List<BlockShape>.from(bestTray);
    result.shuffle(_random);
    return result;
  }

  /// Generates a candidate tray of 3 shapes using weighted selection.
  List<BlockShape>? _tryGenerateCandidateTray({
    required List<BlockShape> catalog,
    required GridBoard board,
    required double fill,
    required Map<BlockShape, ({int validPlacements, int maxLinesCleared})> shapeAnalysis,
  }) {
    final tray = <BlockShape>[];
    final trayFamilies = <ShapeFamily>{};
    final trayCellCounts = <int>{};

    for (var slot = 0; slot < 3; slot++) {
      final weights = <BlockShape, double>{};
      double totalWeight = 0.0;

      for (final shape in catalog) {
        final analysis = shapeAnalysis[shape]!;
        final w = _calculateShapeWeight(
          shape: shape,
          board: board,
          fill: fill,
          validPlacements: analysis.validPlacements,
          maxLinesCleared: analysis.maxLinesCleared,
          currentTrayFamilies: trayFamilies,
          currentTrayCellCounts: trayCellCounts,
        );

        if (w > 0.0) {
          weights[shape] = w;
          totalWeight += w;
        }
      }

      if (totalWeight <= 0.0) {
        // Fallback: pick any fitting shape not yet in current tray families
        final fallbackPool = catalog.where((s) {
          final f = getShapeFamily(s.id);
          return !trayFamilies.contains(f) && shapeAnalysis[s]!.validPlacements > 0;
        }).toList();

        final pool = fallbackPool.isNotEmpty
            ? fallbackPool
            : catalog.where((s) => !trayFamilies.contains(getShapeFamily(s.id))).toList();

        if (pool.isEmpty) return null;
        final chosen = pool[_random.nextInt(pool.length)];
        tray.add(chosen);
        trayFamilies.add(getShapeFamily(chosen.id));
        trayCellCounts.add(chosen.blockCount);
      } else {
        double r = _random.nextDouble() * totalWeight;
        BlockShape chosen = weights.keys.first;
        for (final entry in weights.entries) {
          r -= entry.value;
          if (r <= 0.0) {
            chosen = entry.key;
            break;
          }
        }
        tray.add(chosen);
        trayFamilies.add(getShapeFamily(chosen.id));
        trayCellCounts.add(chosen.blockCount);
      }
    }

    return tray;
  }

  /// Computes the selection weight for a shape given the board state and history.
  double _calculateShapeWeight({
    required BlockShape shape,
    required GridBoard board,
    required double fill,
    required int validPlacements,
    required int maxLinesCleared,
    required Set<ShapeFamily> currentTrayFamilies,
    required Set<int> currentTrayCellCounts,
  }) {
    final family = getShapeFamily(shape.id);

    // Rule: strictly no duplicate families in the same tray
    if (currentTrayFamilies.contains(family)) {
      return 0.0;
    }

    // Adaptive base weight from board fill level
    double weight = _getBaseWeight(family, fill);
    if (weight <= 0.0) return 0.0;

    final canFit = validPlacements > 0;

    // Board awareness: penalize or exclude shapes that do not fit
    if (!canFit) {
      if (fill >= 0.65) {
        // Crowded or nearly blocked: never give unplaceable pieces
        return 0.0;
      } else if (fill >= 0.40) {
        // Moderately filled: heavily penalize unplaceable pieces
        weight *= 0.02;
      } else {
        // Open board: allow occasional larger pieces
        weight *= 0.15;
      }
    } else {
      // Shape fits: reward placement flexibility (multiple valid spots)
      weight *= (1.0 + min(validPlacements, 12) * 0.04);
    }

    // Line clearing reward: boost shapes that clear completed lines
    if (maxLinesCleared > 0) {
      if (fill >= 0.80) {
        weight *= (4.0 + maxLinesCleared * 1.5);
      } else if (fill >= 0.65) {
        weight *= (3.0 + maxLinesCleared * 1.0);
      } else if (fill >= 0.40) {
        weight *= (2.2 + maxLinesCleared * 0.5);
      } else {
        weight *= (1.3 + maxLinesCleared * 0.3);
      }
    }

    // Anti-repetition & Cooldown rules for L and T shapes
    if (family == ShapeFamily.lShape) {
      if (_lCooldown > 0) {
        weight *= 0.10; // Heavily suppressed on cooldown
      }
      // Awkward shape combo suppression: avoid pairing L with T or Skew
      if (currentTrayFamilies.contains(ShapeFamily.tShape) ||
          currentTrayFamilies.contains(ShapeFamily.skew)) {
        weight *= (fill >= 0.65 ? 0.0 : 0.25);
      }
    }

    if (family == ShapeFamily.tShape) {
      if (_tCooldown > 0) {
        weight *= 0.10;
      }
      if (currentTrayFamilies.contains(ShapeFamily.lShape) ||
          currentTrayFamilies.contains(ShapeFamily.skew)) {
        weight *= (fill >= 0.65 ? 0.0 : 0.25);
      }
    }

    // Rare 3x3 solid piece constraints
    if (family == ShapeFamily.square3) {
      if (_rareSquareCooldown > 0 || !canFit || fill >= 0.40) {
        return 0.0;
      }
    }

    // Recent family recency penalty across consecutive trays
    final recentIndex = _recentFamilies.lastIndexOf(family);
    if (recentIndex != -1) {
      final recency = _recentFamilies.length - 1 - recentIndex;
      if (recency < 3) {
        weight *= 0.25;
      } else if (recency < 6) {
        weight *= 0.55;
      }
    }

    // Cell count variety: softly penalize cell counts already present in current tray
    if (currentTrayCellCounts.contains(shape.blockCount)) {
      weight *= 0.35;
    }

    return weight;
  }

  /// Returns adaptive base weights based on board fill percentage.
  double _getBaseWeight(ShapeFamily family, double fill) {
    if (fill >= 0.80) {
      // Nearly blocked board (>= 80% full)
      switch (family) {
        case ShapeFamily.single: return 32.0;
        case ShapeFamily.line2: return 26.0;
        case ShapeFamily.line3: return 20.0;
        case ShapeFamily.lShape: return 6.0;
        case ShapeFamily.line4: return 6.0;
        case ShapeFamily.square2: return 4.0;
        case ShapeFamily.tShape: return 3.0;
        case ShapeFamily.skew: return 3.0;
        case ShapeFamily.rect6: return 0.0;
        case ShapeFamily.rect8: return 0.0;
        case ShapeFamily.square3: return 0.0;
      }
    } else if (fill >= 0.65) {
      // Crowded board (65% to 80% full)
      switch (family) {
        case ShapeFamily.single: return 22.0;
        case ShapeFamily.line2: return 22.0;
        case ShapeFamily.line3: return 18.0;
        case ShapeFamily.lShape: return 8.0;
        case ShapeFamily.line4: return 10.0;
        case ShapeFamily.square2: return 8.0;
        case ShapeFamily.tShape: return 5.0;
        case ShapeFamily.skew: return 5.0;
        case ShapeFamily.rect6: return 2.0;
        case ShapeFamily.rect8: return 0.0;
        case ShapeFamily.square3: return 0.0;
      }
    } else if (fill >= 0.40) {
      // Moderately filled board (40% to 65% full)
      switch (family) {
        case ShapeFamily.single: return 12.0;
        case ShapeFamily.line2: return 16.0;
        case ShapeFamily.line3: return 16.0;
        case ShapeFamily.lShape: return 10.0;
        case ShapeFamily.line4: return 14.0;
        case ShapeFamily.square2: return 12.0;
        case ShapeFamily.tShape: return 8.0;
        case ShapeFamily.skew: return 8.0;
        case ShapeFamily.rect6: return 6.0;
        case ShapeFamily.rect8: return 1.5;
        case ShapeFamily.square3: return 0.0;
      }
    } else {
      // Open board (< 40% full)
      switch (family) {
        case ShapeFamily.single: return 8.0;
        case ShapeFamily.line2: return 12.0;
        case ShapeFamily.line3: return 14.0;
        case ShapeFamily.lShape: return 12.0;
        case ShapeFamily.line4: return 14.0;
        case ShapeFamily.square2: return 12.0;
        case ShapeFamily.tShape: return 10.0;
        case ShapeFamily.skew: return 10.0;
        case ShapeFamily.rect6: return 8.0;
        case ShapeFamily.rect8: return 5.0;
        case ShapeFamily.square3: return 1.5; // Rare solid 3x3 square
      }
    }
  }

  /// Evaluates the candidate tray as a whole for fairness, variety, and playability.
  bool _isTrayFairAndPlayable({
    required List<BlockShape> tray,
    required GridBoard board,
    required double fill,
    required Map<BlockShape, ({int validPlacements, int maxLinesCleared})> shapeAnalysis,
  }) {
    if (tray.length != 3) return false;

    // 1. Family uniqueness: All 3 pieces must belong to different families
    final families = tray.map((s) => getShapeFamily(s.id)).toSet();
    if (families.length < 3) return false;

    // 2. Cell count variety: Not all 3 pieces can have the identical block count
    final cellCounts = tray.map((s) => s.blockCount).toSet();
    if (cellCounts.length == 1) return false;

    // 3. Check fitting pieces
    final fittingPieces = tray.where((s) => shapeAnalysis[s]!.validPlacements > 0).toList();
    final totalFittingInCatalog = shapeAnalysis.values.where((a) => a.validPlacements > 0).length;

    if (totalFittingInCatalog >= 3) {
      // At least 2 pieces MUST fit; on crowded boards aim for as many as possible
      if (fittingPieces.length < 2) return false;
      if (fill >= 0.80 && fittingPieces.length < min(3, totalFittingInCatalog)) return false;
    } else if (totalFittingInCatalog > 0) {
      if (fittingPieces.length < totalFittingInCatalog) return false;
    }

    // 4. Sequential playability / Follow-up viability:
    // Does at least one fitting piece clear lines or leave room for subsequent placements?
    if (fittingPieces.length >= 2) {
      bool hasLineClearer = false;
      for (final p in fittingPieces) {
        if (shapeAnalysis[p]!.maxLinesCleared > 0) {
          hasLineClearer = true;
          break;
        }
      }

      if (!hasLineClearer && fill >= 0.50) {
        // Verify that placing fitting piece 0 doesn't eliminate all placements for fitting piece 1
        final p1 = fittingPieces[0];
        final p2 = fittingPieces[1];
        bool canChain = false;

        for (var r = 0; r <= board.rows - p1.rows; r++) {
          for (var c = 0; c <= board.cols - p1.cols; c++) {
            if (board.canPlace(p1, r, c)) {
              final testBoard = board.clone();
              testBoard.place(p1, r, c);
              final lineClears = testBoard.checkCompletedLines();
              if (lineClears.hasClears) {
                testBoard.clearLines(lineClears.rows, lineClears.cols);
              }
              if (testBoard.hasAnyValidMove(p2)) {
                canChain = true;
                break;
              }
            }
          }
          if (canChain) break;
        }

        if (!canChain) {
          return false;
        }
      }
    }

    return true;
  }

  /// Builds a guaranteed playable and diverse tray when random attempts fail.
  List<BlockShape> _createRepairedTray({
    required List<BlockShape> catalog,
    required GridBoard board,
    required double fill,
    required Map<BlockShape, ({int validPlacements, int maxLinesCleared})> shapeAnalysis,
  }) {
    final tray = <BlockShape>[];
    final usedFamilies = <ShapeFamily>{};

    // Sort catalog shapes: prefer shapes that fit, clear lines, and have small sizes
    final sortedCandidates = catalog.toList()
      ..sort((a, b) {
        final aAnalysis = shapeAnalysis[a]!;
        final bAnalysis = shapeAnalysis[b]!;

        // 1. Fits board first
        final aFits = aAnalysis.validPlacements > 0 ? 1 : 0;
        final bFits = bAnalysis.validPlacements > 0 ? 1 : 0;
        if (aFits != bFits) return bFits.compareTo(aFits);

        // 2. Line clear potential
        if (aAnalysis.maxLinesCleared != bAnalysis.maxLinesCleared) {
          return bAnalysis.maxLinesCleared.compareTo(aAnalysis.maxLinesCleared);
        }

        // 3. For crowded boards, smaller pieces first
        if (fill >= 0.65 && a.blockCount != b.blockCount) {
          return a.blockCount.compareTo(b.blockCount);
        }

        // 4. More placement spots
        return bAnalysis.validPlacements.compareTo(aAnalysis.validPlacements);
      });

    for (final shape in sortedCandidates) {
      final family = getShapeFamily(shape.id);
      if (!usedFamilies.contains(family)) {
        tray.add(shape);
        usedFamilies.add(family);
        if (tray.length == 3) break;
      }
    }

    // Safety fallback: if somehow fewer than 3 pieces found
    while (tray.length < 3) {
      for (final shape in catalog) {
        if (!tray.contains(shape)) {
          tray.add(shape);
          if (tray.length == 3) break;
        }
      }
    }

    return tray;
  }

  /// Updates cooldown timers and recent family history.
  void _updateHistoryAndCooldowns(List<BlockShape> tray) {
    final hasL = tray.any((s) => getShapeFamily(s.id) == ShapeFamily.lShape);
    final hasT = tray.any((s) => getShapeFamily(s.id) == ShapeFamily.tShape);
    final hasSquare3 = tray.any((s) => getShapeFamily(s.id) == ShapeFamily.square3);

    if (hasL) {
      _lCooldown = 2;
    } else if (_lCooldown > 0) {
      _lCooldown--;
    }

    if (hasT) {
      _tCooldown = 2;
    } else if (_tCooldown > 0) {
      _tCooldown--;
    }

    if (hasSquare3) {
      _rareSquareCooldown = 6;
    } else if (_rareSquareCooldown > 0) {
      _rareSquareCooldown--;
    }

    for (final s in tray) {
      _recentFamilies.add(getShapeFamily(s.id));
    }
    while (_recentFamilies.length > 9) {
      _recentFamilies.removeAt(0);
    }
  }
}
