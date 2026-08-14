import 'package:gastegi/features/expenses/domain/entities/expense.dart';

/// [Expense] con el mapeo desde una fila de la consulta de gastos.
///
/// Las columnas `category_name` y `account_name` no están en la tabla: las
/// añade el JOIN de `ExpenseRepository.since`.
class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.date,
    required super.desc,
    required super.categoryId,
    required super.categoryName,
    required super.accountId,
    required super.accountName,
    required super.val,
  });

  factory ExpenseModel.fromRow(Map<String, Object?> r) => ExpenseModel(
    id: r['id'] as String,
    date: DateTime.parse(r['spent_on'] as String),
    desc: r['description'] as String,
    categoryId: r['category_id'] as String,
    categoryName: r['category_name'] as String,
    accountId: r['account_id'] as String?,
    // TODO(l10n): este literal debería salir de aquí y resolverlo la
    // presentación a partir de un `accountName` nulo.
    accountName: (r['account_name'] as String?) ?? 'Sin cuenta',
    val: (r['amount'] as num).toDouble(),
  );
}
