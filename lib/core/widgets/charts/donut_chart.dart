import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gastegi/app/theme/app_colors.dart';

/// Dona de categorías: réplica del SVG del diseño (viewBox 160 renderizado a
/// 128 px → radio 46.4, trazo 16, separación de 0.02 rad por lado).
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.segments,
    required this.centerTitle,
    required this.centerSubtitle,
    this.size = 128,
  });

  /// Pares (fracción del total, color); solo categorías con gasto.
  final List<(double, Color)> segments;
  final String centerTitle;
  final String centerSubtitle;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _DonutPainter(segments),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Encajado al hueco de la dona: el `Stack` recorta por defecto,
              // así que un importe largo se perdería sin avisar de nada.
              SizedBox(
                width: size * 0.58,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    centerTitle,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Text(
                centerSubtitle,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.neutral500,
                ),
              ),
            ],
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
    final scale = size.width / 160;
    final center = size.center(Offset.zero);
    final radius = 58 * scale;
    final stroke = 20 * scale;
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
