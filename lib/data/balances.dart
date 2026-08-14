import 'package:sqflite/sqflite.dart';

/// Recalcula el saldo de todas las cuentas a partir de sus movimientos.
///
/// El saldo no se mantiene sumando y restando sobre la columna, sino que se
/// deriva de filas inmutables. Dos motivos:
///
/// * **Corrección local**: editar o borrar un gasto no necesita aritmética
///   inversa, y un recálculo repetido siempre da el mismo resultado.
/// * **Sincronización**: un contador mutado no se puede fusionar. Dos teléfonos
///   sin conexión restando 20 cada uno acabarían, bajo last-write-wins, con un
///   saldo equivocado por 20 y sin ninguna señal de que algo falló.
///
/// La columna `accounts.balance` es por tanto una caché: cada dispositivo la
/// recalcula y nunca debe subirse a la nube. Lo que sí es dato es
/// `initial_balance`.
///
/// Debe llamarse **dentro de la misma transacción** que la escritura que la
/// motiva, por eso acepta un [DatabaseExecutor] y no un [Database].
Future<void> recomputeBalances(DatabaseExecutor db) => db.execute('''
      UPDATE accounts SET balance = initial_balance
        - COALESCE((SELECT SUM(amount) FROM expenses
                    WHERE account_id = accounts.id AND deleted_at IS NULL), 0)
        - COALESCE((SELECT SUM(amount) FROM transfers
                    WHERE from_account_id = accounts.id AND deleted_at IS NULL), 0)
        + COALESCE((SELECT SUM(amount) FROM transfers
                    WHERE to_account_id = accounts.id AND deleted_at IS NULL), 0)
      WHERE deleted_at IS NULL
      ''');
