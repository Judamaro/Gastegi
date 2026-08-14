import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/core/storage/balances.dart';
import 'package:gastegi/data/account_repository.dart';
import 'package:gastegi/data/category_repository.dart';
import 'package:gastegi/data/expense_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_db.dart';

void main() {
  late Database db;
  late ExpenseRepository expenses;
  late AccountRepository accounts;
  late String categoryId;

  setUp(() async {
    db = await openTestDb();
    expenses = ExpenseRepository(db);
    accounts = AccountRepository(db);
    categoryId = (await CategoryRepository(db).all()).first.id;
  });
  tearDown(() async => db.close());

  Future<String> newAccount([double balance = 1000]) => accounts.create(
    name: 'Débito',
    kind: 'Tarjeta',
    iconKey: 'creditCard',
    initialBalance: balance,
  );

  Future<double> balanceOf(String id) async =>
      (await accounts.all()).firstWhere((a) => a.id == id).balance;

  test('crear un gasto descuenta el saldo de su cuenta', () async {
    final accountId = await newAccount();
    await expenses.create(
      date: testNow,
      description: 'Supermercado',
      categoryId: categoryId,
      accountId: accountId,
      amount: 86,
    );
    expect(await balanceOf(accountId), 914);
  });

  test('un gasto con categoría inexistente no se inserta a medias', () async {
    final accountId = await newAccount();
    await expectLater(
      expenses.create(
        date: testNow,
        description: 'Fantasma',
        categoryId: 'no-existe',
        accountId: accountId,
        amount: 50,
      ),
      throwsA(isA<DatabaseException>()),
    );
    // La transacción revierte: ni gasto ni saldo tocado.
    expect(await expenses.count(), 0);
    expect(await balanceOf(accountId), 1000);
  });

  test('borrar un gasto devuelve el saldo', () async {
    final accountId = await newAccount();
    final id = await expenses.create(
      date: testNow,
      description: 'Cine',
      categoryId: categoryId,
      accountId: accountId,
      amount: 32,
    );
    expect(await balanceOf(accountId), 968);

    await expenses.softDelete(id);

    expect(await balanceOf(accountId), 1000);
    expect(await expenses.count(), 0);
    expect(await expenses.since(testNow), isEmpty);
  });

  test('recalcular saldos es idempotente', () async {
    final accountId = await newAccount();
    await expenses.create(
      date: testNow,
      description: 'Gasolina',
      categoryId: categoryId,
      accountId: accountId,
      amount: 45,
    );
    final once = await balanceOf(accountId);

    await recomputeBalances(db);
    await recomputeBalances(db);

    expect(await balanceOf(accountId), once);
  });

  test('monthlyTotals agrupa por mes e ignora los borrados', () async {
    final accountId = await newAccount();
    Future<String> add(DateTime date, double amount) => expenses.create(
      date: date,
      description: 'Gasto',
      categoryId: categoryId,
      accountId: accountId,
      amount: amount,
    );

    await add(DateTime(2026, 7, 3), 100);
    await add(DateTime(2026, 8), 20);
    await add(DateTime(2026, 8, 9), 30);
    final removed = await add(DateTime(2026, 8, 10), 999);
    await expenses.softDelete(removed);

    final totals = await expenses.monthlyTotals(from: DateTime(2026, 3));
    expect(totals['2026-07'], 100);
    expect(totals['2026-08'], 50);
  });

  test('un gasto sin cuenta se lee como "Sin cuenta"', () async {
    await expenses.create(
      date: testNow,
      description: 'Regalo',
      categoryId: categoryId,
      accountId: null,
      amount: 15,
    );
    expect((await expenses.since(testNow)).single.acct, 'Sin cuenta');
  });

  test(
    'since respeta el corte de fecha y ordena de más nuevo a más viejo',
    () async {
      final accountId = await newAccount();
      for (final day in [1, 10, 20]) {
        await expenses.create(
          date: DateTime(2026, 8, day),
          description: 'Día $day',
          categoryId: categoryId,
          accountId: accountId,
          amount: 10,
        );
      }

      final recent = await expenses.since(DateTime(2026, 8, 10));
      expect(recent.map((e) => e.desc), ['Día 20', 'Día 10']);
    },
  );
}
