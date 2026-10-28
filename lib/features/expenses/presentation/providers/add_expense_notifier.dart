import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/state/app_data.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/core/utils/date_utils.dart';
import 'package:gastegi/core/utils/formatters.dart';
import 'package:gastegi/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:gastegi/features/expenses/domain/usecases/save_expense.dart';

/// Centinela para distinguir "no me pases este campo" de "ponlo a null".
const Object _keep = Object();

/// El formulario de nuevo gasto.
@immutable
class AddExpenseState {
  const AddExpenseState({
    required this.date,
    this.amount = '',
    this.categoryId,
    this.accountId,
    this.description = '',
  });

  /// Importe canónico: dígitos y, como mucho, un punto decimal.
  ///
  /// Sin separadores de miles ni símbolo. Lo que ve el usuario lo compone
  /// `MoneyLabels.typed` en la página, que sí conoce el idioma.
  final String amount;

  /// Id de la categoría elegida.
  ///
  /// El id y no el nombre: el nombre lo escribe el usuario y renombrar una
  /// categoría con el formulario abierto vaciaba el chip elegido.
  final String? categoryId;
  final String? accountId;
  final String description;
  final DateTime date;

  double get amountValue => parseAmount(amount);

  /// Un gasto necesita importe, categoría y cuenta.
  bool get saveDisabled =>
      !(amountValue > 0 && categoryId != null && accountId != null);

  AddExpenseState copyWith({
    String? amount,
    Object? categoryId = _keep,
    Object? accountId = _keep,
    String? description,
    DateTime? date,
  }) => AddExpenseState(
    amount: amount ?? this.amount,
    categoryId: identical(categoryId, _keep)
        ? this.categoryId
        : categoryId as String?,
    accountId: identical(accountId, _keep)
        ? this.accountId
        : accountId as String?,
    description: description ?? this.description,
    date: date ?? this.date,
  );
}

class AddExpenseNotifier extends Notifier<AddExpenseState> {
  @override
  AddExpenseState build() {
    // La categoría o la cuenta elegidas pueden desaparecer mientras el
    // formulario sigue abierto: se borra una cuenta desde su pantalla y el chip
    // seleccionado se quedaría apuntando a una fila que ya no existe.
    ref.listen(appDataProvider, (_, data) => state = _normalized(state, data));
    return AddExpenseState(date: ref.read(appDataProvider).today);
  }

  static AddExpenseState _normalized(AddExpenseState s, AppData data) {
    final accountExists =
        s.accountId == null || data.accounts.any((a) => a.id == s.accountId);
    final categoryExists =
        s.categoryId == null ||
        data.categories.any((c) => c.id == s.categoryId);
    if (accountExists && categoryExists) return s;
    return s.copyWith(
      accountId: accountExists ? _keep : null,
      categoryId: categoryExists ? _keep : null,
    );
  }

  /// El importe, ya canónico.
  ///
  /// No valida nada a propósito: lo que llega viene del campo del visor, que
  /// pasa cada pulsación por `MoneyInputFormatter` y este por
  /// `MoneyLabels.canonical`, donde viven el tope de enteros, el de decimales y
  /// la regla del único separador decimal. Repetirlas aquí las pondría en dos
  /// sitios, y solo uno de los dos se acordaría de cambiarlas.
  void setAmount(String value) => state = state.copyWith(amount: value);

  void pickCategory(String id) => state = state.copyWith(categoryId: id);

  void pickAccount(String id) => state = state.copyWith(accountId: id);

  void setDescription(String value) =>
      state = state.copyWith(description: value);

  void setDate(DateTime date) => state = state.copyWith(date: dateOnly(date));

  /// Guarda el gasto y deja el formulario limpio para el siguiente.
  ///
  /// Devuelve `false` si faltaba algún dato; quien llama decide si navegar,
  /// que es cosa de la pantalla y no del estado.
  Future<bool> save() async {
    if (state.saveDisabled) return false;
    final category = ref.read(appDataProvider).categoryById(state.categoryId!);
    if (category == null) return false;

    final saveExpense = SaveExpense(ref.read(expenseRepositoryProvider));
    final ran = await ref
        .read(appDataProvider.notifier)
        .write(
          () => saveExpense(
            date: state.date,
            description: state.description,
            category: category,
            accountId: state.accountId,
            amount: state.amountValue,
          ),
        );
    // Con el cerrojo echado no se ha guardado nada. Devolver `true` aquí
    // limpiaba el formulario y mandaba a la página a navegar a Inicio como si
    // el gasto existiera.
    if (!ran) return false;

    state = AddExpenseState(date: ref.read(appDataProvider).today);
    return true;
  }
}

final addExpenseProvider =
    NotifierProvider<AddExpenseNotifier, AddExpenseState>(
      AddExpenseNotifier.new,
    );
