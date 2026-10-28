import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_typography.dart';
import 'package:gastegi/core/utils/l10n_context.dart';
import 'package:gastegi/core/widgets/app_card.dart';
import 'package:gastegi/core/widgets/kicker.dart';
import 'package:gastegi/core/widgets/primary_button.dart';
import 'package:gastegi/core/widgets/secondary_button.dart';
import 'package:gastegi/features/categories/domain/entities/category.dart';
import 'package:gastegi/features/categories/presentation/providers/category_form_notifier.dart';

/// Confirmación de borrado de una categoría, en línea bajo su tarjeta.
///
/// Con gastos a cuestas no hay nada que confirmar: se explica por qué no se
/// puede y solo se ofrece cerrar.
class DeleteCategoryConfirm extends ConsumerWidget {
  const DeleteCategoryConfirm({super.key, required this.category});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.read(categoryFormProvider.notifier);
    final l10n = context.l10n;
    final n = ref.watch(
      categoryFormProvider.select((s) => s.pendingDeleteExpenses),
    );
    return AppCard(
      gap: 10,
      elevated: true,
      children: [
        Kicker(l10n.deleteCategoryTitle(category.name)),
        Text(
          n == 0
              ? l10n.deleteCategoryConfirm
              : l10n.deleteCategoryHasExpenses(n),
          style: TextStyle(
            fontSize: AppFontSize.label,
            color: AppColors.neutral500,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 8.r,
          children: [
            SecondaryButton(label: l10n.commonCancel, onTap: form.cancelDelete),
            if (n == 0)
              // Ancho mínimo y no fijo: el botón conserva su presencia y crece
              // con la etiqueta cuando el tamaño de letra del sistema la alarga.
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: 110.r),
                child: PrimaryButton(
                  label: l10n.commonDelete,
                  onTap: form.confirmDelete,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
