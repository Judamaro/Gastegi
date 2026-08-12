import 'package:flutter/material.dart';
import '../theme/phosphor_icons.dart';

import '../state/app_state.dart';
import '../theme/nocturne.dart';
import '../widgets/common.dart';

/// Cuentas: saldo total, tarjetas por cuenta y transferencias entre cuentas.
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
          const Text(
            'Cuentas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              for (final a in state.accounts)
                Container(
                  padding: const EdgeInsets.all(Nocturne.space3),
                  decoration: BoxDecoration(
                    color: Nocturne.surface,
                    borderRadius: BorderRadius.circular(Nocturne.radiusMd),
                    border: Border.all(color: Nocturne.elevSmBorder),
                  ),
                  child: Row(
                    spacing: 12,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Nocturne.neutral900,
                          borderRadius: BorderRadius.circular(Nocturne.radiusMd),
                        ),
                        child: Icon(
                          a.icon,
                          size: 19,
                          color: a.balance < 0
                              ? Nocturne.neutral500
                              : Nocturne.accent300,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.name, style: const TextStyle(fontSize: 14)),
                            Text(
                              a.kind,
                              style: const TextStyle(
                                  fontSize: 11, color: Nocturne.neutral600),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${a.balance < 0 ? '−' : ''}${state.fmt(a.balance.abs())}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: a.balance < 0 ? Nocturne.neutral500 : Nocturne.text,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          PrimaryButton(
            label: 'Transferir entre cuentas',
            icon: PhIcons.arrowsLeftRight,
            onTap: state.openTransfer,
          ),
          if (state.transferOpen)
            NCard(
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
                          NChip(
                            label: a.name,
                            active: state.trFrom == a.name,
                            onTap: () => state.pickTrFrom(a.name),
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
                          NChip(
                            label: a.name,
                            active: state.trTo == a.name,
                            onTap: () => state.pickTrTo(a.name),
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
                    NInput(
                      hint: '0',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      child: PrimaryButton(label: 'Transferir', onTap: state.doTransfer),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
