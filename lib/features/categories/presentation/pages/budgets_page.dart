import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_icons.dart';
import 'package:gastegi/app/theme/app_spacing.dart';
import 'package:gastegi/app/theme/app_typography.dart';
import 'package:gastegi/app/theme/entity_visuals.dart';
import 'package:gastegi/core/utils/l10n_context.dart';
import 'package:gastegi/core/utils/screen.dart';
import 'package:gastegi/core/widgets/app_card.dart';
import 'package:gastegi/core/widgets/color_dot.dart';
import 'package:gastegi/core/widgets/progress_bar.dart';

/// Presupuestos: progreso por categoría con alertas de umbral y exceso.
class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    watchScreen(context);
    final state = ref.watch(appDataProvider);
    final l10n = context.l10n;
    final dates = context.dates;
    final money = context.money;
    return SingleChildScrollView(
      padding: AppSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14.r,
        children: [
          Text(
            l10n.budgetsTitle,
            style: TextStyle(
              fontSize: AppFontSize.title,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            l10n.budgetsSummary(
              dates.monthName(state.monthAnchor),
              money.format(state.total),
              money.format(state.totalBudget),
            ),
            style: TextStyle(
              fontSize: AppFontSize.bodySm,
              color: AppColors.neutral500,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12.r,
            children: [
              for (final b in state.budgetRows)
                AppCard(
                  gap: 8,
                  children: [
                    Row(
                      spacing: 8.r,
                      children: [
                        ColorDot(b.category.color),
                        Expanded(
                          child: Text(
                            b.category.name,
                            style: TextStyle(fontSize: AppFontSize.body),
                          ),
                        ),
                        if (b.alert)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.r,
                              vertical: 3.r,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.accent),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 4.r,
                              children: [
                                Icon(
                                  AppIcons.warning,
                                  size: 11.r,
                                  color: AppColors.accent,
                                ),
                                Text(
                                  b.over
                                      ? l10n.budgetsAlertOver
                                      : l10n.budgetsAlertNear,
                                  style: TextStyle(
                                    fontSize: AppFontSize.caption,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // «Gastado / presupuesto» casi dobla su ancho con la
                        // moneda puesta, y comparte fila con el chip de aviso.
                        Flexible(
                          child: Text(
                            l10n.budgetsSpentOfBudget(
                              money.format(b.spent),
                              money.format(b.category.budget),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppFontSize.label,
                              color: AppColors.neutral500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ProgressBar(fraction: b.ratio, color: b.barColor),
                    Text(
                      b.over
                          ? l10n.budgetsOverBy(
                              money.format(b.spent - b.category.budget),
                            )
                          : l10n.budgetsRemaining(
                              money.format(b.category.budget - b.spent),
                              (b.ratio * 100).round(),
                            ),
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
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
