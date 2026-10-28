import 'package:flutter/material.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_typography.dart';

/// Etiqueta de campo de formulario (.field > label).
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: AppFontSize.label,
        color: AppColors.text.withValues(alpha: 0.7),
      ),
    );
  }
}
