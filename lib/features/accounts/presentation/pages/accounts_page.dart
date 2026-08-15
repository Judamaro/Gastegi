import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_icons.dart';
import 'package:gastegi/core/utils/l10n_context.dart';
import 'package:gastegi/core/widgets/app_card.dart';
import 'package:gastegi/core/widgets/app_icon_button.dart';
import 'package:gastegi/core/widgets/kicker.dart';
import 'package:gastegi/core/widgets/primary_button.dart';
import 'package:gastegi/features/accounts/presentation/providers/account_form_notifier.dart';
import 'package:gastegi/features/accounts/presentation/providers/transfer_form_notifier.dart';
import 'package:gastegi/features/accounts/presentation/widgets/account_card.dart';
import 'package:gastegi/features/accounts/presentation/widgets/account_form.dart';
import 'package:gastegi/features/accounts/presentation/widgets/delete_account_confirm.dart';
import 'package:gastegi/features/accounts/presentation/widgets/transfer_form.dart';

/// Cuentas: saldo total, alta y edición de cuentas, y transferencias.
class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final form = ref.watch(accountFormProvider);
    final transferOpen = ref.watch(transferFormProvider.select((s) => s.open));
    final openForm = ref.read(accountFormProvider.notifier).open;
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.accountsTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              AppIconButton(icon: AppIcons.plusCircle, onTap: openForm),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Kicker(l10n.accountsTotalBalance, size: 11),
              const SizedBox(height: 4),
              // El patrimonio es la cifra más larga de la app: puede ser
              // negativo y de siete dígitos, y ahora lleva moneda y decimales.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  context.money.formatSigned(data.patrimonio),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.68,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          if (data.accounts.isEmpty && !form.open)
            AppCard(
              gap: 10,
              children: [
                Kicker(l10n.accountsEmptyKicker),
                Text(
                  l10n.accountsEmptyBody,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral500,
                  ),
                ),
                PrimaryButton(label: l10n.accountsCreate, onTap: openForm),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                for (final a in data.accounts) ...[
                  AccountCard(account: a),
                  if (form.pendingDeleteId == a.id)
                    DeleteAccountConfirm(account: a),
                ],
              ],
            ),
          if (form.open) const AccountForm(),
          // Con menos de dos cuentas no hay nada entre lo que transferir.
          if (data.canTransfer)
            PrimaryButton(
              label: l10n.accountsTransfer,
              icon: AppIcons.arrowsLeftRight,
              onTap: ref.read(transferFormProvider.notifier).open,
            ),
          if (transferOpen && data.canTransfer) const TransferForm(),
        ],
      ),
    );
  }
}
