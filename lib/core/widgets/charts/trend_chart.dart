import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/theme/app_colors.dart';

/// Tendencia diaria: polilínea en acento sobre un área rellena accent-900.
class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.values, this.height = 90});

  final List<double> values;

  /// Alto **en unidades de diseño**: lo escala este widget.
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height.r,
      width: double.infinity,
      child: CustomPaint(painter: _TrendPainter(values)),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    // Con un solo punto, el reparto horizontal dividiría entre cero.
    if (values.length < 2) return;
    final max = values.fold(1.0, math.max);
    // Todo sale del alto recibido, que ya viene escalado: el painter no
    // necesita saber en qué pantalla está. Las proporciones son las del
    // diseño de 90 dp de alto —línea base a 84, amplitud 72, trazo 2— y el
    // margen lateral es el propio grosor del trazo, para que no se corte
    // contra el borde de la caja.
    final yScale = size.height / 90;
    final stroke = 2 * yScale;
    final baseline = 84 * yScale;
    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          stroke + i / (values.length - 1) * (size.width - stroke * 2),
          (84 - values[i] / max * 72) * yScale,
        ),
    ];

    final area = Path()..moveTo(stroke, baseline);
    for (final p in points) {
      area.lineTo(p.dx, p.dy);
    }
    area
      ..lineTo(size.width - stroke, baseline)
      ..close();
    canvas.drawPath(
      area,
      Paint()..color = AppColors.accent900.withValues(alpha: 0.6),
    );

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.accent,
    );
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.values != values;
}
