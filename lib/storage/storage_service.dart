import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/game_constants.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // High Score
  int getHighScore() {
    return _prefs.getInt(GameConstants.keyHighScore) ?? 0;
  }

  Future<bool> setHighScore(int score) async {
    return await _prefs.setInt(GameConstants.keyHighScore, score);
  }

  // Sound
  bool isSoundEnabled() {
    return _prefs.getBool(GameConstants.keySoundEnabled) ?? true;
  }

  Future<bool> setSoundEnabled(bool enabled) async {
    return await _prefs.setBool(GameConstants.keySoundEnabled, enabled);
  }

  // Music
  bool isMusicEnabled() {
    return _prefs.getBool(GameConstants.keyMusicEnabled) ?? true;
  }

  Future<bool> setMusicEnabled(bool enabled) async {
    return await _prefs.setBool(GameConstants.keyMusicEnabled, enabled);
  }

  // Haptics
  bool isHapticsEnabled() {
    return _prefs.getBool(GameConstants.keyHapticsEnabled) ?? true;
  }

  Future<bool> setHapticsEnabled(bool enabled) async {
    return await _prefs.setBool(GameConstants.keyHapticsEnabled, enabled);
  }

  // Theme Mode ('dark', 'light', 'system')
  String getThemeMode() {
    return _prefs.getString(GameConstants.keyThemeMode) ?? 'dark';
  }

  Future<bool> setThemeMode(String mode) async {
    return await _prefs.setString(GameConstants.keyThemeMode, mode);
  }
}
