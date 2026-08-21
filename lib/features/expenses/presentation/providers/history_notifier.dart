import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/core/utils/date_utils.dart';
import 'package:gastegi/features/expenses/domain/entities/expense.dart';
import 'package:gastegi/features/expenses/presentation/models/history_item.dart';
import 'package:gastegi/features/expenses/presentation/models/history_range.dart';

/// Filtros del historial.
@immutable
class HistoryFilter {
  const HistoryFilter({
    this.search = '',
    this.categoryId,
    this.range = HistoryRange.month,
  });

  final String search;

  /// Id de la categoría por la que se filtra; `null` es "todas".
  ///
  /// El id y no el nombre: el nombre lo escribe el usuario y renombrar una
  /// categoría vaciaba el historial sin decir por qué. Antes de eso era el
  /// literal `'Todas'`, que hacía de etiqueta y de valor de control a la vez:
  /// en cuanto ese texto se traduzca, deja de coincidir consigo mismo.
  final String? categoryId;

  final HistoryRange range;

  HistoryFilter copyWith({
    String? search,
    Object? categoryId = _keep,
    HistoryRange? range,
  }) => HistoryFilter(
    search: search ?? this.search,
    categoryId: identical(categoryId, _keep)
        ? this.categoryId
        : categoryId as String?,
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
      final id = state.categoryId;
      if (id != null && !data.categories.any((c) => c.id == id)) {
        state = state.copyWith(categoryId: null);
      }
    });
    return const HistoryFilter();
  }

  void setSearch(String value) => state = state.copyWith(search: value);

  /// [id] nulo significa "todas las categorías".
  void setCategory(String? id) => state = state.copyWith(categoryId: id);

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
            (filter.categoryId == null || e.categoryId == filter.categoryId) &&
            // La búsqueda libre sí va contra el nombre: es texto que el
            // usuario está leyendo en pantalla, no un enlace entre tablas.
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

/// Los grupos aplanados a una sola lista indexable.
///
/// Es lo que consume `SliverList.builder` en la página: una lista perezosa
/// necesita `itemCount` y un índice, y recorrer grupos anidados obligaría a
/// construirlos todos para saber en cuál cae la fila N.
final historyItemsProvider = Provider<List<HistoryItem>>((ref) {
  final groups = ref.watch(historyGroupsProvider);
  return [
    for (final (day, items) in groups) ...[
      HistoryDay(day),
      for (final e in items) HistoryEntry(e),
    ],
  ];
});
