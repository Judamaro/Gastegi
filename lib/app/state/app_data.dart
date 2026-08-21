import 'dart:math' as math;

import 'package:flutter/foundation.dart' hide Category;
import 'package:gastegi/app/state/budget_row.dart';
import 'package:gastegi/core/utils/date_utils.dart';
import 'package:gastegi/features/accounts/domain/entities/account.dart';
import 'package:gastegi/features/budgets/domain/budget_rules.dart';
import 'package:gastegi/features/categories/domain/entities/category.dart';
import 'package:gastegi/features/expenses/domain/entities/expense.dart';

/// Foto inmutable de los datos de la app.
///
/// Los datos viven en SQLite; esto es una copia del mes en curso que se
/// reemplaza **entera** tras cada escritura. Que sea inmutable es lo que
/// permite que los providers derivados comparen y solo repinten lo que de
/// verdad ha cambiado.
///
/// Todos los cálculos derivados son funciones puras de esta foto, así que no
/// pueden quedarse desfasados respecto de ella.
@immutable
class AppData {
  AppData({
    required this.categories,
    required this.accounts,
    required this.window,
    required this.monthlySums,
    required this.expenseCount,
    required this.today,
    required this.monthAnchor,
  });

  /// Estado antes de la primera carga.
  AppData.empty(DateTime now)
    : categories = const [],
      accounts = const [],
      window = const [],
      monthlySums = const {},
      expenseCount = 0,
      today = dateOnly(now),
      monthAnchor = monthStart(now);

  /// Cuántos meses hacia atrás cubre la gráfica de barras.
  static const int monthsBack = 5;

  /// Días previos al mes que se cargan, para que "últimos 7/15 días" siga
  /// funcionando durante los primeros días de mes.
  static const int windowPadDays = 14;

  final List<Category> categories;
  final List<Account> accounts;

  /// Gastos del mes en curso más [windowPadDays] días previos. El historial
  /// necesita la ventana entera: sus rangos por días alcanzan el mes anterior
  /// a principios de mes.
  final List<Expense> window;

  /// Gasto por mes y categoría, indexado por `YYYY-MM` e **id** de categoría.
  ///
  /// Desglosado y no en total porque las barras de Inicio se componen con el
  /// color de cada categoría. El total de un mes es la suma de su mapa, y de
  /// ahí salen [monthTotals] y [prevTotal].
  final Map<String, Map<String, double>> monthlySums;

  /// Gastos registrados en total, en cualquier fecha.
  final int expenseCount;

  final DateTime today;

  /// Primer día del mes en curso.
  final DateTime monthAnchor;

  /// Los del mes en curso: base de casi todos los derivados. Se calcula una
  /// vez por foto y no en cada lectura.
  late final List<Expense> expenses = window
      .where((e) => sameMonth(e.date, monthAnchor))
      .toList();

  // ── El mes ─────────────────────────────────────────────────────────────

  int get daysInCurrentMonth => daysInMonth(monthAnchor);

  /// Primer día del mes anterior.
  DateTime get prevMonthAnchor => addMonths(monthAnchor, -1);

  // ── Totales del mes ────────────────────────────────────────────────────

  /// Si el usuario no ha registrado nunca nada, en cualquier fecha.
  bool get hasNoExpensesAtAll => expenseCount == 0;

  late final double total = expenses.fold(0, (a, e) => a + e.val);

  /// Gasto del mes por categoría, indexado por **id**.
  ///
  /// Por id y no por nombre: el nombre lo escribe el usuario y puede cambiar
  /// bajo los pies de cualquier cosa que lo guarde. El nombre para pintar sale
  /// de la propia [Category], que se busca con ese id.
  late final Map<String, double> catTotals = () {
    final totals = {for (final c in categories) c.id: 0.0};
    for (final e in expenses) {
      totals[e.categoryId] = (totals[e.categoryId] ?? 0) + e.val;
    }
    return totals;
  }();

  /// Gasto por día del mes (índice 0 = día 1).
  ///
  /// Una sola pasada acumulando: recorrer los gastos una vez por día era
  /// O(días × gastos) para un resultado que sale en O(gastos).
  late final List<double> dailyTotals = () {
    final totals = List.filled(daysInCurrentMonth, 0.0);
    for (final e in expenses) {
      totals[e.day - 1] += e.val;
    }
    return totals;
  }();

  /// Lo mismo desglosado por categoría, indexado por **id** y en el orden de
  /// [categories].
  ///
  /// Otra pasada y no un derivado de [dailyTotals]: cada una sale en
  /// O(gastos) por su cuenta, y sumar el desglose costaría
  /// O(categorías × días) para llegar al mismo sitio.
  late final Map<String, List<double>> dailyCatTotals = () {
    final totals = {
      for (final c in categories) c.id: List.filled(daysInCurrentMonth, 0.0),
    };
    for (final e in expenses) {
      (totals[e.categoryId] ??= List.filled(
        daysInCurrentMonth,
        0.0,
      ))[e.day - 1] += e.val;
    }
    return totals;
  }();

  /// Barras de los últimos 6 meses, desglosadas por categoría; el mes en curso
  /// usa el desglose en vivo.
  ///
  /// Devuelve el mes y el id de cada categoría, no etiquetas ni colores: poner
  /// aquí cualquiera de las dos cosas obligaría a este archivo a conocer el
  /// idioma del usuario o a importar Flutter.
  late final List<(DateTime, Map<String, double>)> monthCatTotals = [
    for (var i = monthsBack; i > 0; i--)
      () {
        final m = addMonths(monthAnchor, -i);
        return (m, monthlySums[monthKey(m)] ?? const <String, double>{});
      }(),
    (monthAnchor, catTotals),
  ];

  /// El total de cada uno de esos meses.
  late final List<(DateTime, double)> monthTotals = [
    for (final (m, cats) in monthCatTotals) (m, _sum(cats)),
  ];

  /// Total del mes anterior, para la comparación del inicio.
  double get prevTotal => _sum(monthlySums[monthKey(prevMonthAnchor)]);

  static double _sum(Map<String, double>? amounts) =>
      amounts == null ? 0 : amounts.values.fold(0.0, (a, v) => a + v);

  /// Vacío cuando no hay mes anterior con el que comparar.
  String get deltaLabel {
    if (prevTotal <= 0) return '';
    final pctChange = ((total - prevTotal).abs() / prevTotal * 100)
        .toStringAsFixed(1)
        .replaceAll('.', ',');
    return '${total < prevTotal ? '−' : '+'}$pctChange%';
  }

  bool get canCompare => prevTotal > 0;

  double get cmpNowFrac => _cmpFrac(total);
  double get cmpPrevFrac => _cmpFrac(prevTotal);

  double _cmpFrac(double value) {
    final denominator = math.max(total, prevTotal);
    return denominator <= 0 ? 0 : value / denominator;
  }

  // ── Búsquedas ──────────────────────────────────────────────────────────

  /// La categoría con ese id, o `null` si ya no existe: puede haberse borrado
  /// mientras alguien seguía apuntando a ella.
  Category? categoryById(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Category? categoryOf(String name) {
    for (final c in categories) {
      if (c.name == name) return c;
    }
    return null;
  }

  Account? accountById(String? id) {
    if (id == null) return null;
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  // ── Cuentas ────────────────────────────────────────────────────────────

  late final double patrimonio = accounts.fold(0, (a, c) => a + c.balance);

  bool get canTransfer => accounts.length > 1;

  // ── Presupuestos ───────────────────────────────────────────────────────

  late final double totalBudget = categories.fold(0, (a, c) => a + c.budget);

  late final List<BudgetRow> budgetRows = [
    for (final c in categories)
      () {
        final spent = catTotals[c.id] ?? 0;
        final r = c.budget > 0 ? spent / c.budget : 0.0;
        return BudgetRow(
          category: c,
          spent: spent,
          ratio: r,
          alert: c.budget > 0 && r >= budgetAlertThreshold,
          over: c.budget > 0 && r >= 1,
        );
      }(),
  ];
}
