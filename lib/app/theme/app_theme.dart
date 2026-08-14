import 'package:flutter/material.dart';
import 'package:gastegi/theme/nocturne.dart';
import 'package:google_fonts/google_fonts.dart';

/// `ThemeData` de la aplicación, construido a partir de los tokens de Nocturne.
abstract final class AppTheme {
  /// Tema oscuro (el único que tiene la app).
  ///
  /// Es un **getter**, no un `final` de nivel superior, a propósito:
  /// `GoogleFonts.interTextTheme` dispara una descarga de la tipografía si se
  /// evalúa antes de que los tests desactiven
  /// `GoogleFonts.config.allowRuntimeFetching` en su `setUpAll`. Un `final` se
  /// materializaría al importar el archivo —es decir, antes—, y
  /// `pumpAndSettle` se quedaría esperando una petición que nunca resuelve.
  static ThemeData get dark {
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

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: Nocturne.text,
        displayColor: Nocturne.text,
      ),
    );
  }
}
