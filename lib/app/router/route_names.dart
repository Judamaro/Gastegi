/// Rutas de la aplicación, en un solo sitio para no repetir cadenas sueltas.
abstract final class RouteNames {
  static const String home = '/home';
  static const String history = '/history';
  static const String accounts = '/accounts';
  static const String budgets = '/budgets';

  /// Nuevo gasto. Vive fuera del shell: es la única pantalla que oculta la
  /// barra de pestañas.
  static const String addExpense = '/add';

  /// Detalle de una categoría, anidado bajo [home].
  static const String categoryDetail = 'categories/:name';

  /// Ruta al detalle de [name], con el nombre escapado: las categorías las
  /// nombra el usuario y pueden llevar espacios o barras.
  static String categoryDetailOf(String name) =>
      '$home/categories/${Uri.encodeComponent(name)}';
}
