import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/app/router/app_screen.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/app/state/app_state.dart';
import 'package:gastegi/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:gastegi/features/accounts/presentation/providers/account_form_notifier.dart';
import 'package:gastegi/features/accounts/presentation/providers/transfer_form_notifier.dart';
import 'package:gastegi/features/categories/data/repositories/category_repository_impl.dart';
import 'package:gastegi/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:gastegi/features/expenses/presentation/models/history_range.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/test_db.dart';

void main() {
  setUpAll(initTestLocale);

  late Database db;
  late ExpenseRepositoryImpl expenses;
  late AccountRepositoryImpl accounts;
  late String categoryId;

  setUp(() async {
    db = await openTestDb();
    expenses = ExpenseRepositoryImpl(db);
    accounts = AccountRepositoryImpl(db);
    categoryId = (await CategoryRepositoryImpl(db).all()).first.id; // Comida
  });
  tearDown(() async => db.close());

  Future<void> addExpense(
    DateTime date,
    double amount, {
    String? accountId,
  }) async {
    await expenses.create(
      date: date,
      description: 'Gasto',
      categoryId: categoryId,
      accountId: accountId,
      amount: amount,
    );
  }

  group('app recién instalada', () {
    test('no produce NaN en ningún cálculo derivado', () async {
      final state = await buildState(db);

      expect(state.total, 0);
      expect(state.patrimonio, 0);
      expect(state.prevTotal, 0);
      expect(state.pct(0, 0), 0);
      expect(state.cmpNowFrac, 0);
      expect(state.cmpPrevFrac, 0);
      expect(state.canCompare, isFalse);
      expect(state.deltaLabel, '');
      expect(state.hasNoExpensesAtAll, isTrue);
      expect(state.historyGroups, isEmpty);

      // Todas las categorías a 0 y sin alertas, no "excedido" por dividir mal.
      for (final row in state.budgetRows) {
        expect(row.ratio, 0);
        expect(row.alert, isFalse);
        expect(row.over, isFalse);
      }
    });

    test('trae las 6 categorías y ninguna cuenta', () async {
      final state = await buildState(db);
      expect(state.categories, hasLength(6));
      expect(state.accounts, isEmpty);
      expect(state.canTransfer, isFalse);
      expect(state.saveDisabled, isTrue);
    });
  });

  test('dailyTotals tiene tantas posiciones como días el mes', () async {
    final feb = await buildState(db, now: DateTime(2026, 2, 10));
    expect(feb.dailyTotals, hasLength(28));

    final ago = await buildState(db, now: DateTime(2026, 8, 12));
    expect(ago.dailyTotals, hasLength(31));
  });

  test('el total solo cuenta el mes en curso', () async {
    await addExpense(DateTime(2026, 8, 5), 100);
    await addExpense(DateTime(2026, 8, 11), 50);
    await addExpense(DateTime(2026, 7, 20), 999);

    final state = await buildState(db);

    expect(state.total, 150);
    expect(state.prevTotal, 999);
    expect(state.canCompare, isTrue);
    expect(state.catTotals['Comida'], 150);
    // La última barra de los 6 meses es el mes en curso.
    expect(state.monthTotals.last, ('Ago', 150.0));
    expect(state.monthTotals, hasLength(6));
  });

  test('historyGroups etiqueta y ordena por fecha real', () async {
    await addExpense(DateTime(2026, 8, 12), 10);
    await addExpense(DateTime(2026, 8, 11), 20);
    await addExpense(DateTime(2026, 8, 3), 30);

    final state = await buildState(db);
    expect(state.historyGroups.map((g) => g.$1), [
      'Hoy',
      'Ayer',
      '3 de agosto',
    ]);
  });

  test('los rangos del historial alcanzan el mes anterior', () async {
    // A 3 de agosto, "últimos 7 días" debe incluir el 28 de julio.
    await addExpense(DateTime(2026, 7, 28), 40);
    await addExpense(DateTime(2026, 8, 2), 10);

    final state = await buildState(db, now: DateTime(2026, 8, 3));

    state.setFilterRange(HistoryRange.month);
    expect(state.filteredExpenses, hasLength(1));

    state.setFilterRange(HistoryRange.last7);
    expect(state.filteredExpenses, hasLength(2));
  });

  test('selCatWeeks reparte hasta el último día real del mes', () async {
    await addExpense(DateTime(2026, 2, 25), 60);
    final state = await buildState(db, now: DateTime(2026, 2, 10));
    state.openCategory('Comida');

    // Febrero acaba el 28: el día 25 cae en la cuarta semana.
    expect(state.selCatWeeks.last.$2, 60);
  });

  test('guardar un gasto lo persiste y descuenta el saldo', () async {
    final accountId = await accounts.create(
      name: 'Efectivo',
      kind: 'Dinero en mano',
      iconKey: 'money',
      initialBalance: 200,
    );
    final state = await buildState(db);

    state.pickAddCat('Comida');
    state.pickAddAcct(accountId);
    state.keypadTap('5');
    state.keypadTap('0');
    expect(state.saveDisabled, isFalse);

    await state.saveExpense();

    expect(state.total, 50);
    expect(state.patrimonio, 150);
    expect(state.screen, Screen.history);
    // El formulario queda limpio para el siguiente gasto.
    expect(state.addAmount, '');
    expect(state.addCat, isNull);

    // Y está en disco, no solo en memoria.
    expect(await expenses.count(), 1);
  });

  test('el teclado limita a una coma y 7 dígitos', () async {
    final state = await buildState(db);

    state.keypadTap(',');
    expect(state.addAmount, '0,');
    state.keypadTap(',');
    expect(state.addAmount, '0,');

    state.addAmount = '';
    for (var i = 0; i < 10; i++) {
      state.keypadTap('9');
    }
    expect(state.addAmount.length, 7);
    state.keypadTap('⌫');
    expect(state.addAmount.length, 6);
  });

  test('las alertas de presupuesto usan el umbral del 90 %', () async {
    // Ocio tiene 200 de presupuesto; 182 son el 91 %.
    final ocio = (await CategoryRepositoryImpl(
      db,
    ).all()).firstWhere((c) => c.name == 'Ocio');
    await expenses.create(
      date: testNow,
      description: 'Concierto',
      categoryId: ocio.id,
      accountId: null,
      amount: 182,
    );

    final state = await buildState(db);
    final byName = {for (final b in state.budgetRows) b.category.name: b};

    expect(byName['Ocio']!.alert, isTrue);
    expect(byName['Ocio']!.over, isFalse);
    expect(byName['Comida']!.alert, isFalse);
  });

  // Este test vigila que ningún trozo de `_normalizeSelections` se pierda por
  // el camino al repartirlo entre funcionalidades: toca a la vez la selección
  // de cuenta del nuevo gasto y la del formulario de transferencia.
  test(
    'borrar una cuenta seleccionada no deja ningún selector apuntando a ella',
    () async {
      final id = await accounts.create(
        name: 'Efectivo',
        kind: '',
        iconKey: 'money',
        initialBalance: 10,
      );
      final container = await buildLoadedContainer(db);
      final state = container.read(appStateProvider);
      state.pickAddAcct(id);
      // Fuerza la construcción del formulario de transferencia para que su
      // normalización quede suscrita antes del borrado.
      expect(container.read(transferFormProvider).fromId, id);

      final form = container.read(accountFormProvider.notifier);
      await form.askDelete(id);
      await form.confirmDelete();

      expect(container.read(appDataProvider).accounts, isEmpty);
      expect(state.addAccountId, isNull);
      expect(container.read(transferFormProvider).fromId, isNull);
    },
  );
}
