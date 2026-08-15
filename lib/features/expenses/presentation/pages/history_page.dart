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
import 'package:gastegi/features/expenses/presentation/models/history_range.dart';
import 'package:gastegi/features/expenses/presentation/providers/history_notifier.dart';

/// Historial: búsqueda, filtros por rango y categoría, gastos agrupados por día.
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    watchScreen(context);
    final data = ref.watch(appDataProvider);
    final filter = ref.watch(historyFilterProvider);
    final filters = ref.read(historyFilterProvider.notifier);
    final groups = ref.watch(historyGroupsProvider);
    final l10n = context.l10n;
    final dates = context.dates;

    String rangeLabel(HistoryRange r) => switch (r) {
      HistoryRange.month => l10n.historyRangeMonth,
      HistoryRange.last15 => l10n.historyRangeLast15,
      HistoryRange.last7 => l10n.historyRangeLast7,
    };

    return SingleChildScrollView(
      padding: AppSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12.r,
        children: [
          Text(
            l10n.historyTitle,
            style: TextStyle(
              fontSize: AppFontSize.title,
              fontWeight: FontWeight.w500,
            ),
          ),
          AppInput(hint: l10n.historySearchHint, onChanged: filters.setSearch),
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
          for (final (day, items) in groups)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 6.r, bottom: 4.r),
                  child: Text(
                    dates.dayLabel(day, data.today).toUpperCase(),
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      letterSpacing: 0.9,
                      color: AppColors.neutral500,
                    ),
                  ),
                ),
                for (final e in items)
                  AmountTile(
                    title: e.desc,
                    subtitle: l10n.historyExpenseSubtitle(
                      e.categoryName,
                      e.accountName ?? l10n.commonNoAccount,
                    ),
                    amount: context.money.formatSigned(-e.val),
                    icon: data.categoryOf(e.categoryName)?.icon,
                    iconColor: data.categoryOf(e.categoryName)?.color,
                  ),
              ],
            ),
          if (groups.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.r),
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
        ],
      ),
    );
  }
}
