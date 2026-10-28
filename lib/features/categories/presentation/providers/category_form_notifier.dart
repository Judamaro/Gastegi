import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/core/utils/formatters.dart';
import 'package:gastegi/features/categories/data/repositories/category_repository_impl.dart';
import 'package:gastegi/features/categories/domain/entities/category.dart';
import 'package:gastegi/features/categories/domain/failures.dart';
import 'package:gastegi/features/categories/domain/usecases/delete_category.dart';
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
    final ran = await ref.read(appDataProvider.notifier).write(() async {
      failure = await saveCategory(
        id: state.editingId,
        name: state.name,
        colorValue: state.colorValue,
        iconKey: state.iconKey,
        budget: parseAmount(state.budget),
      );
    });
    // El cerrojo estaba echado y `saveCategory` no llegó a correr: `failure`
    // sigue a `null` porque nadie lo tocó, no porque haya ido bien. Cerrar
    // aquí tiraría lo tecleado sin haber guardado nada.
    if (!ran) return;

    state = failure == null
        ? const CategoryFormState()
        : state.copyWith(failure: failure);
  }

  // ── Borrado ────────────────────────────────────────────────────────────

  /// Abre la confirmación. El recuento es solo para el aviso: quien decide si
  /// se puede borrar es [DeleteCategory], al confirmar.
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

  /// Pide el borrado y refleja lo que conteste el caso de uso.
  ///
  /// Aquí no se repite la regla: el recuento que trae el estado es del momento
  /// en que se abrió la confirmación, y entre eso y el toque en «Eliminar»
  /// puede haberse registrado un gasto. Si [DeleteCategory] dice que no, la
  /// confirmación se queda abierta con el motivo puesto al día: el usuario ha
  /// tocado el botón y tiene que ver por qué no ha pasado nada.
  Future<void> confirmDelete() async {
    final id = state.pendingDeleteId;
    if (id == null) return;

    final deleteCategory = DeleteCategory(ref.read(categoryRepositoryProvider));
    CategoryFailure? failure;
    final ran = await ref.read(appDataProvider.notifier).write(() async {
      failure = await deleteCategory(id);
    });
    // Sin ejecutar no hay veredicto que reflejar: la confirmación se queda
    // como estaba y el usuario puede volver a tocar.
    if (!ran) return;

    state = switch (failure) {
      CategoryHasExpenses(:final count) => state.copyWith(
        pendingDeleteExpenses: count,
      ),
      _ => state.copyWith(pendingDeleteId: null, pendingDeleteExpenses: 0),
    };
  }
}

final categoryFormProvider =
    NotifierProvider<CategoryFormNotifier, CategoryFormState>(
      CategoryFormNotifier.new,
    );
