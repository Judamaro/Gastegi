import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_icons.dart';
import 'package:gastegi/app/theme/entity_visuals.dart';
import 'package:gastegi/core/utils/formatters.dart';
import 'package:gastegi/core/utils/l10n_context.dart';
import 'package:gastegi/core/widgets/app_card.dart';
import 'package:gastegi/core/widgets/color_dot.dart';
import 'package:gastegi/core/widgets/progress_bar.dart';

/// Presupuestos: progreso por categoría con alertas de umbral y exceso.
class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appDataProvider);
    final l10n = context.l10n;
    final dates = context.dates;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Text(
            l10n.budgetsTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          Text(
            l10n.budgetsSummary(
              dates.monthName(state.monthAnchor),
              formatAmount(state.total),
              formatAmount(state.totalBudget),
            ),
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
                                  b.over
                                      ? l10n.budgetsAlertOver
                                      : l10n.budgetsAlertNear,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          l10n.budgetsSpentOfBudget(
                            formatAmount(b.spent),
                            formatAmount(b.category.budget),
                          ),
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
                          ? l10n.budgetsOverBy(
                              formatAmount(b.spent - b.category.budget),
                            )
                          : l10n.budgetsRemaining(
                              formatAmount(b.category.budget - b.spent),
                              (b.ratio * 100).round(),
                            ),
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
