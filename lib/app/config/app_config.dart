import 'package:flutter/widgets.dart';

/// Configuración global de la aplicación.
///
/// Valores que valen para toda la app y no pertenecen a ninguna funcionalidad
/// concreta. Lo que dependa del entorno (desarrollo, staging, producción) vive
/// en `environment.dart`, no aquí.
abstract final class AppConfig {
  static const String title = 'Gastegi';

  /// La app está pensada en español; el inglés existe para que el selector de
  /// fecha de Material no se quede sin traducciones si el sistema lo pide.
  static const Locale defaultLocale = Locale('es');

  static const List<Locale> supportedLocales = [Locale('es'), Locale('en')];
}
