import 'package:flutter/material.dart';
import 'package:gastegi/app/theme/app_colors.dart';

/// Barra de progreso fina (6 px): pista neutral-900 + relleno coloreado.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.fraction,
    required this.color,
    this.height = 6,
  });

  final double fraction;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: AppColors.neutral900),
            FractionallySizedBox(
              widthFactor: fraction.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
