import 'package:flutter/material.dart';

class AppTheme {
  // --- MODO CLARO CÁLIDO ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF7F9F6), // Fondo marfil/crema muy suave
    primaryColor: const Color(0xFFA3E4D7), // Verde claro amigable
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFA3E4D7),
      onPrimary: Color(0xFF1F2D3D),
      secondary: Color(0xFFFADBD8), // Rosa pastel
      onSecondary: Color(0xFF2C3E50),
      tertiary: Color(0xFFFCF3CF), // Amarillo cálido
      onTertiary: Color(0xFF2C3E50),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF2C3E50),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Color(0xFF2C3E50),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Color(0xFF2C3E50)),
    ),
  );

  // --- MODO OSCURO ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212), // Gris pizarra profundo
    primaryColor: const Color(0xFF48C9B0), // Verde menta oscuro adaptado
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF48C9B0),
      onPrimary: Color(0xFF102A25),
      secondary: Color(0xFFD98880), // Rosa oscuro elegante
      onSecondary: Color(0xFF121212),
      tertiary: Color(0xFFF1C40F), // Amarillo neón suave
      onTertiary: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
      onSurface: Color(0xFFECF0F1),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Color(0xFFECF0F1),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Color(0xFFECF0F1)),
    ),
  );
}