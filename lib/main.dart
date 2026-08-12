import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/shell.dart';
import 'state/app_state.dart';
import 'theme/nocturne.dart';

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Publica el árbol de semántica desde el arranque (accesibilidad en web).
  binding.ensureSemantics();
  runApp(const GastegiApp());
}

class GastegiApp extends StatefulWidget {
  const GastegiApp({super.key});

  @override
  State<GastegiApp> createState() => _GastegiAppState();
}

class _GastegiAppState extends State<GastegiApp> {
  final AppState state = AppState();

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Nocturne.bg,
      colorScheme: const ColorScheme.dark(
        primary: Nocturne.accent,
        surface: Nocturne.surface,
        onSurface: Nocturne.text,
      ),
      splashFactory: NoSplash.splashFactory,
    );
    return MaterialApp(
      title: 'Gastegi',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
          bodyColor: Nocturne.text,
          displayColor: Nocturne.text,
        ),
      ),
      home: Shell(state: state),
    );
  }
}
