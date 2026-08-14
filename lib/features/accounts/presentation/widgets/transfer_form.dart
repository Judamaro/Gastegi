import 'package:flutter/material.dart';
import 'package:gastegi/app/state/app_state.dart';
import 'package:gastegi/core/widgets/app_card.dart';
import 'package:gastegi/core/widgets/app_chip.dart';
import 'package:gastegi/core/widgets/app_input.dart';
import 'package:gastegi/core/widgets/field_label.dart';
import 'package:gastegi/core/widgets/kicker.dart';
import 'package:gastegi/core/widgets/primary_button.dart';
import 'package:gastegi/core/widgets/secondary_button.dart';

class TransferForm extends StatelessWidget {
  const TransferForm({super.key, required this.state});

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
