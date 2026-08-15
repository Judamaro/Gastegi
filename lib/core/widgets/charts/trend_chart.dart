import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gastegi/app/theme/app_colors.dart';

/// Tendencia diaria: polilínea en acento sobre un área rellena accent-900.
class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.values, this.height = 90});

  final List<double> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
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
    final yScale = size.height / 90;
    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          2 + i / (values.length - 1) * (size.width - 4),
          (84 - values[i] / max * 72) * yScale,
        ),
    ];
    final baseline = 84 * yScale;

    final area = Path()..moveTo(2, baseline);
    for (final p in points) {
      area.lineTo(p.dx, p.dy);
    }
    area
      ..lineTo(size.width - 2, baseline)
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
        ..strokeWidth = 2
        ..color = AppColors.accent,
    );
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.values != values;
}
