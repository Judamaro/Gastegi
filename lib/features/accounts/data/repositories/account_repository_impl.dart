import 'package:gastegi/core/storage/balances.dart';
import 'package:gastegi/core/utils/date_utils.dart';
import 'package:gastegi/features/accounts/data/models/account_model.dart';
import 'package:gastegi/features/accounts/domain/entities/account.dart';
import 'package:gastegi/features/accounts/domain/repositories/account_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Lectura y escritura de cuentas y de las transferencias entre ellas.
class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl(this._db);

  final Database _db;
  static const _uuid = Uuid();

  @override
  Future<List<Account>> all({bool includeArchived = false}) async {
    final rows = await _db.query(
      'accounts',
      where: includeArchived
          ? 'deleted_at IS NULL'
          : 'deleted_at IS NULL AND archived = 0',
      orderBy: 'sort_order, name',
    );
    return rows.map(AccountModel.fromRow).toList();
  }

  @override
  Future<String> create({
    required String name,
    required String kind,
    required String iconKey,
    required double initialBalance,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final nextOrder =
        Sqflite.firstIntValue(
          await _db.rawQuery(
            'SELECT COALESCE(MAX(sort_order) + 1, 0) FROM accounts',
          ),
        ) ??
        0;
    await _db.transaction((txn) async {
      await txn.insert('accounts', {
        'id': id,
        'name': name,
        'kind': kind,
        'icon_key': iconKey,
        'initial_balance': initialBalance,
        'balance': initialBalance,
        'sort_order': nextOrder,
        'created_at': now,
        'updated_at': now,
      });
      await recomputeBalances(txn);
    });
    return id;
  }

  /// Edita la cuenta. [balance] es el saldo que el usuario ve y teclea; como el
  /// saldo real se deriva de los movimientos, la diferencia se traslada a
  /// `initial_balance`, que sí es un campo fusionable.
  @override
  Future<void> update(
    String id, {
    required String name,
    required String kind,
    required String iconKey,
    required double balance,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction((txn) async {
      final rows = await txn.query(
        'accounts',
        columns: ['balance', 'initial_balance'],
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows.isEmpty) return;
      final current = (rows.first['balance'] as num).toDouble();
      final initial = (rows.first['initial_balance'] as num).toDouble();
      await txn.update(
        'accounts',
        {
          'name': name,
          'kind': kind,
          'icon_key': iconKey,
          'initial_balance': initial + (balance - current),
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      await recomputeBalances(txn);
    });
  }

  @override
  Future<void> setArchived(String id, bool archived) => _db.update(
    'accounts',
    {
      'archived': archived ? 1 : 0,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    },
    where: 'id = ?',
    whereArgs: [id],
  );

  /// Borrado lógico. Los gastos de la cuenta **no** se tocan: conservan la
  /// referencia y el historial sigue mostrando el nombre de la cuenta.
  @override
  Future<void> softDelete(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction((txn) async {
      await txn.update(
        'accounts',
        {'deleted_at': now, 'updated_at': now},
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: [id],
      );
      await recomputeBalances(txn);
    });
  }

  @override
  Future<int> expenseCount(String id) async =>
      Sqflite.firstIntValue(
        await _db.rawQuery(
          'SELECT COUNT(*) FROM expenses WHERE account_id = ? AND deleted_at IS NULL',
          [id],
        ),
      ) ??
      0;

  @override
  Future<bool> nameExists(String name, {String? exceptId}) async {
    final rows = await _db.query(
      'accounts',
      columns: ['id'],
      where:
          'deleted_at IS NULL AND name = ? COLLATE NOCASE'
          '${exceptId == null ? '' : ' AND id != ?'}',
      whereArgs: [name, ?exceptId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Registra un movimiento entre dos cuentas y recalcula saldos, todo en una
  /// transacción. No hace nada si el importe no es positivo o si origen y
  /// destino coinciden.
  @override
  Future<void> transfer({
    required String fromId,
    required String toId,
    required double amount,
    required DateTime date,
  }) async {
    if (amount <= 0 || fromId == toId) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction((txn) async {
      await txn.insert('transfers', {
        'id': _uuid.v4(),
        'made_on': dayKey(date),
        'from_account_id': fromId,
        'to_account_id': toId,
        'amount': amount,
        'created_at': now,
        'updated_at': now,
      });
      await recomputeBalances(txn);
    });
  }
}
