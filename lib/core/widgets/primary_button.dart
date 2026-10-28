import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_spacing.dart';
import 'package:gastegi/app/theme/app_typography.dart';

/// Botón .btn-primary del diseño: texto y borde en acento, fondo transparente.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.disabled = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        // Sin `width: double.infinity`: era redundante —a pantalla completa
        // siempre cuelga de un `Column(crossAxisAlignment: stretch)`, que ya da
        // la restricción ajustada— y además impedía acotarlo por abajo. Los
        // formularios lo envuelven en un `ConstrainedBox(minWidth:)` para que
        // crezca con su etiqueta, y con el ancho infinito eso reventaba.
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.r),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.accent),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            spacing: 6.r,
            children: [
              if (icon != null) Icon(icon, size: 16.r, color: AppColors.accent),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppFontSize.body,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
