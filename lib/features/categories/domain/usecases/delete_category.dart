import 'package:gastegi/features/categories/domain/failures.dart';
import 'package:gastegi/features/categories/domain/repositories/category_repository.dart';

/// Borra una categoría, validando antes.
///
/// La regla que aplica es de negocio y no de almacenamiento: la categoría de
/// un gasto es obligatoria, así que una categoría con gastos no se puede
/// quitar de en medio.
///
/// Vive aquí y no en el notifier porque contar y decidir tienen que pasar
/// **juntos**: entre que la pantalla pregunta cuántos gastos hay y el usuario
/// confirma, puede haberse registrado uno. Sus gastos quedarían apuntando a
/// una fila que `all()` ya no devuelve, aparecería una clave huérfana en
/// `catTotals` que ninguna pantalla pinta, y la dona y las barras dejarían de
/// sumar el total del mes **sin lanzar nada**.
class DeleteCategory {
  const DeleteCategory(this._repository);

  final CategoryRepository _repository;

  /// Devuelve el fallo, o `null` si se borró.
  Future<CategoryFailure?> call(String id) async {
    final count = await _repository.expenseCount(id);
    if (count > 0) return CategoryHasExpenses(count);

    await _repository.softDelete(id);
    return null;
  }
}
