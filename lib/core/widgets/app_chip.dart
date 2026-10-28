import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_spacing.dart';
import 'package:gastegi/app/theme/app_typography.dart';

/// Chip-botón en forma de píldora, réplica de chipSt() del diseño:
/// activo = tinte del color al 18 % + borde y texto en el color; inactivo =
/// borde divisor y texto neutral-400.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.color,
    this.icon,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  /// Color propio (categorías); si es nulo se usa el acento.
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final accentText = color ?? AppColors.accent300;
    final borderColor = color ?? AppColors.accent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 5.r),
        decoration: BoxDecoration(
          color: active
              ? borderColor.withValues(alpha: 0.18)
              : Colors.transparent,
          border: Border.all(color: active ? borderColor : AppColors.divider),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13.r,
                color: active ? accentText : AppColors.neutral400,
              ),
              SizedBox(width: 5.r),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: AppFontSize.label,
                color: active ? accentText : AppColors.neutral400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
