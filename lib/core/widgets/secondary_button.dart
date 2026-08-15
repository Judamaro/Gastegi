import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_spacing.dart';
import 'package:gastegi/app/theme/app_typography.dart';

/// Botón .btn-secondary: borde divisor, texto normal.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 8.r),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppFontSize.body,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
