import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' hide Category;
import 'package:intl/intl.dart';

import '../data/account_repository.dart';
import '../data/category_repository.dart';
import '../data/expense_repository.dart';
import '../models/models.dart';
import '../theme/nocturne.dart';
import '../theme/phosphor_icons.dart';
import '../util/dates.dart';

enum Screen { home, history, catDetail, accounts, budgets, add }

enum HistoryRange {
  month('Todo el mes'),
  last15('Últimos 15 días'),
  last7('Últimos 7 días');

  const HistoryRange(this.label);
  final String label;

  bool includes(DateTime d, DateTime today, DateTime monthAnchor) =>
      switch (this) {
        month => sameMonth(d, monthAnchor),
        last15 => !d.isBefore(daysBefore(today, 14)),
        last7 => !d.isBefore(daysBefore(today, 6)),
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

/// Estado central de la app.
///
/// Los datos viven en SQLite; aquí solo hay una caché en memoria del mes en
/// curso que se repuebla entera tras cada escritura ([_write]). Eso mantiene
/// todos los getters derivados **síncronos**, que es lo que permite que las
/// pantallas sigan siendo `StatelessWidget` sin `FutureBuilder`.
class AppState extends ChangeNotifier {
  AppState({
    required this.categoryRepo,
    required this.accountRepo,
    required this.expenseRepo,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    final now = _clock();
    _today = dateOnly(now);
    _monthAnchor = monthStart(now);
    addDate = _today;
  }

  final CategoryRepository categoryRepo;
  final AccountRepository accountRepo;
  final ExpenseRepository expenseRepo;

  /// Inyectable para que los tests no dependan del día real.
  final DateTime Function() _clock;

  /// Umbral de alerta de presupuesto.
  static const double umbralAlerta = 0.90;

  /// Cuántos meses hacia atrás cubre la gráfica de barras.
  static const int _monthsBack = 5;

  /// Días previos al mes que se cargan, para que "últimos 7/15 días" siga
  /// funcionando durante los primeros días de mes.
  static const int _windowPadDays = 14;

  List<Category> categories = const [];
  List<Account> accounts = const [];

  /// Gastos del mes en curso más [_windowPadDays] días previos.
  List<Expense> _window = const [];

  /// Los del mes en curso, ya filtrados: base de casi todos los getters.
  List<Expense> _monthExpenses = const [];

  Map<String, double> _monthlySums = const {};
  int _expenseCount = 0;

  late DateTime _today;
  late DateTime _monthAnchor;
  bool _busy = false;

  // ── Estado de UI ───────────────────────────────────────────────────────

  Screen screen = Screen.home;
  String? selCatName;
  String search = '';
  String filterCat = 'Todas';
  HistoryRange filterRange = HistoryRange.month;

  bool transferOpen = false;
  String? trFromId;
  String? trToId;
  String trAmt = '';

  String addAmount = '';
  String? addCat;
  String? addAccountId;
  String addDesc = '';
  late DateTime addDate;

  bool accountFormOpen = false;
  String? editingAccountId;
  String afName = '';
  String afKind = '';
  String afBalance = '';
  String afIconKey = 'wallet';
  String? afError;
  String? pendingDeleteId;

  /// Gastos asociados a la cuenta que se está a punto de borrar; decide si la
  /// confirmación ofrece archivar.
  int pendingDeleteExpenses = 0;

  static final NumberFormat _nf = NumberFormat.decimalPattern('es');

  /// Redondea a entero y aplica separador de miles es-ES.
  String fmt(double n) => _nf.format(n.round());

  /// Porcentaje entero de [part] sobre [whole]; 0 si [whole] no es positivo.
  ///
  /// Sin esta guarda, una app recién instalada calcula `0 / 0` y el
  /// `double.nan.round()` resultante lanza `UnsupportedError`.
  int pct(double part, double whole) =>
      whole > 0 ? (part / whole * 100).round() : 0;

  // ── Carga ──────────────────────────────────────────────────────────────

  /// Repuebla la caché desde la BD. Es también lo que habrá que llamar al
  /// terminar un pull cuando exista sincronización con la nube.
  Future<void> load() async {
    final now = _clock();
    _today = dateOnly(now);
    _monthAnchor = monthStart(now);

    final windowStart =
        earliest(_monthAnchor, daysBefore(_today, _windowPadDays));

    categories = await categoryRepo.all();
    accounts = await accountRepo.all();
    _window = await expenseRepo.since(windowStart);
    _monthExpenses =
        _window.where((e) => sameMonth(e.date, _monthAnchor)).toList();
    _monthlySums = await expenseRepo.monthlyTotals(
      from: addMonths(_monthAnchor, -_monthsBack),
    );
    _expenseCount = await expenseRepo.count();

    // Las cuentas pueden haber cambiado bajo los pies de los selectores.
    _normalizeSelections();
    notifyListeners();
  }

  /// Escritura: opera y recarga. Recargar entero cuesta microsegundos con estos
  /// volúmenes y elimina toda una clase de bugs de desincronización RAM↔disco.
  Future<void> _write(Future<void> Function() op) async {
    if (_busy) return; // evita el doble toque en "Guardar"
    _busy = true;
    try {
      await op();
      await load();
    } finally {
      _busy = false;
    }
  }

  void _normalizeSelections() {
    final ids = accounts.map((a) => a.id).toSet();
    if (trFromId == null || !ids.contains(trFromId)) {
      trFromId = accounts.isNotEmpty ? accounts.first.id : null;
    }
    if (trToId == null || !ids.contains(trToId) || trToId == trFromId) {
      trToId = accounts.length > 1
          ? accounts.firstWhere((a) => a.id != trFromId).id
          : null;
    }
    if (addAccountId != null && !ids.contains(addAccountId)) {
      addAccountId = null;
    }
    final names = categories.map((c) => c.name).toSet();
    if (selCatName != null && !names.contains(selCatName)) selCatName = null;
    if (addCat != null && !names.contains(addCat)) addCat = null;
    if (filterCat != 'Todas' && !names.contains(filterCat)) {
      filterCat = 'Todas';
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

  String dayLabelShortOf(DateTime d) => dayLabelShort(d, _today);

  // ── Totales del mes ────────────────────────────────────────────────────

  List<Expense> get expenses => _monthExpenses;

  /// Si el usuario no ha registrado nunca nada, en cualquier fecha.
  bool get hasNoExpensesAtAll => _expenseCount == 0;

  double get total => _monthExpenses.fold(0, (a, e) => a + e.val);

  Map<String, double> get catTotals {
    final totals = {for (final c in categories) c.name: 0.0};
    for (final e in _monthExpenses) {
      totals[e.cat] = (totals[e.cat] ?? 0) + e.val;
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

  // ── Historial ──────────────────────────────────────────────────────────

  Category? categoryOf(String name) {
    for (final c in categories) {
      if (c.name == name) return c;
    }
    return null;
  }

  /// Recorre la ventana entera, no solo el mes: los rangos por días deben poder
  /// alcanzar el mes anterior cuando estamos a principios de mes.
  List<Expense> get filteredExpenses {
    final q = search.trim().toLowerCase();
    return _window
        .where((e) =>
            filterRange.includes(e.date, _today, _monthAnchor) &&
            (filterCat == 'Todas' || e.cat == filterCat) &&
            (q.isEmpty ||
                e.desc.toLowerCase().contains(q) ||
                e.cat.toLowerCase().contains(q)))
        .toList();
  }

  /// Grupos por día, del más reciente al más antiguo.
  List<(String, List<Expense>)> get historyGroups {
    final byDay = <DateTime, List<Expense>>{};
    for (final e in filteredExpenses) {
      byDay.putIfAbsent(dateOnly(e.date), () => []).add(e);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final d in days) (dayLabel(d, _today), byDay[d]!)];
  }

  // ── Detalle de categoría ───────────────────────────────────────────────

  Category? get selCategory =>
      selCatName == null ? null : categoryOf(selCatName!);

  List<Expense> get selCatExpenses {
    final cat = selCategory;
    if (cat == null) return const [];
    return _monthExpenses.where((e) => e.cat == cat.name).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double get selCatTotal {
    final cat = selCategory;
    return cat == null ? 0 : catTotals[cat.name] ?? 0;
  }

  /// Totales semanales de la categoría seleccionada. El último tramo llega
  /// hasta el final real del mes, sea 28, 29, 30 o 31.
  List<(String, double)> get selCatWeeks {
    final last = daysInCurrentMonth;
    const labels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
    final ranges = [(1, 7), (8, 14), (15, 21), (22, last)];
    final items = selCatExpenses;
    return [
      for (var i = 0; i < labels.length; i++)
        (
          labels[i],
          items
              .where((e) => e.day >= ranges[i].$1 && e.day <= ranges[i].$2)
              .fold(0.0, (s, e) => s + e.val),
        ),
    ];
  }

  // ── Cuentas ────────────────────────────────────────────────────────────

  double get patrimonio => accounts.fold(0, (a, c) => a + c.balance);

  double get trAmtValue => _parseAmount(trAmt);

  bool get canTransfer => accounts.length > 1;

  Account? accountById(String? id) {
    if (id == null) return null;
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  // ── Presupuestos ───────────────────────────────────────────────────────

  double get totalBudget => categories.fold(0, (a, c) => a + c.budget);

  List<BudgetRow> get budgetRows {
    final totals = catTotals;
    return [
      for (final c in categories)
        () {
          final spent = totals[c.name] ?? 0;
          final r = c.budget > 0 ? spent / c.budget : 0.0;
          return BudgetRow(
            category: c,
            spent: spent,
            ratio: r,
            alert: c.budget > 0 && r >= umbralAlerta,
            over: c.budget > 0 && r >= 1,
          );
        }(),
    ];
  }

  // ── Nuevo gasto ────────────────────────────────────────────────────────

  double get addAmountValue => _parseAmount(addAmount);

  bool get saveDisabled =>
      !(addAmountValue > 0 && addCat != null && addAccountId != null);

  /// Etiqueta del chip que abre el calendario.
  String get addDateLabel =>
      addDateIsPreset ? 'Otra fecha…' : dayLabelShort(addDate, _today);

  bool get addDateIsPreset => addDateIsToday || addDateIsYesterday;

  bool get addDateIsToday => sameDay(addDate, _today);

  bool get addDateIsYesterday => sameDay(addDate, daysBefore(_today, 1));

  void setAddDateToday() => setAddDate(_today);

  void setAddDateYesterday() => setAddDate(daysBefore(_today, 1));

  double _parseAmount(String raw) =>
      double.tryParse(raw.replaceAll(',', '.')) ?? 0;

  // ── Acciones de navegación y filtros ───────────────────────────────────

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

  // ── Transferencias ─────────────────────────────────────────────────────

  void openTransfer() {
    transferOpen = true;
    notifyListeners();
  }

  void closeTransfer() {
    transferOpen = false;
    trAmt = '';
    notifyListeners();
  }

  void pickTrFrom(String id) {
    trFromId = id;
    notifyListeners();
  }

  void pickTrTo(String id) {
    trToId = id;
    notifyListeners();
  }

  void setTrAmt(String value) {
    trAmt = value;
    notifyListeners();
  }

  Future<void> doTransfer() async {
    final amount = trAmtValue;
    final from = trFromId;
    final to = trToId;
    if (from == null || to == null || from == to || amount <= 0) return;
    await _write(() => accountRepo.transfer(
          fromId: from,
          toId: to,
          amount: amount,
          date: _today,
        ));
    transferOpen = false;
    trAmt = '';
    notifyListeners();
  }

  // ── Nuevo gasto ────────────────────────────────────────────────────────

  /// Teclado del nuevo gasto: dígitos, una sola coma decimal y borrado, con
  /// máximo 7 dígitos.
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

  void pickAddAcct(String id) {
    addAccountId = id;
    notifyListeners();
  }

  void setAddDesc(String value) {
    addDesc = value;
    notifyListeners();
  }

  void setAddDate(DateTime date) {
    addDate = dateOnly(date);
    notifyListeners();
  }

  Future<void> saveExpense() async {
    if (saveDisabled) return;
    final category = categoryOf(addCat!);
    if (category == null) return;
    final value = addAmountValue;
    final desc = addDesc.trim().isEmpty ? category.name : addDesc.trim();

    await _write(() => expenseRepo.create(
          date: addDate,
          description: desc,
          categoryId: category.id,
          accountId: addAccountId,
          amount: value,
        ));

    addAmount = '';
    addCat = null;
    addAccountId = null;
    addDesc = '';
    addDate = _today;
    screen = Screen.history;
    notifyListeners();
  }

  // ── Formulario de cuentas ──────────────────────────────────────────────

  void openAccountForm([Account? account]) {
    accountFormOpen = true;
    pendingDeleteId = null;
    editingAccountId = account?.id;
    afName = account?.name ?? '';
    afKind = account?.kind ?? '';
    afBalance = account == null ? '' : _plain(account.balance);
    afIconKey = account == null ? 'wallet' : PhIcons.keyOf(account.icon);
    afError = null;
    notifyListeners();
  }

  void closeAccountForm() {
    accountFormOpen = false;
    editingAccountId = null;
    afError = null;
    notifyListeners();
  }

  void setAfName(String value) {
    afName = value;
    afError = null;
    notifyListeners();
  }

  void setAfKind(String value) {
    afKind = value;
    notifyListeners();
  }

  void setAfBalance(String value) {
    afBalance = value;
    notifyListeners();
  }

  void pickAfIcon(String key) {
    afIconKey = key;
    notifyListeners();
  }

  Future<void> submitAccountForm() async {
    final name = afName.trim();
    if (name.isEmpty) {
      afError = 'Ponle un nombre a la cuenta';
      notifyListeners();
      return;
    }
    if (await accountRepo.nameExists(name, exceptId: editingAccountId)) {
      afError = 'Ya tienes una cuenta con ese nombre';
      notifyListeners();
      return;
    }

    final balance = _parseAmount(afBalance);
    final id = editingAccountId;
    await _write(() async {
      if (id == null) {
        await accountRepo.create(
          name: name,
          kind: afKind.trim(),
          iconKey: afIconKey,
          initialBalance: balance,
        );
      } else {
        await accountRepo.update(
          id,
          name: name,
          kind: afKind.trim(),
          iconKey: afIconKey,
          balance: balance,
        );
      }
    });

    accountFormOpen = false;
    editingAccountId = null;
    afError = null;
    notifyListeners();
  }

  Future<void> askDeleteAccount(String id) async {
    pendingDeleteId = id;
    accountFormOpen = false;
    pendingDeleteExpenses = await accountRepo.expenseCount(id);
    notifyListeners();
  }

  void cancelDeleteAccount() {
    pendingDeleteId = null;
    pendingDeleteExpenses = 0;
    notifyListeners();
  }

  Future<void> confirmDeleteAccount() async {
    final id = pendingDeleteId;
    if (id == null) return;
    await _write(() => accountRepo.softDelete(id));
    pendingDeleteId = null;
    pendingDeleteExpenses = 0;
    notifyListeners();
  }

  Future<void> archivePendingAccount() async {
    final id = pendingDeleteId;
    if (id == null) return;
    await _write(() => accountRepo.setArchived(id, true));
    pendingDeleteId = null;
    pendingDeleteExpenses = 0;
    notifyListeners();
  }

  /// Saldo sin separadores de miles, para prellenar el campo editable.
  String _plain(double n) =>
      n == n.roundToDouble() ? n.round().toString() : n.toString();
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
