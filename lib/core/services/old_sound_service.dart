import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static const _key = 'sound_enabled';

  /// 🔊 ATTIVO DI DEFAULT
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
