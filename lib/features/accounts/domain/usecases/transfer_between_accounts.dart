import 'package:gastegi/features/accounts/domain/repositories/account_repository.dart';

/// Mueve dinero de una cuenta a otra.
///
/// Concentra aquí la regla de cuándo un traspaso es válido, que antes estaba
/// duplicada entre la pantalla y el repositorio.
class TransferBetweenAccounts {
  const TransferBetweenAccounts(this._repository);

  final AccountRepository _repository;

  /// `true` si el movimiento se registró. Devuelve `false` sin tocar nada si
  /// falta alguna cuenta, si son la misma o si el importe no es positivo.
  Future<bool> call({
    required String? fromId,
    required String? toId,
    required double amount,
    required DateTime date,
  }) async {
    if (fromId == null || toId == null || fromId == toId || amount <= 0) {
      return false;
    }
    await _repository.transfer(
      fromId: fromId,
      toId: toId,
      amount: amount,
      date: date,
    );
    return true;
  }
}
