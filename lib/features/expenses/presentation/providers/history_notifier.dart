import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/core/utils/date_utils.dart';
import 'package:gastegi/features/expenses/domain/entities/expense.dart';
import 'package:gastegi/features/expenses/presentation/models/history_range.dart';

/// Filtros del historial.
@immutable
class HistoryFilter {
  const HistoryFilter({
    this.search = '',
    this.categoryName,
    this.range = HistoryRange.month,
  });

  final String search;

  /// Categoría por la que se filtra; `null` es "todas".
  ///
  /// Antes esto era el literal `'Todas'`, que hacía de etiqueta y de valor de
  /// control a la vez: en cuanto ese texto se traduzca, dejaría de coincidir
  /// consigo mismo.
  final String? categoryName;

  final HistoryRange range;

  HistoryFilter copyWith({
    String? search,
    Object? categoryName = _keep,
    HistoryRange? range,
  }) => HistoryFilter(
    search: search ?? this.search,
    categoryName: identical(categoryName, _keep)
        ? this.categoryName
        : categoryName as String?,
    range: range ?? this.range,
  );
}

const Object _keep = Object();

class HistoryNotifier extends Notifier<HistoryFilter> {
  @override
  HistoryFilter build() {
    // Si la categoría filtrada desaparece, el historial se quedaría mostrando
    // una lista vacía sin explicación.
    ref.listen(appDataProvider, (_, data) {
      final name = state.categoryName;
      if (name != null && !data.categories.any((c) => c.name == name)) {
        state = state.copyWith(categoryName: null);
      }
    });
    return const HistoryFilter();
  }

  void setSearch(String value) => state = state.copyWith(search: value);

  /// [name] nulo significa "todas las categorías".
  void setCategory(String? name) => state = state.copyWith(categoryName: name);

  void setRange(HistoryRange range) => state = state.copyWith(range: range);
}

final historyFilterProvider = NotifierProvider<HistoryNotifier, HistoryFilter>(
  HistoryNotifier.new,
);

/// Gastos que pasan los filtros.
///
/// Recorre la ventana entera y no solo el mes: los rangos por días deben poder
/// alcanzar el mes anterior cuando estamos a principios de mes.
final filteredExpensesProvider = Provider<List<Expense>>((ref) {
  final data = ref.watch(appDataProvider);
  final filter = ref.watch(historyFilterProvider);
  final q = filter.search.trim().toLowerCase();

  return data.window
      .where(
        (e) =>
            filter.range.includes(e.date, data.today, data.monthAnchor) &&
            (filter.categoryName == null ||
                e.categoryName == filter.categoryName) &&
            (q.isEmpty ||
                e.desc.toLowerCase().contains(q) ||
                e.categoryName.toLowerCase().contains(q)),
      )
      .toList();
});

/// Los gastos filtrados, agrupados por día del más reciente al más antiguo.
///
/// La clave es el día, no su etiqueta: escribir aquí "Hoy" obligaría a este
/// archivo a conocer el idioma del usuario.
final historyGroupsProvider = Provider<List<(DateTime, List<Expense>)>>((ref) {
  final expenses = ref.watch(filteredExpensesProvider);

  final byDay = <DateTime, List<Expense>>{};
  for (final e in expenses) {
    byDay.putIfAbsent(dateOnly(e.date), () => []).add(e);
  }
  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
  return [for (final d in days) (d, byDay[d]!)];
});
