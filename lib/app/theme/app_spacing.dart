/// Escala de espaciado de Nocturne.
///
/// Es una escala de pasos sobre una base de 2.8: `spaceN == 2.8 * N`. Los
/// nombres conservan el número de paso en lugar de traducirse a `sm`/`md`/`lg`
/// porque la relación aritmética entre ellos es la que hace que la retícula
/// cuadre, y un nombre semántico la esconde.
abstract final class AppSpacing {
  static const double space1 = 2.8;
  static const double space2 = 5.6;
  static const double space3 = 8.4;
  static const double space4 = 11.2;
  static const double space6 = 16.8;
  static const double space8 = 22.4;
}

/// Radios de borde.
abstract final class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 14;
}
