import 'package:flutter/material.dart';
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
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(fontSize: size, letterSpacing: size * 0.1, color: color),
    );
  }
}
