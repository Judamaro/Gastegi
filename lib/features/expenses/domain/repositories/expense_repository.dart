import 'package:gastegi/features/expenses/domain/entities/expense.dart';

/// Lo que el dominio necesita saber de los gastos.
abstract interface class ExpenseRepository {
  /// Gastos desde [from] (incluido), del más reciente al más antiguo.
  Future<List<Expense>> since(DateTime from);

  /// Cuántos gastos hay en total. Distingue "todavía no has registrado nada"
  /// de "no hay nada en el periodo que estás mirando".
  Future<int> count();

  /// Total gastado por mes desde [from], indexado por `YYYY-MM`.
  Future<Map<String, double>> monthlyTotals({required DateTime from});

  /// Crea el gasto y devuelve su id. El saldo de la cuenta queda recalculado.
  Future<String> create({
    required DateTime date,
    required String description,
    required String categoryId,
    required String? accountId,
    required double amount,
  });

  /// Borrado lógico; el saldo de la cuenta queda recalculado.
  Future<void> softDelete(String id);
}
