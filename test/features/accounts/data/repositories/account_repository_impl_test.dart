import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:gastegi/features/categories/data/repositories/category_repository_impl.dart';
import 'package:gastegi/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../helpers/test_db.dart';

void main() {
  late Database db;
  late AccountRepositoryImpl accounts;
  late ExpenseRepositoryImpl expenses;

  setUp(() async {
    db = await openTestDb();
    accounts = AccountRepositoryImpl(db);
    expenses = ExpenseRepositoryImpl(db);
  });
  tearDown(() async => db.close());

  Future<String> newAccount(String name, double balance) => accounts.create(
    name: name,
    kind: 'Prueba',
    iconKey: 'money',
    initialBalance: balance,
  );

  test('alta y edición conservan el saldo que ve el usuario', () async {
    final id = await newAccount('Efectivo', 480);
    expect((await accounts.all()).single.balance, 480);

    await accounts.update(
      id,
      name: 'Cartera',
      kind: 'Dinero en mano',
      iconKey: 'wallet',
      balance: 500,
    );
    final updated = (await accounts.all()).single;
    expect(updated.name, 'Cartera');
    expect(updated.balance, 500);
  });

  test(
    'rechaza nombres duplicados pero permite reutilizar el de una borrada',
    () async {
      final id = await newAccount('Efectivo', 0);
      expect(await accounts.nameExists('Efectivo'), isTrue);
      expect(await accounts.nameExists('Efectivo', exceptId: id), isFalse);

      await accounts.softDelete(id);
      expect(await accounts.nameExists('Efectivo'), isFalse);
      // El índice UNIQUE es parcial, así que el alta no choca con el tombstone.
      await newAccount('Efectivo', 0);
      expect(await accounts.all(), hasLength(1));
    },
  );

  test('la transferencia mueve saldo y no altera el patrimonio', () async {
    final from = await newAccount('Débito', 2350);
    final to = await newAccount('Ahorros', 6100);

    await accounts.transfer(fromId: from, toId: to, amount: 100, date: testNow);

    final byName = {for (final a in await accounts.all()) a.name: a.balance};
    expect(byName['Débito'], 2250);
    expect(byName['Ahorros'], 6200);
    expect(byName.values.reduce((a, b) => a + b), 8450);
  });

  test(
    'la transferencia es no-op con importe no positivo o misma cuenta',
    () async {
      final a = await newAccount('Efectivo', 480);
      final b = await newAccount('Ahorros', 100);

      await accounts.transfer(fromId: a, toId: a, amount: 50, date: testNow);
      await accounts.transfer(fromId: a, toId: b, amount: 0, date: testNow);
      await accounts.transfer(fromId: a, toId: b, amount: -20, date: testNow);

      final byName = {for (final x in await accounts.all()) x.name: x.balance};
      expect(byName['Efectivo'], 480);
      expect(byName['Ahorros'], 100);
    },
  );

  test('borrar una cuenta con gastos no borra los gastos', () async {
    final categoryId = (await CategoryRepositoryImpl(db).all()).first.id;
    final accountId = await newAccount('Débito', 1000);
    await expenses.create(
      date: testNow,
      description: 'Supermercado',
      categoryId: categoryId,
      accountId: accountId,
      amount: 86,
    );
    expect(await accounts.expenseCount(accountId), 1);

    await accounts.softDelete(accountId);

    expect(await accounts.all(), isEmpty);
    final remaining = await expenses.since(testNow);
    expect(remaining, hasLength(1));
    // El historial conserva el nombre: el JOIN no filtra tombstones.
    expect(remaining.single.accountName, 'Débito');
  });

  test('archivar oculta la cuenta sin borrarla', () async {
    final id = await newAccount('Ahorros', 300);
    await accounts.setArchived(id, true);

    expect(await accounts.all(), isEmpty);
    expect(await accounts.all(includeArchived: true), hasLength(1));
  });
}
