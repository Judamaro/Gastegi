import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:gastegi/features/categories/data/repositories/category_repository_impl.dart';
import 'package:gastegi/features/categories/domain/entities/category.dart';
import 'package:gastegi/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:gastegi/features/expenses/presentation/providers/add_expense_notifier.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/test_db.dart';

void main() {
  setUpAll(initTestLocale);

  late Database db;
  late String comidaId;

  setUp(() async {
    db = await openTestDb();
    comidaId = (await CategoryRepositoryImpl(db).all()).first.id; // Comida
  });
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

    form.pickCategory(comidaId);
    form.pickAccount(accountId);
    form.setAmount('50');
    expect(container.read(addExpenseProvider).saveDisabled, isFalse);

    expect(await form.save(), isTrue);

    expect(container.read(appDataProvider).total, 50);
    expect(container.read(appDataProvider).patrimonio, 150);
    // El formulario queda limpio para el siguiente gasto.
    expect(container.read(addExpenseProvider).amount, '');
    expect(container.read(addExpenseProvider).categoryId, isNull);

    // Y está en disco, no solo en memoria.
    expect(await ExpenseRepositoryImpl(db).count(), 1);
  });

  test('renombrar la categoría elegida no deselecciona el chip', () async {
    // El estado guarda el id: renombrar desde Presupuestos con el formulario
    // abierto ya no borra lo elegido. Con el nombre, la normalización lo daba
    // por desaparecido y el chip se apagaba solo.
    final container = await buildLoadedContainer(db);
    final form = container.read(addExpenseProvider.notifier);
    form.pickCategory(comidaId);

    final comida = container
        .read(appDataProvider)
        .categories
        .firstWhere((Category c) => c.id == comidaId);
    await CategoryRepositoryImpl(db).update(
      comidaId,
      name: 'Alimentación',
      colorValue: comida.colorValue,
      iconKey: comida.iconKey,
      budget: comida.budget,
    );
    await container.read(appDataProvider.notifier).load();

    expect(container.read(addExpenseProvider).categoryId, comidaId);
  });

  test('borrar la categoría elegida sí apaga el chip', () async {
    // Lo que el id no puede salvar: `save()` la buscaría y no la encontraría.
    final ocio = (await CategoryRepositoryImpl(
      db,
    ).all()).firstWhere((c) => c.name == 'Ocio');
    final container = await buildLoadedContainer(db);
    container.read(addExpenseProvider.notifier).pickCategory(ocio.id);

    await CategoryRepositoryImpl(db).softDelete(ocio.id);
    await container.read(appDataProvider.notifier).load();

    expect(container.read(addExpenseProvider).categoryId, isNull);
  });

  test('sin cuenta o sin importe no se guarda nada', () async {
    final container = await buildLoadedContainer(db);
    final form = container.read(addExpenseProvider.notifier);

    form.pickCategory(comidaId);
    form.setAmount('5');

    expect(container.read(addExpenseProvider).saveDisabled, isTrue);
    expect(await form.save(), isFalse);
    expect(await ExpenseRepositoryImpl(db).count(), 0);
  });

  // Los topes de dígitos y la regla del único separador decimal ya no viven
  // aquí: las aplica `MoneyInputFormatter` sobre `MoneyLabels.canonical`, y las
  // prueban `money_test.dart` y `money_input_formatter_test.dart`. Lo que sí
  // decide este estado es cuándo el importe basta para guardar.
  test('un importe a medio escribir no habilita Guardar', () async {
    final accountId = await AccountRepositoryImpl(
      db,
    ).create(name: 'Efectivo', kind: '', iconKey: 'money', initialBalance: 100);
    final container = await buildLoadedContainer(db);
    final form = container.read(addExpenseProvider.notifier);

    form.pickCategory(comidaId);
    form.pickAccount(accountId);

    // Lo que deja el campo cuando solo se ha tecleado la coma.
    form.setAmount('.');
    expect(container.read(addExpenseProvider).saveDisabled, isTrue);

    form.setAmount('12.');
    expect(container.read(addExpenseProvider).saveDisabled, isFalse);
  });

  test('sin descripción se usa el nombre de la categoría', () async {
    final accountId = await AccountRepositoryImpl(
      db,
    ).create(name: 'Efectivo', kind: '', iconKey: 'money', initialBalance: 100);
    final container = await buildLoadedContainer(db);
    final form = container.read(addExpenseProvider.notifier);

    form.pickCategory(comidaId);
    form.pickAccount(accountId);
    form.setAmount('9');
    await form.save();

    expect(container.read(appDataProvider).expenses.single.desc, 'Comida');
  });
}
