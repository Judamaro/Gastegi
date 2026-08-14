import 'package:flutter/material.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_spacing.dart';

/// Botón de icono 36×36 estilo .btn-icon.btn-secondary.
class AppIconButton extends StatelessWidget {
  const AppIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, size: 16, color: AppColors.text),
      ),
    );
  }
}
