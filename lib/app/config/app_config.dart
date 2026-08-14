import 'package:flutter/widgets.dart';
import 'package:gastegi/app/config/environment.dart';

/// Configuración global de la aplicación.
///
/// Valores que valen para toda la app y no pertenecen a ninguna funcionalidad
/// concreta. Lo específico de una funcionalidad vive con ella: el umbral de
/// aviso de presupuesto, por ejemplo, está en
/// `features/budgets/domain/budget_rules.dart`.
abstract final class AppConfig {
  static const String title = 'Gastegi';

  /// Idioma con el que arranca la app si el del sistema no está soportado, y
  /// el que se precarga en `intl` antes del primer `DateFormat`.
  static const Locale fallbackLocale = Locale('es');

  /// Nombre del fichero de la base de datos.
  ///
  /// Cambia por entorno para que una compilación de desarrollo no escriba
  /// sobre los datos reales de quien tenga las dos instaladas.
  static String get databaseFileName => switch (Environment.current) {
    Environment.production => 'gastegi.db',
    Environment.staging => 'gastegi-staging.db',
    Environment.development => 'gastegi-dev.db',
  };

  /// URL de la API de sincronización. Todavía no la usa nadie: la app es
  /// local. Ver `core/network/README.md`.
  static const String apiUrl = String.fromEnvironment('API_URL');
}
