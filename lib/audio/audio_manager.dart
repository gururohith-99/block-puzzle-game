import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  bool soundEnabled = true;
  bool musicEnabled = true;

  AudioManager() {
    _init();
  }

  void _init() {
    try {
      _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      _bgmPlayer.onPlayerComplete.listen((_) {
        if (musicEnabled) {
          startBgm();
        }
      });
    } catch (e) {
      debugPrint('AudioManager init error: $e');
    }
  }

  void updateSettings({required bool sound, required bool music}) {
    soundEnabled = sound;
    musicEnabled = music;
    if (!musicEnabled) {
      stopBgm();
    }
  }

  Future<void> playPickup() async {
    if (!soundEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/pickup.wav'));
    } catch (e) {
      debugPrint('Audio pickup error: $e');
    }
  }

  Future<void> playPlace() async {
    if (!soundEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/place.wav'));
    } catch (e) {
      debugPrint('Audio place error: $e');
    }
  }

  Future<void> playInvalid() async {
    if (!soundEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/invalid.wav'));
    } catch (e) {
      debugPrint('Audio invalid error: $e');
    }
  }

  Future<void> playClear() async {
    if (!soundEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/clear.wav'));
    } catch (e) {
      debugPrint('Audio clear error: $e');
    }
  }

  Future<void> playCombo() async {
    if (!soundEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/combo.wav'));
    } catch (e) {
      debugPrint('Audio combo error: $e');
    }
  }

  Future<void> playGameOver() async {
    if (!soundEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/game_over.wav'));
    } catch (e) {
      debugPrint('Audio game over error: $e');
    }
  }

  Future<void> playClick() async {
    if (!soundEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/click.wav'));
    } catch (e) {
      debugPrint('Audio click error: $e');
    }
  }

  Future<void> startBgm() async {
    if (!musicEnabled) return;
    try {
      if (_bgmPlayer.state != PlayerState.playing) {
        await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
        await _bgmPlayer.play(AssetSource('audio/bgm.wav'), volume: 0.3);
      }
    } catch (e) {
      debugPrint('Audio BGM error: $e');
    }
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
    } catch (e) {
      debugPrint('Audio BGM stop error: $e');
    }
  }

  void dispose() {
    _sfxPlayer.dispose();
    _bgmPlayer.dispose();
  }
}
