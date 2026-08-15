import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_icons.dart';
import 'package:gastegi/app/theme/app_typography.dart';
import 'package:gastegi/core/utils/l10n_context.dart';
import 'package:gastegi/core/widgets/app_card.dart';
import 'package:gastegi/core/widgets/app_chip.dart';
import 'package:gastegi/core/widgets/app_input.dart';
import 'package:gastegi/core/widgets/field_label.dart';
import 'package:gastegi/core/widgets/kicker.dart';
import 'package:gastegi/core/widgets/money_input.dart';
import 'package:gastegi/core/widgets/primary_button.dart';
import 'package:gastegi/core/widgets/secondary_button.dart';
import 'package:gastegi/features/accounts/presentation/account_failure_message.dart';
import 'package:gastegi/features/accounts/presentation/providers/account_form_notifier.dart';
import 'package:gastegi/l10n/generated/app_localizations.dart';

/// Alta y edición de una cuenta, en línea bajo la lista.
class AccountForm extends ConsumerWidget {
  const AccountForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountFormProvider);
    final form = ref.read(accountFormProvider.notifier);
    final l10n = context.l10n;
    // La key ata los campos al registro editado: sin ella, `TextFormField`
    // conservaría el texto de la cuenta anterior al cambiar de una a otra.
    final formKey = state.editingId ?? 'new';

    return AppCard(
      gap: 12,
      elevated: true,
      children: [
        Kicker(
          state.isEditing
              ? l10n.accountFormEditTitle
              : l10n.accountFormNewTitle,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5.r,
          children: [
            FieldLabel(l10n.accountFormName),
            AppInput(
              key: ValueKey('acct-name-$formKey'),
              hint: l10n.accountFormNameHint,
              initialValue: state.name,
              onChanged: form.setName,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5.r,
          children: [
            FieldLabel(l10n.accountFormKind),
            AppInput(
              key: ValueKey('acct-kind-$formKey'),
              hint: l10n.accountFormKindHint,
              initialValue: state.kind,
              onChanged: form.setKind,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5.r,
          children: [
            FieldLabel(l10n.accountFormIcon),
            Wrap(
              spacing: 6.r,
              runSpacing: 6,
              children: [
                for (final key in AppIcons.accountIconKeys)
                  AppChip(
                    label: _iconLabel(l10n, key),
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
          spacing: 5.r,
          children: [
            FieldLabel(
              state.isEditing
                  ? l10n.accountFormCurrentBalance
                  : l10n.accountFormInitialBalance,
            ),
            MoneyInput(
              key: ValueKey('acct-balance-$formKey'),
              hint: l10n.accountFormAmountHint,
              initialValue: state.balance,
              // El saldo de una tarjeta de crédito es negativo.
              allowNegative: true,
              onChanged: form.setBalance,
            ),
          ],
        ),
        if (state.failure != null)
          Text(
            accountFailureMessage(l10n, state.failure!),
            style: TextStyle(
              fontSize: AppFontSize.label,
              color: AppColors.accent,
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 8.r,
          children: [
            SecondaryButton(label: l10n.commonCancel, onTap: form.close),
            // Ancho mínimo y no fijo: el botón conserva su presencia y crece
            // con la etiqueta cuando el tamaño de letra del sistema la alarga.
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: 110.r),
              child: PrimaryButton(label: l10n.commonSave, onTap: form.submit),
            ),
          ],
        ),
      ],
    );
  }
}

/// Nombre visible de un icono de cuenta.
String _iconLabel(AppLocalizations l10n, String key) => switch (key) {
  'money' => l10n.accountIconMoney,
  'creditCard' => l10n.accountIconCreditCard,
  'bank' => l10n.accountIconBank,
  'wallet' => l10n.accountIconWallet,
  // Una clave desconocida puede llegar de un dispositivo con la app más nueva
  // cuando exista sincronización; mejor mostrarla que romper la pantalla.
  _ => key,
};
