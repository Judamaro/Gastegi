import 'package:gastegi/features/categories/domain/failures.dart';
import 'package:gastegi/features/categories/domain/repositories/category_repository.dart';

/// Crea o edita una categoría, validando antes.
///
/// Las dos reglas que aplica son de negocio y no de almacenamiento: una
/// categoría necesita nombre, y dos categorías vivas no pueden llamarse igual
/// —el nombre es lo que las enlaza con sus gastos en toda la presentación—.
class SaveCategory {
  const SaveCategory(this._repository);

  final CategoryRepository _repository;

  /// Devuelve el fallo, o `null` si se guardó. Con [id] nulo crea; si no, edita.
  Future<CategoryFailure?> call({
    required String? id,
    required String name,
    required int colorValue,
    required String iconKey,
    required double budget,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return const EmptyCategoryName();
    if (await _repository.nameExists(trimmedName, exceptId: id)) {
      return const DuplicateCategoryName();
    }

    if (id == null) {
      await _repository.create(
        name: trimmedName,
        colorValue: colorValue,
        iconKey: iconKey,
        budget: budget,
      );
    } else {
      await _repository.update(
        id,
        name: trimmedName,
        colorValue: colorValue,
        iconKey: iconKey,
        budget: budget,
      );
    }
    return null;
  }
}
