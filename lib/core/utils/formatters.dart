import 'package:intl/intl.dart';

final NumberFormat _decimal = NumberFormat.decimalPattern('es');

/// Redondea a entero y aplica separador de miles es-ES.
String formatAmount(double n) => _decimal.format(n.round());

/// Porcentaje entero de [part] sobre [whole]; 0 si [whole] no es positivo.
///
/// Sin esta guarda, una app recién instalada calcula `0 / 0` y el
/// `double.nan.round()` resultante lanza `UnsupportedError`.
int percentOf(double part, double whole) =>
    whole > 0 ? (part / whole * 100).round() : 0;
