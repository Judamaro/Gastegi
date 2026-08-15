import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:gastegi/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:gastegi/features/expenses/presentation/providers/add_expense_notifier.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/test_db.dart';

void main() {
  setUpAll(initTestLocale);

  late Database db;

  setUp(() async => db = await openTestDb());
  tearDown(() async => db.close());

  test('guardar un gasto lo persiste y descuenta el saldo', () async {
    final accountId = await AccountRepositoryImpl(db).create(
      name: 'Efectivo',
      kind: 'Dinero en mano',
      iconKey: 'money',
      initialBalance: 200,
    );
    final container = await buildLoadedContainer(db);
    final form = container.read(addExpenseProvider.notifier);

    form.pickCategory('Comida');
    form.pickAccount(accountId);
    form.keypadTap('5');
    form.keypadTap('0');
    expect(container.read(addExpenseProvider).saveDisabled, isFalse);

    expect(await form.save(), isTrue);

    expect(container.read(appDataProvider).total, 50);
    expect(container.read(appDataProvider).patrimonio, 150);
    // El formulario queda limpio para el siguiente gasto.
    expect(container.read(addExpenseProvider).amount, '');
    expect(container.read(addExpenseProvider).categoryName, isNull);

    // Y está en disco, no solo en memoria.
    expect(await ExpenseRepositoryImpl(db).count(), 1);
  });

  test('sin cuenta o sin importe no se guarda nada', () async {
    final container = await buildLoadedContainer(db);
    final form = container.read(addExpenseProvider.notifier);

    form.pickCategory('Comida');
    form.keypadTap('5');

    expect(container.read(addExpenseProvider).saveDisabled, isTrue);
    expect(await form.save(), isFalse);
    expect(await ExpenseRepositoryImpl(db).count(), 0);
  });

  test('el teclado limita a una coma y 7 dígitos', () async {
    final container = await buildLoadedContainer(db);
    final form = container.read(addExpenseProvider.notifier);
    String amount() => container.read(addExpenseProvider).amount;

    form.keypadTap(',');
    expect(amount(), '0,');
    form.keypadTap(',');
    expect(amount(), '0,');

    for (var i = 0; i < 10; i++) {
      form.keypadTap('9');
    }
    // '0,' más siete dígitos: el límite cuenta dígitos, no caracteres.
    expect(amount().replaceAll(',', '').length, 7);

    form.keypadTap('⌫');
    expect(amount().replaceAll(',', '').length, 6);
  });

  test('sin descripción se usa el nombre de la categoría', () async {
    final accountId = await AccountRepositoryImpl(
      db,
    ).create(name: 'Efectivo', kind: '', iconKey: 'money', initialBalance: 100);
    final container = await buildLoadedContainer(db);
    final form = container.read(addExpenseProvider.notifier);

    form.pickCategory('Comida');
    form.pickAccount(accountId);
    form.keypadTap('9');
    await form.save();

    expect(container.read(appDataProvider).expenses.single.desc, 'Comida');
  });
}
