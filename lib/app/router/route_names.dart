/// Rutas de la aplicación, en un solo sitio para no repetir cadenas sueltas.
abstract final class RouteNames {
  static const String home = '/home';
  static const String history = '/history';
  static const String accounts = '/accounts';
  static const String budgets = '/budgets';

  /// Nuevo gasto. Vive fuera del shell: es la única pantalla que oculta la
  /// barra de pestañas.
  static const String addExpense = '/add';

  /// El segmento, una sola vez: escrito en los dos sitios, cambiar uno deja
  /// el otro apuntando a una ruta que no existe **sin error de compilación**.
  static const String _categories = 'categories';

  /// Detalle de una categoría, anidado bajo [home].
  static const String categoryDetail = '$_categories/:id';

  /// Ruta al detalle de la categoría [id].
  ///
  /// Por id y no por nombre: el nombre lo escribe el usuario, se puede
  /// renombrar desde Presupuestos, y una ruta abierta en la otra rama del
  /// shell se quedaría apuntando a algo que ya no existe. El id además es un
  /// UUID, así que no hace falta escaparlo.
  static String categoryDetailOf(String id) => '$home/$_categories/$id';
}
