import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_health/providers/theme_provider.dart';
import 'package:pet_health/themes/app_theme.dart';
import 'package:pet_health/widgets/glass_card.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'PetHealth',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const TestGlassScreen(),
    );
  }
}

class TestGlassScreen extends StatelessWidget {
  const TestGlassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PetHealth - Test Glassmorphism'),
      ),
      body: Container(
        // Un fondo con color o patrón ayuda a apreciar el efecto de desenfoque del BackdropFilter
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: themeProvider.isDarkMode
                ? [const Color(0xFF1F4037), const Color(0xFF99F2C8)]
                : [const Color(0xFFA3E4D7), const Color(0xFFFADBD8)],
          ),
        ),
        child: Center(
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🐾 ¡Efecto Glassmorphism Activo!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Las tarjetas translúcidas con desenfoque le dan el toque moderno y profesional a PetHealth.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    themeProvider.toggleTheme(!themeProvider.isDarkMode);
                  },
                  icon: Icon(themeProvider.isDarkMode
                      ? Icons.wb_sunny_rounded
                      : Icons.nightlight_round),
                  label: Text(themeProvider.isDarkMode
                      ? 'Cambiar a Modo Claro'
                      : 'Cambiar a Modo Oscuro'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}