import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HapticService {
  static const _key = 'haptic_enabled';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  static Future<void> tap() async {
    if (await isEnabled()) {
      HapticFeedback.lightImpact();
    }
  }

  static Future<void> success() async {
    if (await isEnabled()) {
      HapticFeedback.mediumImpact();
    }
  }

  static Future<void> error() async {
    if (await isEnabled()) {
      HapticFeedback.heavyImpact();
    }
  }
}
