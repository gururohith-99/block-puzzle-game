import 'package:flutter/services.dart';

class HapticUtils {
  static void selectionClick(bool enabled) {
    if (enabled) {
      HapticFeedback.selectionClick();
    }
  }

  static void lightImpact(bool enabled) {
    if (enabled) {
      HapticFeedback.lightImpact();
    }
  }

  static void mediumImpact(bool enabled) {
    if (enabled) {
      HapticFeedback.mediumImpact();
    }
  }

  static void heavyImpact(bool enabled) {
    if (enabled) {
      HapticFeedback.heavyImpact();
    }
  }

  static void vibrate(bool enabled) {
    if (enabled) {
      HapticFeedback.vibrate();
    }
  }
}
