import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/theme/app_colors.dart';

/// Tira horizontal que llena una fracción de su ancho.
///
/// Es la única gráfica compartida: la usan la comparación con el mes anterior,
/// el presupuesto del detalle de categoría y cada tarjeta de Presupuestos, con
/// la misma configuración y sin ningún mapeo de datos que justifique tenerla
/// junto a cada página.
///
/// Por dentro es un `BarChart` de un grupo tumbado con `rotationQuarterTurns`:
/// el andamio de `fl_chart` envuelve el dibujo en un `RotatedBox`, así que la
/// barra vertical se acuesta y crece hacia la derecha.
class MeterBar extends StatelessWidget {
  const MeterBar({
    super.key,
    required this.fraction,
    required this.color,
    this.height = 6,
    this.track = true,
  });

  final double fraction;
  final Color color;

  /// Grosor **en unidades de diseño**: lo escala este widget.
  final double height;

  /// Pista de fondo. La comparación de Inicio va sin ella: allí las dos tiras
  /// se leen una contra otra y un fondo las igualaría.
  final bool track;

  @override
  Widget build(BuildContext context) {
    final thickness = height.r;
    final radius = BorderRadius.all(Radius.circular(3.r));

    return SizedBox(
      height: thickness,
      child: BarChart(
        BarChartData(
          rotationQuarterTurns: 1,
          alignment: BarChartAlignment.center,
          maxY: 1,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          // Sin apagarlo, la tira se come los toques de la lista que la
          // contiene: en Presupuestos hay una por tarjeta.
          barTouchData: BarTouchData(enabled: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  // Un presupuesto a 0 da una fracción NaN, y `clamp` la deja
                  // en 0 en vez de descuadrar el eje.
                  toY: fraction.clamp(0, 1),
                  color: color,
                  width: thickness,
                  borderRadius: radius,
                  backDrawRodData: BackgroundBarChartRodData(
                    show: track,
                    toY: 1,
                    color: AppColors.neutral900,
                  ),
                ),
              ],
            ),
          ],
        ),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}
