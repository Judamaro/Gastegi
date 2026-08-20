import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/core/utils/formatters.dart';
import 'package:gastegi/features/categories/data/repositories/category_repository_impl.dart';
import 'package:gastegi/features/categories/domain/entities/category.dart';
import 'package:gastegi/features/categories/domain/failures.dart';
import 'package:gastegi/features/categories/domain/usecases/save_category.dart';

/// Centinela para distinguir "no me pases este campo" de "ponlo a null" en
/// [CategoryFormState.copyWith].
const Object _keep = Object();

/// Color e icono de partida de una categoría nueva. Los primeros de sus
/// catálogos, para que el formulario abra con algo elegido y no en blanco.
///
/// El color se toma de [AppColors] y no se copia aquí: un literal suelto se
/// queda atrás en cuanto la paleta cambia, y el formulario abriría sin ninguna
/// muestra marcada sin que nada fallara.
const int _defaultColorValue = AppColors.defaultCategoryColorValue;
const String _defaultIconKey = 'forkKnife';

/// Formulario de alta y edición de categorías, y confirmación de borrado.
///
/// Como el de cuentas, los dos se renderizan **en línea** bajo la lista de
/// presupuestos, no en un diálogo.
@immutable
class CategoryFormState {
  const CategoryFormState({
    this.open = false,
    this.editingId,
    this.name = '',
    this.colorValue = _defaultColorValue,
    this.iconKey = _defaultIconKey,
    this.budget = '',
    this.failure,
    this.pendingDeleteId,
    this.pendingDeleteExpenses = 0,
  });

  final bool open;

  /// Id de la categoría que se edita; nulo si se está creando una.
  final String? editingId;

  final String name;
  final int colorValue;
  final String iconKey;

  /// Importe **canónico**: punto decimal, sin miles ni símbolo. La página lo
  /// traduce al idioma del dispositivo.
  final String budget;

  final CategoryFailure? failure;

  /// Categoría cuya confirmación de borrado está abierta.
  final String? pendingDeleteId;

  /// Gastos de esa categoría; si hay alguno, el borrado no se ofrece.
  final int pendingDeleteExpenses;

  bool get isEditing => editingId != null;

  CategoryFormState copyWith({
    bool? open,
    Object? editingId = _keep,
    String? name,
    int? colorValue,
    String? iconKey,
    String? budget,
    Object? failure = _keep,
    Object? pendingDeleteId = _keep,
    int? pendingDeleteExpenses,
  }) => CategoryFormState(
    open: open ?? this.open,
    editingId: identical(editingId, _keep)
        ? this.editingId
        : editingId as String?,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
    iconKey: iconKey ?? this.iconKey,
    budget: budget ?? this.budget,
    failure: identical(failure, _keep)
        ? this.failure
        : failure as CategoryFailure?,
    pendingDeleteId: identical(pendingDeleteId, _keep)
        ? this.pendingDeleteId
        : pendingDeleteId as String?,
    pendingDeleteExpenses: pendingDeleteExpenses ?? this.pendingDeleteExpenses,
  );
}

class CategoryFormNotifier extends Notifier<CategoryFormState> {
  @override
  CategoryFormState build() => const CategoryFormState();

  /// Abre el formulario. Sin [category] crea una categoría nueva.
  void open([Category? category]) {
    state = CategoryFormState(
      open: true,
      editingId: category?.id,
      name: category?.name ?? '',
      colorValue: category?.colorValue ?? _defaultColorValue,
      iconKey: category?.iconKey ?? _defaultIconKey,
      budget: category == null ? '' : canonicalAmount(category.budget),
    );
  }

  void close() => state = const CategoryFormState();

  /// El fallo se limpia al escribir: dejarlo puesto haría creer al usuario que
  /// el nombre que acaba de teclear también está mal.
  void setName(String value) =>
      state = state.copyWith(name: value, failure: null);

  void setBudget(String value) => state = state.copyWith(budget: value);

  void pickColor(int value) => state = state.copyWith(colorValue: value);

  void pickIcon(String key) => state = state.copyWith(iconKey: key);

  Future<void> submit() async {
    final saveCategory = SaveCategory(ref.read(categoryRepositoryProvider));
    CategoryFailure? failure;
    await ref.read(appDataProvider.notifier).write(() async {
      failure = await saveCategory(
        id: state.editingId,
        name: state.name,
        colorValue: state.colorValue,
        iconKey: state.iconKey,
        budget: parseAmount(state.budget),
      );
    });

    state = failure == null
        ? const CategoryFormState()
        : state.copyWith(failure: failure);
  }

  // ── Borrado ────────────────────────────────────────────────────────────

  Future<void> askDelete(String id) async {
    final count = await ref.read(categoryRepositoryProvider).expenseCount(id);
    state = state.copyWith(
      open: false,
      pendingDeleteId: id,
      pendingDeleteExpenses: count,
    );
  }

  void cancelDelete() =>
      state = state.copyWith(pendingDeleteId: null, pendingDeleteExpenses: 0);

  /// No hace nada si la categoría tiene gastos.
  ///
  /// La categoría de un gasto es obligatoria y la dona del inicio reparte el
  /// total entre las categorías vivas: borrar una con gastos dejaría porciones
  /// que ya no suman el total del mes, sin que fallara nada.
  Future<void> confirmDelete() async {
    final id = state.pendingDeleteId;
    if (id == null || state.pendingDeleteExpenses > 0) return;
    final repo = ref.read(categoryRepositoryProvider);
    await ref.read(appDataProvider.notifier).write(() => repo.softDelete(id));
    cancelDelete();
  }
}

final categoryFormProvider =
    NotifierProvider<CategoryFormNotifier, CategoryFormState>(
      CategoryFormNotifier.new,
    );
