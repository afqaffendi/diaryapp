import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TextScaleProvider with ChangeNotifier {
  double _scale = 1.0;

  double get scale => _scale;

  TextScaleProvider() {
    _loadScale();
  }

  void _loadScale() async {
    final prefs = await SharedPreferences.getInstance();
    _scale = prefs.getDouble('textScale') ?? 1.0;
    notifyListeners();
  }

  void setScale(double newScale) async {
    _scale = newScale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('textScale', newScale);
  }
}
