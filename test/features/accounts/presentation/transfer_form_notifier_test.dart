import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:gastegi/features/accounts/presentation/providers/transfer_form_notifier.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/test_db.dart';

/// El formulario de traspaso no puede quedar apuntando a la misma cuenta en
/// los dos lados.
///
/// `TransferBetweenAccounts` lo rechaza, pero devolviendo `false` sin más: el
/// formulario se queda abierto y no se dice nada. Quien lo tiene que impedir
/// es el estado, y esa garantía descansa en que **todos** los mutadores pasen
/// por la normalización.
void main() {
  late Database db;

  setUp(() async => db = await openTestDb());
  tearDown(() async => db.close());

  Future<List<String>> seedAccounts(int n) async {
    final repo = AccountRepositoryImpl(db);
    return [
      for (var i = 0; i < n; i++)
        await repo.create(
          name: 'Cuenta $i',
          kind: 'Banco',
          iconKey: 'bank',
          initialBalance: 1000,
        ),
    ];
  }

  test(
    'elegir como destino la cuenta de origen no deja las dos iguales',
    () async {
      final ids = await seedAccounts(3);
      final container = await buildLoadedContainer(db);
      final form = container.read(transferFormProvider.notifier);

      form.open();
      form.pickFrom(ids[0]);
      form.pickTo(ids[0]);

      final state = container.read(transferFormProvider);
      expect(state.fromId, ids[0]);
      expect(state.toId, isNot(ids[0]));
      expect(state.toId, isNotNull);
    },
  );

  test('elegir como origen la cuenta de destino mueve el destino', () async {
    final ids = await seedAccounts(3);
    final container = await buildLoadedContainer(db);
    final form = container.read(transferFormProvider.notifier);

    form.open();
    form.pickTo(ids[2]);
    form.pickFrom(ids[2]);

    final state = container.read(transferFormProvider);
    expect(state.fromId, ids[2]);
    expect(state.toId, isNot(ids[2]));
  });

  test('escribir el importe no descoloca la selección', () async {
    final ids = await seedAccounts(2);
    final container = await buildLoadedContainer(db);
    final form = container.read(transferFormProvider.notifier);

    form.open();
    form.pickFrom(ids[1]);
    form.setAmount('50');

    final state = container.read(transferFormProvider);
    expect(state.fromId, ids[1]);
    expect(state.toId, ids[0]);
    expect(state.amountValue, 50);
  });

  test(
    'borrar la cuenta seleccionada la reemplaza, no la deja colgando',
    () async {
      final ids = await seedAccounts(2);
      final container = await buildLoadedContainer(db);
      final form = container.read(transferFormProvider.notifier);

      form.open();
      form.pickFrom(ids[0]);
      expect(container.read(transferFormProvider).fromId, ids[0]);

      await AccountRepositoryImpl(db).softDelete(ids[0]);
      await container.read(appDataProvider.notifier).load();

      expect(container.read(transferFormProvider).fromId, ids[1]);
    },
  );

  test('copyWith distingue "no me pases el campo" de "ponlo a null"', () async {
    final ids = await seedAccounts(2);
    final container = await buildLoadedContainer(db);
    final base = container.read(transferFormProvider);

    expect(base.copyWith().toId, base.toId);
    expect(base.copyWith(toId: null).toId, isNull);
    expect(base.copyWith(toId: ids[1]).toId, ids[1]);
    expect(base.copyWith(amount: '5').fromId, base.fromId);
  });
}
