import 'package:flutter/material.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_elevation.dart';
import 'package:gastegi/app/theme/app_spacing.dart';

/// Tarjeta Nocturne: superficie + borde fino (elev-sm) o borde y sombra (elev-md).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.children,
    this.gap = AppSpacing.space2,
    this.elevated = false,
  });

  final List<Widget> children;
  final double gap;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: elevated ? AppElevation.mdBorder : AppElevation.smBorder,
        ),
        boxShadow: elevated ? const [AppElevation.mdShadow] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: gap,
        children: children,
      ),
    );
  }
}
