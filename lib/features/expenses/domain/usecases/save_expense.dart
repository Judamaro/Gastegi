import 'package:gastegi/features/categories/domain/entities/category.dart';
import 'package:gastegi/features/expenses/domain/repositories/expense_repository.dart';

/// Registra un gasto.
///
/// Importa la entidad `Category` de otra funcionalidad, que es la única
/// dependencia entre features que la arquitectura permite: `domain` contra
/// `domain`, nunca contra su `data` ni su `presentation`.
class SaveExpense {
  const SaveExpense(this._repository);

  final ExpenseRepository _repository;

  /// Devuelve el id del gasto creado.
  ///
  /// Si la descripción viene vacía se usa el nombre de la categoría: una fila
  /// del historial sin texto no le dice nada al usuario.
  Future<String> call({
    required DateTime date,
    required String description,
    required Category category,
    required String? accountId,
    required double amount,
  }) {
    final trimmed = description.trim();
    return _repository.create(
      date: date,
      description: trimmed.isEmpty ? category.name : trimmed,
      categoryId: category.id,
      accountId: accountId,
      amount: amount,
    );
  }
}
