import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: GameColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: GameColors.primaryAccent,
        secondary: GameColors.secondaryAccent,
        surface: GameColors.darkSurface,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      useMaterial3: true,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: GameColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: GameColors.primaryAccent,
        secondary: GameColors.secondaryAccent,
        surface: GameColors.lightSurface,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      useMaterial3: true,
    );
  }
}
