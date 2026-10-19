import 'package:flutter/material.dart';

class DragStateData {
  final int activePieceIndex;
  final Offset globalPosition;
  final int? hoveredRow;
  final int? hoveredCol;
  final bool isPlacementValid;

  DragStateData({
    required this.activePieceIndex,
    required this.globalPosition,
    this.hoveredRow,
    this.hoveredCol,
    this.isPlacementValid = false,
  });
}
