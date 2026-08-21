import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/features/categories/data/repositories/category_repository_impl.dart';
import 'package:gastegi/features/categories/domain/failures.dart';
import 'package:gastegi/features/categories/domain/usecases/delete_category.dart';
import 'package:gastegi/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../helpers/test_db.dart';

/// La regla que sostiene el enlace por id: una categoría con gastos no se
/// borra.
///
/// Si se saltara, sus gastos quedarían apuntando a una fila que `all()` ya no
/// devuelve, y la dona y las barras dejarían de sumar el total del mes sin
/// lanzar nada. Por eso contar y decidir pasan aquí, juntos, y no en la
/// pantalla.
void main() {
  late Database db;
  late CategoryRepositoryImpl categories;
  late DeleteCategory deleteCategory;

  setUp(() async {
    db = await openTestDb();
    categories = CategoryRepositoryImpl(db);
    deleteCategory = DeleteCategory(categories);
  });
  tearDown(() async => db.close());

  Future<String> idOf(String name) async =>
      (await categories.all()).firstWhere((c) => c.name == name).id;

  test('sin gastos, la borra', () async {
    final ocio = await idOf('Ocio');

    expect(await deleteCategory(ocio), isNull);
    expect((await categories.all()).any((c) => c.id == ocio), isFalse);
  });

  test('con gastos, devuelve el fallo con su recuento y no la borra', () async {
    final ocio = await idOf('Ocio');
    for (final importe in [12.0, 30.0]) {
      await ExpenseRepositoryImpl(db).create(
        date: testNow,
        description: 'Cine',
        categoryId: ocio,
        accountId: null,
        amount: importe,
      );
    }

    final failure = await deleteCategory(ocio);

    expect(failure, isA<CategoryHasExpenses>());
    expect((failure! as CategoryHasExpenses).count, 2);
    expect((await categories.all()).any((c) => c.id == ocio), isTrue);
  });

  test('un gasto borrado ya no cuenta', () async {
    final ocio = await idOf('Ocio');
    final expenses = ExpenseRepositoryImpl(db);
    final id = await expenses.create(
      date: testNow,
      description: 'Cine',
      categoryId: ocio,
      accountId: null,
      amount: 12,
    );
    await expenses.softDelete(id);

    expect(await deleteCategory(ocio), isNull);
  });
}
