class GameConstants {
  static const String appName = 'Block Haven';
  static const int boardSize = 8;
  static const int pieceTraySize = 3;

  // Storage Keys
  static const String keyHighScore = 'block_haven_high_score';
  static const String keySoundEnabled = 'block_haven_sound_enabled';
  static const String keyMusicEnabled = 'block_haven_music_enabled';
  static const String keyHapticsEnabled = 'block_haven_haptics_enabled';
  static const String keyThemeMode = 'block_haven_theme_mode'; // 'dark', 'light', 'system'

  // Score Values
  static const int pointsPerBlock = 10;
  static const int pointsSingleLine = 100;
  static const int pointsDoubleLine = 300;
  static const int pointsTripleLine = 600;
  static const int pointsQuadPlusLine = 1000;
}
