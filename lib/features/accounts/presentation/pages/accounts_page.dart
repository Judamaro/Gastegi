import 'package:flutter/material.dart';
import 'package:gastegi/app/state/app_state.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_icons.dart';
import 'package:gastegi/core/widgets/app_card.dart';
import 'package:gastegi/core/widgets/app_icon_button.dart';
import 'package:gastegi/core/widgets/kicker.dart';
import 'package:gastegi/core/widgets/primary_button.dart';
import 'package:gastegi/features/accounts/presentation/widgets/account_card.dart';
import 'package:gastegi/features/accounts/presentation/widgets/account_form.dart';
import 'package:gastegi/features/accounts/presentation/widgets/delete_account_confirm.dart';
import 'package:gastegi/features/accounts/presentation/widgets/transfer_form.dart';

/// Cuentas: saldo total, alta y edición de cuentas, y transferencias.
class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Cuentas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
              ),
              AppIconButton(
                icon: AppIcons.plusCircle,
                onTap: state.openAccountForm,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Kicker('Saldo total', size: 11),
              const SizedBox(height: 4),
              Text(
                state.fmt(state.patrimonio),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.68,
                  height: 1,
                ),
              ),
            ],
          ),
          if (state.accounts.isEmpty && !state.accountFormOpen)
            AppCard(
              gap: 10,
              children: [
                const Kicker('Sin cuentas'),
                const Text(
                  'Crea una cuenta para poder registrar gastos y ver tu saldo.',
                  style: TextStyle(fontSize: 13, color: AppColors.neutral500),
                ),
                PrimaryButton(
                  label: 'Crear cuenta',
                  onTap: state.openAccountForm,
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                for (final a in state.accounts) ...[
                  AccountCard(state: state, account: a),
                  if (state.pendingDeleteId == a.id)
                    DeleteAccountConfirm(state: state, account: a),
                ],
              ],
            ),
          if (state.accountFormOpen) AccountForm(state: state),
          // Con menos de dos cuentas no hay nada entre lo que transferir.
          if (state.canTransfer)
            PrimaryButton(
              label: 'Transferir entre cuentas',
              icon: AppIcons.arrowsLeftRight,
              onTap: state.openTransfer,
            ),
          if (state.transferOpen && state.canTransfer)
            TransferForm(state: state),
        ],
      ),
    );
  }
}
