import 'package:gastegi/features/categories/domain/entities/category.dart';

/// Lo que el dominio necesita saber de las categorías.
abstract interface class CategoryRepository {
  /// Categorías vivas, en su orden de presentación.
  Future<List<Category>> all();

  /// Cambia el presupuesto mensual de una categoría.
  // TODO(presupuestos): todavía no hay pantalla que edite presupuestos, así que
  // nadie llama a esto. Se conserva porque la columna existe desde la v1 del
  // esquema y la funcionalidad está prevista.
  Future<void> updateBudget(String id, double budget);
}
