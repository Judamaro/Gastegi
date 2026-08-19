import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/features/categories/data/repositories/category_repository_impl.dart';
import 'package:gastegi/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../helpers/test_db.dart';

void main() {
  late Database db;
  late CategoryRepositoryImpl repo;

  setUp(() async {
    db = await openTestDb();
    repo = CategoryRepositoryImpl(db);
  });
  tearDown(() async => db.close());

  test('la categoría nueva se coloca al final de la lista', () async {
    // La siembra deja seis con sort_order 0..5, y el orden es el del diseño:
    // una categoría nueva no debe colarse entre medias.
    await repo.create(
      name: 'Viajes',
      colorValue: 0xFF796CBF,
      iconKey: 'popcorn',
      budget: 300,
    );

    final all = await repo.all();
    expect(all, hasLength(7));
    expect(all.last.name, 'Viajes');
    expect(all.last.budget, 300);
  });

  test('editar una categoría no toca las columnas que no se pasan', () async {
    final comida = (await repo.all()).firstWhere((c) => c.name == 'Comida');
    final before = (await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [comida.id],
    )).single;

    await repo.update(
      comida.id,
      name: 'Alimentación',
      colorValue: comida.colorValue,
      iconKey: comida.iconKey,
      budget: 620,
    );

    final after = (await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [comida.id],
    )).single;
    expect(after['name'], 'Alimentación');
    expect(after['budget'], 620);
    expect(after['sort_order'], before['sort_order']);
    expect(after['created_at'], before['created_at']);
    expect(after['deleted_at'], isNull);
  });

  test('la categoría borrada sale de la lista pero no de sus gastos', () async {
    final ocio = (await repo.all()).firstWhere((c) => c.name == 'Ocio');
    await ExpenseRepositoryImpl(db).create(
      date: testNow,
      description: 'Cine',
      categoryId: ocio.id,
      accountId: null,
      amount: 12,
    );

    await repo.softDelete(ocio.id);

    expect((await repo.all()).map((c) => c.name), isNot(contains('Ocio')));
    // El JOIN del historial no filtra tombstones a propósito: el gasto sigue
    // mostrando el nombre de su categoría.
    final expenses = await ExpenseRepositoryImpl(db).since(testNow);
    expect(expenses.single.categoryName, 'Ocio');
  });

  test('el nombre duplicado se detecta ignorando mayúsculas', () async {
    final comida = (await repo.all()).firstWhere((c) => c.name == 'Comida');

    expect(await repo.nameExists('COMIDA'), isTrue);
    // La propia categoría no cuenta como duplicada de sí misma al editarla.
    expect(await repo.nameExists('Comida', exceptId: comida.id), isFalse);
    expect(await repo.nameExists('Viajes'), isFalse);

    // Un nombre liberado por un borrado vuelve a estar disponible.
    await repo.softDelete(comida.id);
    expect(await repo.nameExists('Comida'), isFalse);
  });

  test('expenseCount solo cuenta los gastos vivos de esa categoría', () async {
    final all = await repo.all();
    final comida = all.firstWhere((c) => c.name == 'Comida');
    final ocio = all.firstWhere((c) => c.name == 'Ocio');
    final expenses = ExpenseRepositoryImpl(db);

    await expenses.create(
      date: testNow,
      description: 'Menú',
      categoryId: comida.id,
      accountId: null,
      amount: 11,
    );
    final borrado = await expenses.create(
      date: testNow,
      description: 'Café',
      categoryId: comida.id,
      accountId: null,
      amount: 2,
    );
    await expenses.softDelete(borrado);

    expect(await repo.expenseCount(comida.id), 1);
    expect(await repo.expenseCount(ocio.id), 0);
  });
}
