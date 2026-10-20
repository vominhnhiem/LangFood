import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý Theme Mode (Sáng / Tối / Hệ thống)
/// Mặc định: Chế độ sáng (ThemeMode.light) theo yêu cầu người dùng
class ThemeProvider extends ChangeNotifier {
  static const String _themePrefKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider({ThemeMode initialMode = ThemeMode.light}) {
    _themeMode = initialMode;
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themePrefKey);
      if (savedMode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (savedMode == 'system') {
        _themeMode = ThemeMode.system;
      } else {
        // Mặc định luôn là Chế độ sáng
        _themeMode = ThemeMode.light;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ThemeProvider._loadThemeFromPrefs error: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        if (mode == ThemeMode.dark) {
          await prefs.setString(_themePrefKey, 'dark');
        } else if (mode == ThemeMode.system) {
          await prefs.setString(_themePrefKey, 'system');
        } else {
          await prefs.setString(_themePrefKey, 'light');
        }
      } catch (e) {
        debugPrint('ThemeProvider.setThemeMode error: $e');
      }
    }
  }

  Future<void> toggleTheme() async {
    final nextMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }
}
