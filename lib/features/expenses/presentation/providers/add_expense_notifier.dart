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
    this.categoryName,
    this.accountId,
    this.description = '',
  });

  /// Importe tal y como lo teclea el usuario, con coma decimal.
  final String amount;

  final String? categoryName;
  final String? accountId;
  final String description;
  final DateTime date;

  double get amountValue => parseAmount(amount);

  /// Un gasto necesita importe, categoría y cuenta.
  bool get saveDisabled =>
      !(amountValue > 0 && categoryName != null && accountId != null);

  AddExpenseState copyWith({
    String? amount,
    Object? categoryName = _keep,
    Object? accountId = _keep,
    String? description,
    DateTime? date,
  }) => AddExpenseState(
    amount: amount ?? this.amount,
    categoryName: identical(categoryName, _keep)
        ? this.categoryName
        : categoryName as String?,
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
        s.categoryName == null ||
        data.categories.any((c) => c.name == s.categoryName);
    if (accountExists && categoryExists) return s;
    return s.copyWith(
      accountId: accountExists ? _keep : null,
      categoryName: categoryExists ? _keep : null,
    );
  }

  /// Teclado propio: dígitos, una sola coma decimal y borrado, con máximo 7
  /// dígitos.
  void keypadTap(String key) {
    var a = state.amount;
    if (key == '⌫') {
      a = a.isEmpty ? a : a.substring(0, a.length - 1);
    } else if (key == ',') {
      if (!a.contains(',')) a = '${a.isEmpty ? '0' : a},';
    } else if (a.replaceAll(',', '').length < 7) {
      a += key;
    }
    state = state.copyWith(amount: a);
  }

  void pickCategory(String name) => state = state.copyWith(categoryName: name);

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
    final category = ref.read(appDataProvider).categoryOf(state.categoryName!);
    if (category == null) return false;

    final saveExpense = SaveExpense(ref.read(expenseRepositoryProvider));
    await ref
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

    state = AddExpenseState(date: ref.read(appDataProvider).today);
    return true;
  }
}

final addExpenseProvider =
    NotifierProvider<AddExpenseNotifier, AddExpenseState>(
      AddExpenseNotifier.new,
    );
