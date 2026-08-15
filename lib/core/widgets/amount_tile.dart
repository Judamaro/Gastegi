import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_typography.dart';

/// Fila de un importe con icono, título y subtítulo.
///
/// Vive en `core/` y no en `features/expenses/` porque la usan dos
/// funcionalidades distintas —el historial de gastos y el detalle de
/// categoría—, y solo recibe primitivos: no sabe qué es un gasto.
class AmountTile extends StatelessWidget {
  const AmountTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.icon,
    this.iconColor,
  });

  final String title;
  final String subtitle;

  /// Ya formateado **y con su signo**: quien llama sabe si es un gasto o un
  /// ingreso, y el signo forma parte del importe en cada idioma.
  final String amount;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7.r),
      child: Row(
        spacing: 10.r,
        children: [
          if (icon != null)
            Container(
              width: 34.r,
              height: 34.r,
              decoration: const BoxDecoration(
                color: AppColors.neutral900,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17.r, color: iconColor),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: AppFontSize.listTitle),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: AppFontSize.body,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
