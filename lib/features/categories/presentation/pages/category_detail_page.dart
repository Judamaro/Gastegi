import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
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
import 'package:gastegi/core/utils/text_measure.dart';
import 'package:gastegi/core/widgets/amount_tile.dart';
import 'package:gastegi/core/widgets/app_card.dart';
import 'package:gastegi/core/widgets/app_icon_button.dart';
import 'package:gastegi/core/widgets/color_dot.dart';
import 'package:gastegi/core/widgets/kicker.dart';
import 'package:gastegi/core/widgets/meter_bar.dart';
import 'package:gastegi/features/categories/presentation/providers/category_detail_providers.dart';
import 'package:go_router/go_router.dart';

/// Detalle de una categoría: total, presupuesto, barras semanales y gastos.
class CategoryDetailPage extends ConsumerWidget {
  const CategoryDetailPage({super.key, required this.categoryId});

  /// Llega por la ruta.
  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    watchScreen(context);
    final cat = ref.watch(categoryByIdProvider(categoryId));
    // La categoría puede haber desaparecido bajo los pies de la pantalla:
    // borrada desde Presupuestos mientras su detalle seguía vivo en la otra
    // rama del shell. Hay que salir, no quedarse en blanco: el botón de volver
    // es parte de esta página, así que un hueco vacío deja la pestaña de
    // Inicio sin salida. Renombrarla ya no la hace desaparecer: la ruta guarda
    // el id.
    if (cat == null) {
      // Después del frame: `go` durante el `build` reentra en el router.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(RouteNames.home);
      });
      return const SizedBox.shrink();
    }

    final state = ref.watch(appDataProvider);
    final catTotal = ref.watch(categoryTotalProvider(categoryId));
    final expenses = ref.watch(categoryExpensesProvider(categoryId));
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
                  // Con moneda y decimales, la cifra más larga no cabe
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
                  MeterBar(
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
              _WeekBars(
                bars: [
                  for (final (i, value)
                      in ref.watch(categoryWeeksProvider(categoryId)).indexed)
                    (l10n.categoryWeekLabel(i + 1), value),
                ],
                color: cat.color,
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

/// Reparto semanal de la categoría, una barra por tramo.
///
/// Las proporciones son las del diseño —96 dp de alto, 64 para la barra más
/// alta y 55 % del hueco de ancho—, pero `fl_chart` las pide en píxeles del eje
/// y no en fracciones, así que se despejan aquí a partir del ancho que da el
/// `LayoutBuilder` y del alto medido de la etiqueta.
class _WeekBars extends StatefulWidget {
  const _WeekBars({required this.bars, required this.color});

  /// Pares (etiqueta, importe). El color lo comparten todas: es la categoría.
  final List<(String, double)> bars;
  final Color color;

  @override
  State<_WeekBars> createState() => _WeekBarsState();
}

class _WeekBarsState extends State<_WeekBars> {
  /// Los datos entran desde el suelo en vez de aparecer a su altura.
  ///
  /// `fl_chart` solo anima **entre dos fotos distintas**: al montar construye
  /// el tween con la misma a los dos lados y no mueve nada. Este frame de más
  /// es toda la animación de entrada. Vive en el `State`, así que se dispara al
  /// montar y no en cada recarga de `AppData`.
  bool _entrado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _entrado = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = 96.r;
    // `calculateGroupsX` tiene un `assert(barGroups.isNotEmpty)`.
    if (widget.bars.isEmpty) return SizedBox(height: height);

    final l10n = context.l10n;
    final money = context.money;
    final labelStyle = TextStyle(
      fontSize: AppFontSize.micro,
      color: AppColors.neutral500,
    );
    // La banda de la etiqueta se mide y no se supone: `reservedSize` fuerza el
    // alto del hijo con un `tightFor`, y un texto más grande se recorta **sin
    // lanzar nada**. Se mide con el estilo que se pinta, familia incluida (ver
    // `text_measure.dart`).
    final labelHeight = textHeight(
      widget.bars.first.$1,
      style: DefaultTextStyle.of(context).style.merge(labelStyle),
      scaler: MediaQuery.textScalerOf(context),
      direction: Directionality.of(context),
    );
    final plot = height - labelHeight;
    // La barra más alta nunca puede invadir la banda de la etiqueta.
    final maxBar = math.min(64.r, plot);
    // Suelo de 1: una semana sin gastos dividiría entre cero.
    final max = widget.bars.fold(1.0, (m, b) => math.max(m, b.$2));
    final maxY = max * plot / maxBar;
    // `fl_chart` no dibuja una barra de valor cero y estira a `2·radio` la que
    // no lo es. Este suelo es ese mismo alto en unidades del eje.
    final minBar = 2 * AppRadius.sm * maxY / plot;

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, caja) => BarChart(
          BarChartData(
            // Centra cada barra en su hueco, como hacía el painter;
            // `spaceEvenly` —la de por defecto— reparte un hueco de más.
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              // Sin esto salen los cuatro lados: es lo que trae por defecto.
              leftTitles: const AxisTitles(),
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: labelHeight,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    space: 0,
                    child: Text(
                      widget.bars[value.toInt()].$1,
                      style: labelStyle,
                    ),
                  ),
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.neutral900,
                tooltipBorder: const BorderSide(color: AppColors.divider),
                tooltipBorderRadius: BorderRadius.circular(AppRadius.sm),
                tooltipPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.space2,
                  vertical: AppSpacing.space1,
                ),
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                    BarTooltipItem(
                      // El importe del globo es el de verdad, no el del suelo.
                      l10n.chartTooltip(
                        widget.bars[groupIndex].$1,
                        money.format(widget.bars[groupIndex].$2),
                      ),
                      TextStyle(
                        fontSize: AppFontSize.caption,
                        color: AppColors.text,
                      ),
                    ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < widget.bars.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: _entrado
                          ? math.max(minBar, widget.bars[i].$2)
                          : minBar,
                      color: widget.color,
                      width: caja.maxWidth / widget.bars.length * 0.55,
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadius.sm),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }
}
