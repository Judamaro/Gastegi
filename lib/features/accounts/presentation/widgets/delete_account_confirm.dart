import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/theme/app_colors.dart';
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
    final n = ref.watch(
      accountFormProvider.select((s) => s.pendingDeleteExpenses),
    );
    return AppCard(
      gap: 10,
      elevated: true,
      children: [
        Kicker('Eliminar ${account.name}'),
        Text(
          n == 0
              ? '¿Seguro que quieres eliminar esta cuenta?'
              : 'Esta cuenta tiene $n ${n == 1 ? 'gasto' : 'gastos'}. '
                    'Si la eliminas, los gastos se conservan; si prefieres '
                    'ocultarla sin perderla de vista, archívala.',
          style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
        ),
        if (n > 0) PrimaryButton(label: 'Archivar', onTap: form.archivePending),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 8,
          children: [
            SecondaryButton(label: 'Cancelar', onTap: form.cancelDelete),
            SizedBox(
              width: 110,
              child: PrimaryButton(
                label: 'Eliminar',
                onTap: form.confirmDelete,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
