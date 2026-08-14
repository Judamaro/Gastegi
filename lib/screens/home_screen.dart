import 'package:flutter/material.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/entity_visuals.dart';
import 'package:gastegi/core/widgets/app_card.dart';
import 'package:gastegi/core/widgets/charts/bar_chart.dart';
import 'package:gastegi/core/widgets/charts/compare_bar.dart';
import 'package:gastegi/core/widgets/charts/donut_chart.dart';
import 'package:gastegi/core/widgets/charts/trend_chart.dart';
import 'package:gastegi/core/widgets/color_dot.dart';
import 'package:gastegi/core/widgets/kicker.dart';
import 'package:gastegi/core/widgets/primary_button.dart';
import 'package:gastegi/state/app_state.dart';

/// Inicio: total del mes, comparación con el mes anterior, dona por categoría,
/// tendencia diaria y últimos 6 meses.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final total = state.total;
    final catTotals = state.catTotals;
    final bars = state.monthTotals;
    final hasHistory = bars.any((b) => b.$2 > 0);
    final monthAbbr = state.currentMonthAbbr.toLowerCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Kicker(state.currentMonthTitle, size: 11),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                spacing: 8,
                children: [
                  Text(
                    state.fmt(total),
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.76,
                      height: 1,
                    ),
                  ),
                  const Flexible(
                    child: Text(
                      'gastado este mes',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
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
                            '${state.currentMonthName} ${state.fmt(total)}'
                            ' · ${state.prevMonthName} ${state.fmt(state.prevTotal)}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.neutral500,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            '${state.deltaLabel} vs ${state.prevMonthName.toLowerCase()}',
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
                const Kicker('Sin gastos'),
                Text(
                  state.hasNoExpensesAtAll
                      ? 'Todavía no has registrado ningún gasto.'
                      : 'Aún no has registrado gastos en '
                            '${state.currentMonthName.toLowerCase()}.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral500,
                  ),
                ),
                PrimaryButton(
                  label: 'Registrar el primero',
                  onTap: () => state.goTo(Screen.add),
                ),
              ],
            )
          else ...[
            AppCard(
              gap: 10,
              children: [
                const Kicker('Por categoría'),
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
                          centerTitle: state.fmt(total),
                          centerSubtitle: 'este mes',
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        spacing: 7,
                        children: [
                          for (final c in state.categories)
                            InkWell(
                              onTap: () => state.openCategory(c.name),
                              child: Row(
                                spacing: 7,
                                children: [
                                  ColorDot(c.color),
                                  Expanded(
                                    child: Text(
                                      c.name,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Text(
                                    state.fmt(catTotals[c.name] ?? 0),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.neutral400,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 30,
                                    child: Text(
                                      '${state.pct(catTotals[c.name] ?? 0, total)}%',
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
                const Kicker('Tendencia diaria'),
                TrendChart(values: state.dailyTotals),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 $monthAbbr', style: _axisStyle),
                    Text('15 $monthAbbr', style: _axisStyle),
                    Text(
                      '${state.daysInCurrentMonth} $monthAbbr',
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
                const Kicker('Últimos 6 meses'),
                BarChart(
                  bars: [
                    for (var i = 0; i < bars.length; i++)
                      (
                        bars[i].$1,
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
