import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_spacing.dart';
import 'package:gastegi/app/theme/app_typography.dart';

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

  /// Alto total y alto de la barra más alta, **en unidades de diseño**: los
  /// escala este widget.
  final double height;
  final double maxBarHeight;
  final double barWidthFraction;
  final double minBarHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height.r,
      width: double.infinity,
      child: CustomPaint(
        // El painter recibe fracciones y no dp: así no guarda ni un número
        // escalado, y `shouldRepaint` no se puede quedar corto al girar.
        painter: _BarPainter(
          bars: bars,
          maxBarFraction: maxBarHeight / height,
          minBarFraction: minBarHeight / height,
          barWidthFraction: barWidthFraction,
          labelStyle: TextStyle(
            fontSize: AppFontSize.micro,
            color: AppColors.neutral500,
          ),
          // Un painter no cuelga del árbol, así que el ajuste de tamaño de
          // letra del sistema no le llega solo: sin esto las etiquetas se
          // quedarían pequeñas mientras todo lo demás crece.
          textScaler: MediaQuery.textScalerOf(context),
          radius: Radius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.bars,
    required this.maxBarFraction,
    required this.minBarFraction,
    required this.barWidthFraction,
    required this.labelStyle,
    required this.textScaler,
    required this.radius,
  });

  final List<(String, double, Color)> bars;
  final double maxBarFraction;
  final double minBarFraction;
  final double barWidthFraction;
  final TextStyle labelStyle;
  final TextScaler textScaler;
  final Radius radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    final max = bars.fold(1.0, (m, b) => math.max(m, b.$2));
    final slot = size.width / bars.length;
    final barWidth = slot * barWidthFraction;

    // El hueco de la etiqueta se mide en vez de suponerse. Antes eran 14 dp
    // fijos, que era justo lo que ocupaba un cuerpo de 10 sin escalar: con el
    // ajuste de texto del sistema al máximo, la etiqueta se comía la barra.
    final ruler = TextPainter(
      text: TextSpan(text: bars.first.$1, style: labelStyle),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    final labelHeight = ruler.height;
    final baseline = size.height - labelHeight;
    // La barra más alta nunca puede invadir la banda de la etiqueta.
    final maxBar = math.min(size.height * maxBarFraction, baseline);
    final minBar = size.height * minBarFraction;

    for (var i = 0; i < bars.length; i++) {
      final (label, value, color) = bars[i];
      final h = math.max(minBar, value / max * maxBar);
      final cx = slot * i + slot / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - barWidth / 2, baseline - h, barWidth, h),
          radius,
        ),
        Paint()..color = color,
      );
      final tp = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, size.height - tp.height));
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.bars != bars ||
      old.maxBarFraction != maxBarFraction ||
      old.minBarFraction != minBarFraction ||
      old.barWidthFraction != barWidthFraction ||
      old.labelStyle != labelStyle ||
      old.textScaler != textScaler ||
      old.radius != radius;
}
