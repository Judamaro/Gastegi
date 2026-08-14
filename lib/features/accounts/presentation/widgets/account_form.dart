import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:gastegi/features/accounts/presentation/providers/account_form_notifier.dart';

/// Alta y edición de una cuenta, en línea bajo la lista.
class AccountForm extends ConsumerWidget {
  const AccountForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountFormProvider);
    final form = ref.read(accountFormProvider.notifier);
    // La key ata los campos al registro editado: sin ella, `TextFormField`
    // conservaría el texto de la cuenta anterior al cambiar de una a otra.
    final formKey = state.editingId ?? 'new';

    return AppCard(
      gap: 12,
      elevated: true,
      children: [
        Kicker(state.isEditing ? 'Editar cuenta' : 'Nueva cuenta'),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            const FieldLabel('Nombre'),
            AppInput(
              key: ValueKey('acct-name-$formKey'),
              hint: 'Efectivo',
              initialValue: state.name,
              onChanged: form.setName,
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
              initialValue: state.kind,
              onChanged: form.setKind,
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
                    active: state.iconKey == key,
                    onTap: () => form.pickIcon(key),
                  ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            FieldLabel(state.isEditing ? 'Saldo actual' : 'Saldo inicial'),
            AppInput(
              key: ValueKey('acct-balance-$formKey'),
              hint: '0',
              initialValue: state.balance,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              onChanged: form.setBalance,
            ),
          ],
        ),
        if (state.failure != null)
          Text(
            accountFailureMessage(state.failure!),
            style: const TextStyle(fontSize: 12, color: AppColors.accent),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 8,
          children: [
            SecondaryButton(label: 'Cancelar', onTap: form.close),
            SizedBox(
              width: 110,
              child: PrimaryButton(label: 'Guardar', onTap: form.submit),
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
