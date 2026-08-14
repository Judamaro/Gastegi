import 'package:flutter/widgets.dart';

/// Configuración global de la aplicación.
///
/// Valores que valen para toda la app y no pertenecen a ninguna funcionalidad
/// concreta. Lo que dependa del entorno (desarrollo, staging, producción) vive
/// en `environment.dart`, no aquí.
abstract final class AppConfig {
  static const String title = 'Gastegi';

  /// Idioma con el que arranca la app si el del sistema no está soportado, y
  /// el que se precarga en `intl` antes del primer `DateFormat`.
  static const Locale fallbackLocale = Locale('es');
}
