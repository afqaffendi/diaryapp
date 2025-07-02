import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _selectedTheme = 'ice'; // default theme

  ThemeMode get themeMode => _themeMode;
  String get selectedTheme => _selectedTheme;

  static final Map<String, Map<String, Color>> _themeColors = {
    'red': {
      'light': Color(0xFFFAD4CF),
      'dark': Color(0xFF8B3A3A),
    },
    'pink': {
      'light': Color(0xFFFFDDEE),
      'dark': Color(0xFFAD5175),
    },
    'black': {
      'light': Colors.white,
      'dark': Colors.black,
    },
    'blue': {
      'light': Color(0xFFD6E6FF),
      'dark': Color(0xFF223366),
    },
  };

  Color get accentColor {
    final colors = _themeColors[_selectedTheme];
    if (colors == null) return Colors.grey;
    return _themeMode == ThemeMode.dark ? colors['dark']! : colors['light']!;
  }

  ThemeProvider() {
    _loadPreferences();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _savePreferences();
    notifyListeners();
  }

  void setThemeByName(String themeName) {
    if (_themeColors.containsKey(themeName)) {
      _selectedTheme = themeName;
      _savePreferences();
      notifyListeners();
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = prefs.getBool('isDark') ?? false ? ThemeMode.dark : ThemeMode.light;
    _selectedTheme = prefs.getString('selectedTheme') ?? 'ice';
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _themeMode == ThemeMode.dark);
    await prefs.setString('selectedTheme', _selectedTheme);
  }
}
