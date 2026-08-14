import 'dart:math' as math;

import 'package:flutter/foundation.dart' hide Category;
import 'package:gastegi/core/utils/date_utils.dart';
import 'package:gastegi/features/accounts/domain/entities/account.dart';
import 'package:gastegi/features/budgets/domain/budget_rules.dart';
import 'package:gastegi/features/budgets/presentation/models/budget_row.dart';
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

  /// Total gastado por mes, indexado por `YYYY-MM`.
  final Map<String, double> monthlySums;

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

  late final Map<String, double> catTotals = () {
    final totals = {for (final c in categories) c.name: 0.0};
    for (final e in expenses) {
      totals[e.categoryName] = (totals[e.categoryName] ?? 0) + e.val;
    }
    return totals;
  }();

  /// Gasto por día del mes (índice 0 = día 1).
  late final List<double> dailyTotals = List.generate(
    daysInCurrentMonth,
    (i) => expenses.where((e) => e.day == i + 1).fold(0.0, (a, e) => a + e.val),
  );

  /// Barras de los últimos 6 meses; el mes en curso usa el total en vivo.
  ///
  /// Devuelve el mes, no su nombre: poner aquí una etiqueta obligaría a este
  /// archivo a conocer el idioma del usuario.
  late final List<(DateTime, double)> monthTotals = [
    for (var i = monthsBack; i > 0; i--)
      () {
        final m = addMonths(monthAnchor, -i);
        return (m, monthlySums[monthKey(m)] ?? 0.0);
      }(),
    (monthAnchor, total),
  ];

  /// Total del mes anterior, para la comparación del inicio.
  double get prevTotal => monthlySums[monthKey(prevMonthAnchor)] ?? 0;

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
        final spent = catTotals[c.name] ?? 0;
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
