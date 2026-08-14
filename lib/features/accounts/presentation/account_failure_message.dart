import 'package:gastegi/features/accounts/domain/failures.dart';

/// Texto para el usuario de cada fallo al guardar una cuenta.
///
/// El dominio devuelve el fallo; el texto se decide aquí, que es lo que permite
/// traducirlo sin tocar el dominio. El `switch` es exhaustivo sobre un `sealed`:
/// si mañana se añade un fallo, el compilador señala esta función.
String accountFailureMessage(AccountFailure failure) => switch (failure) {
  EmptyAccountName() => 'Ponle un nombre a la cuenta',
  DuplicateAccountName() => 'Ya tienes una cuenta con ese nombre',
};
