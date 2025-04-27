import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeData _currentTheme =
      ThemeData.light(); // Utiliza el tema claro predeterminado

  ThemeMode get themeMode => _themeMode;
  ThemeData get currentTheme => _currentTheme;

  ThemeProvider() {
    loadThemeMode(); // Cargar el modo de tema al inicio
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    _themeMode = mode;
    _currentTheme =
        _themeMode == ThemeMode.light ? ThemeData.light() : ThemeData.dark();
    notifyListeners();
  }

  Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getInt('theme_mode');
    if (storedMode != null) {
      _themeMode = ThemeMode.values[storedMode];
      _currentTheme =
          _themeMode == ThemeMode.light ? ThemeData.light() : ThemeData.dark();
      notifyListeners();
    }
  }

  Color get textColor {
    if (_themeMode == ThemeMode.dark) {
      return Colors.white; // Color de texto en el tema oscuro
    } else {
      return Colors.black; // Color de texto en el tema claro
    }
  }
}
