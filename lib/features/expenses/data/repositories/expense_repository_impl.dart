import 'package:gastegi/core/storage/balances.dart';
import 'package:gastegi/core/utils/date_utils.dart';
import 'package:gastegi/features/expenses/data/models/expense_model.dart';
import 'package:gastegi/features/expenses/domain/entities/expense.dart';
import 'package:gastegi/features/expenses/domain/repositories/expense_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Lectura y escritura de gastos.
class ExpenseRepositoryImpl implements ExpenseRepository {
  const ExpenseRepositoryImpl(this._db);

  final Database _db;
  static const _uuid = Uuid();

  /// Gastos desde [from] (incluido), del más reciente al más antiguo.
  ///
  /// El `LEFT JOIN` sobre cuentas **no** filtra los tombstones a propósito: así
  /// el historial de un gasto sigue mostrando el nombre de su cuenta aunque el
  /// usuario la haya borrado después.
  @override
  Future<List<Expense>> since(DateTime from) async {
    final rows = await _db.rawQuery(
      '''
      SELECT e.*, c.name AS category_name, a.name AS account_name
      FROM expenses e
      JOIN categories c ON c.id = e.category_id
      LEFT JOIN accounts a ON a.id = e.account_id
      WHERE e.spent_on >= ? AND e.deleted_at IS NULL
      ORDER BY e.spent_on DESC, e.created_at DESC
      ''',
      [dayKey(from)],
    );
    return rows.map(ExpenseModel.fromRow).toList();
  }

  /// Cuántos gastos hay en total. Distingue "todavía no has registrado nada"
  /// de "no hay nada en el periodo que estás mirando".
  @override
  Future<int> count() async =>
      Sqflite.firstIntValue(
        await _db.rawQuery(
          'SELECT COUNT(*) FROM expenses WHERE deleted_at IS NULL',
        ),
      ) ??
      0;

  /// Total gastado por mes desde [from], indexado por `YYYY-MM`.
  @override
  Future<Map<String, double>> monthlyTotals({required DateTime from}) async {
    final rows = await _db.rawQuery(
      '''
      SELECT substr(spent_on, 1, 7) AS ym, SUM(amount) AS total
      FROM expenses
      WHERE spent_on >= ? AND deleted_at IS NULL
      GROUP BY ym
      ''',
      [dayKey(from)],
    );
    return {
      for (final r in rows)
        r['ym'] as String: (r['total'] as num?)?.toDouble() ?? 0,
    };
  }

  /// Inserta el gasto y recalcula saldos en una sola transacción: si algo
  /// falla, no queda un gasto sin reflejar en el saldo de su cuenta.
  @override
  Future<String> create({
    required DateTime date,
    required String description,
    required String categoryId,
    required String? accountId,
    required double amount,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction((txn) async {
      await txn.insert('expenses', {
        'id': id,
        'spent_on': dayKey(date),
        'description': description,
        'category_id': categoryId,
        'account_id': accountId,
        'amount': amount,
        'created_at': now,
        'updated_at': now,
      });
      await recomputeBalances(txn);
    });
    return id;
  }

  /// Borrado lógico: la fila sobrevive como tombstone para que el borrado se
  /// pueda propagar cuando exista sincronización.
  @override
  Future<void> softDelete(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction((txn) async {
      await txn.update(
        'expenses',
        {'deleted_at': now, 'updated_at': now},
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: [id],
      );
      await recomputeBalances(txn);
    });
  }
}
