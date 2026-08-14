import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:gastegi/features/accounts/domain/failures.dart';
import 'package:gastegi/features/accounts/presentation/providers/account_form_notifier.dart';
import 'package:gastegi/features/accounts/presentation/providers/transfer_form_notifier.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/test_db.dart';

void main() {
  setUpAll(initTestLocale);

  late Database db;

  setUp(() async => db = await openTestDb());
  tearDown(() async => db.close());

  Future<String> newAccount(String name, {double balance = 0}) =>
      AccountRepositoryImpl(
        db,
      ).create(name: name, kind: '', iconKey: 'money', initialBalance: balance);

  test('el nombre de cuenta duplicado se rechaza con mensaje', () async {
    await newAccount('Efectivo');
    final container = await buildLoadedContainer(db);
    final form = container.read(accountFormProvider.notifier);

    form.open();
    form.setName('Efectivo');
    await form.submit();

    expect(
      container.read(accountFormProvider).failure,
      isA<DuplicateAccountName>(),
    );
    // El formulario sigue abierto con lo tecleado, para poder corregirlo.
    expect(container.read(accountFormProvider).open, isTrue);
    expect(container.read(appDataProvider).accounts, hasLength(1));
  });

  test('el nombre vacío se rechaza sin tocar la base de datos', () async {
    final container = await buildLoadedContainer(db);
    final form = container.read(accountFormProvider.notifier);

    form.open();
    await form.submit();

    expect(
      container.read(accountFormProvider).failure,
      isA<EmptyAccountName>(),
    );
    expect(container.read(appDataProvider).accounts, isEmpty);
  });

  test('escribir el nombre limpia el error anterior', () async {
    await newAccount('Efectivo');
    final container = await buildLoadedContainer(db);
    final form = container.read(accountFormProvider.notifier);

    form.open();
    form.setName('Efectivo');
    await form.submit();
    expect(container.read(accountFormProvider).failure, isNotNull);

    form.setName('Efectivo 2');
    expect(container.read(accountFormProvider).failure, isNull);
  });

  test('la transferencia preselecciona origen y destino distintos', () async {
    await newAccount('Débito', balance: 100);
    await newAccount('Ahorros', balance: 50);
    final container = await buildLoadedContainer(db);

    final transfer = container.read(transferFormProvider);
    expect(transfer.fromId, isNotNull);
    expect(transfer.toId, isNotNull);
    expect(transfer.fromId, isNot(transfer.toId));
  });

  test('archivar una cuenta la saca de la lista sin borrarla', () async {
    final id = await newAccount('Débito', balance: 100);
    final container = await buildLoadedContainer(db);
    final form = container.read(accountFormProvider.notifier);

    await form.askDelete(id);
    await form.archivePending();

    expect(container.read(appDataProvider).accounts, isEmpty);
    expect(container.read(accountFormProvider).pendingDeleteId, isNull);
    expect(
      await AccountRepositoryImpl(db).all(includeArchived: true),
      hasLength(1),
    );
  });
}
