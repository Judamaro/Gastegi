import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/features/categories/data/repositories/category_repository_impl.dart';
import 'package:gastegi/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:gastegi/features/expenses/presentation/models/history_range.dart';
import 'package:gastegi/features/expenses/presentation/providers/history_notifier.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/test_db.dart';

void main() {
  setUpAll(initTestLocale);

  late Database db;
  late ExpenseRepositoryImpl expenses;
  late String comidaId;

  setUp(() async {
    db = await openTestDb();
    expenses = ExpenseRepositoryImpl(db);
    comidaId = (await CategoryRepositoryImpl(db).all()).first.id; // Comida
  });
  tearDown(() async => db.close());

  Future<void> addExpense(DateTime date, double amount, {String? categoryId}) =>
      expenses.create(
        date: date,
        description: 'Gasto',
        categoryId: categoryId ?? comidaId,
        accountId: null,
        amount: amount,
      );

  test('historyGroups agrupa por día y ordena del más reciente', () async {
    await addExpense(DateTime(2026, 8, 12), 10);
    await addExpense(DateTime(2026, 8, 11), 20);
    await addExpense(DateTime(2026, 8, 3), 30);

    final container = await buildLoadedContainer(db);

    // Días, no etiquetas: el texto lo pone la pantalla con el idioma activo.
    expect(container.read(historyGroupsProvider).map((g) => g.$1), [
      DateTime(2026, 8, 12),
      DateTime(2026, 8, 11),
      DateTime(2026, 8, 3),
    ]);
  });

  test('los rangos alcanzan el mes anterior', () async {
    // A 3 de agosto, "últimos 7 días" debe incluir el 28 de julio.
    await addExpense(DateTime(2026, 7, 28), 40);
    await addExpense(DateTime(2026, 8, 2), 10);

    final container = await buildLoadedContainer(db, now: DateTime(2026, 8, 3));
    final filters = container.read(historyFilterProvider.notifier);

    filters.setRange(HistoryRange.month);
    expect(container.read(filteredExpensesProvider), hasLength(1));

    filters.setRange(HistoryRange.last7);
    expect(container.read(filteredExpensesProvider), hasLength(2));
  });

  test('el filtro de categoría nulo significa todas', () async {
    final ocio = (await CategoryRepositoryImpl(
      db,
    ).all()).firstWhere((c) => c.name == 'Ocio');
    await addExpense(testNow, 10);
    await addExpense(testNow, 20, categoryId: ocio.id);

    final container = await buildLoadedContainer(db);
    final filters = container.read(historyFilterProvider.notifier);

    expect(container.read(filteredExpensesProvider), hasLength(2));

    filters.setCategory('Ocio');
    expect(container.read(filteredExpensesProvider), hasLength(1));

    filters.setCategory(null);
    expect(container.read(filteredExpensesProvider), hasLength(2));
  });

  test('la búsqueda mira descripción y categoría', () async {
    await addExpense(testNow, 10);

    final container = await buildLoadedContainer(db);
    final filters = container.read(historyFilterProvider.notifier);

    filters.setSearch('comi'); // por categoría, sin tildes ni mayúsculas
    expect(container.read(filteredExpensesProvider), hasLength(1));

    filters.setSearch('gast'); // por descripción
    expect(container.read(filteredExpensesProvider), hasLength(1));

    filters.setSearch('nada de esto');
    expect(container.read(filteredExpensesProvider), isEmpty);
  });
}
