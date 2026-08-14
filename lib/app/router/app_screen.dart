/// Destinos de navegación de la app.
///
/// La navegación es hoy un enum y un `switch` en `app_shell.dart`, sin
/// `Navigator`. Vive en `app/router/` porque es donde estará su sustituto
/// cuando llegue el router de verdad.
enum Screen { home, history, catDetail, accounts, budgets, add }
