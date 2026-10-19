import '../../core/constants/game_constants.dart';
import '../models/block_shape.dart';

class ScoreResult {
  final int totalScoreAdded;
  final int placementPoints;
  final int lineClearPoints;
  final int comboStreak;
  final double multiplier;

  const ScoreResult({
    required this.totalScoreAdded,
    required this.placementPoints,
    required this.lineClearPoints,
    required this.comboStreak,
    required this.multiplier,
  });
}

class ScoreCalculator {
  static ScoreResult calculateScore({
    required BlockShape shape,
    required int linesCleared,
    required int currentComboStreak,
  }) {
    final placementPoints = shape.blockCount * GameConstants.pointsPerBlock;

    int lineClearPoints = 0;
    int newStreak = currentComboStreak;

    if (linesCleared > 0) {
      newStreak += 1;
      if (linesCleared == 1) {
        lineClearPoints = GameConstants.pointsSingleLine;
      } else if (linesCleared == 2) {
        lineClearPoints = GameConstants.pointsDoubleLine;
      } else if (linesCleared == 3) {
        lineClearPoints = GameConstants.pointsTripleLine;
      } else {
        lineClearPoints = GameConstants.pointsQuadPlusLine * (linesCleared - 3);
      }
    } else {
      newStreak = 0; // Reset streak if move cleared no lines
    }

    final multiplier = newStreak > 1 ? 1.0 + (newStreak - 1) * 0.5 : 1.0;
    final totalAdded = ((placementPoints + lineClearPoints) * multiplier).round();

    return ScoreResult(
      totalScoreAdded: totalAdded,
      placementPoints: placementPoints,
      lineClearPoints: lineClearPoints,
      comboStreak: newStreak,
      multiplier: multiplier,
    );
  }
}
