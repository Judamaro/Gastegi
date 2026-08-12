import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' hide Category;
import 'package:intl/intl.dart';
import '../theme/phosphor_icons.dart';

import '../models/models.dart';
import '../theme/nocturne.dart';

enum Screen { home, history, catDetail, accounts, budgets, add }

enum HistoryRange {
  month('Todo el mes'),
  last15('Últimos 15 días'),
  last7('Últimos 7 días');

  const HistoryRange(this.label);
  final String label;

  bool includes(int day) => switch (this) {
        month => true,
        last15 => day >= 16,
        last7 => day >= 24,
      };
}

/// Fila derivada para la pantalla de presupuestos.
class BudgetRow {
  const BudgetRow({
    required this.category,
    required this.spent,
    required this.ratio,
    required this.alert,
    required this.over,
  });

  final Category category;
  final double spent;
  final double ratio;
  final bool alert;
  final bool over;
}

/// Estado central de la app: datos de demo (julio 2026) y toda la lógica
/// portada del script DCLogic del diseño.
class AppState extends ChangeNotifier {
  /// Umbral de alerta de presupuesto (prop `umbralAlerta` del diseño).
  static const double umbralAlerta = 0.90;

  /// Total de junio, para la comparación del inicio.
  static const double prevTotal = 1568;

  /// Meses anteriores para la gráfica de 6 meses (julio se calcula en vivo).
  static const List<(String, double)> prevMonths = [
    ('Feb', 1350),
    ('Mar', 1490),
    ('Abr', 1280),
    ('May', 1445),
    ('Jun', 1568),
  ];

  final List<Category> categories = const [
    Category('Comida', Color(0xFFB5ABFC), PhIcons.forkKnife, 500),
    Category('Transporte', Color(0xFF9690C9), PhIcons.bus, 180),
    Category('Hogar', Color(0xFFD2CEFD), PhIcons.houseLine, 400),
    Category('Ocio', Color(0xFF796CBF), PhIcons.popcorn, 200),
    Category('Salud', Color(0xFFB2B6CA), PhIcons.heartbeat, 120),
    Category('Compras', Color(0xFF75798C), PhIcons.shoppingBag, 240),
  ];

  final List<Account> accounts = [
    Account('Efectivo', 'Dinero en mano', PhIcons.money, 480),
    Account('Débito', 'Tarjeta de débito', PhIcons.creditCard, 2350),
    Account('Crédito', 'Tarjeta de crédito', PhIcons.creditCard, -820),
    Account('Ahorros', 'Cuenta bancaria', PhIcons.bank, 6100),
  ];

  final List<Expense> expenses = [
    const Expense(30, 'Supermercado Central', 'Comida', 'Débito', 86),
    const Expense(30, 'Taxi aeropuerto', 'Transporte', 'Efectivo', 24),
    const Expense(29, 'Cine y palomitas', 'Ocio', 'Crédito', 32),
    const Expense(28, 'Farmacia', 'Salud', 'Débito', 18),
    const Expense(28, 'Almuerzo oficina', 'Comida', 'Efectivo', 14),
    const Expense(27, 'Gasolina', 'Transporte', 'Crédito', 45),
    const Expense(26, 'Internet hogar', 'Hogar', 'Débito', 55),
    const Expense(25, 'Cena con amigos', 'Comida', 'Crédito', 48),
    const Expense(24, 'Camiseta', 'Compras', 'Crédito', 35),
    const Expense(23, 'Mercado semanal', 'Comida', 'Débito', 92),
    const Expense(22, 'Recarga metro', 'Transporte', 'Efectivo', 20),
    const Expense(21, 'Recibo de luz', 'Hogar', 'Débito', 68),
    const Expense(20, 'Concierto', 'Ocio', 'Crédito', 75),
    const Expense(19, 'Café', 'Comida', 'Efectivo', 6),
    const Expense(18, 'Zapatillas', 'Compras', 'Crédito', 89),
    const Expense(17, 'Recibo de agua', 'Hogar', 'Débito', 32),
    const Expense(16, 'Consulta dental', 'Salud', 'Débito', 60),
    const Expense(15, 'Supermercado', 'Comida', 'Débito', 78),
    const Expense(14, 'Bus interurbano', 'Transporte', 'Efectivo', 18),
    const Expense(13, 'Streaming', 'Ocio', 'Crédito', 15),
    const Expense(12, 'Gas natural', 'Hogar', 'Débito', 40),
    const Expense(11, 'Panadería', 'Comida', 'Efectivo', 9),
    const Expense(10, 'App de transporte', 'Transporte', 'Crédito', 28),
    const Expense(9, 'Libros', 'Compras', 'Crédito', 42),
    const Expense(8, 'Parking mensual', 'Hogar', 'Débito', 95),
    const Expense(7, 'Pizza a domicilio', 'Comida', 'Crédito', 26),
    const Expense(6, 'Gimnasio', 'Salud', 'Débito', 30),
    const Expense(5, 'Videojuego', 'Ocio', 'Crédito', 60),
    const Expense(4, 'Mercado', 'Comida', 'Débito', 71),
    const Expense(3, 'Taxi', 'Transporte', 'Efectivo', 15),
    const Expense(2, 'Decoración', 'Hogar', 'Crédito', 38),
    const Expense(1, 'Regalo cumpleaños', 'Compras', 'Crédito', 52),
  ];

  Screen screen = Screen.home;
  String? selCatName;
  String search = '';
  String filterCat = 'Todas';
  HistoryRange filterRange = HistoryRange.month;
  bool transferOpen = false;
  String trFrom = 'Débito';
  String trTo = 'Ahorros';
  String trAmt = '';
  String addAmount = '';
  String? addCat;
  String? addAcct;
  String addDesc = '';

  static final NumberFormat _nf = NumberFormat.decimalPattern('es');

  /// Redondea a entero y aplica separador de miles es-ES, como fmt() del diseño.
  String fmt(double n) => _nf.format(n.round());

  Category categoryOf(String name) =>
      categories.firstWhere((c) => c.name == name, orElse: () => categories.first);

  double get total => expenses.fold(0, (a, e) => a + e.val);

  Map<String, double> get catTotals {
    final totals = {for (final c in categories) c.name: 0.0};
    for (final e in expenses) {
      totals[e.cat] = (totals[e.cat] ?? 0) + e.val;
    }
    return totals;
  }

  /// Gasto por día del mes (índice 0 = día 1), 30 días como en el diseño.
  List<double> get dailyTotals => List.generate(
      30, (i) => expenses.where((e) => e.day == i + 1).fold(0.0, (a, e) => a + e.val));

  /// Barras de los últimos 6 meses; julio usa el total en vivo.
  List<(String, double)> get monthTotals => [...prevMonths, ('Jul', total)];

  String get deltaLabel {
    final pct = ((total - prevTotal).abs() / prevTotal * 100)
        .toStringAsFixed(1)
        .replaceAll('.', ',');
    return '${total < prevTotal ? '−' : '+'}$pct%';
  }

  double get cmpNowFrac => total / (total > prevTotal ? total : prevTotal);
  double get cmpPrevFrac => prevTotal / (total > prevTotal ? total : prevTotal);

  // ── Historial ──────────────────────────────────────────────────────────

  List<Expense> get filteredExpenses {
    final q = search.trim().toLowerCase();
    return expenses
        .where((e) =>
            filterRange.includes(e.day) &&
            (filterCat == 'Todas' || e.cat == filterCat) &&
            (q.isEmpty ||
                e.desc.toLowerCase().contains(q) ||
                e.cat.toLowerCase().contains(q)))
        .toList();
  }

  /// Grupos por día, descendente, con su etiqueta ("Hoy" para el día 31).
  List<(String, List<Expense>)> get historyGroups {
    final byDay = <int, List<Expense>>{};
    for (final e in filteredExpenses) {
      byDay.putIfAbsent(e.day, () => []).add(e);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final d in days) (d == 31 ? 'Hoy' : '$d de julio', byDay[d]!)];
  }

  // ── Detalle de categoría ───────────────────────────────────────────────

  Category get selCategory => categoryOf(selCatName ?? 'Comida');

  List<Expense> get selCatExpenses =>
      (expenses.where((e) => e.cat == selCategory.name).toList()
        ..sort((a, b) => b.day.compareTo(a.day)));

  double get selCatTotal => catTotals[selCategory.name] ?? 0;

  /// Totales semanales de la categoría seleccionada (días 1–7/8–14/15–21/22–31).
  List<(String, double)> get selCatWeeks => [
        for (final (a, b, label) in const [
          (1, 7, 'Sem 1'),
          (8, 14, 'Sem 2'),
          (15, 21, 'Sem 3'),
          (22, 31, 'Sem 4'),
        ])
          (
            label,
            selCatExpenses
                .where((e) => e.day >= a && e.day <= b)
                .fold(0.0, (s, e) => s + e.val)
          ),
      ];

  // ── Cuentas ────────────────────────────────────────────────────────────

  double get patrimonio => accounts.fold(0, (a, c) => a + c.balance);

  double get trAmtValue => double.tryParse(trAmt.replaceAll(',', '.')) ?? 0;

  // ── Presupuestos ───────────────────────────────────────────────────────

  double get totalBudget => categories.fold(0, (a, c) => a + c.budget);

  List<BudgetRow> get budgetRows => [
        for (final c in categories)
          () {
            final spent = catTotals[c.name] ?? 0;
            final r = spent / c.budget;
            return BudgetRow(
              category: c,
              spent: spent,
              ratio: r,
              alert: r >= umbralAlerta,
              over: r >= 1,
            );
          }(),
      ];

  // ── Nuevo gasto ────────────────────────────────────────────────────────

  double get addAmountValue => double.tryParse(addAmount.replaceAll(',', '.')) ?? 0;

  bool get saveDisabled => !(addAmountValue > 0 && addCat != null && addAcct != null);

  // ── Acciones ───────────────────────────────────────────────────────────

  void goTo(Screen s) {
    screen = s;
    notifyListeners();
  }

  void openCategory(String name) {
    selCatName = name;
    screen = Screen.catDetail;
    notifyListeners();
  }

  void setSearch(String value) {
    search = value;
    notifyListeners();
  }

  void setFilterCat(String name) {
    filterCat = name;
    notifyListeners();
  }

  void setFilterRange(HistoryRange range) {
    filterRange = range;
    notifyListeners();
  }

  void openTransfer() {
    transferOpen = true;
    notifyListeners();
  }

  void closeTransfer() {
    transferOpen = false;
    trAmt = '';
    notifyListeners();
  }

  void pickTrFrom(String name) {
    trFrom = name;
    notifyListeners();
  }

  void pickTrTo(String name) {
    trTo = name;
    notifyListeners();
  }

  void setTrAmt(String value) {
    trAmt = value;
    notifyListeners();
  }

  void doTransfer() {
    final amount = trAmtValue;
    if (!(amount > 0) || trFrom == trTo) return;
    for (final a in accounts) {
      if (a.name == trFrom) a.balance -= amount;
      if (a.name == trTo) a.balance += amount;
    }
    transferOpen = false;
    trAmt = '';
    notifyListeners();
  }

  /// Teclado del nuevo gasto: dígitos, una sola coma decimal y borrado,
  /// con máximo 7 dígitos como en el diseño.
  void keypadTap(String key) {
    var a = addAmount;
    if (key == '⌫') {
      a = a.isEmpty ? a : a.substring(0, a.length - 1);
    } else if (key == ',') {
      if (!a.contains(',')) a = '${a.isEmpty ? '0' : a},';
    } else if (a.replaceAll(',', '').length < 7) {
      a += key;
    }
    addAmount = a;
    notifyListeners();
  }

  void pickAddCat(String name) {
    addCat = name;
    notifyListeners();
  }

  void pickAddAcct(String name) {
    addAcct = name;
    notifyListeners();
  }

  void setAddDesc(String value) {
    addDesc = value;
    notifyListeners();
  }

  void saveExpense() {
    if (saveDisabled) return;
    final value = addAmountValue;
    expenses.insert(0, Expense(31, addDesc.isEmpty ? addCat! : addDesc, addCat!, addAcct!, value));
    for (final a in accounts) {
      if (a.name == addAcct) a.balance -= value;
    }
    addAmount = '';
    addCat = null;
    addAcct = null;
    addDesc = '';
    screen = Screen.history;
    notifyListeners();
  }
}

/// Colores auxiliares que el estado expone a las pantallas.
extension BudgetRowColors on BudgetRow {
  Color get barColor => over
      ? Nocturne.accent300
      : alert
          ? Nocturne.accent
          : category.color;

  String get alertLabel => over ? 'Excedido' : 'Alerta';
}
