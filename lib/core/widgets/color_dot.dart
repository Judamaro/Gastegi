import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// Punto de color de una categoría.
class ColorDot extends StatelessWidget {
  const ColorDot(this.color, {super.key, this.size = 8});

  final Color color;

  /// Diámetro **en unidades de diseño**: lo escala este widget.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.r,
      height: size.r,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
