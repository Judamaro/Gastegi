import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/core/widgets/app_card.dart';
import 'package:gastegi/core/widgets/app_chip.dart';
import 'package:gastegi/core/widgets/app_input.dart';
import 'package:gastegi/core/widgets/field_label.dart';
import 'package:gastegi/core/widgets/kicker.dart';
import 'package:gastegi/core/widgets/primary_button.dart';
import 'package:gastegi/core/widgets/secondary_button.dart';
import 'package:gastegi/features/accounts/presentation/providers/transfer_form_notifier.dart';

/// Transferencia entre dos cuentas, en línea bajo la lista.
class TransferForm extends ConsumerWidget {
  const TransferForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(appDataProvider.select((d) => d.accounts));
    final state = ref.watch(transferFormProvider);
    final form = ref.read(transferFormProvider.notifier);

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
                for (final a in accounts)
                  AppChip(
                    label: a.name,
                    active: state.fromId == a.id,
                    onTap: () => form.pickFrom(a.id),
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
                for (final a in accounts)
                  AppChip(
                    label: a.name,
                    active: state.toId == a.id,
                    onTap: () => form.pickTo(a.id),
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
              onChanged: form.setAmount,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 8,
          children: [
            SecondaryButton(label: 'Cancelar', onTap: form.close),
            SizedBox(
              width: 110,
              child: PrimaryButton(label: 'Transferir', onTap: form.submit),
            ),
          ],
        ),
      ],
    );
  }
}
