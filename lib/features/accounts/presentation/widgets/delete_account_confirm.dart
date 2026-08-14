import 'package:flutter/material.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/core/widgets/app_card.dart';
import 'package:gastegi/core/widgets/kicker.dart';
import 'package:gastegi/core/widgets/primary_button.dart';
import 'package:gastegi/core/widgets/secondary_button.dart';
import 'package:gastegi/features/accounts/domain/entities/account.dart';
import 'package:gastegi/state/app_state.dart';

/// Confirmación de borrado, en línea bajo la fila: la app no usa `Navigator`,
/// así que un `showDialog` rompería el patrón.
class DeleteAccountConfirm extends StatelessWidget {
  const DeleteAccountConfirm({
    super.key,
    required this.state,
    required this.account,
  });

  final AppState state;
  final Account account;

  @override
  Widget build(BuildContext context) {
    final n = state.pendingDeleteExpenses;
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
        if (n > 0)
          PrimaryButton(label: 'Archivar', onTap: state.archivePendingAccount),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 8,
          children: [
            SecondaryButton(
              label: 'Cancelar',
              onTap: state.cancelDeleteAccount,
            ),
            SizedBox(
              width: 110,
              child: PrimaryButton(
                label: 'Eliminar',
                onTap: state.confirmDeleteAccount,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
