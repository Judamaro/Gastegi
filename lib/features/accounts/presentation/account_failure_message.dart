import 'package:gastegi/features/accounts/domain/failures.dart';
import 'package:gastegi/l10n/generated/app_localizations.dart';

/// Texto para el usuario de cada fallo al guardar una cuenta.
///
/// El dominio devuelve el fallo; el texto se decide aquí, que es lo que permite
/// traducirlo sin tocar el dominio. El `switch` es exhaustivo sobre un `sealed`:
/// si mañana se añade un fallo, el compilador señala esta función.
String accountFailureMessage(AppLocalizations l10n, AccountFailure failure) =>
    switch (failure) {
      EmptyAccountName() => l10n.accountFormEmptyName,
      DuplicateAccountName() => l10n.accountFormDuplicateName,
    };
