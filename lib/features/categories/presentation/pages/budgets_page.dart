import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_icons.dart';
import 'package:gastegi/app/theme/app_spacing.dart';
import 'package:gastegi/app/theme/app_typography.dart';
import 'package:gastegi/core/utils/l10n_context.dart';
import 'package:gastegi/core/utils/screen.dart';
import 'package:gastegi/core/widgets/app_card.dart';
import 'package:gastegi/core/widgets/app_icon_button.dart';
import 'package:gastegi/core/widgets/kicker.dart';
import 'package:gastegi/core/widgets/primary_button.dart';
import 'package:gastegi/features/categories/presentation/providers/category_form_notifier.dart';
import 'package:gastegi/features/categories/presentation/widgets/budget_card.dart';
import 'package:gastegi/features/categories/presentation/widgets/category_form.dart';
import 'package:gastegi/features/categories/presentation/widgets/delete_category_confirm.dart';

/// Presupuestos: progreso por categoría con alertas de umbral y exceso, y el
/// alta, edición y borrado de las categorías que los llevan.
///
/// Vive en `categories` y no en `budgets` porque el presupuesto es una columna
/// de la categoría: el formulario necesita su repositorio, y una funcionalidad
/// no puede alcanzar el `data/` de otra.
class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  /// Distingue el formulario de alta del de edición, que van en sitios
  /// distintos del árbol.
  static const Key _newKey = ValueKey('cat-form-new');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    watchScreen(context);
    final state = ref.watch(appDataProvider);
    final form = ref.watch(categoryFormProvider);
    final openForm = ref.read(categoryFormProvider.notifier).open;
    final l10n = context.l10n;
    final dates = context.dates;
    final money = context.money;
    return SingleChildScrollView(
      padding: AppSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14.r,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.budgetsTitle,
                  style: TextStyle(
                    fontSize: AppFontSize.title,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              AppIconButton(icon: AppIcons.plusCircle, onTap: openForm),
            ],
          ),
          Text(
            l10n.budgetsSummary(
              dates.monthName(state.monthAnchor),
              money.format(state.total),
              money.format(state.totalBudget),
            ),
            style: TextStyle(
              fontSize: AppFontSize.bodySm,
              color: AppColors.neutral500,
            ),
          ),
          // El alta va aquí arriba, pegada al «+» que la abre: al final de seis
          // tarjetas quedaría fuera de pantalla y parecería que no ha pasado
          // nada. La edición, por lo mismo, va bajo su propia tarjeta.
          if (form.open && !form.isEditing) const CategoryForm(key: _newKey),
          // Sin categorías no hay nada que presupuestar. Solo pasa si se han
          // borrado todas: la siembra crea seis.
          if (state.categories.isEmpty && !form.open)
            AppCard(
              gap: 10,
              children: [
                Kicker(l10n.budgetsEmptyKicker),
                Text(
                  l10n.budgetsEmptyBody,
                  style: TextStyle(
                    fontSize: AppFontSize.bodySm,
                    color: AppColors.neutral500,
                  ),
                ),
                PrimaryButton(label: l10n.budgetsCreate, onTap: openForm),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12.r,
              children: [
                for (final b in state.budgetRows) ...[
                  BudgetCard(row: b),
                  // La key ata el formulario a la categoría que edita: sin
                  // ella, al saltar de una tarjeta a otra Flutter reutilizaría
                  // el mismo elemento y los campos conservarían lo anterior.
                  if (form.editingId == b.category.id)
                    CategoryForm(key: ValueKey('cat-form-${b.category.id}')),
                  if (form.pendingDeleteId == b.category.id)
                    DeleteCategoryConfirm(category: b.category),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
