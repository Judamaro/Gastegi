import 'package:flutter/material.dart';

/// Punto de color de una categoría.
class ColorDot extends StatelessWidget {
  const ColorDot(this.color, {super.key, this.size = 8});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
