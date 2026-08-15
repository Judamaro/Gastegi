import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/state/app_data.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/core/utils/formatters.dart';
import 'package:gastegi/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:gastegi/features/accounts/domain/usecases/transfer_between_accounts.dart';

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

  TransferFormState _withSelection(String? fromId, String? toId) =>
      TransferFormState(open: open, fromId: fromId, toId: toId, amount: amount);
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

    return s._withSelection(from, to);
  }

  void open() => state = _normalized(
    const TransferFormState(open: true),
    ref.read(appDataProvider),
  );

  void close() =>
      state = _normalized(const TransferFormState(), ref.read(appDataProvider));

  void pickFrom(String id) => state = _normalized(
    TransferFormState(open: state.open, fromId: id, amount: state.amount),
    ref.read(appDataProvider),
  );

  void pickTo(String id) => state = TransferFormState(
    open: state.open,
    fromId: state.fromId,
    toId: id,
    amount: state.amount,
  );

  void setAmount(String value) => state = TransferFormState(
    open: state.open,
    fromId: state.fromId,
    toId: state.toId,
    amount: value,
  );

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
