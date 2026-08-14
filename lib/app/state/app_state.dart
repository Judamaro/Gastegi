import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/router/app_screen.dart';
import 'package:gastegi/app/state/app_data.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/core/utils/date_utils.dart';
import 'package:gastegi/core/utils/formatters.dart';
import 'package:gastegi/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:gastegi/features/accounts/domain/entities/account.dart';
import 'package:gastegi/features/accounts/domain/failures.dart';
import 'package:gastegi/features/accounts/domain/repositories/account_repository.dart';
import 'package:gastegi/features/accounts/domain/usecases/save_account.dart';
import 'package:gastegi/features/accounts/domain/usecases/transfer_between_accounts.dart';
import 'package:gastegi/features/budgets/presentation/models/budget_row.dart';
import 'package:gastegi/features/categories/domain/entities/category.dart';
import 'package:gastegi/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:gastegi/features/expenses/domain/entities/expense.dart';
import 'package:gastegi/features/expenses/domain/usecases/save_expense.dart';
import 'package:gastegi/features/expenses/presentation/models/history_range.dart';

/// Estado de la interfaz: navegación, formularios, filtros y selecciones.
///
/// Los datos son de [appDataProvider]; aquí solo se delegan. Es una clase de
/// transición: cada funcionalidad se irá llevando su trozo a
/// `features/*/presentation/providers/` hasta que no quede nada.
class AppState extends ChangeNotifier {
  AppState(this._ref) {
    // Al recargar hay que corregir las selecciones **antes** de que nadie
    // repinte: una cuenta o una categoría puede haber desaparecido bajo los
    // pies de un selector. `ref.listen` corre en el mismo microtask que el
    // cambio, mucho antes del siguiente frame.
    _ref.listen(appDataProvider, (_, _) {
      _normalizeSelections();
      notifyListeners();
    });
    addDate = _data.today;
  }

  final Ref _ref;

  AppData get _data => _ref.read(appDataProvider);
  AccountRepository get _accountRepo => _ref.read(accountRepositoryProvider);
  SaveAccount get _saveAccount => SaveAccount(_accountRepo);
  SaveExpense get _saveExpense =>
      SaveExpense(_ref.read(expenseRepositoryProvider));
  TransferBetweenAccounts get _transfer =>
      TransferBetweenAccounts(_accountRepo);

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
  AccountFailure? afError;
  String? pendingDeleteId;

  /// Gastos asociados a la cuenta que se está a punto de borrar; decide si la
  /// confirmación ofrece archivar.
  int pendingDeleteExpenses = 0;

  // Delegados a `core/utils/formatters.dart`. Siguen aquí porque las pantallas
  // todavía llaman `state.fmt(...)`; desaparecen cuando dejen de recibir el
  // estado por constructor.
  String fmt(double n) => formatAmount(n);

  int pct(double part, double whole) => percentOf(part, whole);

  // ── Carga ──────────────────────────────────────────────────────────────

  Future<void> load() => _ref.read(appDataProvider.notifier).load();

  Future<void> _write(Future<void> Function() op) =>
      _ref.read(appDataProvider.notifier).write(op);

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

  // ── Delegados al almacén de datos ──────────────────────────────────────

  List<Category> get categories => _data.categories;
  List<Account> get accounts => _data.accounts;
  List<Expense> get expenses => _data.expenses;

  DateTime get today => _data.today;
  String get currentMonthTitle => _data.currentMonthTitle;
  String get currentMonthName => _data.currentMonthName;
  String get currentMonthAbbr => _data.currentMonthAbbr;
  String get prevMonthName => _data.prevMonthName;
  int get daysInCurrentMonth => _data.daysInCurrentMonth;
  String dayLabelShortOf(DateTime d) => _data.dayLabelShortOf(d);

  bool get hasNoExpensesAtAll => _data.hasNoExpensesAtAll;
  double get total => _data.total;
  Map<String, double> get catTotals => _data.catTotals;
  List<double> get dailyTotals => _data.dailyTotals;
  List<(String, double)> get monthTotals => _data.monthTotals;
  double get prevTotal => _data.prevTotal;
  String get deltaLabel => _data.deltaLabel;
  bool get canCompare => _data.canCompare;
  double get cmpNowFrac => _data.cmpNowFrac;
  double get cmpPrevFrac => _data.cmpPrevFrac;

  Category? categoryOf(String name) => _data.categoryOf(name);
  Account? accountById(String? id) => _data.accountById(id);

  double get patrimonio => _data.patrimonio;
  bool get canTransfer => _data.canTransfer;
  double get totalBudget => _data.totalBudget;
  List<BudgetRow> get budgetRows => _data.budgetRows;

  // ── Historial ──────────────────────────────────────────────────────────

  /// Recorre la ventana entera, no solo el mes: los rangos por días deben poder
  /// alcanzar el mes anterior cuando estamos a principios de mes.
  List<Expense> get filteredExpenses {
    final q = search.trim().toLowerCase();
    return _data.window
        .where(
          (e) =>
              filterRange.includes(e.date, today, _data.monthAnchor) &&
              (filterCat == 'Todas' || e.categoryName == filterCat) &&
              (q.isEmpty ||
                  e.desc.toLowerCase().contains(q) ||
                  e.categoryName.toLowerCase().contains(q)),
        )
        .toList();
  }

  /// Grupos por día, del más reciente al más antiguo.
  List<(String, List<Expense>)> get historyGroups {
    final byDay = <DateTime, List<Expense>>{};
    for (final e in filteredExpenses) {
      byDay.putIfAbsent(dateOnly(e.date), () => []).add(e);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final d in days) (dayLabel(d, today), byDay[d]!)];
  }

  // ── Detalle de categoría ───────────────────────────────────────────────

  Category? get selCategory =>
      selCatName == null ? null : categoryOf(selCatName!);

  List<Expense> get selCatExpenses {
    final cat = selCategory;
    if (cat == null) return const [];
    return expenses.where((e) => e.categoryName == cat.name).toList()
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

  // ── Transferencias ─────────────────────────────────────────────────────

  double get trAmtValue => _parseAmount(trAmt);

  // ── Nuevo gasto ────────────────────────────────────────────────────────

  double get addAmountValue => _parseAmount(addAmount);

  bool get saveDisabled =>
      !(addAmountValue > 0 && addCat != null && addAccountId != null);

  /// Etiqueta del chip que abre el calendario.
  String get addDateLabel =>
      addDateIsPreset ? 'Otra fecha…' : dayLabelShort(addDate, today);

  bool get addDateIsPreset => addDateIsToday || addDateIsYesterday;

  bool get addDateIsToday => sameDay(addDate, today);

  bool get addDateIsYesterday => sameDay(addDate, daysBefore(today, 1));

  void setAddDateToday() => setAddDate(today);

  void setAddDateYesterday() => setAddDate(daysBefore(today, 1));

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
    var done = false;
    await _write(() async {
      done = await _transfer(
        fromId: trFromId,
        toId: trToId,
        amount: trAmtValue,
        date: today,
      );
    });
    if (!done) return;
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

    await _write(
      () => _saveExpense(
        date: addDate,
        description: addDesc,
        category: category,
        accountId: addAccountId,
        amount: addAmountValue,
      ),
    );

    addAmount = '';
    addCat = null;
    addAccountId = null;
    addDesc = '';
    addDate = today;
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
    afIconKey = account?.iconKey ?? 'wallet';
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
    AccountFailure? failure;
    await _write(() async {
      failure = await _saveAccount(
        id: editingAccountId,
        name: afName,
        kind: afKind,
        iconKey: afIconKey,
        balance: _parseAmount(afBalance),
      );
    });
    if (failure != null) {
      afError = failure;
      notifyListeners();
      return;
    }

    accountFormOpen = false;
    editingAccountId = null;
    afError = null;
    notifyListeners();
  }

  Future<void> askDeleteAccount(String id) async {
    pendingDeleteId = id;
    accountFormOpen = false;
    pendingDeleteExpenses = await _accountRepo.expenseCount(id);
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
    await _write(() => _accountRepo.softDelete(id));
    pendingDeleteId = null;
    pendingDeleteExpenses = 0;
    notifyListeners();
  }

  Future<void> archivePendingAccount() async {
    final id = pendingDeleteId;
    if (id == null) return;
    await _write(() => _accountRepo.setArchived(id, true));
    pendingDeleteId = null;
    pendingDeleteExpenses = 0;
    notifyListeners();
  }

  /// Saldo sin separadores de miles, para prellenar el campo editable.
  String _plain(double n) =>
      n == n.roundToDouble() ? n.round().toString() : n.toString();
}

/// El estado de interfaz de la app.
///
/// `ChangeNotifierProvider` es transitorio: existe mientras quede un objeto
/// dios que notifique en bloque. Cada funcionalidad que se lleva su trozo a un
/// `Notifier` propio recorta esta clase, y con la última desaparece.
final appStateProvider = ChangeNotifierProvider<AppState>(AppState.new);
