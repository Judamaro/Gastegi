import 'package:flutter/material.dart';
import 'package:gastegi/app/state/app_state.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/entity_visuals.dart';
import 'package:gastegi/core/widgets/amount_tile.dart';
import 'package:gastegi/core/widgets/app_chip.dart';
import 'package:gastegi/core/widgets/app_input.dart';
import 'package:gastegi/features/expenses/presentation/models/history_range.dart';

/// Historial: búsqueda, filtros por rango y categoría, gastos agrupados por día.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final groups = state.historyGroups;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          const Text(
            'Historial',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          AppInput(hint: 'Buscar gasto…', onChanged: state.setSearch),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final range in HistoryRange.values)
                AppChip(
                  label: range.label,
                  active: state.filterRange == range,
                  onTap: () => state.setFilterRange(range),
                ),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final name in [
                'Todas',
                ...state.categories.map((c) => c.name),
              ])
                AppChip(
                  label: name,
                  active: state.filterCat == name,
                  onTap: () => state.setFilterCat(name),
                ),
            ],
          ),
          for (final (label, items) in groups)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 4),
                  child: Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.9,
                      color: AppColors.neutral500,
                    ),
                  ),
                ),
                for (final e in items)
                  AmountTile(
                    title: e.desc,
                    subtitle: '${e.categoryName} · ${e.accountName}',
                    amount: state.fmt(e.val),
                    icon: state.categoryOf(e.categoryName)?.icon,
                    iconColor: state.categoryOf(e.categoryName)?.color,
                  ),
              ],
            ),
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                // Distinguir "no hay nada" de "los filtros no encuentran nada":
                // en una app recién instalada el segundo mensaje despista.
                state.hasNoExpensesAtAll
                    ? 'Todavía no hay gastos registrados'
                    : 'Sin resultados para esta búsqueda',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
