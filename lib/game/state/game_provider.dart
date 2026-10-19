import 'package:flutter/material.dart';
import '../../audio/audio_manager.dart';
import '../../core/utils/haptics.dart';
import '../../storage/storage_service.dart';
import '../logic/piece_generator.dart';
import '../logic/score_calculator.dart';
import '../models/block_shape.dart';
import '../models/grid_board.dart';
import '../../core/theme/game_colors.dart';
import 'drag_state.dart';

class GameProvider extends ChangeNotifier {
  final StorageService storageService;
  final AudioManager audioManager;
  final PieceGenerator _pieceGenerator = PieceGenerator();

  GridBoard board = GridBoard();
  List<BlockShape?> currentPieces = [null, null, null];

  int score = 0;
  int bestScore = 0;
  int comboStreak = 0;
  bool isGameOver = false;
  bool isNewHighScore = false;
  bool isPaused = false;

  // Settings
  bool soundEnabled = true;
  bool musicEnabled = true;
  bool hapticsEnabled = true;
  String themeMode = 'dark';

  // Active Drag State
  int? activePieceIndex;
  Offset? dragGlobalPosition;
  
  final ValueNotifier<DragStateData?> dragNotifier = ValueNotifier(null);

  // Line Clear Animation State
  List<int> animatingRows = [];
  List<int> animatingCols = [];
  bool isClearingAnimationActive = false;

  GameProvider({
    required this.storageService,
    required this.audioManager,
  }) {
    _loadSettingsAndHighScore();
    startNewGame();
  }

  void _loadSettingsAndHighScore() {
    bestScore = storageService.getHighScore();
    soundEnabled = storageService.isSoundEnabled();
    musicEnabled = storageService.isMusicEnabled();
    hapticsEnabled = storageService.isHapticsEnabled();
    themeMode = storageService.getThemeMode();

    audioManager.updateSettings(sound: soundEnabled, music: musicEnabled);
    if (musicEnabled) {
      audioManager.startBgm();
    }
  }

  PieceGenerator get pieceGenerator => _pieceGenerator;

  void startNewGame() {
    board.clearBoard();
    _applyStarterPattern();
    _pieceGenerator.reset();
    score = 0;
    comboStreak = 0;
    isGameOver = false;
    isNewHighScore = false;
    isPaused = false;
    activePieceIndex = null;
    dragGlobalPosition = null;
    dragNotifier.value = null;
    animatingRows.clear();
    animatingCols.clear();
    isClearingAnimationActive = false;

    _generateNewPieceTray();
    checkGameOver();
    notifyListeners();
  }

  void _applyStarterPattern() {
    // A deterministic, carefully designed starter pattern with 13 occupied cells.
    // Leaves plenty of room, but breaks up the empty 8x8 space immediately.
    
    final c1 = GameColors.getBlockColor(1);
    final c2 = GameColors.getBlockColor(2);
    final c3 = GameColors.getBlockColor(3);
    final c4 = GameColors.getBlockColor(4);
    final c5 = GameColors.getBlockColor(5);
    final c6 = GameColors.getBlockColor(6);

    // Row 0
    board.cells[0][2] = c1;
    board.cells[0][3] = c1;
    
    // Row 1
    board.cells[1][1] = c2;
    board.cells[1][2] = c1;
    board.cells[1][5] = c3;
    board.cells[1][6] = c3;
    
    // Row 2
    board.cells[2][1] = c2;
    
    // Row 3
    board.cells[3][3] = c4;
    board.cells[3][4] = c4;
    board.cells[3][5] = c4;
    
    // Row 4
    board.cells[4][4] = c4;
    
    // Row 5
    board.cells[5][6] = c5;
    
    // Row 6
    board.cells[6][2] = c6;
    board.cells[6][3] = c6;
    board.cells[6][6] = c5;
  }

  void _generateNewPieceTray() {
    final newThree = _pieceGenerator.generateThreePieces(board);
    currentPieces = List<BlockShape?>.from(newThree);
  }

  // --- DRAG INTERACTION HANDLERS ---

  void startDrag(int pieceIndex, Offset globalPos) {
    if (isGameOver || isPaused || isClearingAnimationActive) return;
    if (pieceIndex < 0 || pieceIndex >= currentPieces.length) return;
    if (currentPieces[pieceIndex] == null) return;

    activePieceIndex = pieceIndex;
    dragGlobalPosition = globalPos;
    
    dragNotifier.value = DragStateData(
      activePieceIndex: pieceIndex,
      globalPosition: globalPos,
    );

    audioManager.playPickup();
    HapticUtils.lightImpact(hapticsEnabled);
    notifyListeners();
  }

  void updateDrag({
    required Offset globalPos,
    required Rect boardRect,
    required double cellSize,
  }) {
    if (activePieceIndex == null || currentPieces[activePieceIndex!] == null) return;

    dragGlobalPosition = globalPos;
    final shape = currentPieces[activePieceIndex!]!;

    // Check if touch is near or over the board area
    // Offset the target position upward slightly so finger doesn't obscure piece preview!
    final fingerOffsetY = cellSize * 2.0;
    final targetPos = Offset(globalPos.dx, globalPos.dy - fingerOffsetY);

    int? newHoveredRow;
    int? newHoveredCol;
    bool newIsValid = false;

    if (boardRect.contains(targetPos)) {
      final localX = targetPos.dx - boardRect.left;
      final localY = targetPos.dy - boardRect.top;

      // Centered placement preview under touch
      final col = ((localX - (shape.cols * cellSize / 2)) / cellSize).round();
      final row = ((localY - (shape.rows * cellSize / 2)) / cellSize).round();

      if (row >= 0 && col >= 0 && row + shape.rows <= board.rows && col + shape.cols <= board.cols) {
        newHoveredRow = row;
        newHoveredCol = col;
        newIsValid = board.canPlace(shape, row, col);
      }
    }

    dragNotifier.value = DragStateData(
      activePieceIndex: activePieceIndex!,
      globalPosition: globalPos,
      hoveredRow: newHoveredRow,
      hoveredCol: newHoveredCol,
      isPlacementValid: newIsValid,
    );
  }

  Future<void> endDrag() async {
    if (activePieceIndex == null) return;

    final shape = currentPieces[activePieceIndex!];
    final dragData = dragNotifier.value;
    final row = dragData?.hoveredRow;
    final col = dragData?.hoveredCol;
    final isValid = dragData?.isPlacementValid ?? false;

    if (shape != null && row != null && col != null && isValid) {
      // Valid placement!
      board.place(shape, row, col);
      currentPieces[activePieceIndex!] = null;

      audioManager.playPlace();
      HapticUtils.mediumImpact(hapticsEnabled);

      // Check completed lines
      final lineResult = board.checkCompletedLines();

      // Calculate score & combo
      final scoreResult = ScoreCalculator.calculateScore(
        shape: shape,
        linesCleared: lineResult.totalLines,
        currentComboStreak: comboStreak,
      );

      score += scoreResult.totalScoreAdded;
      comboStreak = scoreResult.comboStreak;

      if (score > bestScore) {
        bestScore = score;
        isNewHighScore = true;
        storageService.setHighScore(bestScore);
      }

      if (lineResult.hasClears) {
        // Trigger Line Clear Animation
        animatingRows = List<int>.from(lineResult.rows);
        animatingCols = List<int>.from(lineResult.cols);
        isClearingAnimationActive = true;
        notifyListeners();

        if (scoreResult.comboStreak > 1) {
          audioManager.playCombo();
          HapticUtils.heavyImpact(hapticsEnabled);
        } else {
          audioManager.playClear();
          HapticUtils.mediumImpact(hapticsEnabled);
        }

        // Wait for clear pulse animation
        await Future.delayed(const Duration(milliseconds: 280));

        board.clearLines(lineResult.rows, lineResult.cols);
        animatingRows.clear();
        animatingCols.clear();
        isClearingAnimationActive = false;
      }

      // Check if all 3 pieces in tray are placed
      if (currentPieces.every((p) => p == null)) {
        _generateNewPieceTray();
      }

      // Check Game Over: No valid moves remaining for ANY available piece in tray
      checkGameOver();
    } else {
      // Invalid release
      if (activePieceIndex != null && row != null) {
        audioManager.playInvalid();
        HapticUtils.lightImpact(hapticsEnabled);
      }
    }

    // Reset drag variables
    activePieceIndex = null;
    dragGlobalPosition = null;
    dragNotifier.value = null;
    notifyListeners();
  }

  void checkGameOver() {
    final remainingPieces = currentPieces.whereType<BlockShape>().toList();
    if (remainingPieces.isEmpty) {
      isGameOver = false;
      return;
    }

    bool anyMovePossible = false;
    for (final p in remainingPieces) {
      if (board.hasAnyValidMove(p)) {
        anyMovePossible = true;
        break;
      }
    }

    if (!anyMovePossible) {
      isGameOver = true;
      audioManager.playGameOver();
      HapticUtils.vibrate(hapticsEnabled);
    } else {
      isGameOver = false;
    }
  }

  // --- SETTINGS CONTROLS ---

  void togglePause() {
    isPaused = !isPaused;
    audioManager.playClick();
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    soundEnabled = value;
    await storageService.setSoundEnabled(value);
    audioManager.updateSettings(sound: soundEnabled, music: musicEnabled);
    notifyListeners();
  }

  Future<void> setMusicEnabled(bool value) async {
    musicEnabled = value;
    await storageService.setMusicEnabled(value);
    audioManager.updateSettings(sound: soundEnabled, music: musicEnabled);
    if (musicEnabled) {
      audioManager.startBgm();
    } else {
      audioManager.stopBgm();
    }
    notifyListeners();
  }

  Future<void> setHapticsEnabled(bool value) async {
    hapticsEnabled = value;
    await storageService.setHapticsEnabled(value);
    notifyListeners();
  }

  Future<void> setThemeMode(String mode) async {
    themeMode = mode;
    await storageService.setThemeMode(mode);
    notifyListeners();
  }
}
