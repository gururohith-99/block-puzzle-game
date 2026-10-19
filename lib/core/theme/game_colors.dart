import 'package:flutter/material.dart';

class GameColors {
  // Brand / Theme Colors
  static const Color darkBackground = Color(0xFF0F141C);
  static const Color darkSurface = Color(0xFF1A2230);
  static const Color darkBoardBg = Color(0xFF131924);
  static const Color darkCellEmpty = Color(0xFF1E2838);

  static const Color lightBackground = Color(0xFFF4F6FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBoardBg = Color(0xFFE6ECF5);
  static const Color lightCellEmpty = Color(0xFFD6E0EE);

  // Accents
  static const Color primaryAccent = Color(0xFF6366F1); // Soft Indigo
  static const Color secondaryAccent = Color(0xFF10B981); // Emerald
  static const Color warningAccent = Color(0xFFEF4444); // Red warning
  static const Color validHighlight = Color(0xFF22C55E); // Green placement

  // Vibrant Block Color Palette
  static const List<Color> blockPalette = [
    Color(0xFF38BDF8), // Sky Blue
    Color(0xFF4ADE80), // Vibrant Green
    Color(0xFFFBBF24), // Amber Gold
    Color(0xFFF43F5E), // Rose Coral
    Color(0xFFA855F7), // Purple Violet
    Color(0xFFFB923C), // Bright Orange
    Color(0xFF2DD4BF), // Teal
    Color(0xFFEC4899), // Pink
  ];

  static Color getBlockColor(int index) {
    return blockPalette[index % blockPalette.length];
  }
}
