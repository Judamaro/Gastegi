import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/nocturne.dart';

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
          CustomPaint(size: Size.square(size), painter: _DonutPainter(segments)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerTitle,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500),
              ),
              Text(
                centerSubtitle,
                style: const TextStyle(fontSize: 9, color: Nocturne.neutral500),
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
      Paint()..color = Nocturne.accent900.withValues(alpha: 0.6),
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
        ..color = Nocturne.accent,
    );
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.values != values;
}

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
        painter: _BarPainter(bars, maxBarHeight, barWidthFraction, minBarHeight),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.bars, this.maxBarHeight, this.barWidthFraction, this.minBarHeight);

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
          style: const TextStyle(fontSize: 10, color: Nocturne.neutral500),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, size.height - tp.height));
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.bars != bars;
}

/// Barra de comparación del inicio: rectángulo redondeado de ancho fraccional.
class CompareBar extends StatelessWidget {
  const CompareBar({super.key, required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: fraction.clamp(0.0, 1.0),
        child: Container(
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
