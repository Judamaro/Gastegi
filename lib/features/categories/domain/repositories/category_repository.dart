import 'package:gastegi/features/categories/domain/entities/category.dart';

/// Lo que el dominio necesita saber de las categorías.
abstract interface class CategoryRepository {
  /// Categorías vivas, en su orden de presentación.
  Future<List<Category>> all();

  /// Crea la categoría y devuelve su id.
  Future<String> create({
    required String name,
    required int colorValue,
    required String iconKey,
    required double budget,
  });

  /// Edita la categoría entera, presupuesto mensual incluido.
  Future<void> update(
    String id, {
    required String name,
    required int colorValue,
    required String iconKey,
    required double budget,
  });

  /// Borrado lógico.
  Future<void> softDelete(String id);

  /// Cuántos gastos apuntan a esta categoría. Decide si se puede borrar: a
  /// diferencia de la cuenta, la categoría de un gasto es obligatoria.
  Future<int> expenseCount(String id);

  /// Si ya existe otra categoría con ese nombre, ignorando mayúsculas.
  Future<bool> nameExists(String name, {String? exceptId});
}
