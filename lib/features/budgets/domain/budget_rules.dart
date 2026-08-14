/// Reglas de negocio de los presupuestos.
///
/// No están en `core/constants/` porque no son constantes de la aplicación:
/// son una decisión sobre cuándo avisar al usuario, y le pertenece a esta
/// funcionalidad.
library;

/// Fracción del presupuesto a partir de la cual se avisa. Por debajo no se
/// dice nada; a partir de 1 el presupuesto está excedido.
const double budgetAlertThreshold = 0.90;
