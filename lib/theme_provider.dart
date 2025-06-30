import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Color _accentColor = const Color(0xFFF1B1E21); // Default accent red

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;

  ThemeProvider() {
    _loadPreferences();
  }

  /// Toggles between light and dark theme
  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _savePreferences();
    notifyListeners();
  }

  /// Allows dynamic accent color changes
  void setAccentColor(Color color) {
    _accentColor = color;
    _savePreferences();
    notifyListeners();
  }

  /// Loads theme mode and accent color from SharedPreferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final isDark = prefs.getBool('isDark') ?? false;
    final savedColor = prefs.getInt('accentColor');

    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    if (savedColor != null) {
      _accentColor = Color(savedColor);
    }

    notifyListeners();
  }

  /// Saves current theme mode and accent color to SharedPreferences
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _themeMode == ThemeMode.dark);
    await prefs.setInt('accentColor', _accentColor.value);
  }
}
