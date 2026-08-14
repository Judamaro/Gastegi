import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/router/route_names.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_icons.dart';
import 'package:gastegi/app/theme/entity_visuals.dart';
import 'package:gastegi/core/utils/formatters.dart';
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
    final cat = ref.watch(categoryByNameProvider(categoryName));
    // La categoría puede haber desaparecido bajo los pies de la pantalla.
    if (cat == null) return const SizedBox.shrink();

    final state = ref.watch(appDataProvider);
    final catTotal = ref.watch(categoryTotalProvider(categoryName));
    final expenses = ref.watch(categoryExpensesProvider(categoryName));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Row(
            spacing: 8,
            children: [
              AppIconButton(
                icon: AppIcons.caretLeft,
                onTap: () => context.go(RouteNames.home),
              ),
              Expanded(
                child: Text(
                  cat.name,
                  style: const TextStyle(
                    fontSize: 20,
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
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                spacing: 8,
                children: [
                  Text(
                    formatAmount(catTotal),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.64,
                      height: 1,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      'en ${state.currentMonthName.toLowerCase()}'
                      ' · ${percentOf(catTotal, state.total)}% del total',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 4,
                children: [
                  ProgressBar(
                    // Un presupuesto a 0 daría una fracción NaN y reventaría el
                    // layout del FractionallySizedBox.
                    fraction: cat.budget > 0 ? catTotal / cat.budget : 0,
                    color: cat.color,
                  ),
                  Text(
                    'Presupuesto: ${formatAmount(catTotal)} de ${formatAmount(cat.budget)}',
                    style: const TextStyle(
                      fontSize: 11,
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
              const Kicker('Por semana'),
              BarChart(
                bars: [
                  for (final (label, value) in ref.watch(
                    categoryWeeksProvider(categoryName),
                  ))
                    (label, value, cat.color),
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
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Sin gastos de ${cat.name.toLowerCase()} en '
                '${state.currentMonthName.toLowerCase()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
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
                    subtitle:
                        '${state.dayLabelShortOf(e.date)} · ${e.accountName}',
                    amount: formatAmount(e.val),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
