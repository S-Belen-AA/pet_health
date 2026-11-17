import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // Por defecto iniciamos con el Modo Claro Cálido
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Método para alternar el tema
  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Notifica a toda la app que debe redibujarse con el nuevo tema
  }
}