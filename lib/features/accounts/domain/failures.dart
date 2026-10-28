import 'package:gastegi/core/errors/failures.dart';

/// Fallos al guardar una cuenta.
///
/// `sealed` para que un `switch` en la presentación sea exhaustivo: si mañana
/// se añade un fallo nuevo, el compilador señala dónde falta el mensaje.
sealed class AccountFailure extends Failure {
  const AccountFailure();
}

/// El nombre está vacío o son solo espacios.
final class EmptyAccountName extends AccountFailure {
  const EmptyAccountName();
}

/// Ya existe otra cuenta viva con ese nombre (ignorando mayúsculas).
final class DuplicateAccountName extends AccountFailure {
  const DuplicateAccountName();
}
