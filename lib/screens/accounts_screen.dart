import 'package:flutter/material.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_elevation.dart';
import 'package:gastegi/app/theme/app_icons.dart';
import 'package:gastegi/app/theme/app_spacing.dart';
import 'package:gastegi/app/theme/entity_visuals.dart';
import 'package:gastegi/core/widgets/app_card.dart';
import 'package:gastegi/core/widgets/app_chip.dart';
import 'package:gastegi/core/widgets/app_icon_button.dart';
import 'package:gastegi/core/widgets/app_input.dart';
import 'package:gastegi/core/widgets/field_label.dart';
import 'package:gastegi/core/widgets/kicker.dart';
import 'package:gastegi/core/widgets/primary_button.dart';
import 'package:gastegi/core/widgets/secondary_button.dart';
import 'package:gastegi/features/accounts/domain/entities/account.dart';
import 'package:gastegi/state/app_state.dart';

/// Cuentas: saldo total, alta y edición de cuentas, y transferencias.
class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key, required this.state});

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
                  _AccountCard(state: state, account: a),
                  if (state.pendingDeleteId == a.id)
                    _DeleteConfirm(state: state, account: a),
                ],
              ],
            ),
          if (state.accountFormOpen) _AccountForm(state: state),
          // Con menos de dos cuentas no hay nada entre lo que transferir.
          if (state.canTransfer)
            PrimaryButton(
              label: 'Transferir entre cuentas',
              icon: AppIcons.arrowsLeftRight,
              onTap: state.openTransfer,
            ),
          if (state.transferOpen && state.canTransfer)
            _TransferForm(state: state),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.state, required this.account});

  final AppState state;
  final Account account;

  @override
  Widget build(BuildContext context) {
    final negative = account.balance < 0;
    return InkWell(
      onTap: () => state.openAccountForm(account),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppElevation.smBorder),
        ),
        child: Row(
          spacing: 12,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.neutral900,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                account.icon,
                size: 19,
                color: negative ? AppColors.neutral500 : AppColors.accent300,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.name, style: const TextStyle(fontSize: 14)),
                  if (account.kind.isNotEmpty)
                    Text(
                      account.kind,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.neutral600,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${negative ? '−' : ''}${state.fmt(account.balance.abs())}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: negative ? AppColors.neutral500 : AppColors.text,
              ),
            ),
            AppIconButton(
              icon: AppIcons.x,
              onTap: () => state.askDeleteAccount(account.id),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirmación de borrado, en línea bajo la fila: la app no usa `Navigator`,
/// así que un `showDialog` rompería el patrón.
class _DeleteConfirm extends StatelessWidget {
  const _DeleteConfirm({required this.state, required this.account});

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

class _AccountForm extends StatelessWidget {
  const _AccountForm({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final editing = state.editingAccountId != null;
    // La key ata los campos al registro editado: sin ella, `TextFormField`
    // conservaría el texto de la cuenta anterior al cambiar de una a otra.
    final formKey = state.editingAccountId ?? 'new';

    return AppCard(
      gap: 12,
      elevated: true,
      children: [
        Kicker(editing ? 'Editar cuenta' : 'Nueva cuenta'),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            const FieldLabel('Nombre'),
            AppInput(
              key: ValueKey('acct-name-$formKey'),
              hint: 'Efectivo',
              initialValue: state.afName,
              onChanged: state.setAfName,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            const FieldLabel('Tipo'),
            AppInput(
              key: ValueKey('acct-kind-$formKey'),
              hint: 'Tarjeta de débito',
              initialValue: state.afKind,
              onChanged: state.setAfKind,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            const FieldLabel('Icono'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final key in AppIcons.accountIconKeys)
                  AppChip(
                    label: _iconLabels[key] ?? key,
                    icon: AppIcons.resolve(key),
                    active: state.afIconKey == key,
                    onTap: () => state.pickAfIcon(key),
                  ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            FieldLabel(editing ? 'Saldo actual' : 'Saldo inicial'),
            AppInput(
              key: ValueKey('acct-balance-$formKey'),
              hint: '0',
              initialValue: state.afBalance,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              onChanged: state.setAfBalance,
            ),
          ],
        ),
        if (state.afError != null)
          Text(
            state.afError!,
            style: const TextStyle(fontSize: 12, color: AppColors.accent),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 8,
          children: [
            SecondaryButton(label: 'Cancelar', onTap: state.closeAccountForm),
            SizedBox(
              width: 110,
              child: PrimaryButton(
                label: 'Guardar',
                onTap: state.submitAccountForm,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Nombres visibles de los iconos elegibles para una cuenta.
const Map<String, String> _iconLabels = {
  'money': 'Efectivo',
  'creditCard': 'Tarjeta',
  'bank': 'Banco',
  'wallet': 'Cartera',
};

class _TransferForm extends StatelessWidget {
  const _TransferForm({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      gap: 12,
      elevated: true,
      children: [
        const Kicker('Nueva transferencia'),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            const FieldLabel('Desde'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final a in state.accounts)
                  AppChip(
                    label: a.name,
                    active: state.trFromId == a.id,
                    onTap: () => state.pickTrFrom(a.id),
                  ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            const FieldLabel('Hacia'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final a in state.accounts)
                  AppChip(
                    label: a.name,
                    active: state.trToId == a.id,
                    onTap: () => state.pickTrTo(a.id),
                  ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            const FieldLabel('Monto'),
            AppInput(
              hint: '0',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: state.setTrAmt,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 8,
          children: [
            SecondaryButton(label: 'Cancelar', onTap: state.closeTransfer),
            SizedBox(
              width: 110,
              child: PrimaryButton(
                label: 'Transferir',
                onTap: state.doTransfer,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
