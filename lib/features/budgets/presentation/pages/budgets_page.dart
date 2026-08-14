import 'package:flutter/material.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_icons.dart';
import 'package:gastegi/app/theme/entity_visuals.dart';
import 'package:gastegi/core/widgets/app_card.dart';
import 'package:gastegi/core/widgets/color_dot.dart';
import 'package:gastegi/core/widgets/progress_bar.dart';
import 'package:gastegi/state/app_state.dart';

/// Presupuestos: progreso por categoría con alertas de umbral y exceso.
class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key, required this.state});

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
            '${state.currentMonthName} · ${state.fmt(state.total)}'
            ' de ${state.fmt(state.totalBudget)} presupuestados',
            style: const TextStyle(fontSize: 13, color: AppColors.neutral500),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              for (final b in state.budgetRows)
                AppCard(
                  gap: 8,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        ColorDot(b.category.color),
                        Expanded(
                          child: Text(
                            b.category.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        if (b.alert)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.accent),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 4,
                              children: [
                                const Icon(
                                  AppIcons.warning,
                                  size: 11,
                                  color: AppColors.accent,
                                ),
                                Text(
                                  b.alertLabel,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          '${state.fmt(b.spent)} / ${state.fmt(b.category.budget)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                    ProgressBar(fraction: b.ratio, color: b.barColor),
                    Text(
                      b.over
                          ? 'Excedido por ${state.fmt(b.spent - b.category.budget)}'
                          : 'Quedan ${state.fmt(b.category.budget - b.spent)} · ${(b.ratio * 100).round()}% usado',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.neutral600,
                      ),
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
