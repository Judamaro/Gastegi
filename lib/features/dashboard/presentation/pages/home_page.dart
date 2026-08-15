import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/router/route_names.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/entity_visuals.dart';
import 'package:gastegi/core/utils/formatters.dart';
import 'package:gastegi/core/utils/l10n_context.dart';
import 'package:gastegi/core/widgets/app_card.dart';
import 'package:gastegi/core/widgets/charts/bar_chart.dart';
import 'package:gastegi/core/widgets/charts/compare_bar.dart';
import 'package:gastegi/core/widgets/charts/donut_chart.dart';
import 'package:gastegi/core/widgets/charts/trend_chart.dart';
import 'package:gastegi/core/widgets/color_dot.dart';
import 'package:gastegi/core/widgets/kicker.dart';
import 'package:gastegi/core/widgets/primary_button.dart';
import 'package:go_router/go_router.dart';

/// Inicio: total del mes, comparación con el mes anterior, dona por categoría,
/// tendencia diaria y últimos 6 meses.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appDataProvider);
    final total = state.total;
    final catTotals = state.catTotals;
    final bars = state.monthTotals;
    final hasHistory = bars.any((b) => b.$2 > 0);
    final l10n = context.l10n;
    final dates = context.dates;
    final money = context.money;
    final monthAbbr = dates.monthAbbr(state.monthAnchor).toLowerCase();
    final monthName = dates.monthName(state.monthAnchor);
    final prevMonthName = dates.monthName(state.prevMonthAnchor);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Kicker(dates.monthTitle(state.monthAnchor), size: 11),
              const SizedBox(height: 4),
              Row(
                // Alineación por abajo y no por línea base: un `FittedBox` no
                // expone la suya, y con `baseline` el `Row` se cae.
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 8,
                children: [
                  // Con moneda y decimales, un importe de siete cifras no cabe
                  // al lado del texto: mejor encogerlo que desbordar.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        money.format(total),
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.76,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      l10n.homeSpentThisMonth,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ),
                ],
              ),
              // Sin mes anterior con datos no hay nada que comparar, y las
              // fracciones saldrían 0/0.
              if (state.canCompare) ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 5,
                  children: [
                    CompareBar(
                      fraction: state.cmpNowFrac,
                      color: AppColors.accent,
                    ),
                    CompareBar(
                      fraction: state.cmpPrevFrac,
                      color: AppColors.neutral800,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            l10n.homeMonthComparison(
                              monthName,
                              money.format(total),
                              prevMonthName,
                              money.format(state.prevTotal),
                            ),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.neutral500,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            l10n.homeDeltaVsPrevMonth(
                              state.deltaLabel,
                              prevMonthName.toLowerCase(),
                            ),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.accent300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
          if (total <= 0)
            AppCard(
              gap: 10,
              children: [
                Kicker(l10n.homeNoExpensesKicker),
                Text(
                  state.hasNoExpensesAtAll
                      ? l10n.homeNeverAnyExpense
                      : l10n.homeNoExpensesInMonth(monthName.toLowerCase()),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral500,
                  ),
                ),
                PrimaryButton(
                  label: l10n.homeRegisterFirst,
                  onTap: () => context.push(RouteNames.addExpense),
                ),
              ],
            )
          else ...[
            AppCard(
              gap: 10,
              children: [
                Kicker(l10n.homeByCategory),
                Row(
                  spacing: 16,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: DonutChart(
                          segments: [
                            for (final c in state.categories)
                              if ((catTotals[c.name] ?? 0) > 0)
                                (catTotals[c.name]! / total, c.color),
                          ],
                          centerTitle: money.format(total),
                          centerSubtitle: l10n.homeThisMonth,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        spacing: 7,
                        children: [
                          for (final c in state.categories)
                            InkWell(
                              onTap: () => context.go(
                                RouteNames.categoryDetailOf(c.name),
                              ),
                              child: Row(
                                spacing: 7,
                                children: [
                                  ColorDot(c.color),
                                  // La leyenda va en la mitad estrecha, al
                                  // lado de la dona, y el importe con moneda y
                                  // decimales ya no cabe junto al nombre: se
                                  // reparte a propósito, con más sitio para la
                                  // cifra, que es el dato. El nombre se corta
                                  // antes que envolverse a tres líneas.
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      c.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        money.format(catTotals[c.name] ?? 0),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.neutral400,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 30,
                                    child: Text(
                                      '${percentOf(catTotals[c.name] ?? 0, total)}%',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.neutral600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            AppCard(
              gap: 8,
              children: [
                Kicker(l10n.homeDailyTrend),
                TrendChart(values: state.dailyTotals),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.homeAxisDay(1, monthAbbr), style: _axisStyle),
                    Text(l10n.homeAxisDay(15, monthAbbr), style: _axisStyle),
                    Text(
                      l10n.homeAxisDay(state.daysInCurrentMonth, monthAbbr),
                      style: _axisStyle,
                    ),
                  ],
                ),
              ],
            ),
          ],
          if (hasHistory)
            AppCard(
              gap: 8,
              children: [
                Kicker(l10n.homeLastSixMonths),
                BarChart(
                  bars: [
                    for (var i = 0; i < bars.length; i++)
                      (
                        dates.monthAbbr(bars[i].$1),
                        bars[i].$2,
                        // La última barra es siempre el mes en curso.
                        i == bars.length - 1
                            ? AppColors.accent
                            : AppColors.neutral800,
                      ),
                  ],
                  height: 112,
                  maxBarHeight: 78,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

const TextStyle _axisStyle = TextStyle(
  fontSize: 10,
  color: AppColors.neutral600,
);
