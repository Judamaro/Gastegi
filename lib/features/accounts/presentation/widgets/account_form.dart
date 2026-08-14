import 'package:flutter/material.dart';
import 'package:gastegi/app/state/app_state.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_icons.dart';
import 'package:gastegi/core/widgets/app_card.dart';
import 'package:gastegi/core/widgets/app_chip.dart';
import 'package:gastegi/core/widgets/app_input.dart';
import 'package:gastegi/core/widgets/field_label.dart';
import 'package:gastegi/core/widgets/kicker.dart';
import 'package:gastegi/core/widgets/primary_button.dart';
import 'package:gastegi/core/widgets/secondary_button.dart';
import 'package:gastegi/features/accounts/presentation/account_failure_message.dart';

class AccountForm extends StatelessWidget {
  const AccountForm({super.key, required this.state});

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
            accountFailureMessage(state.afError!),
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
