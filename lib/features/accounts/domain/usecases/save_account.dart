import 'package:gastegi/features/accounts/domain/failures.dart';
import 'package:gastegi/features/accounts/domain/repositories/account_repository.dart';

/// Crea o edita una cuenta, validando antes.
///
/// Existe como caso de uso —y no como una llamada directa al repositorio—
/// porque las dos reglas que aplica son de negocio y no de almacenamiento: una
/// cuenta necesita nombre, y dos cuentas vivas no pueden llamarse igual.
class SaveAccount {
  const SaveAccount(this._repository);

  final AccountRepository _repository;

  /// Devuelve el fallo, o `null` si se guardó. Con [id] nulo crea; si no, edita.
  Future<AccountFailure?> call({
    required String? id,
    required String name,
    required String kind,
    required String iconKey,
    required double balance,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return const EmptyAccountName();
    if (await _repository.nameExists(trimmedName, exceptId: id)) {
      return const DuplicateAccountName();
    }

    if (id == null) {
      await _repository.create(
        name: trimmedName,
        kind: kind.trim(),
        iconKey: iconKey,
        initialBalance: balance,
      );
    } else {
      await _repository.update(
        id,
        name: trimmedName,
        kind: kind.trim(),
        iconKey: iconKey,
        balance: balance,
      );
    }
    return null;
  }
}
