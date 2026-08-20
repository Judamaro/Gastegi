import 'dart:math' as math;

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
import 'package:gastegi/core/utils/text_measure.dart';
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
                  // Con moneda y decimales, la cifra más larga no cabe
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
                // La fila se mide una vez y sirve para la dona y para todas
                // las filas de la leyenda.
                LayoutBuilder(
                  builder: (context, fila) {
                    // La dona pide lo suyo y la leyenda se queda con el resto.
                    //
                    // Antes las dos iban a `flex: 1`: la fila se partía por la
                    // mitad, la dona gastaba sus 128 y lo que le sobraba de su
                    // mitad no volvía a la leyenda —`mainAxisAlignment` es
                    // `start`, así que se quedaba muerto al final—. Eran unos
                    // 30 dp en un móvil de 390 y más de 200 en apaisado, justo
                    // mientras los nombres se cortaban.
                    //
                    // El tope del 40 % conserva la red del `FittedBox`: en el
                    // catálogo de pantallas la dona no se acerca, pero un
                    // `SizedBox` a secas desbordaría el día que el diseño
                    // cambie.
                    final donut = math.min(128.r, fila.maxWidth * 0.4);
                    final legend = fila.maxWidth - donut - 16.r;

                    final labelStyle = DefaultTextStyle.of(
                      context,
                    ).style.merge(TextStyle(fontSize: AppFontSize.label));
                    final scaler = MediaQuery.textScalerOf(context);
                    final direction = Directionality.of(context);

                    // Lo que ocupan el punto, los tres huecos y el porcentaje;
                    // el resto se lo reparten el nombre y el importe.
                    final fixed = 8.r + 21.r + 30.r;
                    final shared = math.max(0.0, legend - fixed);
                    // El nombre coge lo que pide el más largo, no una fracción
                    // fija, y con un tope para que un nombre inventado muy
                    // largo no ahogue la cifra. Por debajo del tope, lo que el
                    // nombre no necesita se lo queda el importe.
                    //
                    // El tope pasa de la mitad porque los dos no degradan
                    // igual: al importe le queda el `FittedBox`, que lo encoge
                    // y lo sigue enseñando entero, y al nombre solo la
                    // elisión, que se come letras. Con la mitad justa
                    // «Transporte» se quedaba a 0,2 dp de caber.
                    //
                    // Se mide con el estilo que se pinta, familia incluida:
                    // los estilos de la app no la llevan —la pone el tema— y
                    // medir con uno suelto mide con la del sistema, que es más
                    // estrecha. Ver `text_measure.dart`.
                    final nameWidth = math.min(
                      state.categories.fold(
                        0.0,
                        (w, c) => math.max(
                          w,
                          textWidth(
                            c.name,
                            style: labelStyle,
                            scaler: scaler,
                            direction: direction,
                          ),
                        ),
                      ),
                      shared * 0.55,
                    );

                    return Row(
                      spacing: 16.r,
                      children: [
                        SizedBox(
                          width: donut,
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
                                      SizedBox(
                                        width: nameWidth,
                                        // La elisión solo entra cuando el
                                        // nombre topa con la mitad.
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
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            money.format(
                                              catTotals[c.name] ?? 0,
                                            ),
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: AppFontSize.label,
                                              color: AppColors.neutral400,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Ancho mínimo y no fijo: alinea la
                                      // columna de porcentajes mientras caben,
                                      // y la deja crecer cuando el tamaño de
                                      // letra del sistema los hace más anchos.
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: 30.r,
                                        ),
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
                    );
                  },
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
