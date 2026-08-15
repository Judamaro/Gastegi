import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/router/route_names.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_icons.dart';
import 'package:gastegi/app/theme/app_spacing.dart';
import 'package:gastegi/app/theme/app_typography.dart';
import 'package:gastegi/app/theme/entity_visuals.dart';
import 'package:gastegi/core/utils/formatters.dart';
import 'package:gastegi/core/utils/l10n_context.dart';
import 'package:gastegi/core/utils/screen.dart';
import 'package:gastegi/core/widgets/amount_tile.dart';
import 'package:gastegi/core/widgets/app_card.dart';
import 'package:gastegi/core/widgets/app_icon_button.dart';
import 'package:gastegi/core/widgets/charts/bar_chart.dart';
import 'package:gastegi/core/widgets/color_dot.dart';
import 'package:gastegi/core/widgets/kicker.dart';
import 'package:gastegi/core/widgets/progress_bar.dart';
import 'package:gastegi/features/categories/presentation/providers/category_detail_providers.dart';
import 'package:go_router/go_router.dart';

/// Detalle de una categoría: total, presupuesto, barras semanales y gastos.
class CategoryDetailPage extends ConsumerWidget {
  const CategoryDetailPage({super.key, required this.categoryName});

  /// Llega por la ruta.
  final String categoryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    watchScreen(context);
    final cat = ref.watch(categoryByNameProvider(categoryName));
    // La categoría puede haber desaparecido bajo los pies de la pantalla.
    if (cat == null) return const SizedBox.shrink();

    final state = ref.watch(appDataProvider);
    final catTotal = ref.watch(categoryTotalProvider(categoryName));
    final expenses = ref.watch(categoryExpensesProvider(categoryName));
    final l10n = context.l10n;
    final dates = context.dates;
    final money = context.money;
    final monthName = dates.monthName(state.monthAnchor);

    return SingleChildScrollView(
      padding: AppSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14.r,
        children: [
          Row(
            spacing: 8.r,
            children: [
              AppIconButton(
                icon: AppIcons.caretLeft,
                onTap: () => context.go(RouteNames.home),
              ),
              Expanded(
                child: Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: AppFontSize.title,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ColorDot(cat.color, size: 12),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                // Alineación por abajo y no por línea base: un `FittedBox` no
                // expone la suya, y con `baseline` el `Row` se cae.
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 8.r,
                children: [
                  // Con moneda y decimales, un importe de siete cifras no cabe
                  // al lado del texto: mejor encogerlo que desbordar.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        money.format(catTotal),
                        style: AppTextStyles.hero(AppFontSize.displaySm),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      l10n.categoryShareOfTotal(
                        monthName.toLowerCase(),
                        percentOf(catTotal, state.total),
                      ),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppFontSize.bodySm,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.r),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 4.r,
                children: [
                  ProgressBar(
                    // Un presupuesto a 0 daría una fracción NaN y reventaría el
                    // layout del FractionallySizedBox.
                    fraction: cat.budget > 0 ? catTotal / cat.budget : 0,
                    color: cat.color,
                  ),
                  Text(
                    l10n.categoryBudgetLine(
                      money.format(catTotal),
                      money.format(cat.budget),
                    ),
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          AppCard(
            gap: 8,
            children: [
              Kicker(l10n.categoryByWeek),
              BarChart(
                bars: [
                  for (final (i, value)
                      in ref.watch(categoryWeeksProvider(categoryName)).indexed)
                    (l10n.categoryWeekLabel(i + 1), value, cat.color),
                ],
                height: 96,
                maxBarHeight: 64,
                barWidthFraction: 0.55,
                minBarHeight: 3,
              ),
            ],
          ),
          if (expenses.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.r),
              child: Text(
                l10n.categoryNoExpenses(
                  cat.name.toLowerCase(),
                  monthName.toLowerCase(),
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppFontSize.bodySm,
                  color: AppColors.neutral600,
                ),
              ),
            )
          else
            Column(
              children: [
                for (final e in expenses)
                  AmountTile(
                    title: e.desc,
                    subtitle: l10n.categoryExpenseSubtitle(
                      dates.dayLabelShort(e.date, state.today),
                      e.accountName ?? l10n.commonNoAccount,
                    ),
                    amount: money.formatSigned(-e.val),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
