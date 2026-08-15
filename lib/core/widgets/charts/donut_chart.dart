import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/theme/app_colors.dart';

/// Dona de categorías, con el total en el hueco.
///
/// Las proporciones son las del SVG del diseño (viewBox 160, trazo 20,
/// separación de 0.02 rad por lado), pero el círculo **llena su caja**: el SVG
/// traía 15 % de margen incorporado, y aquí el hueco que sobra ya lo pone el
/// `Row` que la coloca al lado de la leyenda.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.segments,
    required this.centerTitle,
    required this.centerSubtitle,
    this.size = 128,
  });

  /// Grosor del anillo como fracción del diámetro (20 sobre 160 del diseño).
  static const double _strokeRatio = 0.125;

  /// Interlineado de los dos textos del centro. Explícito porque de él sale el
  /// alto del bloque, y de ese alto sale el ancho que cabe en el hueco.
  static const double _lineHeight = 1.15;

  /// Pares (fracción del total, color); solo categorías con gasto.
  final List<(double, Color)> segments;
  final String centerTitle;
  final String centerSubtitle;

  /// Diámetro **en unidades de diseño**: lo escala este widget.
  final double size;

  @override
  Widget build(BuildContext context) {
    final diameter = size.r;
    final holeRadius = diameter * (0.5 - _strokeRatio);

    // Los dos textos salen del diámetro, no de `AppFontSize`, y por eso no
    // llevan `.sp`: ya escalan con la dona. Es el único sitio de la app que no
    // respeta el ajuste de tamaño de letra del sistema, y por eso lo desactiva
    // explícitamente: el hueco es geométrico y honrarlo sacaría el texto del
    // círculo. Las proporciones son las del diseño: 19 y 9 sobre 128.
    final titleFont = diameter * 19 / 128;
    final subtitleFont = diameter * 9 / 128;

    // El ancho que cabe no es el diámetro del hueco: el bloque de dos líneas
    // ocupa una banda, y en sus esquinas —lo más alejado del centro— la cuerda
    // del círculo es más estrecha. Medir ahí es lo que evita que el importe se
    // monte sobre el anillo.
    final halfBlock = (titleFont + subtitleFont) * _lineHeight / 2;
    final textWidth =
        2 *
        math.sqrt(math.max(0, holeRadius * holeRadius - halfBlock * halfBlock));

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(diameter),
            painter: _DonutPainter(segments),
          ),
          // Encajados al hueco: el `Stack` recorta por defecto, así que un
          // texto largo se perdería sin avisar de nada.
          SizedBox(
            width: textWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    centerTitle,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: titleFont,
                      height: _lineHeight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    centerSubtitle,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: subtitleFont,
                      height: _lineHeight,
                      color: AppColors.neutral500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.segments);

  final List<(double, Color)> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * DonutChart._strokeRatio;
    final center = size.center(Offset.zero);
    // Radio de la línea media: con medio trazo a cada lado, el borde exterior
    // cae justo en el borde de la caja.
    final radius = (size.width - stroke) / 2;
    var angle = -math.pi / 2;
    for (final (frac, color) in segments) {
      final sweep = frac * 2 * math.pi;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle + 0.02,
        sweep - 0.04,
        false,
        paint,
      );
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.segments != segments;
}
