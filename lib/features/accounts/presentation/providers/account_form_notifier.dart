import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/core/utils/formatters.dart';
import 'package:gastegi/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:gastegi/features/accounts/domain/entities/account.dart';
import 'package:gastegi/features/accounts/domain/failures.dart';
import 'package:gastegi/features/accounts/domain/usecases/save_account.dart';

/// Centinela para distinguir "no me pases este campo" de "ponlo a null" en
/// [AccountFormState.copyWith].
const Object _keep = Object();

/// Formulario de alta y edición de cuentas, y confirmación de borrado.
///
/// Los dos se renderizan **en línea** bajo la lista, no en un diálogo: es una
/// decisión de diseño de la app, no una consecuencia de no tener router.
@immutable
class AccountFormState {
  const AccountFormState({
    this.open = false,
    this.editingId,
    this.name = '',
    this.kind = '',
    this.balance = '',
    this.iconKey = 'wallet',
    this.failure,
    this.pendingDeleteId,
    this.pendingDeleteExpenses = 0,
  });

  final bool open;

  /// Id de la cuenta que se edita; nulo si se está creando una.
  final String? editingId;

  final String name;
  final String kind;
  final String balance;
  final String iconKey;
  final AccountFailure? failure;

  /// Cuenta cuya confirmación de borrado está abierta.
  final String? pendingDeleteId;

  /// Gastos asociados a esa cuenta; decide si la confirmación ofrece archivar.
  final int pendingDeleteExpenses;

  bool get isEditing => editingId != null;

  AccountFormState copyWith({
    bool? open,
    Object? editingId = _keep,
    String? name,
    String? kind,
    String? balance,
    String? iconKey,
    Object? failure = _keep,
    Object? pendingDeleteId = _keep,
    int? pendingDeleteExpenses,
  }) => AccountFormState(
    open: open ?? this.open,
    editingId: identical(editingId, _keep)
        ? this.editingId
        : editingId as String?,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    balance: balance ?? this.balance,
    iconKey: iconKey ?? this.iconKey,
    failure: identical(failure, _keep)
        ? this.failure
        : failure as AccountFailure?,
    pendingDeleteId: identical(pendingDeleteId, _keep)
        ? this.pendingDeleteId
        : pendingDeleteId as String?,
    pendingDeleteExpenses: pendingDeleteExpenses ?? this.pendingDeleteExpenses,
  );
}

class AccountFormNotifier extends Notifier<AccountFormState> {
  @override
  AccountFormState build() => const AccountFormState();

  /// Abre el formulario. Sin [account] crea una cuenta nueva.
  void open([Account? account]) {
    state = AccountFormState(
      open: true,
      editingId: account?.id,
      name: account?.name ?? '',
      kind: account?.kind ?? '',
      balance: account == null ? '' : canonicalAmount(account.balance),
      iconKey: account?.iconKey ?? 'wallet',
    );
  }

  void close() => state = const AccountFormState();

  /// El fallo se limpia al escribir: dejarlo puesto haría creer al usuario que
  /// el nombre que acaba de teclear también está mal.
  void setName(String value) =>
      state = state.copyWith(name: value, failure: null);

  void setKind(String value) => state = state.copyWith(kind: value);

  void setBalance(String value) => state = state.copyWith(balance: value);

  void pickIcon(String key) => state = state.copyWith(iconKey: key);

  Future<void> submit() async {
    final saveAccount = SaveAccount(ref.read(accountRepositoryProvider));
    AccountFailure? failure;
    final ran = await ref.read(appDataProvider.notifier).write(() async {
      failure = await saveAccount(
        id: state.editingId,
        name: state.name,
        kind: state.kind,
        iconKey: state.iconKey,
        balance: parseAmount(state.balance),
      );
    });
    // El cerrojo estaba echado y `saveAccount` no llegó a correr: `failure`
    // sigue a `null` porque nadie lo tocó, no porque haya ido bien. Cerrar
    // aquí tiraría lo tecleado sin haber guardado nada.
    if (!ran) return;

    state = failure == null
        ? const AccountFormState()
        : state.copyWith(failure: failure);
  }

  // ── Borrado ────────────────────────────────────────────────────────────

  Future<void> askDelete(String id) async {
    final count = await ref.read(accountRepositoryProvider).expenseCount(id);
    state = state.copyWith(
      open: false,
      pendingDeleteId: id,
      pendingDeleteExpenses: count,
    );
  }

  void cancelDelete() =>
      state = state.copyWith(pendingDeleteId: null, pendingDeleteExpenses: 0);

  Future<void> confirmDelete() async {
    final id = state.pendingDeleteId;
    if (id == null) return;
    final repo = ref.read(accountRepositoryProvider);
    // La confirmación solo se cierra si el borrado se hizo de verdad.
    if (await ref
        .read(appDataProvider.notifier)
        .write(() => repo.softDelete(id))) {
      cancelDelete();
    }
  }

  Future<void> archivePending() async {
    final id = state.pendingDeleteId;
    if (id == null) return;
    final repo = ref.read(accountRepositoryProvider);
    if (await ref
        .read(appDataProvider.notifier)
        .write(() => repo.setArchived(id, true))) {
      cancelDelete();
    }
  }
}

final accountFormProvider =
    NotifierProvider<AccountFormNotifier, AccountFormState>(
      AccountFormNotifier.new,
    );
