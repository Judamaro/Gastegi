import 'dart:math' as math;

import 'package:flutter/foundation.dart' hide Category;
import 'package:gastegi/core/utils/date_utils.dart';
import 'package:gastegi/features/accounts/domain/entities/account.dart';
import 'package:gastegi/features/accounts/domain/repositories/account_repository.dart';
import 'package:gastegi/features/budgets/domain/budget_rules.dart';
import 'package:gastegi/features/budgets/presentation/models/budget_row.dart';
import 'package:gastegi/features/categories/domain/entities/category.dart';
import 'package:gastegi/features/categories/domain/repositories/category_repository.dart';
import 'package:gastegi/features/expenses/domain/entities/expense.dart';
import 'package:gastegi/features/expenses/domain/repositories/expense_repository.dart';

/// Caché en memoria de los datos de la app y único punto de escritura.
///
/// Los datos viven en SQLite; aquí solo hay una copia del mes en curso que se
/// repuebla **entera** tras cada escritura ([write]). Eso mantiene todos los
/// getters derivados síncronos —lo que permite que las pantallas sigan siendo
/// `StatelessWidget` sin `FutureBuilder`— y elimina una clase entera de bugs
/// de desincronización entre memoria y disco.
///
/// Es el dueño de los datos y de nada más: el estado de la interfaz
/// —formularios, filtros, selecciones— vive fuera. Los derivados que cruzan
/// funcionalidades ([patrimonio], [budgetRows], [monthTotals]) se calculan aquí
/// en cada lectura, así que no pueden quedarse desfasados respecto de la caché.
class AppDataStore extends ChangeNotifier {
  AppDataStore({
    required this.categoryRepo,
    required this.accountRepo,
    required this.expenseRepo,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    final now = _clock();
    _today = dateOnly(now);
    _monthAnchor = monthStart(now);
  }

  final CategoryRepository categoryRepo;
  final AccountRepository accountRepo;
  final ExpenseRepository expenseRepo;

  /// Inyectable para que los tests no dependan del día real.
  final DateTime Function() _clock;

  /// Cuántos meses hacia atrás cubre la gráfica de barras.
  static const int _monthsBack = 5;

  /// Días previos al mes que se cargan, para que "últimos 7/15 días" siga
  /// funcionando durante los primeros días de mes.
  static const int _windowPadDays = 14;

  /// Se invoca tras repoblar la caché y **antes** de notificar.
  ///
  /// Es el enganche que necesita quien guarda selecciones de interfaz: al
  /// recargar, una cuenta o una categoría pueden haber desaparecido bajo los
  /// pies de un selector, y hay que corregirlo antes de que nadie repinte.
  VoidCallback? onReloaded;

  List<Category> _categories = const [];
  List<Account> _accounts = const [];

  /// Gastos del mes en curso más [_windowPadDays] días previos.
  List<Expense> _window = const [];

  /// Los del mes en curso, ya filtrados: base de casi todos los getters.
  List<Expense> _monthExpenses = const [];

  Map<String, double> _monthlySums = const {};
  int _expenseCount = 0;

  late DateTime _today;
  late DateTime _monthAnchor;
  bool _busy = false;

  List<Category> get categories => _categories;
  List<Account> get accounts => _accounts;

  /// La ventana completa, no solo el mes: los rangos por días del historial
  /// deben poder alcanzar el mes anterior a principios de mes.
  List<Expense> get window => _window;

  // ── Carga y escritura ──────────────────────────────────────────────────

  /// Repuebla la caché desde la BD. Es también lo que habrá que llamar al
  /// terminar un pull cuando exista sincronización con la nube.
  Future<void> load() async {
    final now = _clock();
    _today = dateOnly(now);
    _monthAnchor = monthStart(now);

    final windowStart = earliest(
      _monthAnchor,
      daysBefore(_today, _windowPadDays),
    );

    _categories = await categoryRepo.all();
    _accounts = await accountRepo.all();
    _window = await expenseRepo.since(windowStart);
    _monthExpenses = _window
        .where((e) => sameMonth(e.date, _monthAnchor))
        .toList();
    _monthlySums = await expenseRepo.monthlyTotals(
      from: addMonths(_monthAnchor, -_monthsBack),
    );
    _expenseCount = await expenseRepo.count();

    onReloaded?.call();
    notifyListeners();
  }

  /// Ejecuta [op] y recarga. Recargar entero cuesta microsegundos con estos
  /// volúmenes.
  ///
  /// El cerrojo [_busy] es de toda la aplicación y tiene que seguir siéndolo:
  /// es lo que evita que un doble toque en "Guardar" cree dos filas. Si cada
  /// dueño de estado tuviera el suyo, el bug volvería.
  Future<void> write(Future<void> Function() op) async {
    if (_busy) return;
    _busy = true;
    try {
      await op();
      await load();
    } finally {
      _busy = false;
    }
  }

  // ── Etiquetas del mes ──────────────────────────────────────────────────

  DateTime get today => _today;

  /// `Agosto 2026`.
  String get currentMonthTitle => monthTitle(_monthAnchor);

  /// `Agosto`.
  String get currentMonthName => monthName(_monthAnchor);

  /// `Ago`.
  String get currentMonthAbbr => monthAbbr(_monthAnchor);

  String get prevMonthName => monthName(addMonths(_monthAnchor, -1));

  int get daysInCurrentMonth => daysInMonth(_monthAnchor);

  DateTime get monthAnchor => _monthAnchor;

  String dayLabelShortOf(DateTime d) => dayLabelShort(d, _today);

  // ── Totales del mes ────────────────────────────────────────────────────

  List<Expense> get expenses => _monthExpenses;

  /// Si el usuario no ha registrado nunca nada, en cualquier fecha.
  bool get hasNoExpensesAtAll => _expenseCount == 0;

  double get total => _monthExpenses.fold(0, (a, e) => a + e.val);

  Map<String, double> get catTotals {
    final totals = {for (final c in _categories) c.name: 0.0};
    for (final e in _monthExpenses) {
      totals[e.categoryName] = (totals[e.categoryName] ?? 0) + e.val;
    }
    return totals;
  }

  /// Gasto por día del mes (índice 0 = día 1).
  List<double> get dailyTotals => List.generate(
    daysInCurrentMonth,
    (i) => _monthExpenses
        .where((e) => e.day == i + 1)
        .fold(0.0, (a, e) => a + e.val),
  );

  /// Barras de los últimos 6 meses; el mes en curso usa el total en vivo.
  List<(String, double)> get monthTotals => [
    for (var i = _monthsBack; i > 0; i--)
      () {
        final m = addMonths(_monthAnchor, -i);
        return (monthAbbr(m), _monthlySums[monthKey(m)] ?? 0.0);
      }(),
    (currentMonthAbbr, total),
  ];

  /// Total del mes anterior, para la comparación del inicio.
  double get prevTotal =>
      _monthlySums[monthKey(addMonths(_monthAnchor, -1))] ?? 0;

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
    for (final c in _categories) {
      if (c.name == name) return c;
    }
    return null;
  }

  Account? accountById(String? id) {
    if (id == null) return null;
    for (final a in _accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  // ── Cuentas ────────────────────────────────────────────────────────────

  double get patrimonio => _accounts.fold(0, (a, c) => a + c.balance);

  bool get canTransfer => _accounts.length > 1;

  // ── Presupuestos ───────────────────────────────────────────────────────

  double get totalBudget => _categories.fold(0, (a, c) => a + c.budget);

  List<BudgetRow> get budgetRows {
    final totals = catTotals;
    return [
      for (final c in _categories)
        () {
          final spent = totals[c.name] ?? 0;
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
}
