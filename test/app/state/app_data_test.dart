import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/app/state/app_data.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/core/utils/formatters.dart';
import 'package:gastegi/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:gastegi/features/accounts/presentation/providers/account_form_notifier.dart';
import 'package:gastegi/features/accounts/presentation/providers/transfer_form_notifier.dart';
import 'package:gastegi/features/categories/data/repositories/category_repository_impl.dart';
import 'package:gastegi/features/categories/presentation/providers/category_detail_providers.dart';
import 'package:gastegi/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:gastegi/features/expenses/presentation/providers/add_expense_notifier.dart';
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

  Future<AppData> loadData({DateTime? now}) async =>
      (await buildLoadedContainer(db, now: now)).read(appDataProvider);

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

  test('write no ejecuta ni miente cuando el cerrojo está echado', () async {
    // El cerrojo es global y a propósito: es lo que evita que un doble toque
    // en «Guardar» cree dos filas. Lo que no puede es callárselo — un `op` que
    // no corre deja intactas las variables que iba a rellenar, y quien llama
    // lee ese silencio como éxito.
    final container = await buildLoadedContainer(db);
    final notifier = container.read(appDataProvider.notifier);

    var innerRan = false;
    late Future<bool> nested;
    final outer = notifier.write(() async {
      nested = notifier.write(() async => innerRan = true);
      await nested;
    });

    expect(await outer, isTrue);
    expect(await nested, isFalse);
    expect(innerRan, isFalse);
  });

  group('app recién instalada', () {
    test('no produce NaN en ningún cálculo derivado', () async {
      final state = await loadData();

      expect(state.total, 0);
      expect(state.patrimonio, 0);
      expect(state.prevTotal, 0);
      expect(percentOf(0, 0), 0);
      expect(state.cmpNowFrac, 0);
      expect(state.cmpPrevFrac, 0);
      expect(state.canCompare, isFalse);
      expect(state.deltaFraction, 0);
      expect(state.hasNoExpensesAtAll, isTrue);

      // Todas las categorías a 0 y sin alertas, no "excedido" por dividir mal.
      for (final row in state.budgetRows) {
        expect(row.ratio, 0);
        expect(row.alert, isFalse);
        expect(row.over, isFalse);
      }
    });

    test('trae las 6 categorías y ninguna cuenta', () async {
      final state = await loadData();
      expect(state.categories, hasLength(6));
      expect(state.accounts, isEmpty);
      expect(state.canTransfer, isFalse);
    });
  });

  test('dailyCatTotals tiene tantas posiciones como días el mes', () async {
    // Una columna por categoría, todas del largo del mes: la tendencia de
    // Inicio indexa por día sin comprobar nada.
    final feb = await loadData(now: DateTime(2026, 2, 10));
    expect(feb.dailyCatTotals.values, everyElement(hasLength(28)));

    final ago = await loadData(now: DateTime(2026, 8, 12));
    expect(ago.dailyCatTotals.values, everyElement(hasLength(31)));
    expect(ago.dailyCatTotals, hasLength(ago.categories.length));
  });

  test('el total solo cuenta el mes en curso', () async {
    await addExpense(DateTime(2026, 8, 5), 100);
    await addExpense(DateTime(2026, 8, 11), 50);
    await addExpense(DateTime(2026, 7, 20), 999);

    final state = await loadData();

    expect(state.total, 150);
    expect(state.prevTotal, 999);
    expect(state.canCompare, isTrue);
    expect(state.catTotals[categoryId], 150);
    // La última barra de los 6 meses es el mes en curso.
    expect(state.monthTotals.last.$1, DateTime(2026, 8));
    expect(state.monthTotals.last.$2, 150.0);
    expect(state.monthTotals, hasLength(6));
    // La variación sale en tanto por uno y con signo, sin formatear: 150
    // frente a 999 es una caída del 85 %.
    expect(state.deltaFraction, closeTo(-0.8498, 0.0001));
  });

  test('los cortes semanales llegan al último día real del mes', () async {
    await addExpense(DateTime(2026, 2, 25), 60);
    final container = await buildLoadedContainer(
      db,
      now: DateTime(2026, 2, 10),
    );

    // Febrero acaba el 28: el día 25 cae en la cuarta semana. Con un corte
    // fijo en el 28 se perdería.
    expect(container.read(categoryWeeksProvider(categoryId)).last, 60);
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

    final state = await loadData();
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
      container.read(addExpenseProvider.notifier).pickAccount(id);
      // Fuerza la construcción del formulario de transferencia para que su
      // normalización quede suscrita antes del borrado.
      expect(container.read(transferFormProvider).fromId, id);

      final form = container.read(accountFormProvider.notifier);
      await form.askDelete(id);
      await form.confirmDelete();

      expect(container.read(appDataProvider).accounts, isEmpty);
      expect(container.read(addExpenseProvider).accountId, isNull);
      expect(container.read(transferFormProvider).fromId, isNull);
    },
  );
}
