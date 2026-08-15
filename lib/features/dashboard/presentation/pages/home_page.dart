import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/router/route_names.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_spacing.dart';
import 'package:gastegi/app/theme/app_typography.dart';
import 'package:gastegi/app/theme/entity_visuals.dart';
import 'package:gastegi/core/utils/formatters.dart';
import 'package:gastegi/core/utils/l10n_context.dart';
import 'package:gastegi/core/utils/screen.dart';
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
    watchScreen(context);
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
      padding: AppSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16.r,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Kicker(dates.monthTitle(state.monthAnchor), size: 11),
              SizedBox(height: 4.r),
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
                        money.format(total),
                        style: AppTextStyles.hero(AppFontSize.displayLg),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      l10n.homeSpentThisMonth,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppFontSize.bodySm,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ),
                ],
              ),
              // Sin mes anterior con datos no hay nada que comparar, y las
              // fracciones saldrían 0/0.
              if (state.canCompare) ...[
                SizedBox(height: 12.r),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 5.r,
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
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
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
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
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
                  style: TextStyle(
                    fontSize: AppFontSize.bodySm,
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
                  spacing: 16.r,
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
                        spacing: 7.r,
                        children: [
                          for (final c in state.categories)
                            InkWell(
                              onTap: () => context.go(
                                RouteNames.categoryDetailOf(c.name),
                              ),
                              child: Row(
                                spacing: 7.r,
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
                                      style: TextStyle(
                                        fontSize: AppFontSize.label,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        money.format(catTotals[c.name] ?? 0),
                                        style: TextStyle(
                                          fontSize: AppFontSize.label,
                                          color: AppColors.neutral400,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Ancho mínimo y no fijo: alinea la columna
                                  // de porcentajes mientras caben, y la deja
                                  // crecer cuando el tamaño de letra del
                                  // sistema los hace más anchos.
                                  ConstrainedBox(
                                    constraints: BoxConstraints(minWidth: 30.r),
                                    child: Text(
                                      '${percentOf(catTotals[c.name] ?? 0, total)}%',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: AppFontSize.label,
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
                    Text(l10n.homeAxisDay(1, monthAbbr), style: _axisStyle()),
                    Text(l10n.homeAxisDay(15, monthAbbr), style: _axisStyle()),
                    Text(
                      l10n.homeAxisDay(state.daysInCurrentMonth, monthAbbr),
                      style: _axisStyle(),
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

/// Una función y no una constante de nivel superior: `AppFontSize` necesita la
/// pantalla ya medida, y un `final` aquí se evaluaría al importar el archivo.
TextStyle _axisStyle() =>
    TextStyle(fontSize: AppFontSize.micro, color: AppColors.neutral600);
