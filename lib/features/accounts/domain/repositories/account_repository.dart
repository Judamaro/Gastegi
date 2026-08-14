import 'package:gastegi/features/accounts/domain/entities/account.dart';

/// Lo que el dominio necesita saber de las cuentas y de las transferencias
/// entre ellas. El *cómo* —SQLite hoy, quizá una API mañana— vive en
/// `data/repositories/`.
abstract interface class AccountRepository {
  /// Cuentas activas, ordenadas. Las archivadas solo salen con
  /// [includeArchived].
  Future<List<Account>> all({bool includeArchived});

  /// Crea la cuenta y devuelve su id.
  Future<String> create({
    required String name,
    required String kind,
    required String iconKey,
    required double initialBalance,
  });

  /// Edita la cuenta. [balance] es el saldo que el usuario ve y teclea; como el
  /// saldo real se deriva de los movimientos, la implementación traslada la
  /// diferencia al saldo inicial.
  Future<void> update(
    String id, {
    required String name,
    required String kind,
    required String iconKey,
    required double balance,
  });

  Future<void> setArchived(String id, bool archived);

  /// Borrado lógico. Los gastos de la cuenta no se tocan.
  Future<void> softDelete(String id);

  /// Cuántos gastos apuntan a esta cuenta. Decide si al borrarla se ofrece
  /// archivarla en su lugar.
  Future<int> expenseCount(String id);

  /// Si ya existe otra cuenta con ese nombre, ignorando mayúsculas.
  Future<bool> nameExists(String name, {String? exceptId});

  /// Registra un movimiento entre dos cuentas. No hace nada si el importe no es
  /// positivo o si origen y destino coinciden.
  Future<void> transfer({
    required String fromId,
    required String toId,
    required double amount,
    required DateTime date,
  });
}
