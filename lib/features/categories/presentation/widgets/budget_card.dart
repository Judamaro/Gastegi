import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/state/budget_row.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_elevation.dart';
import 'package:gastegi/app/theme/app_icons.dart';
import 'package:gastegi/app/theme/app_spacing.dart';
import 'package:gastegi/app/theme/app_typography.dart';
import 'package:gastegi/app/theme/entity_visuals.dart';
import 'package:gastegi/core/utils/l10n_context.dart';
import 'package:gastegi/core/widgets/app_icon_button.dart';
import 'package:gastegi/core/widgets/color_dot.dart';
import 'package:gastegi/core/widgets/meter_bar.dart';
import 'package:gastegi/features/categories/presentation/providers/category_form_notifier.dart';

/// Tarjeta de una categoría en Presupuestos: progreso del mes, aviso de umbral
/// y los dos accesos a su edición.
///
/// No usa `AppCard` porque la tarjeta entera abre el formulario, y eso pide un
/// `InkWell` por fuera del relleno para que el destello cubra todo el recuadro.
class BudgetCard extends ConsumerWidget {
  const BudgetCard({super.key, required this.row, this.selected = false});

  final BudgetRow row;

  /// La está editando el formulario de justo debajo. El recuadro y el borde de
  /// acento los pone entonces el grupo que envuelve a los dos, así que la
  /// tarjeta se pinta sin los suyos para no dibujar una caja dentro de otra.
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.read(categoryFormProvider.notifier);
    final l10n = context.l10n;
    final money = context.money;
    final category = row.category;

    return InkWell(
      // Vuelve a abrir la misma categoría, que es inofensivo, y cierra la que
      // hubiera abierta de otra.
      onTap: () => form.open(category),
      // Sin radio cuando va dentro del grupo: el destello lo recorta el
      // recuadro de fuera, y redondearlo aquí lo dejaría a medias.
      borderRadius: selected ? null : BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: AppSpacing.card,
        decoration: selected
            ? null
            : BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppElevation.smBorder),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8.r,
          children: [
            Row(
              spacing: 8.r,
              children: [
                ColorDot(category.color),
                Expanded(
                  child: Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: AppFontSize.body),
                  ),
                ),
                if (row.alert)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.r,
                      vertical: 3.r,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.accent),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4.r,
                      children: [
                        Icon(
                          AppIcons.warning,
                          size: 11.r,
                          color: AppColors.accent,
                        ),
                        Text(
                          row.over
                              ? l10n.budgetsAlertOver
                              : l10n.budgetsAlertNear,
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                // «Gastado / presupuesto» casi dobla su ancho con la moneda
                // puesta, y comparte fila con el chip de aviso.
                Flexible(
                  child: Text(
                    l10n.budgetsSpentOfBudget(
                      money.format(row.spent),
                      money.format(category.budget),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppFontSize.label,
                      color: AppColors.neutral500,
                    ),
                  ),
                ),
              ],
            ),
            MeterBar(fraction: row.ratio, color: row.barColor),
            // El botón de borrar va en la línea de abajo y no arriba: esa fila
            // ya reparte el nombre, el aviso y el importe, y en apaisado con el
            // texto del sistema crecido no le cabe nada más.
            Row(
              spacing: 8.r,
              children: [
                Expanded(
                  child: Text(
                    row.over
                        ? l10n.budgetsOverBy(
                            money.format(row.spent - category.budget),
                          )
                        : l10n.budgetsRemaining(
                            money.format(category.budget - row.spent),
                            (row.ratio * 100).round(),
                          ),
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      color: AppColors.neutral600,
                    ),
                  ),
                ),
                AppIconButton(
                  icon: AppIcons.x,
                  onTap: () => form.askDelete(category.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
