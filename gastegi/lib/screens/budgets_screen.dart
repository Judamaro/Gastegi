import 'package:flutter/material.dart';
import '../theme/phosphor_icons.dart';

import '../state/app_state.dart';
import '../theme/nocturne.dart';
import '../widgets/common.dart';

/// Presupuestos: progreso por categoría con alertas de umbral y exceso.
class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key, required this.state});

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
            'Presupuestos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          Text(
            'Julio · ${state.fmt(state.total)} de ${state.fmt(state.totalBudget)} presupuestados',
            style: const TextStyle(fontSize: 13, color: Nocturne.neutral500),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              for (final b in state.budgetRows)
                NCard(
                  gap: 8,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        ColorDot(b.category.color),
                        Expanded(
                          child: Text(b.category.name,
                              style: const TextStyle(fontSize: 14)),
                        ),
                        if (b.alert)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              border: Border.all(color: Nocturne.accent),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 4,
                              children: [
                                const Icon(PhIcons.warning,
                                    size: 11, color: Nocturne.accent),
                                Text(
                                  b.alertLabel,
                                  style: const TextStyle(
                                      fontSize: 11, color: Nocturne.accent),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          '${state.fmt(b.spent)} / ${state.fmt(b.category.budget)}',
                          style: const TextStyle(
                              fontSize: 12, color: Nocturne.neutral500),
                        ),
                      ],
                    ),
                    ProgressBar(fraction: b.ratio, color: b.barColor),
                    Text(
                      b.over
                          ? 'Excedido por ${state.fmt(b.spent - b.category.budget)}'
                          : 'Quedan ${state.fmt(b.category.budget - b.spent)} · ${(b.ratio * 100).round()}% usado',
                      style: const TextStyle(fontSize: 11, color: Nocturne.neutral600),
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
