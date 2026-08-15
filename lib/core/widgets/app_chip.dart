import 'package:flutter/material.dart';
import 'package:gastegi/app/theme/app_colors.dart';

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
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? borderColor.withValues(alpha: 0.18)
              : Colors.transparent,
          border: Border.all(color: active ? borderColor : AppColors.divider),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: active ? accentText : AppColors.neutral400,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? accentText : AppColors.neutral400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
