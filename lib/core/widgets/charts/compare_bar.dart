import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

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
          height: 8.r,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3.r),
          ),
        ),
      ),
    );
  }
}
