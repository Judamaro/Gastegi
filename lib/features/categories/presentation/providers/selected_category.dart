import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/features/categories/domain/entities/category.dart';
import 'package:gastegi/features/expenses/domain/entities/expense.dart';

/// Nombre de la categoría cuyo detalle se está mirando.
class SelectedCategoryNotifier extends Notifier<String?> {
  @override
  String? build() {
    // La categoría puede desaparecer mientras se mira su detalle; sin esto la
    // pantalla se quedaría con un nombre que ya no corresponde a nada.
    ref.listen(appDataProvider, (_, data) {
      final name = state;
      if (name != null && !data.categories.any((c) => c.name == name)) {
        state = null;
      }
    });
    return null;
  }

  void select(String name) => state = name;
}

final selectedCategoryNameProvider =
    NotifierProvider<SelectedCategoryNotifier, String?>(
      SelectedCategoryNotifier.new,
    );

/// La categoría seleccionada, o `null` si no hay ninguna o ya no existe.
final selectedCategoryProvider = Provider<Category?>((ref) {
  final name = ref.watch(selectedCategoryNameProvider);
  return name == null ? null : ref.watch(appDataProvider).categoryOf(name);
});

/// Gastos del mes de la categoría seleccionada, del más reciente al más antiguo.
final selectedCategoryExpensesProvider = Provider<List<Expense>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  if (category == null) return const [];
  return ref
      .watch(appDataProvider)
      .expenses
      .where((e) => e.categoryName == category.name)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

final selectedCategoryTotalProvider = Provider<double>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  if (category == null) return 0;
  return ref.watch(appDataProvider).catTotals[category.name] ?? 0;
});

/// Totales semanales de la categoría seleccionada.
///
/// El último tramo llega hasta el final real del mes, sea 28, 29, 30 o 31: con
/// un corte fijo en el 28, los gastos de fin de mes desaparecerían del gráfico.
final selectedCategoryWeeksProvider = Provider<List<(String, double)>>((ref) {
  final last = ref.watch(appDataProvider).daysInCurrentMonth;
  final items = ref.watch(selectedCategoryExpensesProvider);
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
