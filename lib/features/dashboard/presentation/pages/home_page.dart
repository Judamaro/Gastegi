import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
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
import 'package:gastegi/core/widgets/color_dot.dart';
import 'package:gastegi/core/widgets/kicker.dart';
import 'package:gastegi/core/widgets/meter_bar.dart';
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
                    // Sin pista: las dos tiras se leen una contra otra, y un
                    // fondo común las igualaría.
                    MeterBar(
                      fraction: state.cmpNowFrac,
                      color: AppColors.accent,
                      height: 8,
                      track: false,
                    ),
                    MeterBar(
                      fraction: state.cmpPrevFrac,
                      color: AppColors.neutral800,
                      height: 8,
                      track: false,
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
                        _CategoryDonut(
                          diameter: donut,
                          segments: [
                            for (final c in state.categories)
                              if ((catTotals[c.name] ?? 0) > 0)
                                (c.name, catTotals[c.name]!, c.color),
                          ],
                          total: total,
                          centerTitle: money.format(total),
                          centerSubtitle: l10n.homeThisMonth,
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
                _DailyTrend(
                  series: [
                    // Mismo orden y mismos colores que la leyenda de la dona y
                    // que las barras de los meses.
                    for (final c in state.categories)
                      if ((catTotals[c.name] ?? 0) > 0)
                        (state.dailyCatTotals[c.name]!, c.color),
                  ],
                  monthAbbr: monthAbbr,
                ),
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
                _MonthBars(
                  bars: [
                    for (final (mes, porCategoria) in state.monthCatTotals)
                      (
                        dates.monthAbbr(mes),
                        // El orden de las categorías es el mismo en los seis
                        // meses y el mismo que en la leyenda de la dona: es lo
                        // que deja seguir un color de una barra a la
                        // siguiente.
                        [
                          for (final c in state.categories)
                            if ((porCategoria[c.name] ?? 0) > 0)
                              (porCategoria[c.name]!, c.color),
                        ],
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

/// Dona de categorías, con el total en el hueco.
///
/// Las proporciones son las del SVG del diseño (viewBox 160, separación de
/// 0.02 rad por lado), con dos cambios. El círculo **llena su caja**: el SVG
/// traía 15 % de margen incorporado, y aquí el hueco que sobra ya lo pone el
/// `Row` que la coloca al lado de la leyenda. Y el trazo es la mitad del que
/// traía el diseño, que es lo que ensancha el hueco para el importe.
///
/// Tiene estado propio porque `PieChart` no gestiona el toque solo —no tiene
/// `handleBuiltInTouches`— y porque subir el sector tocado a `HomePage`
/// reconstruiría la pantalla entera con cada movimiento del dedo.
class _CategoryDonut extends StatefulWidget {
  const _CategoryDonut({
    required this.diameter,
    required this.segments,
    required this.total,
    required this.centerTitle,
    required this.centerSubtitle,
  });

  /// Grosor del anillo como fracción del diámetro: la mitad del que traía el
  /// diseño (20 sobre 160).
  ///
  /// Adelgazarlo no cambia el tamaño de la dona —el borde exterior sigue en el
  /// borde de la caja—, sino el radio del hueco, y de ese radio sale el ancho
  /// que le queda al importe del centro: pasa del 71 % del diámetro al 84 %.
  /// Con la cifra larga, que va en un `FittedBox`, es la diferencia entre
  /// enseñarla encogida y enseñarla a su cuerpo.
  static const double _strokeRatio = 0.0625;

  /// Interlineado de los dos textos del centro. Explícito porque de él sale el
  /// alto del bloque, y de ese alto sale el ancho que cabe en el hueco.
  static const double _lineHeight = 1.15;

  /// Diámetro **ya escalado**: lo mide el `LayoutBuilder` de la fila, que es
  /// quien sabe lo que le deja la leyenda.
  final double diameter;

  /// Ternas (categoría, importe, color); solo las que tienen gasto.
  final List<(String, double, Color)> segments;
  final double total;
  final String centerTitle;
  final String centerSubtitle;

  @override
  State<_CategoryDonut> createState() => _CategoryDonutState();
}

class _CategoryDonutState extends State<_CategoryDonut> {
  /// Sector bajo el dedo, o `null` cuando no hay ninguno.
  int? _touched;

  /// El anillo entra creciendo desde el hueco en vez de aparecer entero.
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
    final diameter = widget.diameter;
    final segments = widget.segments;
    final holeRadius = diameter * (0.5 - _CategoryDonut._strokeRatio);

    // Los dos textos salen del diámetro, no de `AppFontSize`, y por eso no
    // llevan `.sp`: ya escalan con la dona. Es el único sitio de la app que no
    // respeta el ajuste de tamaño de letra del sistema, y por eso lo desactiva
    // explícitamente: el hueco es geométrico y honrarlo sacaría el texto del
    // círculo.
    //
    // El diseño traía 19 y 9 sobre 128, y los dos se mueven por motivos
    // distintos. El título baja al 70 % porque con el de origen la cifra larga
    // llegaba al hueco y el `FittedBox` la encogía; a 13.3 cabe entera y se
    // pinta al tamaño que pide. El subtítulo no tenía ese problema: bajarlo
    // igual lo dejaba en 6.3, que en apaisado —donde la dona baja a 106 dp—
    // son 5,2 reales y no hay quien los lea.
    final titleFont = diameter * 13.3 / 128;
    final subtitleFont = diameter * 8.19 / 128;

    // El ancho que cabe no es el diámetro del hueco: el bloque de dos líneas
    // ocupa una banda, y en sus esquinas —lo más alejado del centro— la cuerda
    // del círculo es más estrecha. Medir ahí es lo que evita que el importe se
    // monte sobre el anillo.
    final halfBlock =
        (titleFont + subtitleFont) * _CategoryDonut._lineHeight / 2;
    final textWidth =
        2 *
        math.sqrt(math.max(0, holeRadius * holeRadius - halfBlock * halfBlock));

    // Mientras se toca un sector, el centro deja de decir el total del mes y
    // pasa a decir lo de esa categoría. Es el globo que `PieChart` no trae, y
    // aquí cabe sin tapar la gráfica.
    final touched = _touched;
    final selected =
        touched != null && touched >= 0 && touched < segments.length
        ? segments[touched]
        : null;
    final title = selected == null
        ? widget.centerTitle
        : context.money.format(selected.$2);
    final subtitle = selected == null
        ? widget.centerSubtitle
        : context.l10n.chartCategoryShare(
            selected.$1,
            percentOf(selected.$2, widget.total),
          );

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              // Grados y sentido horario, con el cero a las tres en punto:
              // −90 es arrancar arriba, como el painter con su −π/2.
              startDegreeOffset: -90,
              centerSpaceRadius: holeRadius,
              // `sectionsSpace` va en píxeles, no en radianes. Los 0.04 rad de
              // hueco del diseño, medidos en el radio de la línea media
              // (0.46875·d), son este arco.
              sectionsSpace: diameter * 0.01875,
              borderData: FlBorderData(show: false),
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  final index = response?.touchedSection?.touchedSectionIndex;
                  final valido =
                      index != null && index >= 0 && index < segments.length;
                  // Soltar sobre un sector lleva al detalle, igual que tocar
                  // su fila en la leyenda.
                  if (event is FlTapUpEvent && valido) {
                    setState(() => _touched = null);
                    context.go(RouteNames.categoryDetailOf(segments[index].$1));
                    return;
                  }
                  setState(
                    () => _touched = event.isInterestedForInteractions && valido
                        ? index
                        : null,
                  );
                },
              ),
              sections: [
                for (final (i, (_, amount, color)) in segments.indexed)
                  PieChartSectionData(
                    value: amount,
                    // El sector tocado conserva su color y los demás se
                    // apagan. Crecer sería el gesto habitual, pero el borde
                    // exterior está en el borde de la caja y se recortaría.
                    color: touched == null || touched == i
                        ? color
                        : color.withValues(alpha: 0.35),
                    radius: _entrado
                        ? diameter * _CategoryDonut._strokeRatio
                        : 0,
                    showTitle: false,
                  ),
              ],
            ),
            curve: Curves.easeOut,
          ),
          // Encajados al hueco: el `Stack` recorta por defecto, así que un
          // texto largo se perdería sin avisar de nada.
          SizedBox(
            width: textWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: titleFont,
                      height: _CategoryDonut._lineHeight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    subtitle,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: subtitleFont,
                      height: _CategoryDonut._lineHeight,
                      color: AppColors.neutral500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Últimos seis meses, una barra por mes compuesta por categorías.
///
/// Cada barra se apila con el color de cada categoría, el mismo que usa la
/// dona y su leyenda, para que las dos gráficas se lean con el mismo código de
/// color. `fl_chart` recorta el `RRect` de la barra entera contra la banda de
/// cada tramo, así que el redondeo de arriba y abajo se conserva y solo lo
/// tocan el primer y el último tramo.
///
/// Las proporciones son las del diseño —112 dp de alto, 78 para la barra más
/// alta y 64 % del hueco de ancho—, pero `fl_chart` las pide en píxeles del
/// eje y no en fracciones, así que se despejan aquí a partir del ancho que da
/// el `LayoutBuilder` y del alto medido de la etiqueta.
class _MonthBars extends StatefulWidget {
  const _MonthBars({required this.bars});

  /// Pares (etiqueta del mes, tramos). Cada tramo es un par (importe, color) y
  /// solo vienen las categorías con gasto ese mes.
  final List<(String, List<(double, Color)>)> bars;

  @override
  State<_MonthBars> createState() => _MonthBarsState();
}

class _MonthBarsState extends State<_MonthBars> {
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
    final height = 112.r;
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
    // Lo que le queda al lienzo cuando la etiqueta se lleva lo suyo.
    final plot = height - labelHeight;
    // La barra más alta nunca puede invadir la banda de la etiqueta.
    final maxBar = math.min(78.r, plot);
    final totales = [
      for (final (_, tramos) in widget.bars)
        tramos.fold(0.0, (a, t) => a + t.$1),
    ];
    // Suelo de 1: sin gastos, el eje se dividiría entre cero.
    final max = totales.fold(1.0, math.max);
    // El eje se estira para que el importe mayor caiga justo en `maxBar`.
    final maxY = max * plot / maxBar;
    // `fl_chart` no dibuja una barra de valor cero y estira a `2·radio` la que
    // no lo es. Este suelo es ese mismo alto puesto en unidades del eje: así un
    // mes sin gastos se sigue viendo y el mínimo no sale de la nada.
    final minBar = 2 * AppRadius.sm * maxY / plot;

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, caja) => BarChart(
          BarChartData(
            // Reparte el ancho en tantos huecos como barras y centra cada una
            // en el suyo, que es lo que hacía el painter. `spaceEvenly` —la de
            // por defecto— reparte uno más y descoloca las etiquetas.
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
                        money.format(totales[groupIndex]),
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
                () {
                  final alto = _entrado ? math.max(minBar, totales[i]) : minBar;
                  // Los tramos se apilan en unidades del eje, escalados al
                  // alto que acaba teniendo la barra: cuando el suelo o la
                  // entrada la encogen, el reparto se encoge con ella en vez
                  // de desbordarla.
                  final escala = totales[i] > 0 ? alto / totales[i] : 0.0;
                  var acumulado = 0.0;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: alto,
                        // Se ve solo cuando el mes no tiene ni un gasto y la
                        // barra es el suelo: entonces no hay ningún tramo que
                        // la tape.
                        color: AppColors.neutral800,
                        width: caja.maxWidth / widget.bars.length * 0.64,
                        borderRadius: BorderRadius.all(
                          Radius.circular(AppRadius.sm),
                        ),
                        rodStackItems: [
                          for (final (importe, color) in widget.bars[i].$2)
                            () {
                              final desde = acumulado;
                              acumulado += importe * escala;
                              return BarChartRodStackItem(
                                desde,
                                acumulado,
                                color,
                              );
                            }(),
                        ],
                      ),
                    ],
                  );
                }(),
            ],
          ),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }
}

/// Tendencia diaria: áreas apiladas, una banda por categoría.
///
/// Cada línea es el **acumulado** de las categorías anteriores más la suya, así
/// que la banda entre dos líneas consecutivas es lo que gastó una sola y la de
/// arriba del todo es el total del día. Es lo que pide `betweenBarsData`, que
/// rellena entre dos líneas y no entre una línea y el eje; la primera, que no
/// tiene ninguna debajo, se rellena con su `belowBarData` contra el cero.
///
/// Las proporciones son las del diseño de 90 dp de alto —línea base a 84,
/// amplitud 72— y de ahí salen los límites del eje, no de los datos. Despejar
/// el eje en vez de empujar la gráfica con un `Padding` vertical es lo que
/// mantiene el lienzo a todo el alto: `fl_chart` reparte los valores sobre lo
/// que le queda, así que cualquier margen se lo come a la línea.
class _DailyTrend extends StatefulWidget {
  const _DailyTrend({required this.series, required this.monthAbbr});

  /// Opacidad del relleno de cada banda.
  ///
  /// Los colores de categoría son de luminosidad alta a propósito —están
  /// pensados para porciones de dona de pocos píxeles— y a plena saturación
  /// ocupando media tarjeta gritan. El trazo sí va al color entero: es lo que
  /// separa una banda de la siguiente.
  static const double _areaAlpha = 0.45;

  /// Una serie por categoría con gasto, en el orden de la leyenda: sus
  /// importes por día (índice 0 = día 1) y su color.
  final List<(List<double>, Color)> series;
  final String monthAbbr;

  @override
  State<_DailyTrend> createState() => _DailyTrendState();
}

class _DailyTrendState extends State<_DailyTrend> {
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
    final height = 90.r;
    final dias = widget.series.isEmpty ? 0 : widget.series.first.$1.length;
    // Con un solo punto no hay recta que trazar y el reparto horizontal
    // dividiría entre cero.
    if (dias < 2) return SizedBox(height: height);

    final l10n = context.l10n;
    final money = context.money;

    // Acumulado por categoría: la serie k lleva la suma de las k+1 primeras.
    final acumulado = <List<double>>[];
    for (final (valores, _) in widget.series) {
      final previa = acumulado.isEmpty ? null : acumulado.last;
      acumulado.add([
        for (var d = 0; d < dias; d++) (previa?[d] ?? 0) + valores[d],
      ]);
    }
    // La última acumula todas: es el total de cada día, y de ella sale el eje.
    // Suelo de 1: un mes recién empezado son todo ceros y saldría plano.
    final max = acumulado.last.fold(1.0, math.max);
    // El trazo hace también de margen lateral: arrancando en el borde, la
    // mitad de su grosor se cortaría contra la caja.
    final stroke = height / 45;

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: stroke),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (dias - 1).toDouble(),
            // De 84/90 para la base y 72/90 de amplitud sale
            // `maxY - minY = 1.25·max` con `maxY` en los 7/6.
            minY: -max / 12,
            maxY: 7 * max / 6,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.neutral900,
                tooltipBorder: const BorderSide(color: AppColors.divider),
                tooltipBorderRadius: BorderRadius.circular(AppRadius.sm),
                // Dentro de la caja por los dos lados: son 90 dp de alto y el
                // globo de un pico alto se saldría por arriba.
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                // Un globo y no uno por banda: la lista tiene que medir lo
                // mismo que la de puntos tocados, así que las demás van a
                // `null`. La de arriba acumula todas las categorías, o sea que
                // su `y` ya es el total de ese día.
                getTooltipItems: (spots) => [
                  for (final spot in spots)
                    if (spot.barIndex == acumulado.length - 1)
                      LineTooltipItem(
                        l10n.chartTooltip(
                          // El índice 0 es el día 1.
                          l10n.homeAxisDay(
                            spot.x.round() + 1,
                            widget.monthAbbr,
                          ),
                          money.format(spot.y),
                        ),
                        TextStyle(
                          fontSize: AppFontSize.caption,
                          color: AppColors.text,
                        ),
                      )
                    else
                      null,
                ],
              ),
            ),
            lineBarsData: [
              for (final (i, serie) in acumulado.indexed)
                LineChartBarData(
                  spots: [
                    for (var d = 0; d < dias; d++)
                      FlSpot(d.toDouble(), _entrado ? serie[d] : 0),
                  ],
                  color: widget.series[i].$2,
                  barWidth: stroke,
                  dotData: const FlDotData(show: false),
                  // Solo la de abajo rellena contra el eje; de ahí para arriba
                  // lo hacen las bandas de `betweenBarsData`.
                  belowBarData: i == 0
                      ? BarAreaData(
                          show: true,
                          color: widget.series[i].$2.withValues(
                            alpha: _DailyTrend._areaAlpha,
                          ),
                          // El relleno baja hasta el cero del eje, no hasta el
                          // borde: por debajo de la línea base todavía queda
                          // caja.
                          applyCutOffY: true,
                        )
                      : null,
                ),
            ],
            betweenBarsData: [
              for (var i = 1; i < acumulado.length; i++)
                BetweenBarsData(
                  fromIndex: i - 1,
                  toIndex: i,
                  color: widget.series[i].$2.withValues(
                    alpha: _DailyTrend._areaAlpha,
                  ),
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

/// Una función y no una constante de nivel superior: `AppFontSize` necesita la
/// pantalla ya medida, y un `final` aquí se evaluaría al importar el archivo.
TextStyle _axisStyle() =>
    TextStyle(fontSize: AppFontSize.micro, color: AppColors.neutral600);
