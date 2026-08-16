import 'package:gastegi/core/errors/failures.dart';

/// Fallos al guardar una categoría.
///
/// `sealed` para que un `switch` en la presentación sea exhaustivo: si mañana
/// se añade un fallo nuevo, el compilador señala dónde falta el mensaje.
sealed class CategoryFailure extends Failure {
  const CategoryFailure();
}

/// El nombre está vacío o son solo espacios.
final class EmptyCategoryName extends CategoryFailure {
  const EmptyCategoryName();
}

/// Ya existe otra categoría viva con ese nombre (ignorando mayúsculas).
final class DuplicateCategoryName extends CategoryFailure {
  const DuplicateCategoryName();
}
