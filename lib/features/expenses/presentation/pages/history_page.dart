import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_spacing.dart';
import 'package:gastegi/app/theme/app_typography.dart';
import 'package:gastegi/app/theme/entity_visuals.dart';
import 'package:gastegi/core/utils/l10n_context.dart';
import 'package:gastegi/core/utils/screen.dart';
import 'package:gastegi/core/widgets/amount_tile.dart';
import 'package:gastegi/core/widgets/app_chip.dart';
import 'package:gastegi/core/widgets/app_input.dart';
import 'package:gastegi/features/categories/domain/entities/category.dart';
import 'package:gastegi/features/expenses/domain/entities/expense.dart';
import 'package:gastegi/features/expenses/presentation/models/history_item.dart';
import 'package:gastegi/features/expenses/presentation/models/history_range.dart';
import 'package:gastegi/features/expenses/presentation/providers/history_notifier.dart';

/// Historial: búsqueda, filtros por rango y categoría, gastos agrupados por día.
///
/// La lista es **perezosa**. Con un `Column` dentro de un
/// `SingleChildScrollView` se construía una fila por cada gasto de la ventana,
/// estuviera o no en pantalla: con dos años de uso son casi dos mil filas para
/// enseñar nueve, y cada pulsación en el buscador las rehacía todas.
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    watchScreen(context);
    final data = ref.watch(appDataProvider);
    final filter = ref.watch(historyFilterProvider);
    final filters = ref.read(historyFilterProvider.notifier);
    final items = ref.watch(historyItemsProvider);
    final l10n = context.l10n;
    final dates = context.dates;
    final page = AppSpacing.page;

    String rangeLabel(HistoryRange r) => switch (r) {
      HistoryRange.month => l10n.historyRangeMonth,
      HistoryRange.last15 => l10n.historyRangeLast15,
      HistoryRange.last7 => l10n.historyRangeLast7,
    };

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(page.left, page.top, page.right, 0),
          // Cabecera fija en número de widgets: da igual cuántos gastos haya.
          sliver: SliverList.list(
            children: [
              Text(
                l10n.historyTitle,
                style: TextStyle(
                  fontSize: AppFontSize.title,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12.r),
              AppInput(
                hint: l10n.historySearchHint,
                onChanged: filters.setSearch,
              ),
              SizedBox(height: 12.r),
              Wrap(
                spacing: 6.r,
                runSpacing: 6.r,
                children: [
                  for (final range in HistoryRange.values)
                    AppChip(
                      label: rangeLabel(range),
                      active: filter.range == range,
                      onTap: () => filters.setRange(range),
                    ),
                ],
              ),
              SizedBox(height: 12.r),
              Wrap(
                spacing: 6.r,
                runSpacing: 6.r,
                children: [
                  // `null` es "todas": el chip lleva etiqueta, pero el filtro no
                  // guarda texto de interfaz.
                  for (final name in <String?>[
                    null,
                    ...data.categories.map((c) => c.name),
                  ])
                    AppChip(
                      label: name ?? l10n.commonAll,
                      active: filter.categoryName == name,
                      onTap: () => filters.setCategory(name),
                    ),
                ],
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: page.left),
          sliver: SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, i) => switch (items[i]) {
              HistoryDay(:final day) => Padding(
                padding: EdgeInsets.only(top: 18.r, bottom: 4.r),
                child: Text(
                  dates.dayLabel(day, data.today).toUpperCase(),
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    letterSpacing: 0.9,
                    color: AppColors.neutral500,
                  ),
                ),
              ),
              // La categoría se busca **una vez** por fila y se pasa entera; el
              // icono y el color salían antes de dos búsquedas separadas.
              HistoryEntry(:final expense) => _ExpenseRow(
                expense: expense,
                category: data.categoryOf(expense.categoryName),
              ),
            },
          ),
        ),
        if (items.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(page.left, 36.r, page.right, 24.r),
              child: Text(
                // Distinguir "no hay nada" de "los filtros no encuentran nada":
                // en una app recién instalada el segundo mensaje despista.
                data.hasNoExpensesAtAll
                    ? l10n.historyEmptyEver
                    : l10n.historyEmptyForFilters,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppFontSize.bodySm,
                  color: AppColors.neutral600,
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: page.bottom)),
      ],
    );
  }
}

/// Una fila de gasto del historial.
class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense, required this.category});

  final Expense expense;

  /// Puede faltar: el gasto guarda el nombre de la categoría, no su fila.
  final Category? category;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AmountTile(
      title: expense.desc,
      subtitle: l10n.historyExpenseSubtitle(
        expense.categoryName,
        expense.accountName ?? l10n.commonNoAccount,
      ),
      amount: context.money.formatSigned(-expense.val),
      icon: category?.icon,
      iconColor: category?.color,
    );
  }
}
