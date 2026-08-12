import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/nocturne.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

/// Inicio: total del mes, comparación con junio, dona por categoría,
/// tendencia diaria y últimos 6 meses.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final total = state.total;
    final catTotals = state.catTotals;
    final donutSegments = [
      for (final c in state.categories)
        if ((catTotals[c.name] ?? 0) > 0) (catTotals[c.name]! / total, c.color),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Kicker('Julio 2026', size: 11),
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
                      style: TextStyle(fontSize: 13, color: Nocturne.neutral500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 5,
                children: [
                  CompareBar(fraction: state.cmpNowFrac, color: Nocturne.accent),
                  CompareBar(fraction: state.cmpPrevFrac, color: Nocturne.neutral800),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Julio ${state.fmt(total)} · Junio ${state.fmt(AppState.prevTotal)}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Nocturne.neutral500),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '${state.deltaLabel} vs junio',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Nocturne.accent300),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          NCard(
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
                        segments: donutSegments,
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
                                  child: Text(c.name, style: const TextStyle(fontSize: 12)),
                                ),
                                Text(
                                  state.fmt(catTotals[c.name] ?? 0),
                                  style: const TextStyle(
                                      fontSize: 12, color: Nocturne.neutral400),
                                ),
                                SizedBox(
                                  width: 30,
                                  child: Text(
                                    '${((catTotals[c.name] ?? 0) / total * 100).round()}%',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 12, color: Nocturne.neutral600),
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
          NCard(
            gap: 8,
            children: [
              const Kicker('Tendencia diaria'),
              TrendChart(values: state.dailyTotals),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1 jul', style: TextStyle(fontSize: 10, color: Nocturne.neutral600)),
                  Text('15 jul', style: TextStyle(fontSize: 10, color: Nocturne.neutral600)),
                  Text('30 jul', style: TextStyle(fontSize: 10, color: Nocturne.neutral600)),
                ],
              ),
            ],
          ),
          NCard(
            gap: 8,
            children: [
              const Kicker('Últimos 6 meses'),
              BarChart(
                bars: [
                  for (final (label, value) in state.monthTotals)
                    (
                      label,
                      value,
                      label == 'Jul' ? Nocturne.accent : Nocturne.neutral800,
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
