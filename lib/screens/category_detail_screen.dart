import 'package:flutter/material.dart';
import '../theme/phosphor_icons.dart';

import '../state/app_state.dart';
import '../theme/nocturne.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

/// Detalle de una categoría: total, presupuesto, barras semanales y gastos.
class CategoryDetailScreen extends StatelessWidget {
  const CategoryDetailScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final cat = state.selCategory;
    final catTotal = state.selCatTotal;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Row(
            spacing: 8,
            children: [
              NIconButton(
                icon: PhIcons.caretLeft,
                onTap: () => state.goTo(Screen.home),
              ),
              Expanded(
                child: Text(
                  cat.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
              ),
              ColorDot(cat.color, size: 12),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                spacing: 8,
                children: [
                  Text(
                    state.fmt(catTotal),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.64,
                      height: 1,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      'en julio · ${(catTotal / state.total * 100).round()}% del total',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Nocturne.neutral500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 4,
                children: [
                  ProgressBar(fraction: catTotal / cat.budget, color: cat.color),
                  Text(
                    'Presupuesto: ${state.fmt(catTotal)} de ${state.fmt(cat.budget)}',
                    style: const TextStyle(fontSize: 11, color: Nocturne.neutral500),
                  ),
                ],
              ),
            ],
          ),
          NCard(
            gap: 8,
            children: [
              const Kicker('Por semana'),
              BarChart(
                bars: [
                  for (final (label, value) in state.selCatWeeks) (label, value, cat.color),
                ],
                height: 96,
                maxBarHeight: 64,
                barWidthFraction: 0.55,
                minBarHeight: 3,
              ),
            ],
          ),
          Column(
            children: [
              for (final e in state.selCatExpenses)
                ExpenseTile(
                  title: e.desc,
                  subtitle: '${e.day == 31 ? 'Hoy' : '${e.day} jul'} · ${e.acct}',
                  amount: state.fmt(e.val),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
