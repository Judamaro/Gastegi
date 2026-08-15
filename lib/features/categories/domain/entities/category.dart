/// Categoría de gasto con su color, icono y presupuesto mensual.
///
/// Sin dependencias de Flutter: [colorValue] es un ARGB y [iconKey] la clave
/// que se guarda en la BD. Las extensiones de `app/theme/entity_visuals.dart`
/// las traducen a `Color` e `IconData` para las pantallas.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconKey,
    required this.budget,
  });

  /// UUID de texto, no entero autoincremental: cuando la app sincronice con la
  /// nube, dos teléfonos generarían el mismo `id = 1` para filas distintas y
  /// habría que remapear todas las claves ajenas.
  final String id;
  final String name;

  /// Color en formato ARGB de 32 bits.
  final int colorValue;

  /// Clave persistible del icono; ver `AppIcons.byKey`.
  final String iconKey;

  final double budget;
}
