import 'package:flutter/material.dart';
import 'package:gastegi/app/theme/app_colors.dart';

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
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        spacing: 10,
        children: [
          if (icon != null)
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.neutral900,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
