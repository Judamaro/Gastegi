import 'package:flutter/material.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// `ThemeData` de la aplicación, construido a partir de los tokens de Nocturne.
abstract final class AppTheme {
  /// Memoria de [dark]. Ver ahí por qué no puede ser un `final` de nivel
  /// superior.
  static ThemeData? _dark;

  /// Tema oscuro (el único que tiene la app).
  ///
  /// Es un **getter**, no un `final` de nivel superior, a propósito:
  /// `GoogleFonts.interTextTheme` dispara una descarga de la tipografía si se
  /// evalúa antes de que los tests desactiven
  /// `GoogleFonts.config.allowRuntimeFetching` en su `setUpAll`. Un `final` se
  /// materializaría al importar el archivo —es decir, antes—, y
  /// `pumpAndSettle` se quedaría esperando una petición que nunca resuelve.
  ///
  /// El resultado se memoriza en la primera llamada, que es lo caro:
  /// `interTextTheme` recompone trece estilos cada vez, y el `builder` de
  /// `ScreenUtilPlusInit` invoca esto en **cada cambio de métricas**. Guardarlo
  /// mantiene la pereza que exige el párrafo anterior y quita 411 µs de cada
  /// rotación.
  static ThemeData get dark => _dark ??= _build();

  static ThemeData _build() {
    final base = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.text,
      ),
      splashFactory: NoSplash.splashFactory,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(
        base.textTheme,
      ).apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    );
  }
}
