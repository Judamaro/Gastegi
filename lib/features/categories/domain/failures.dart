import 'package:gastegi/core/errors/failures.dart';

/// Fallos al guardar o borrar una categoría.
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

/// Tiene gastos, así que no se puede borrar: todo gasto pertenece a una
/// categoría.
///
/// Lleva [count] porque el mensaje lo dice —«tiene 3 gastos»— y quien aplica
/// la regla ya lo ha contado: volver a preguntarlo desde la pantalla abriría
/// una ventana en la que el número puede haber cambiado.
final class CategoryHasExpenses extends CategoryFailure {
  const CategoryHasExpenses(this.count);

  final int count;
}
