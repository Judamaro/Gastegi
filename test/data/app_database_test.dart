import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/data/account_repository.dart';
import 'package:gastegi/data/app_database.dart';
import 'package:gastegi/data/category_repository.dart';
import 'package:gastegi/data/seed.dart';
import 'package:path/path.dart' as p;
// `Sqflite` (con sus helpers estáticos) solo lo expone el paquete sqflite.
import 'package:sqflite/sqflite.dart' show Sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_db.dart';

void main() {
  late Database db;

  setUp(() async => db = await openTestDb());
  tearDown(() async => db.close());

  test('una BD nueva se siembra solo con las categorías', () async {
    final categories = await CategoryRepository(db).all();
    expect(categories.map((c) => c.name), initialCategories.map((c) => c.$1));

    final comida = categories.firstWhere((c) => c.name == 'Comida');
    expect(comida.budget, 500);
    expect(comida.color.toARGB32(), 0xFFB5ABFC);

    // El dinero lo pone el usuario: ni cuentas ni gastos de mentira.
    expect(
      Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM accounts')),
      0,
    );
    expect(
      Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM expenses')),
      0,
    );
  });

  test(
    'la BD queda en la versión 1 con un device_id y las FK activas',
    () async {
      expect(await db.getVersion(), 1);

      final device = await db.query('sync_state', where: "key = 'device_id'");
      expect(device, hasLength(1));
      expect(device.first['value'] as String, isNotEmpty);

      final pragma = await db.rawQuery('PRAGMA foreign_keys');
      expect(pragma.first.values.first, 1);
    },
  );

  test('reabrir la BD no vuelve a sembrar ni pierde lo guardado', () async {
    // Sobre fichero: `inMemoryDatabasePath` crea una BD nueva en cada apertura
    // y no serviría para comprobar la persistencia.
    final dir = await Directory.systemTemp.createTemp('gastegi_test');
    final path = p.join(dir.path, 'gastegi.db');
    addTearDown(() => dir.delete(recursive: true));

    var reopened = await AppDatabase.openAt(path);
    final beforeIds = (await CategoryRepository(
      reopened,
    ).all()).map((c) => c.id).toList();
    await AccountRepository(reopened).create(
      name: 'Efectivo',
      kind: 'Dinero en mano',
      iconKey: 'money',
      initialBalance: 100,
    );
    await reopened.close();

    reopened = await AppDatabase.openAt(path);
    addTearDown(reopened.close);

    final afterIds = (await CategoryRepository(
      reopened,
    ).all()).map((c) => c.id).toList();
    expect(afterIds, beforeIds, reason: 'no debe re-sembrar categorías');
    expect(await AccountRepository(reopened).all(), hasLength(1));
  });
}
