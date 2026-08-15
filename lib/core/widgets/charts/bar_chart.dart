import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gastegi/app/theme/app_colors.dart';

/// Gráfica de barras redondeadas con etiquetas debajo (meses y semanas).
class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.bars,
    required this.height,
    required this.maxBarHeight,
    this.barWidthFraction = 0.64,
    this.minBarHeight = 4,
  });

  /// Ternas (etiqueta, valor, color).
  final List<(String, double, Color)> bars;
  final double height;
  final double maxBarHeight;
  final double barWidthFraction;
  final double minBarHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarPainter(
          bars,
          maxBarHeight,
          barWidthFraction,
          minBarHeight,
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(
    this.bars,
    this.maxBarHeight,
    this.barWidthFraction,
    this.minBarHeight,
  );

  final List<(String, double, Color)> bars;
  final double maxBarHeight;
  final double barWidthFraction;
  final double minBarHeight;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    final max = bars.fold(1.0, (m, b) => math.max(m, b.$2));
    final slot = size.width / bars.length;
    final barWidth = slot * barWidthFraction;
    final labelHeight = 14.0;
    final baseline = size.height - labelHeight;

    for (var i = 0; i < bars.length; i++) {
      final (label, value, color) = bars[i];
      final h = math.max(minBarHeight, value / max * maxBarHeight);
      final cx = slot * i + slot / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - barWidth / 2, baseline - h, barWidth, h),
          const Radius.circular(4),
        ),
        Paint()..color = color,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(fontSize: 10, color: AppColors.neutral500),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, size.height - tp.height));
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.bars != bars;
}
