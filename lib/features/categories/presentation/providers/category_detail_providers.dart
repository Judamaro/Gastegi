/// Derivados del detalle de una categoría, indexados por su nombre.
///
/// El nombre viene de la ruta y no de un provider de "categoría seleccionada":
/// con el router, la URL es la única fuente de verdad, y así no hay dos sitios
/// que puedan discrepar sobre qué se está mirando.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/features/categories/domain/entities/category.dart';
import 'package:gastegi/features/expenses/domain/entities/expense.dart';

/// La categoría, o `null` si ya no existe: puede haberse borrado mientras se
/// miraba su detalle.
final categoryByNameProvider = Provider.family<Category?, String>(
  (ref, name) => ref.watch(appDataProvider).categoryOf(name),
);

/// Gastos del mes de esa categoría, del más reciente al más antiguo.
final categoryExpensesProvider = Provider.family<List<Expense>, String>((
  ref,
  name,
) {
  return ref
      .watch(appDataProvider)
      .expenses
      .where((e) => e.categoryName == name)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

final categoryTotalProvider = Provider.family<double, String>(
  (ref, name) => ref.watch(appDataProvider).catTotals[name] ?? 0,
);

/// Totales semanales de la categoría.
///
/// El último tramo llega hasta el final real del mes, sea 28, 29, 30 o 31: con
/// un corte fijo en el 28, los gastos de fin de mes desaparecerían del gráfico.
final categoryWeeksProvider = Provider.family<List<(String, double)>, String>((
  ref,
  name,
) {
  final last = ref.watch(appDataProvider).daysInCurrentMonth;
  final items = ref.watch(categoryExpensesProvider(name));
  const labels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
  final ranges = [(1, 7), (8, 14), (15, 21), (22, last)];

  return [
    for (var i = 0; i < labels.length; i++)
      (
        labels[i],
        items
            .where((e) => e.day >= ranges[i].$1 && e.day <= ranges[i].$2)
            .fold(0.0, (s, e) => s + e.val),
      ),
  ];
});
