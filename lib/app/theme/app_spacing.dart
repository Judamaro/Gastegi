import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// Escala de espaciado de Nocturne.
///
/// Es una escala de pasos sobre una base de 2.8: `spaceN == 2.8 * N`. Los
/// nombres conservan el número de paso en lugar de traducirse a `sm`/`md`/`lg`
/// porque la relación aritmética entre ellos es la que hace que la retícula
/// cuadre, y un nombre semántico la esconde.
///
/// Son **getters** y no constantes, igual que [AppRadius] y `AppFontSize`:
/// `.r` necesita la pantalla ya medida, y un `const` o un `final` de nivel
/// superior se evaluaría al importar el archivo —antes de que
/// `ScreenUtilPlusInit` haya configurado nada—. Por lo mismo no sirven como
/// valor por defecto de un parámetro ni dentro de un `const`.
abstract final class AppSpacing {
  static double get space1 => 2.8.r;
  static double get space2 => 5.6.r;
  static double get space3 => 8.4.r;
  static double get space4 => 11.2.r;
  static double get space6 => 16.8.r;
  static double get space8 => 22.4.r;

  /// Márgenes de una pantalla completa. El inferior es mayor que el superior
  /// porque debajo va la barra de pestañas.
  static EdgeInsets get page => EdgeInsets.fromLTRB(20.r, 12.r, 20.r, 20.r);

  /// Relleno interior de una tarjeta.
  static EdgeInsets get card => EdgeInsets.all(space3);
}

/// Radios de borde.
abstract final class AppRadius {
  static double get sm => 4.r;
  static double get md => 8.r;
  static double get lg => 14.r;

  /// Píldora. No se escala: es una forma, no una medida — cualquier radio mayor
  /// que la mitad del alto da el mismo semicírculo.
  static const double pill = 999;
}
