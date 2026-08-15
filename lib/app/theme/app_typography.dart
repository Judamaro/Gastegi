import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// Tamaños de fuente por papel, en dp del lienzo de diseño y ya escalados.
///
/// No hay un `TextTheme` de Material detrás a propósito: ningún `Text` de la
/// app hereda estilo —todos lo declaran—, y los nombres de Material
/// (`displayLarge`, `bodyMedium`) no dicen nada de los papeles que tiene esta
/// pantalla. Un tema intermedio solo añadiría un sitio más donde mirar.
///
/// Getters por lo mismo que [AppSpacing]: un `final` de nivel superior se
/// evaluaría antes de que la pantalla esté medida.
///
/// Encima de esto el sistema aplica su propia escala de texto, acotada a 1.3×
/// en `GastegiApp`. El caso peor no es la tableta: es un móvil de 320 dp con la
/// escala al máximo, donde los componentes van al 0.82 y el texto al 1.07, así
/// que la proporción entre texto y caja crece un 30 % respecto al diseño.
abstract final class AppFontSize {
  /// Importe que se teclea en «Nuevo gasto».
  static double get displayXl => 44.sp;

  /// Total del mes, en Inicio.
  static double get displayLg => 38.sp;

  /// Saldo total, en Cuentas.
  static double get displayMd => 34.sp;

  /// Total de una categoría.
  static double get displaySm => 32.sp;

  /// Título de pantalla, y tecla del teclado del importe.
  static double get title => 20.sp;

  /// Saldo de una cuenta en su fila.
  static double get subtitle => 16.sp;

  /// Texto base: campos, botones, importe de una fila.
  static double get body => 14.sp;

  /// Título de una fila de importe.
  static double get listTitle => 13.5.sp;

  /// Texto secundario de párrafo: resúmenes y pantallas vacías.
  static double get bodySm => 13.sp;

  /// Etiquetas: chips, rótulos de campo, leyenda de la dona.
  static double get label => 12.sp;

  /// Pies y subtítulos.
  static double get caption => 11.sp;

  /// Ejes de gráficas y kicker.
  static double get micro => 10.sp;

  /// Etiqueta de la barra de pestañas. Con cinco pestañas no cabe más.
  static double get tab => 9.5.sp;
}

/// Estilos compuestos que no se reducen a un tamaño.
abstract final class AppTextStyles {
  /// Cifra grande.
  ///
  /// El interletrado es el −2 % del cuerpo, que es la proporción que ya
  /// cumplían a mano las cuatro cifras grandes del diseño (38→−0.76,
  /// 44→−0.88, 34→−0.68, 32→−0.64): escrito como fracción deja de haber cuatro
  /// números que cuadrar cada vez que cambia la escala.
  ///
  /// `height: 1` porque estas cifras se alinean por abajo dentro de un `Row` y
  /// el hueco del interlineado las descuadraría.
  static TextStyle hero(double size, {Color? color}) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.02 * size,
    height: 1,
    color: color,
  );
}
