/// Gasto individual.
///
/// [categoryName] y [accountName] son los nombres resueltos por el JOIN de la
/// consulta, para que las pantallas sigan mostrando texto sin más búsquedas.
class Expense {
  const Expense({
    required this.id,
    required this.date,
    required this.desc,
    required this.categoryId,
    required this.categoryName,
    required this.accountId,
    required this.accountName,
    required this.val,
  });

  /// UUID de texto; ver la nota en `Category`.
  final String id;

  /// Medianoche local del día del gasto.
  final DateTime date;
  final String desc;
  final String categoryId;
  final String categoryName;
  final String? accountId;

  /// Nombre de la cuenta, o `null` si el gasto no tiene ninguna. El texto que
  /// se muestra en ese caso lo decide la presentación.
  final String? accountName;

  final double val;

  /// Día del mes; lo usan los cortes semanales del detalle de categoría.
  int get day => date.day;
}
