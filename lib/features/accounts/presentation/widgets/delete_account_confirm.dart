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
import 'package:gastegi/features/accounts/domain/entities/account.dart';
import 'package:gastegi/features/accounts/presentation/providers/account_form_notifier.dart';

/// Confirmación de borrado, en línea bajo la fila.
///
/// Es una decisión de diseño, no un apaño: la app no interrumpe con diálogos,
/// muestra la consecuencia donde estaba mirando el usuario.
class DeleteAccountConfirm extends ConsumerWidget {
  const DeleteAccountConfirm({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.read(accountFormProvider.notifier);
    final l10n = context.l10n;
    final n = ref.watch(
      accountFormProvider.select((s) => s.pendingDeleteExpenses),
    );
    return AppCard(
      gap: 10,
      elevated: true,
      children: [
        Kicker(l10n.deleteAccountTitle(account.name)),
        Text(
          n == 0
              ? l10n.deleteAccountConfirm
              : l10n.deleteAccountWithExpenses(n),
          style: TextStyle(
            fontSize: AppFontSize.label,
            color: AppColors.neutral500,
          ),
        ),
        if (n > 0)
          PrimaryButton(label: l10n.commonArchive, onTap: form.archivePending),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 8.r,
          children: [
            SecondaryButton(label: l10n.commonCancel, onTap: form.cancelDelete),
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
