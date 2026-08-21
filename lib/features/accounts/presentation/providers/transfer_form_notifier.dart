import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/state/app_data.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/core/utils/formatters.dart';
import 'package:gastegi/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:gastegi/features/accounts/domain/usecases/transfer_between_accounts.dart';

/// Centinela para distinguir "no me pases este campo" de "ponlo a null" en
/// [TransferFormState.copyWith].
const Object _keep = Object();

/// Formulario de transferencia entre cuentas.
@immutable
class TransferFormState {
  const TransferFormState({
    this.open = false,
    this.fromId,
    this.toId,
    this.amount = '',
  });

  final bool open;
  final String? fromId;
  final String? toId;
  final String amount;

  double get amountValue => parseAmount(amount);

  TransferFormState copyWith({
    bool? open,
    Object? fromId = _keep,
    Object? toId = _keep,
    String? amount,
  }) => TransferFormState(
    open: open ?? this.open,
    fromId: identical(fromId, _keep) ? this.fromId : fromId as String?,
    toId: identical(toId, _keep) ? this.toId : toId as String?,
    amount: amount ?? this.amount,
  );
}

class TransferFormNotifier extends Notifier<TransferFormState> {
  @override
  TransferFormState build() {
    // Las cuentas pueden desaparecer bajo los pies de los selectores: al
    // borrar o archivar una, el chip seleccionado apuntaría a una fila que ya
    // no existe. Se corrige aquí, y no en quien escribe, porque este es el
    // único sitio que sabe qué tiene seleccionado.
    ref.listen(appDataProvider, (_, data) => state = _normalized(state, data));
    return _normalized(const TransferFormState(), ref.read(appDataProvider));
  }

  static TransferFormState _normalized(TransferFormState s, AppData data) {
    final accounts = data.accounts;
    final ids = accounts.map((a) => a.id).toSet();

    final from = (s.fromId == null || !ids.contains(s.fromId))
        ? (accounts.isNotEmpty ? accounts.first.id : null)
        : s.fromId;

    final to = (s.toId == null || !ids.contains(s.toId) || s.toId == from)
        ? (accounts.length > 1
              ? accounts.firstWhere((a) => a.id != from).id
              : null)
        : s.toId;

    return s.copyWith(fromId: from, toId: to);
  }

  /// Todo cambio de estado pasa por aquí.
  ///
  /// Normalizar en un solo sitio es lo que impide que un mutador nuevo se
  /// olvide de hacerlo: así fue como `pickTo` llegó a admitir la cuenta de
  /// origen como destino, y el traspaso se quedaba sin hacer en silencio.
  void _apply(TransferFormState next) =>
      state = _normalized(next, ref.read(appDataProvider));

  void open() => _apply(const TransferFormState(open: true));

  void close() => _apply(const TransferFormState());

  void pickFrom(String id) => _apply(state.copyWith(fromId: id));

  void pickTo(String id) => _apply(state.copyWith(toId: id));

  void setAmount(String value) => _apply(state.copyWith(amount: value));

  Future<void> submit() async {
    final transfer = TransferBetweenAccounts(
      ref.read(accountRepositoryProvider),
    );
    var done = false;
    await ref.read(appDataProvider.notifier).write(() async {
      done = await transfer(
        fromId: state.fromId,
        toId: state.toId,
        amount: state.amountValue,
        date: ref.read(appDataProvider).today,
      );
    });
    // Si no se hizo nada, el formulario se queda abierto con lo tecleado: el
    // usuario tiene que poder corregir el importe o el destino.
    if (done) close();
  }
}

final transferFormProvider =
    NotifierProvider<TransferFormNotifier, TransferFormState>(
      TransferFormNotifier.new,
    );
