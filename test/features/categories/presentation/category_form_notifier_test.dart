import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/features/categories/data/repositories/category_repository_impl.dart';
import 'package:gastegi/features/categories/domain/failures.dart';
import 'package:gastegi/features/categories/presentation/providers/category_form_notifier.dart';
import 'package:gastegi/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/test_db.dart';

void main() {
  setUpAll(initTestLocale);

  late Database db;

  setUp(() async => db = await openTestDb());
  tearDown(() async => db.close());

  test('con el cerrojo echado el formulario no se da por guardado', () async {
    // El cerrojo es de toda la app, así que la escritura en vuelo puede venir
    // de cualquier pantalla. Antes, `submit` leía el `failure` a `null` —que
    // nadie había tocado— como éxito, y cerraba el formulario tirando lo
    // tecleado sin haber guardado nada.
    final container = await buildLoadedContainer(db);
    final gate = Completer<void>();
    final retenida = container
        .read(appDataProvider.notifier)
        .write(() => gate.future);

    final form = container.read(categoryFormProvider.notifier);
    form
      ..open()
      ..setName('Viajes')
      ..setBudget('300');
    await form.submit();

    final state = container.read(categoryFormProvider);
    expect(state.open, isTrue, reason: 'el formulario sigue abierto');
    expect(state.name, 'Viajes', reason: 'con lo tecleado dentro');
    expect(
      container.read(appDataProvider).categoryNamed('Viajes'),
      isNull,
      reason: 'y no se ha guardado nada',
    );

    gate.complete();
    await retenida;
  });

  test('crear una categoría la añade y suma en el presupuesto', () async {
    final container = await buildLoadedContainer(db);
    final budgetBefore = container.read(appDataProvider).totalBudget;
    final form = container.read(categoryFormProvider.notifier);

    form.open();
    form.setName('Viajes');
    form.setBudget('300');
    form.pickIcon('bus');
    form.pickColor(0xFF419DDA);
    await form.submit();

    final data = container.read(appDataProvider);
    final viajes = data.categoryNamed('Viajes')!;
    expect(viajes.budget, 300);
    expect(viajes.iconKey, 'bus');
    expect(viajes.colorValue, 0xFF419DDA);
    expect(data.totalBudget, budgetBefore + 300);
    // El formulario se cierra solo cuando ha guardado.
    expect(container.read(categoryFormProvider).open, isFalse);
  });

  test('el nombre vacío se rechaza sin tocar la base de datos', () async {
    final container = await buildLoadedContainer(db);
    final form = container.read(categoryFormProvider.notifier);

    form.open();
    form.setBudget('300');
    await form.submit();

    expect(
      container.read(categoryFormProvider).failure,
      isA<EmptyCategoryName>(),
    );
    expect(container.read(appDataProvider).categories, hasLength(6));
  });

  test('el nombre duplicado se rechaza y deja corregir', () async {
    final container = await buildLoadedContainer(db);
    final form = container.read(categoryFormProvider.notifier);

    form.open();
    form.setName('comida');
    await form.submit();

    expect(
      container.read(categoryFormProvider).failure,
      isA<DuplicateCategoryName>(),
    );
    expect(container.read(categoryFormProvider).open, isTrue);
    expect(container.read(appDataProvider).categories, hasLength(6));

    form.setName('Comida fuera');
    expect(container.read(categoryFormProvider).failure, isNull);
  });

  test('editar sin tocar el presupuesto no lo altera', () async {
    // El prellenado y la lectura del campo tienen que hablar el mismo idioma;
    // es el mismo tropiezo que ya cazó el formulario de cuentas.
    final container = await buildLoadedContainer(db);
    final ocio = container.read(appDataProvider).categoryNamed('Ocio')!;
    final form = container.read(categoryFormProvider.notifier);

    form.open(ocio);
    expect(container.read(categoryFormProvider).budget, '200.00');

    form.setName('Ocio y cultura');
    await form.submit();

    final data = container.read(appDataProvider);
    expect(data.categoryNamed('Ocio y cultura')!.budget, 200);
    expect(data.categoryNamed('Ocio y cultura')!.id, ocio.id);
  });

  test('bajar el presupuesto por debajo del gasto marca el exceso', () async {
    final ocio = (await CategoryRepositoryImpl(
      db,
    ).all()).firstWhere((c) => c.name == 'Ocio');
    await ExpenseRepositoryImpl(db).create(
      date: testNow,
      description: 'Conciertos',
      categoryId: ocio.id,
      accountId: null,
      amount: 182,
    );
    final container = await buildLoadedContainer(db);
    final form = container.read(categoryFormProvider.notifier);

    // Con 200 de presupuesto, 182 son el 91 %: avisa pero no excede.
    var row = container
        .read(appDataProvider)
        .budgetRows
        .firstWhere((b) => b.category.name == 'Ocio');
    expect(row.alert, isTrue);
    expect(row.over, isFalse);

    form.open(container.read(appDataProvider).categoryNamed('Ocio')!);
    form.setBudget('150');
    await form.submit();

    row = container
        .read(appDataProvider)
        .budgetRows
        .firstWhere((b) => b.category.name == 'Ocio');
    expect(row.over, isTrue);
  });

  test('la categoría sin gastos se borra', () async {
    final container = await buildLoadedContainer(db);
    final ocio = container.read(appDataProvider).categoryNamed('Ocio')!;
    final form = container.read(categoryFormProvider.notifier);

    await form.askDelete(ocio.id);
    expect(container.read(categoryFormProvider).pendingDeleteExpenses, 0);
    await form.confirmDelete();

    expect(container.read(appDataProvider).categoryNamed('Ocio'), isNull);
    expect(container.read(categoryFormProvider).pendingDeleteId, isNull);
  });

  test('la categoría con gastos no se borra', () async {
    final ocio = (await CategoryRepositoryImpl(
      db,
    ).all()).firstWhere((c) => c.name == 'Ocio');
    await ExpenseRepositoryImpl(db).create(
      date: testNow,
      description: 'Cine',
      categoryId: ocio.id,
      accountId: null,
      amount: 12,
    );
    final container = await buildLoadedContainer(db);
    final form = container.read(categoryFormProvider.notifier);

    await form.askDelete(ocio.id);
    expect(container.read(categoryFormProvider).pendingDeleteExpenses, 1);

    await form.confirmDelete();

    expect(container.read(appDataProvider).categoryNamed('Ocio'), isNotNull);
    // Y la confirmación se queda abierta: el usuario tocó «Eliminar» y tiene
    // que ver por qué no ha pasado nada.
    expect(container.read(categoryFormProvider).pendingDeleteId, ocio.id);
  });

  test('un gasto registrado mientras se confirma corta el borrado', () async {
    // La carrera que el recuento del estado no puede ver: se abre la
    // confirmación con la categoría vacía y el gasto entra antes del toque en
    // «Eliminar». Quien decide es el caso de uso, que cuenta en ese momento.
    final ocio = (await CategoryRepositoryImpl(
      db,
    ).all()).firstWhere((c) => c.name == 'Ocio');
    final container = await buildLoadedContainer(db);
    final form = container.read(categoryFormProvider.notifier);

    await form.askDelete(ocio.id);
    expect(container.read(categoryFormProvider).pendingDeleteExpenses, 0);

    await ExpenseRepositoryImpl(db).create(
      date: testNow,
      description: 'Cine',
      categoryId: ocio.id,
      accountId: null,
      amount: 12,
    );
    await form.confirmDelete();

    expect(container.read(appDataProvider).categoryNamed('Ocio'), isNotNull);
    // Y el aviso se pone al día, para que la confirmación explique el motivo.
    expect(container.read(categoryFormProvider).pendingDeleteExpenses, 1);
    expect(container.read(categoryFormProvider).pendingDeleteId, ocio.id);
  });
}
