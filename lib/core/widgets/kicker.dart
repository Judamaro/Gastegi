import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/theme/app_colors.dart';

/// Etiqueta kicker de tarjeta: mayúsculas pequeñas en acento.
class Kicker extends StatelessWidget {
  const Kicker(
    this.text, {
    super.key,
    this.color = AppColors.accent,
    this.size = 10,
  });

  final String text;
  final Color color;

  /// Cuerpo **en unidades de diseño**: lo escala este widget. Así el valor por
  /// defecto sigue siendo constante y quien lo pasa escribe el número del
  /// diseño, no uno ya escalado.
  final double size;

  @override
  Widget build(BuildContext context) {
    final scaled = size.sp;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: scaled,
        letterSpacing: scaled * 0.1,
        color: color,
      ),
    );
  }
}
